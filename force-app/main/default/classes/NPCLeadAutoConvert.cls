// To execute the batch process run:
//    
//    Database.executeBatch(new NPCLeadAutoConvert(), 5);
//
// -OR- to process records older than 12 hours
//
//    NPCLeadAutoConvert n = new NPCLeadAutoConvert();
//    n.processRecordsOlderThan = 12;
//    Database.executeBatch(n, 5);
//
global class NPCLeadAutoConvert implements Database.Batchable<sObject> {
    global String[] emailTo = new String[] { 'jonathan.f.griggs@gmail.com' };
    global String emailFrom = 'pmorrow@twilio.com';

	public Integer processRecordsOlderThan = 24;  // Number of hours

    global Database.querylocator start(Database.BatchableContext BC){
    	// Only select leads that have been inserted before X hours
    	DateTime t = DateTime.now().addHours(-1 * processRecordsOlderThan);
    	
    	return DataBase.getQueryLocator([
        	SELECT Id, Email, Preferred_Email__c, ISO_Country_Code__c, FirstName, LastName, LeadSource, Description, Status, Owner.Type
			FROM Lead
			WHERE IsConverted = false
			AND CreatedDate < :t 
			AND NPC_Date_5__c != null
			and ISO_Country_Code__c != null
		]);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,Lead> leads = new Map<Id,Lead>();
        for(sObject s : scope){
            Lead l = (Lead)s;
            leads.put(l.Id, l);
        }

        // Identify leads that qualify for LeadAutoConvert and 
        // attempt to process them
        Map<Id,Lead> leadsToAutoConvert = new Map<Id,Lead>();
        Map<Id,Lead> leadsNotConverted = new Map<Id,Lead>();
        Set<String> freemail = new Set<String>(Free_Email_Domains__c.getAll().keySet());
        
        for (Lead l : leads.values()) {
            String email = String.isBlank(l.Email) ? l.Preferred_Email__c : l.Email;
            if (!String.isBlank(email)
                && !freemail.contains(email)
                && l.Status == 'Open'
                && l.Owner.Type == 'User'
            ) {
                leadsToAutoConvert.put(l.Id, l);
            } else {
                leadsNotConverted.put(l.Id, l);
            }
            
        }
        
        if (!leadsToAutoConvert.isEmpty()) {
            leadsNotConverted.putAll(LeadAutoConvertHandler.convert(leadsToAutoConvert));
        }
        
        // For all leads that were not converted using LeadAutoConvert
        // do a straightforward lead conversion
        LeadAutoConvertHandler.convertNPCLead(leadsNotConverted);
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