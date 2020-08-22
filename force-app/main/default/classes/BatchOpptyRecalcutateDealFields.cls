public with sharing class BatchOpptyRecalcutateDealFields implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Generate a list of records to batch process
        return Database.getQueryLocator([ SELECT Id, Deal__c FROM Opportunity ]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        OpportunityDealHandler.recalcutateDealFields(new Map<Id,Opportunity>((List<Opportunity>)scope));
    }
    
    public void finish(Database.BatchableContext BC) {
        // Actions to perform when batch processing is finished
    }

    // Schedulable Interface Method
    public void execute(SchedulableContext context) {
        database.executebatch(new BatchOpptyRecalcutateDealFields());
    }
}