trigger CampaignMemberAutoConvert on CampaignMember (after insert, after update) {
    
    Set<Id> leadIds = new Set<Id>();
    
    // If the campaign member is updated and the Eloqua_Campaign_Association_Done__c is changed from false to true then auto-convert.
    if(Trigger.isUpdate){
        for(CampaignMember m : Trigger.new){
            System.debug('======> CampaignMember(' + m.LeadId + ', old=' + Trigger.oldMap.get(m.Id).Eloqua_Campaign_Association_Done__c + ', new=' + m.Eloqua_Campaign_Association_Done__c + ')');
            if (m.LeadId != null
                && m.Eloqua_Campaign_Association_Done__c == true
                && Trigger.oldMap.get(m.Id).Eloqua_Campaign_Association_Done__c == false
            ) {
                leadIds.add(m.LeadId);
            }
        }
    }

    // If the campaign member is new the Eloqua_Campaign_Association_Done__c is true then attempt to auto-convert.
    if (Trigger.isInsert) {
        for(CampaignMember m : Trigger.new){
            System.debug('======> CampaignMember(' + m.LeadId + ', new=' + m.Eloqua_Campaign_Association_Done__c + ')');
            if (m.LeadId != null
                && m.Eloqua_Campaign_Association_Done__c == true
            ) {
                leadIds.add(m.LeadId);
            }
        }
    }

    if (!leadIds.isEmpty()) {
        List<Id> ids = new List<Id>(leadIds);
        Map<Id,Lead> leads = new Map<Id,Lead>([
            SELECT Id, Email, FirstName, LastName, LeadSource, Description
            FROM Lead
            WHERE IsConverted = false
            AND Email != ''
            AND Email LIKE '%@checkboxtest.com'
            AND Is_Free_Email_ELOQUA1__c = 'No'
            AND Is_Free_Email_ELOQUA2__c = 'No'
            AND Status = 'Open'
            AND Owner.Type = 'User'
            AND Id IN :ids
        ]);

        if (!leads.isEmpty()) {
            LeadAutoConvertHandler.convert(leads);
        }
    }
}