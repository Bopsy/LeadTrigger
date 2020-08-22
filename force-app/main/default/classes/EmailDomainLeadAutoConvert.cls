// To execute the batch process run:
//    
//    Database.executeBatch(new EmailDomainLeadAutoConvert(), 5);
//
// -OR- to process records older than 12 hours
//
//    EmailDomainLeadAutoConvert e = new EmailDomainLeadAutoConvert();
//    e.processRecordsOlderThan = 12;
//    Database.executeBatch(e, 5);
//
global class EmailDomainLeadAutoConvert implements Database.Batchable<sObject> {
//    global String[] emailTo = new String[] { 'jonathan.f.griggs@gmail.com' };
//    global String emailFrom = 'pmorrow@twilio.com';

	public Set<String> emailDomains = new Set<String>();
	public Integer processRecordsOlderThan = 24;  // Number of hours
	
	global EmailDomainLeadAutoConvert (){
		for (Email_Domain__c e : [ SELECT Id, Name FROM Email_Domain__c WHERE Approved__c = true ]) {
			emailDomains.add(e.Name);
		}
	}

	global EmailDomainLeadAutoConvert (Set<String> emailDomains){
		this.emailDomains = emailDomains;
	}

    global Database.querylocator start(Database.BatchableContext BC){
    	// Only select leads that have been inserted before X hours
    	DateTime t = DateTime.now().addHours(-1 * processRecordsOlderThan);
    	
		// Get the list of profile IDs that should be excluded from auto-conversion on record update only
		// Query the lead's profile owner ID to determine if it should be excluded
		// If the lead should be exclude remove it from the leadsToProcess
		Set<String> userProfilesToExclude = new Set<String>();
		for (DoNotAutoConvert__c d : DoNotAutoConvert__c.getAll().values()) {
			userProfilesToExclude.add(d.Profile_ID__c);
		}

		return DataBase.getQueryLocator([
			SELECT Id, Email, Preferred_Email__c, ISO_Country_Code__c, FirstName, LastName, LeadSource, Description, Status, Owner.Type
			FROM Lead
			WHERE IsConverted = false
			AND Status = 'Open'
            AND Owner.Type = 'User'
            AND CreatedDate < :t 
			AND Email_Domain_Without_HTTP_lower__c IN :emailDomains
			AND (NOT (
				Owner.ProfileId IN :userProfilesToExclude
				AND Owner.UserRole.Name LIKE '%Outbound%'
			))
		]);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,Lead> leads = new Map<Id,Lead>();
        for(sObject s : scope){
            Lead l = (Lead)s;
            leads.put(l.Id, l);
        }

        if (!leads.isEmpty()) {
            LeadAutoConvertHandler.convert(leads);
        }
    }

    global void finish(Database.BatchableContext BC){
//        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
//            TotalJobItems, ExtendedStatus, CreatedBy.Email
//            FROM AsyncApexJob WHERE Id = :BC.getJobId()];
    
//        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//        mail.setToAddresses(emailTo);
//        mail.setReplyTo(emailFrom);
//        mail.setSenderDisplayName('NPC Lead Auto-Conversion Totals Processing');
//        mail.setSubject('NPCLeadAutoConvert Batch Process Completed:'  + a.Status);
//        mail.setPlainTextBody('NPCLeadAutoConvert Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.\n\n' + a.ExtendedStatus);

//        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}