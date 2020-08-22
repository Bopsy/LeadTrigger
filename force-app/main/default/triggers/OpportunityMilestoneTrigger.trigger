trigger OpportunityMilestoneTrigger on Opportunity_Milestone__c (after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            for(Opportunity_Milestone__c milestone: trigger.new){
                if(milestone.Id != null && milestone.JIRA_Id__c != null){
                    JIRAWebserviceCalloutSyncFields.syncfields(milestone.JIRA_Id__c, milestone.Id);
                }
            }
        }
        else if(trigger.isUpdate){
            for(Opportunity_Milestone__c milestone: trigger.new){
                Opportunity_Milestone__c oldData = trigger.oldMap.get(milestone.Id);
                if(oldData.JIRA_Id__c != milestone.JIRA_Id__c){
                    JIRAWebserviceCalloutSyncFields.syncfields(milestone.JIRA_Id__c, milestone.Id);
                }
            }
        }
    }
}