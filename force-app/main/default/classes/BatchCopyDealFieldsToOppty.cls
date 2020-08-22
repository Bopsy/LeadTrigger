public with sharing class BatchCopyDealFieldsToOppty implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Generate a list of records to batch process
        return Database.getQueryLocator([ Select Id, Close_Date__c FROM Deal__c ]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        OpportunityDealHandler.copyFieldsToOpportunity(new Map<Id,Deal__c>((List<Deal__c>)scope));
    }
    
    public void finish(Database.BatchableContext BC) {
        // Actions to perform when batch processing is finished
    }

    // Schedulable Interface Method
    public void execute(SchedulableContext context) {
        database.executebatch(new BatchCopyDealFieldsToOppty());
    }
}