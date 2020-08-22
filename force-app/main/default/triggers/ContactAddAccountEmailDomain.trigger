trigger ContactAddAccountEmailDomain on Contact (after insert, after update) {
    Trigger_Bypass_Settings__c trigBypass = Trigger_Bypass_Settings__c.getInstance(UserInfo.getUserId());
    if(trigBypass != null){
        if(trigBypass.Contact__c == TRUE){ 
            return; 
        }
	}	
    
    Map<String,Contact> contacts = new Map<String,Contact>();

    if(Trigger.isUpdate){
        for(Contact c : Trigger.new){
            //System.debug('====> UPDATE CONTACT(Id=' + c.Id + ', New.Email=' + c.Email + ', Old.Email=' + Trigger.oldMap.get(c.Id).Email + ')');
            //System.debug('====> UPDATE CONTACT(Id=' + c.Id + ', New.PreferedEmail=' + c.Preferred_Email__c + ', Old.Preferred_Email__c=' + Trigger.oldMap.get(c.Id).Preferred_Email__c + ')');
            if (c.AccountId != null) {
	            if (c.Email != Trigger.oldMap.get(c.Id).Email || c.Preferred_Email__c != Trigger.oldMap.get(c.Id).Preferred_Email__c) {
	                String domain = LeadAutoConvertHandler.getEmailDomain(c.Email, c.Preferred_Email__c);
		            if (!String.isBlank(domain)) {
		                contacts.put(domain, c);
		            }
	            }
	            
            }
        }
    }

    // If the campaign member is new and the Status is either 'Opened Email' or 'Clicked Email' 
    // create a Task for the Lead/Contact Owner
    if (Trigger.isInsert) {
        for(Contact c : Trigger.new) {
            //System.debug('====> INSERT CONTACT(Id=' + c.Id + ', Email=' + c.Email + ')');
            //System.debug('====> INSERT CONTACT(Id=' + c.Id + ', PreferredEmail=' + c.Preferred_Email__c + ')');
            if (c.AccountId != null) {
	            String domain = LeadAutoConvertHandler.getEmailDomain(c.Email, c.Preferred_Email__c);
	            if (!String.isBlank(domain)) {
	                contacts.put(domain, c);
	            }
            }
        }
    }

    if (!contacts.isEmpty()) {
        // Remove any contact email domains that are already associated to accounts
        for (Email_Domain__c d : [ SELECT Id, Name FROM Email_Domain__c WHERE Name IN :contacts.keySet() ]) {
            if (contacts.containsKey(d.Name)) {
                contacts.remove(d.Name);
            }
        }
        
        // Create the account email domains from the remaining contact email domains
        List<Email_Domain__c> emailDomains = new List<Email_Domain__c>();
        for (String domain : contacts.keySet()) {
            Contact c = contacts.get(domain);
            Email_Domain__c newEmailDomain = new Email_Domain__c(Name = domain, Account__c = c.AccountId);
            if(UseCaseConvertController.inConversion) newEmailDomain.Approved__c = true;
            emailDomains.add(newEmailDomain);
        }
        
        if (!emailDomains.isEmpty()) {
            insert emailDomains;
        }
    }
}