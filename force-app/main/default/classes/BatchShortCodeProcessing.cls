global class BatchShortCodeProcessing implements Database.Batchable<sObject> {

	global Database.querylocator start(Database.BatchableContext BC) {
		// Generate a list of records to batch process
		// (1) A Short Code record has Short_Code__c.Application_Status__c = "Pending Twilio"
		return Database.getQueryLocator([
			SELECT Id, OwnerUser_Email_Address__c, Customer_Name__c, Account__c, Contact__c, Lead__c
			FROM Short_Code__c
			WHERE Application_Status__c = 'Pending Twilio'
			AND OwnerUser_Email_Address__c != null
		]);
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		Set<Short_Code__c> shortCodesToUpdate = new Set<Short_Code__c>();
		Map<Id,Short_Code__c> shortCodesToProcess = new Map<Id,Short_Code__c>();
		Map<Id,String> emailAddresses = new Map<Id,String>();

		for (sObject s : scope) {
			Short_Code__c sc = (Short_Code__c)s;
			shortCodesToProcess.put(sc.id, sc);
			emailAddresses.put(sc.Id, sc.OwnerUser_Email_Address__c);
		}
		
		// Query the Contacts object using Short_Code__c.OwnerUser_Email_Address__c to find a Contact with that Email
		if (!shortCodesToProcess.isEmpty()) {
			Map<Id,Contact> contacts = new Map<Id,Contact>([
				SELECT Id, AccountId, Email
				FROM Contact
				WHERE Email IN :emailAddresses.values()
			]);
	
			if (!shortCodesToProcess.isEmpty()) {
				// If Contact with Contact.Email equal to Short_Code__c.OwnerUser_Email_Address__c found
				// link Short Code to Contact via Short_Code__c.Contact__c
				for (Contact c : contacts.values()) {
					for (Short_Code__c sc : shortCodesToProcess.values()) {
						if (c.Email == sc.OwnerUser_Email_Address__c) {
							sc.Lead__c = null;
							sc.Contact__c = c.Id;
							sc.Account__c = c.AccountId;
							shortCodesToUpdate.add(sc);
		
							// Remove from list since it is being handled here
							shortCodesToProcess.remove(sc.Id);
						}
					}
				}
			}
		}
				
		// If no Contact linked, query Leads for matching email
		if (!shortCodesToProcess.isEmpty()) {
			Map<Id,Lead> leads = new Map<Id,Lead>([
				SELECT Id, Email
				FROM Lead
				WHERE Email IN :emailAddresses.values()
			]);

			for (Lead l : leads.values()) {
				// If Lead with Lead.Email equal to Short_Code__c.OwnerUser_Email_Address__c found
				// link Short Code to Lead via Short_Code__c.Lead__c
				for (Short_Code__c sc :  shortCodesToProcess.values()) {
					if (l.Email == sc.OwnerUser_Email_Address__c) {
						sc.Lead__c = l.Id;
						shortCodesToUpdate.add(sc);

						// Remove from list since it is being handled here
						shortCodesToProcess.remove(sc.Id);
					}
				}
			}
		}

		if (!shortCodesToUpdate.isEmpty()) {
			update new List<Short_Code__c>(shortCodesToUpdate);
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		// Actions to perform when batch processing is finished
	}
}