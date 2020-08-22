global class BatchMQLProcessing implements Database.Batchable<sObject>, Schedulable {
	public static String campaignName = 'RCCT - Short Code Application';

    global Database.querylocator start(Database.BatchableContext BC) {
        // Generate a list of records to batch process
        // (1) A Short Code record has Short_Code__c.Application_Status__c != "Rejects"
        // (2) A Short Code record has either Lead__c or Contact__c set
        // (3) A Short Code record that is a campaign member of "RCCT - Short Code Application"
        return Database.getQueryLocator([
            SELECT Id, MQL__c, Contact__c, Lead__c
            FROM Short_Code__c
            WHERE Application_Status__c != 'Rejected'
            AND (Lead__c != null OR Contact__c != null)
            AND MQL__c = null
        ]);
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchMQLProcessing());
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,Id> leads = new Map<Id,Id>();
        Map<Id,Id> contacts = new Map<Id,Id>();

        for (sObject s : scope) {
            Short_Code__c sc = (Short_Code__c)s;
            if (sc.Contact__c != null) {
                contacts.put(sc.Contact__c, sc.Id);
           		System.debug('BatchMQLProcessing.execute(): Mapping Contact(' + sc.Contact__c + ') to Short_Code__c(' + sc.Id + ')');
            } else {
                leads.put(sc.Lead__c, sc.Id);
           		System.debug('BatchMQLProcessing.execute(): Mapping Lead(' + sc.Lead__c + ') to Short_Code__c(' + sc.Id + ')');
            }
        }
        
        // Query the CampaignMember via Contact and Lead to determine if Short_Code__c should be linked
        // to a MQL (FSR__c) record
        if (!contacts.isEmpty() || !leads.isEmpty()) {
            List<Id> matchingLeads = new List<Id>();
            List<Id> matchingContacts = new List<Id>();
        
            for (CampaignMember member : [
                SELECT Id, ContactId, LeadId
                FROM CampaignMember
                WHERE Campaign.Name = :campaignName
                AND (LeadId IN :leads.keySet() OR ContactId IN :contacts.keySet())
            ]) {
                if (member.ContactId != null && contacts.containsKey(member.ContactId)) {
                    matchingContacts.add(member.ContactId);
            		System.debug('BatchMQLProcessing.execute(): Found qualifying Contact(' + member.ContactId + ')');
                } else if (member.LeadId != null && leads.containsKey(member.LeadId)) {
                    matchingLeads.add(member.LeadId);
            		System.debug('BatchMQLProcessing.execute(): Found qualifying Lead(' + member.LeadId + ')');
                }
            }
            
            if (!matchingLeads.isEmpty() || !matchingContacts.isEmpty()) {
                MQLHandler.linkShortCodesByLeadOrContact([
                    SELECT Id, Contact__c, Lead__c
                    FROM FSR__c
                    WHERE (Contact__c IN :matchingContacts OR Lead__c IN :matchingLeads)
                ]);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Actions to perform when batch processing is finished
    }
}