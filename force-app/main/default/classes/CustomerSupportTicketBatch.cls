public with sharing class CustomerSupportTicketBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    //
    // The batch will query back all Country Phone Number Type.
    //
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Generate a list of records to batch process
        return Database.getQueryLocator(
            'SELECT Id, Submitters_Email__c, Account__c, Account_SID__c ' +
            'FROM Customer_Support_Ticket__c ' +
            'WHERE Account__c = null AND Submitters_Email__c != null'
        );
    }

    //
    // If there is a Contact has exact match with the field Submitters_Email__c, populate this Contact's Account on Account__c
    // If the email domain is matching any Email_Domain__c object, populate the email domain's account lookup on Account__c.
    //
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,Customer_Support_Ticket__c> recMap = new Map<Id,Customer_Support_Ticket__c>();
        Set<String> emails = new Set<String>();
        Set<String> emailDomains = new Set<String>();
        Set<String> accountSids = new Set<String>();
        for (sObject s : scope) {
            Customer_Support_Ticket__c r = (Customer_Support_Ticket__c)s;
            recMap.put(r.Id, r);
            emails.add(r.Submitters_Email__c);
            emailDomains.add(r.Submitters_Email__c.split('@').get(1));
            if (String.isNotBlank(r.Account_SID__c))
            	accountSids.add(r.Account_SID__c);
        }

        
        System.debug('CustomerSupportTicketBatch LINKING RECORDS TO ACCOUNTS VIA ACCOUNT.EMAIL');
        Map<Id,Customer_Support_Ticket__c> recordsToUpdate = new Map<Id,Customer_Support_Ticket__c>();
        Map<String,Contact> emailToContactMap = new Map<String,Contact>();
        for (Contact c : [ SELECT Id, Email, AccountId FROM Contact WHERE Email IN :emails ]) {
            emailToContactMap.put(c.Email, c);
        }

        for (Customer_Support_Ticket__c t : recMap.values()) {
            if (emailToContactMap.containsKey(t.Submitters_Email__c)) {
                t.Account__c = emailToContactMap.get(t.Submitters_Email__c).AccountId;
                t.Contact__c = emailToContactMap.get(t.Submitters_Email__c).Id;
                recordsToUpdate.put(t.Id, t);
            }
        }

        System.debug('CustomerSupportTicketBatch LINKING RECORDS TO ACCOUNTS VIA EMAIL_DOMAIN__C.NAME');
        Map<String,Email_Domain__c> emailToEmailDomainMap = new Map<String,Email_Domain__c>();
        for (Email_Domain__c e : [ SELECT Id, Name, Account__r.Id FROM Email_Domain__c WHERE Name IN :emailDomains ]) {
            emailToEmailDomainMap.put(e.Name, e);
        }

		System.debug('CustomSupportTicketBatch LINKING RECORDS TO ACCOUNT SIDS');
		Map<String,Account_SID__c> accountSidMap = new Map<String,Account_SID__c>();
		for (Account_SID__c a : [ SELECT Id, Name FROM Account_SID__c WHERE Name IN :accountSids ]) {
			accountSidMap.put(a.Name, a);
		}

        for (Customer_Support_Ticket__c t : recMap.values()) {
			Boolean recordUpdated = false;
            String d = t.Submitters_Email__c.split('@').get(1);
            
            if (emailToEmailDomainMap.containsKey(d)) {
                t.Account__c = emailToEmailDomainMap.get(d).Account__r.Id;
                recordUpdated = true;
            }

            if (accountSidMap.containsKey(t.Account_SID__c)) {
            	t.Account_SID_lookup__c = accountSidMap.get(t.Account_SID__c).Id;
                recordUpdated = true;
            }

			if (recordUpdated) {
	            recordsToUpdate.put(t.Id, t);
			}
        }

        update recordsToUpdate.values();
    }
    
    public void finish(Database.BatchableContext BC) {
        // Actions to perform when batch processing is finished
    }

    // Schedulable Interface Method
    public void execute(SchedulableContext context) {
        // Run the batch with a size of 2000 records instead of the default of 200
        database.executebatch(new CustomerSupportTicketBatch(), 2000);
    }
}