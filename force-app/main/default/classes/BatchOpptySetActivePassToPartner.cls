public with sharing class BatchOpptySetActivePassToPartner implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Generate a list of records to batch process
        return Database.getQueryLocator([
            SELECT Id, Opportunity__c, Partner_Status__c, Record_Lock__c
            FROM Pass_To_Partner__c
        ]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,Pass_To_Partner__c> ptpMap = new Map<Id,Pass_To_Partner__c>();

        for (Pass_To_Partner__c p : (List<Pass_To_Partner__c>)scope) {
        	ptpMap.put(p.Id, p);
        }
        
        PassToPartnerTriggerHandler.setOpportunityActivePassToPartner(ptpMap);
    }
    
    public void finish(Database.BatchableContext BC) {
        // Actions to perform when batch processing is finished
    }

    // Schedulable Interface Method
    public void execute(SchedulableContext context) {
        database.executebatch(new BatchOpptySetActivePassToPartner());
    }
}