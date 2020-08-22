// To execute the batch process run:
//    
//    Database.executeBatch(new CampaignMemberAutoConvert(), 50);
//
global class CampaignMemberAutoConvert implements Database.Batchable<sObject> {
//    global String[] emailTo = new String[] { 'pmorrow@twilio.com', 'jbauch@twilio.com', 'van@twilio.com', 'jonathan.f.griggs@gmail.com' };
//    global String[] emailTo = new String[] { 'jonathan.f.griggs@gmail.com' };
//    global String emailFrom = 'pmorrow@twilio.com';

	public Set<Id> leadIds;  
	global CampaignMemberAutoConvert (){
		this.leadIds = new Set<Id>();
	}

	global CampaignMemberAutoConvert (Set<Id> leadIds){
		this.leadIds = leadIds;
	}

    global Database.querylocator start(Database.BatchableContext BC){
    	
    	if (leadIds.isEmpty()) {
    		return Test.isRunningTest() ? Database.getQueryLocator([
				SELECT Id, LeadId
				FROM CampaignMember
				WHERE Lead.IsConverted = false
				AND Eloqua_Campaign_Association_Done__c = true
				LIMIT 10
			]) : Database.getQueryLocator([
				SELECT Id, LeadId
				FROM CampaignMember
				WHERE Lead.IsConverted = false
				AND Eloqua_Campaign_Association_Done__c = true
			]);
    	} else {
    		return DataBase.getQueryLocator([
				SELECT Id, LeadId
				FROM CampaignMember
				WHERE Lead.IsConverted = false
				AND Eloqua_Campaign_Association_Done__c = true
				AND LeadId IN :leadIds
			]);
    	}
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<CampaignMember> members = new List<CampaignMember>();
    	Set<Id> leadIds = new Set<Id>();
        for(sObject s : scope){
            CampaignMember m = (CampaignMember)s;
            leadIds.add(m.LeadId);

			// Toggle the Eloqua_Campaign_Association_Done__c to avoid
			// reprocessing the lead in the future
            m.Eloqua_Campaign_Association_Done__c = false;
			members.add(m);
        }
        update members;

        if (!leadIds.isEmpty()) {
        	List<String> freemail = new List<String>(Free_Email_Domains__c.getAll().keySet());
			Map<Id,Lead> leads = new Map<Id,Lead>([
	            SELECT Id, Email, Preferred_Email__c, FirstName, LastName, LeadSource, Description
	            FROM Lead
	            WHERE IsConverted = false
	            AND Email != ''
	            AND Email NOT IN :freemail
	            AND Status = 'Open'
	            AND Owner.Type = 'User'
	            AND Id IN :leadIds
	        ]);
	
	        if (!leads.isEmpty()) {
	            LeadAutoConvertHandler.convert(leads);
	        }
        }
    }

    global void finish(Database.BatchableContext BC){
//        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
//            TotalJobItems, ExtendedStatus, CreatedBy.Email
//            FROM AsyncApexJob WHERE Id = :BC.getJobId()];
//    
//        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//        mail.setToAddresses(emailTo);
//        mail.setReplyTo(emailFrom);
//        mail.setSenderDisplayName('Eloqua Lead Auto-Conversion Totals Processing');
//        mail.setSubject('CampaignMemberAutoConvert Batch Process Completed:'  + a.Status);
//        mail.setPlainTextBody('CampaignMemberAutoConvert Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.\n\n' + a.ExtendedStatus);
//
//        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}