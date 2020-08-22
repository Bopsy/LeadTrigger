global class BatchUpdateLaunchPlanForecast implements Database.Batchable<SObject>, Schedulable{
    global void execute(SchedulableContext sc) {
        //Set scheduler action
        Database.executeBatch(new BatchUpdateLaunchPlanForecast(), 25);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, Opportunity__c FROM Launch_Plan__c]);
    }
    
    global void execute(Database.BatchableContext bc, List<Launch_Plan__c> launchPlans){
       LaunchForecastServices.upsertLaunchPlanForecasts(launchPlans);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}