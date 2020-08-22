global class BatchShortCodeOwnerBackfill implements Database.Batchable<sObject>, Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchShortCodeOwnerBackfill());
    }

    global Database.querylocator start(Database.BatchableContext BC) {
        // Generate a list of records to batch process
        // (1) A Short Code record has Short_Code__c.Application_Status__c = "Pending Twilio"
        return Database.getQueryLocator([
            SELECT Id, Contact__c, Opportunity__c, Contact__r.AccountId, Contact__r.Account.OwnerId, Opportunity__r.OwnerId, Application_Status__c, Status__c
            FROM Short_Code__c
            WHERE Contact__c != null
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Short_Code__c> shortCodes = new List<Short_Code__c>();
        
        Set<String> appStatusInclusions = new Set<String> {'Approved', 'In Provisioning', 'Pending Carriers', 'Pending Payment'};

        for (sObject s : scope) {
            Short_Code__c sc = (Short_Code__c)s;
            if (appStatusInclusions.contains(sc.Application_Status__c) && sc.Status__c == 'Waiting for Approval') {
				if (sc.Opportunity__c != null && sc.Opportunity__r.OwnerId != null) {
					sc.OwnerId = sc.Opportunity__r.OwnerId;
					shortCodes.add(sc);
					System.debug('BatchShortCodeOwnerBackfill.execute(SET OWNERSHIP SAME AS OPPTY): ' + sc);
					System.debug('BatchShortCodeOwnerBackfill.execute(OPPTY.OWNER): ' + sc.Opportunity__r.OwnerId);
				}
            } else {
				if (sc.Contact__c != null && sc.Contact__r.AccountId != null && sc.Contact__r.Account.OwnerId != null) {
		    		sc.OwnerId = sc.Contact__r.Account.OwnerId;
		    		sc.Account__c = sc.Contact__r.AccountId;
		    		sc.Contact__c = sc.Contact__c;
	                shortCodes.add(sc);
					System.debug('BatchShortCodeOwnerBackfill.execute(SET OWNERSHIP SAME AS CONTACT.ACCOUNT): ' + sc);
					System.debug('BatchShortCodeOwnerBackfill.execute(CONTACT.ACCOUNT.OWNER): ' + sc.Contact__r.Account.OwnerId);
				}
            }
        }
        
        update shortCodes;
    }
    
    global void finish(Database.BatchableContext BC) {
        // Actions to perform when batch processing is finished
    }
}