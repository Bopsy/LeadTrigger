global class BatchLinkTwilioUsageToProductSchedule implements Database.Batchable<SObject>, Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchLinkTwilioUsageToProductSchedule());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id FROM Product_Schedule__c WHERE Start_Date__c >= 2018-07-01 AND Start_Date__c <= :Date.today() AND Forecast_Schedule__r.Opportunity__r.StageName In ('Closed Won', 'Go / No Go', 'Partner - FR')]);
    }
    
    global void execute(Database.BatchableContext bc, List<Product_Schedule__c> schedules){
        //delete [SELECT Id FROM Product_Usage_By_Month__c WHERE Date_Diff_Between_Schedule_and_Usage__c != 0];
        system.debug('schedules.size()=>'+schedules.size());
        system.debug('first'+limits.getCpuTime());
        ProductUsageService.createProductUsageByMonthRecords(schedules);
        system.debug('second'+limits.getCpuTime());
        update [SELECT Id FROM Product_Usage_By_Month__c WHERE Product_Schedule__c =: schedules];
        system.debug('third'+limits.getCpuTime());
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}