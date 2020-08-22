global class RollupAccountUsageTotal implements Database.Batchable<sObject> {
    global String[] emailTo = new String[] { 'pmorrow@twilio.com', 'jonathan.f.griggs@gmail.com' };
    global String emailFrom = 'pmorrow@twilio.com';

    global String current_months_year = String.valueOf(Datetime.now().year());
    global String current_months_month = Datetime.now().format('MMMMM');
    
    global Boolean run_forecast_initialization = false;
     
    
    global Database.querylocator start(Database.BatchableContext BC){
		return Database.getQueryLocator('SELECT Id, Name FROM Account WHERE IsDeleted = false');
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> accountIds = new Set<Id>();
        List<Account> accounts = new List<Account>();
        for(sObject s : scope){
            Account a = (Account)s;
			accountIds.add(a.Id);
			accounts.add(a);
        }
        if (run_forecast_initialization) {
	        TwilioForecastHandler.initializeForecast(accounts, current_months_year);
        }
        TwilioForecastHandler.updateAccountMonthlyRollup(accountIds, current_months_month, current_months_year);
    }

    global void finish(Database.BatchableContext BC){
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
			TotalJobItems, CreatedBy.Email
			FROM AsyncApexJob WHERE Id = :BC.getJobId()];
	
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailTo);
        mail.setReplyTo(emailFrom);
        mail.setSenderDisplayName('Rollup Account Usage Totals Processing');
        mail.setSubject('RollupAccountUsageTotal Batch Process Completed:'  + a.Status);
		mail.setPlainTextBody('RollupAccountUsageTotal Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

    }
}