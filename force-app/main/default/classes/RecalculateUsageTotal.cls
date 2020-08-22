global class RecalculateUsageTotal implements Database.Batchable<sObject> {
    global String[] emailTo = new String[] { 'pmorrow@twilio.com', 'jonathan.f.griggs@gmail.com' };
    global String emailFrom = 'pmorrow@twilio.com';

    global String current_months_year = String.valueOf(Datetime.now().year());
    global String current_months_month = Datetime.now().format('MMMMM');
    
    global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id, Product__c, AccountLookup__c, Year__c, Month__c, Current_Month_Forecast__c, Last_Month_Forecast__c, X2_Month_Ago_Forecast__c, Twilio_Forecast_3__c, Fiscal_Year__c, Usage_Date__c FROM Twilio_Usage__c WHERE IsDeleted = false');
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,Twilio_Usage__c> usages = new Map<Id,Twilio_Usage__c>();
        for(sObject s : scope){
            Twilio_Usage__c u = (Twilio_Usage__c)s;
            usages.put(u.Id, u);
        }

        TwilloUsageTriggerHandler.updateForcastFields(usages.values(), usages, true);
        update usages.values();
    }

    global void finish(Database.BatchableContext BC){
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
			TotalJobItems, CreatedBy.Email
			FROM AsyncApexJob WHERE Id = :BC.getJobId()];
	
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailTo);
        mail.setReplyTo(emailFrom);
        mail.setSenderDisplayName('Recalculate Usage Totals Processing');
        mail.setSubject('RecalculateUsageTotal Batch Process Completed:'  + a.Status);
		mail.setPlainTextBody('RecalculateUsageTotal Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
}