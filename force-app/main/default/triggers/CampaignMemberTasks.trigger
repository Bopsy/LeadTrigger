trigger CampaignMemberTasks on CampaignMember (after insert, after update) {
    
    // All SalesOps owned Leads/Contacts will be assigned to Behzad Nouri.
    String salesOpsUserName = 'Sales Operations';
    String salesOpsOwnerAssignment = 'Behzad Nouri';
    
    Map<Id,CampaignMember> members = new Map<Id,CampaignMember>();
    Set<Id> campaignIds = new Set<Id>();

    // If the campaign member is updated and the Status has changed to either 'Opened Email'
    // or 'Clicked Email' create a Task for the Lead/Contact Owner
    if(Trigger.isUpdate){
        for(CampaignMember m : Trigger.new){
            System.debug('====> UPDATE CAMPAIGNMEMBER(CampaignMember=' + m.Id + ', New.Status=' + m.Status + ', Old.Status=' + Trigger.oldMap.get(m.Id).Status + ')');
            if ((m.Status == 'Opened Email' && Trigger.oldMap.get(m.Id).Status != 'Opened Email')
                || (m.Status == 'Clicked Email' && Trigger.oldMap.get(m.Id).Status != 'Clicked Email')
            ) {
                members.put(m.Id, m);
                campaignIds.add(m.CampaignId);
            }
        }
    }

    // If the campaign member is new and the Status is either 'Opened Email' or 'Clicked Email' 
    // create a Task for the Lead/Contact Owner
    if (Trigger.isInsert) {
        for(CampaignMember m : Trigger.new) {
            System.debug('====> INSERT CAMPAIGNMEMBER(CampaignMember=' + m.Id + ', Status=' + m.Status + ')');
            if (m.Status == 'Opened Email' || m.Status == 'Clicked Email') {
                members.put(m.Id, m);
                campaignIds.add(m.CampaignId);
            }
        }
    }

    if (!campaignIds.isEmpty()) {
        List<Task> tasks = new List<Task>();

        // Get the SalesOps and it's task owner user Ids
        Map<String, Id> salesOpsAssignment = new Map<String, Id>();
        for (User u : [ SELECT Id, Name FROM User WHERE Name IN (:salesOpsUserName, :salesOpsOwnerAssignment) ]) {
            salesOpsAssignment.put(u.Name, u.Id);
        }

        // Get a mapping of the related campaigns to check if a tast should be created
        // and if so want information to include in the task
        Map<Id,Campaign> campaigns = new Map<Id,Campaign>([
            SELECT Id, Create_Task_for_Clicked_Email__c, Create_Task_for_Opened_Email__c,
                Task_Call_Script__c, Task_Subject_Line__c
            FROM Campaign
            WHERE Id IN :campaignIds
        ]);
        
        // Get a mapping of the owners to assign to the task
        Map<Id,Id> owners = new Map<Id,Id>();
        for (CampaignMember m : [
            SELECT Id, LeadId, ContactId, Lead.OwnerId, Contact.OwnerId
            FROM CampaignMember
            WHERE Id IN :members.keySet()
        ]) {
            Id owner = (m.ContactId != null) ? m.Contact.OwnerId : m.Lead.OwnerId;

            // If the owner is SalesOps then set it to the intended fallback owner
            owner = (owner == salesOpsAssignment.get(salesOpsUserName)) ? salesOpsAssignment.get(salesOpsOwnerAssignment) : owner;

            owners.put(m.Id, owner);
        }

        for (CampaignMember m : members.values()) {
            if (campaigns.containsKey(m.CampaignId)) {
                Campaign c = campaigns.get(m.CampaignId);
                if ((c.Create_Task_for_Opened_Email__c && m.Status == 'Opened Email')
                    || (c.Create_Task_for_Clicked_Email__c && m.Status == 'Clicked Email')
                ) {
                    System.debug('====> CREATE TASK(CampaignMember=' + m.Id + ', LeadId=' + m.LeadId + ', ContactId=' + m.ContactId + ')');
                    tasks.add(new Task(
                        WhoId = (m.ContactId != null) ? m.ContactId : m.LeadId,
                        WhatId = (m.ContactId != null) ? c.Id : null,
                        OwnerId = owners.get(m.Id),
                        Subject = c.Task_Subject_Line__c,
                        Description = c.Task_Call_Script__c,
                        Type = 'Call',
                        ActivityDate = Date.today(),
                        Priority = 'Normal',
                        Status = 'Not Started'
                    ));
                }
            }
        }
        
        if (!tasks.isEmpty()) {
            //Set EmailHeader.triggerUserEmail to true
            Database.DMLOptions dmlo = new Database.DMLOptions();
            dmlo.EmailHeader.triggerUserEmail = true;
            Database.insert(tasks, dmlo);  
        }
    }
}