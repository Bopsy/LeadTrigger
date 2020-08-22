trigger FeatureRequestTrigger on JIRA_Ticket__c (after update, after insert, before insert, before update) {
    if(trigger.isAfter){
        Map<Id, String> changeReqStatus = new Map<Id, String>();
        Map<String, String> statusMap = new Map<String, String>{'Not-Planned' => 'Closed - Not on Roadmap', 'Planned' => 'Closed - On Roadmap', 'Delivered' => 'Closed - Available'};
        for(JIRA_Ticket__c req: trigger.new){
            JIRA_Ticket__c oldReq = trigger.oldMap == null ? null : trigger.oldMap.get(req.Id);
            if(req.Status__c != null && (oldReq == null || oldReq.Status__c != req.Status__c)){
                if(req.Status__c == 'Planned' || req.Status__c == 'Not-Planned' || req.Status__c == 'Delivered'){
                    changeReqStatus.put(req.Id, statusMap.get(req.Status__c));
                }
            }
        }
        List<Feature_Requests__c> updateStories = new List<Feature_Requests__c>();
        if(!changeReqStatus.isEmpty()){
            for(Feature_Requests__c story: [SELECT JIRA_Ticket_Lookup__c FROM Feature_Requests__c WHERE JIRA_Ticket_Lookup__c =: changeReqStatus.keySet()]){
                story.Status__c = changeReqStatus.get(story.JIRA_Ticket_Lookup__c);
                updateStories.add(story);
            }
            update updateStories;
        }
        if(trigger.isUpdate){
            List<JIRA_Ticket__c> completeReqs = new List<JIRA_Ticket__c>();
            List<JIRA_Ticket__c> plannedornotReqs = new List<JIRA_Ticket__c>();
            for(JIRA_Ticket__c req: trigger.new){
                JIRA_Ticket__c oldReq = trigger.oldMap.get(req.Id);
                if(oldReq.Status__c != req.Status__c){
                    if(req.Status__c == 'Delivered'){
                        completeReqs.add(req);
                    }
                    else if(req.Status__c == 'Planned' || req.Status__c == 'Not-Planned'){
                        plannedornotReqs.add(req);
                    }
                }
            }
            
            
            List<Feature_Requests__c> stories = new List<Feature_Requests__c>();
            
            for(Feature_Requests__c story: [SELECT Id FROM Feature_Requests__c WHERE JIRA_Ticket_Lookup__c =: completeReqs]){
                story.Send_Complete_Email__c = true;
                stories.add(story);
            }
            
            for(Feature_Requests__c story: [SELECT Id FROM Feature_Requests__c WHERE JIRA_Ticket_Lookup__c =: plannedornotReqs]){
                story.Send_Planned_Not_Planned_Email__c = true;
                stories.add(story);
            }
            
            update stories;
        }
    }
    else if(trigger.isBefore){
        Map<String, Id> queueIdMap = new Map<String, Id>();
        for(FR_Product_Group_Email__mdt setting: [SELECT QueueId__c, MasterLabel FROM FR_Product_Group_Email__mdt]){
            queueIdMap.put(setting.MasterLabel, setting.QueueId__c);
        }
        Map<Id, Group> queueMap = new Map<Id, Group>([SELECT Id, Email FROM Group WHERE Id =: queueIdMap.values()]);
        for(JIRA_Ticket__c ticket: trigger.new){
            if(trigger.isInsert){
                ticket.Status__c = 'Assigned';
            }
            for(String groupName: queueIdMap.keySet()){
                if(groupName == ticket.Product_Group__c){
                    Id queueId = queueIdMap.get(groupName);
                    String email = queueMap.get(queueId).Email;
                    ticket.OwnerId = queueId;
                    ticket.Product_Group_Queue_Email__c = email;
                }
            }
        }
    }
    
}