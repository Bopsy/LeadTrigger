global class RollupLeadUsageTotal implements Database.Batchable<sObject> {
    global String[] emailTo = new String[] { 'pmorrow@twilio.com', 'jonathan.f.griggs@gmail.com' };
    global String emailFrom = 'pmorrow@twilio.com';

    global String current_months_year = String.valueOf(Datetime.now().year());
    global String current_months_month = Datetime.now().format('MMMMM'); 

    global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id FROM Lead WHERE IsDeleted = false AND IsConverted = false');
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> LeadIds = new Set<Id>();
        for(sObject s : scope){
            Lead a = (Lead)s;
            LeadIds.add(a.Id);
        }
        TwilioForecastHandler.updateLeadMonthlyRollup(LeadIds, current_months_month, current_months_year);
    }

    global void finish(Database.BatchableContext BC){
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
			TotalJobItems, CreatedBy.Email
			FROM AsyncApexJob WHERE Id = :BC.getJobId()];
	
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailTo);
        mail.setReplyTo(emailFrom);
        mail.setSenderDisplayName('Rollup Lead Usage Totals Processing');
        mail.setSubject('RollupLeadUsageTotal Batch Process Completed:'  + a.Status);
		mail.setPlainTextBody('RollupLeadUsageTotal Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}