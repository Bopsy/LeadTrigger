trigger CampaignMemberFSR on CampaignMember (after insert, after update) {

    Set<String> apiUsers = new Set<String> { 'Kevin Eloqua', 'Jonathan Eloqua', 'API-Read Only', 'Eloqua Marketing' };

    List<CampaignMember> members = new List<CampaignMember>();
    Set<Id> campaignIds = new Set<Id>();
    
    // If the campaign member is inserted by an Eloqua API user create an FSR record
    if(Trigger.isInsert){
        for (CampaignMember m : Trigger.new) {
            System.debug('===> CAMPAIGN MEMBER INSERT(isApiUser=' + apiUsers.contains(UserInfo.getName()) + '/' + UserInfo.getName() + ')');
            if (apiUsers.contains(UserInfo.getName())) {
                members.add(m);
                campaignIds.add(m.CampaignId);
            }
        }
    }

    // If the campaign member is updated by an Eloqua API user and the Campaign_Member_Updated_Date__c changes create an FSR record
    if(Trigger.isUpdate){
        for (CampaignMember m : Trigger.new) {
            System.debug('===> CAMPAIGN MEMBER UPDATE('
                + 'isApiUser=' + apiUsers.contains(UserInfo.getName()) + '/' + UserInfo.getName()
                + 'hasCampaignMemberUpdatedDateChanged=' + (m.Campaign_Member_Updated_Date__c != Trigger.oldMap.get(m.Id).Campaign_Member_Updated_Date__c) + '/' + m.Campaign_Member_Updated_Date__c + ' != ' + Trigger.oldMap.get(m.Id).Campaign_Member_Updated_Date__c
                + ')');
            if (apiUsers.contains(UserInfo.getName())
                && m.Campaign_Member_Updated_Date__c != Trigger.oldMap.get(m.Id).Campaign_Member_Updated_Date__c
            ) {
                members.add(m);
                campaignIds.add(m.CampaignId);
            }
        }
    }


    if (!members.isEmpty()) {
        Map<Id,Campaign> fsrCampaigns = new Map<Id,Campaign>([ SELECT Id FROM Campaign WHERE Id IN :campaignIds AND Type = 'Full Service Request' ]);
        List<FSR__c> fsrToUpsert = new List<FSR__c>();
        
        // Get the list of the CampaignMember to FSR record fields mapping
        List<CampaignMember_to_FSR_Mapping__c> fieldMap = CampaignMember_to_FSR_Mapping__c.getAll().values();
        for (CampaignMember m : members) {
            if (fsrCampaigns.containsKey(m.CampaignId)) {
                String fsrKey = m.Email__c + '.' + m.Campaign_Member_Updated_Date__c;
                FSR__c fsr = new FSR__c(Name = fsrKey, FSR_Key__c = fsrKey);
                if (m.ContactId != null) { fsr.Contact__c = m.ContactId; }
                if (m.LeadId != null)    { fsr.Lead__c = m.LeadId; }
                System.debug('===> FSR RECORD(Name=' + fsr.Name
                    + ', FSR_Key=' + fsr.FSR_Key__c
                    + ', ContactId=' + (m.ContactId == null ? 'not set' : m.ContactId)
                    + ', LeadId=' + (m.LeadId == null ? 'not set' : m.LeadId)
                    + ')');
    
                for (CampaignMember_to_FSR_Mapping__c fm : fieldMap) {
                    System.debug('===> FSR SET FIELD(' + fm.FSR_Field__c + '=' + fm.CampaignMember_Field__c + ')');
                    fsr.put(fm.FSR_Field__c, m.get(fm.CampaignMember_Field__c));
                }
                fsrToUpsert.add(fsr);
            }
        }

        if (!fsrToUpsert.isEmpty()) {
            upsert fsrToUpsert FSR_Key__c;
        }
    }
}