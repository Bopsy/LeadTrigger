// To execute the batch process run:
//    
//    Database.executeBatch(new BatchLinkAccountToAccountSID(), 5);
//
global class BatchLinkAccountToAccountSID implements Database.Batchable<sObject> {

    global Database.querylocator start(Database.BatchableContext BC){
        // Generate a list of Account_SID__c records where the Account__c
        // is not set
        return DataBase.getQueryLocator([
            SELECT Id, Account__c, Email_Domain__c
            FROM Account_SID__c
            WHERE Account__c = null
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Account_SID__c> sids = new Set<Account_SID__c>();
        for(sObject s : scope){
            Account_SID__c l = (Account_SID__c)s;
            sids.add(l);
        }

        if (!sids.isEmpty()) {
	        // Get a list of all Free_Email_Domains__c so that can be excluded
	        Set<String> freemail = new Set<String>();
	        for (String s : Free_Email_Domains__c.getAll().keySet()) {
	            freemail.add(s.toLowerCase());
	        }           
	        System.debug('Free_Email_Domains__c count:  ' + freemail.size());

	        // Get a list of all email domains (except for freemail) for
	        // Account_SID__c record that have not already been related
	        // to an Account
	        // If the email domain matches a freemail remove it from the
	        // list of Account_SID__c records
	        Set<String> emailDomains = new Set<String>();
	        for (Account_SID__c sid : sids) {
	        	if (freemail.contains(sid.Email_Domain__c)) {
	        		sids.remove(sid);
	        	} else {
	            	emailDomains.add(sid.Email_Domain__c);
	        	}
	        }
	        System.debug('Unique email domains for Account_SID__c ' + sids.size() + ' records:  ' + emailDomains.size());
	        
	        // Cross-reference the Account_SID__c email domains with approved
	        // account Email_Domains__c to create a list of matching email domains
		    Map<String,Email_Domain__c> matchingEmailDomains = new Map<String,Email_Domain__c>();
	        for (Email_Domain__c d : [
	            SELECT Id, Name, Account__r.Id
	            FROM Email_Domain__c
	            WHERE Name IN :emailDomains
	            AND Approved__c = true
	        ]) {
	            matchingEmailDomains.put(d.Name, d);
	        }
	        System.debug('Matching email domains for Account_SID__c records that can be related to an Account:  ' + matchingEmailDomains.size());
	        
	        // Process the Account_SID__c records by attempting to match
	        // their Email_Domain__c to a related Account
	        // If not match then remove it from the list of Account_SID__c records
	        for (Account_SID__c sid : sids) {
	        	if (matchingEmailDomains.containsKey(sid.Email_Domain__c)) {
	        		sid.Account__c = matchingEmailDomains.get(sid.Email_Domain__c).Account__r.Id;
	        		System.debug('Account_SID__c has matching email domain:  AccountSID=' + sid.Id + ', Account=' + sid.Account__c + ', EmailDomain=' + sid.Email_Domain__c + ')');
	        	} else {
	        		sids.remove(sid);
	        	}
	        }
	        
	        // If any Account_SID__c records were matched to an Account
	        // then update them
	        if (!sids.isEmpty()) {
        		System.debug('Updated Account_SID__c records:  ' + sids.size() + ' total records');
	        	update new List<Account_SID__c>(sids);
	        }
        }
    }

    global void finish(Database.BatchableContext BC){
    }    
}