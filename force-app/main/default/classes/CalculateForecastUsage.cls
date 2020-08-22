global class CalculateForecastUsage implements Database.Batchable<sObject> {
    global String current_months_year = String.valueOf(Datetime.now().year());
    global String current_months_month = Datetime.now().format('MMMMM');
    
    global Database.querylocator start(Database.BatchableContext BC){
 		return Database.getQueryLocator('SELECT Id, Product__c, AccountLookup__c, Year__c, Month__c, Lead__c, Current_Month_Forecast__c, Last_Month_Forecast__c, X2_Month_Ago_Forecast__c, Twilio_Forecast_3__c, X2_Month_Ahead_Forecast__c, Fiscal_Year__c, Usage_Date__c FROM Twilio_Usage__c');
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,Twilio_Usage__c> usages = new Map<Id,Twilio_Usage__c>();
        for(sObject s : scope){
            Twilio_Usage__c u = (Twilio_Usage__c)s;
            usages.put(u.Id, u);
        } 
        TwilioForecastHandler.calculateForecastUsage(usages.values());
    }

    global void finish(Database.BatchableContext BC){}
}