global class BatchGeneratePhantomForecast implements Database.Batchable<SObject>, Schedulable{
    
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchGeneratePhantomForecast());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Contract_Terms_Months__c, Launch_Date__c, Number_of_Schedules__c FROM Opportunity WHERE Number_of_Schedules__c < 24 AND StageName = \'Closed Won\' AND CloseDate >= 2017-01-01');
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> oppty){
        PhantomForecastServices.createPhantomForecasts(oppty);
        ProductUsageService.createProductUsageByMonthRecords([SELECT Id FROM Product_Schedule__c WHERE Forecast_Schedule__r.Opportunity__c =: oppty]);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}