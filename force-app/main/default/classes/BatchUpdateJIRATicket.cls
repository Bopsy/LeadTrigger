global class BatchUpdateJIRATicket implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT JIRA_Id__c, Id FROM Opportunity_Milestone__c]);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity_Milestone__c> recs){
        for(Opportunity_Milestone__c mileStone: recs){
            JIRAWebserviceCalloutSyncFields.batchSyncFields(mileStone.JIRA_Id__c, mileStone.Id);
        }
    }
    global void execute(SchedulableContext sc){
        Database.executeBatch(new BatchUpdateJIRATicket(), 10);
    }
    global void finish(Database.BatchableContext BC){
        
    }
    
    
}