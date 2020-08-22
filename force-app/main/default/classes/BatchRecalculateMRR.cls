global without sharing class BatchRecalculateMRR implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchRecalculateMRR(), 50);
    }
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id FROM Account_SID_SKU__c WHERE New_Business_Opportunity__r.IsClosed = false AND New_Business_Opportunity__r.CloseDate >= 2020-01-01]);
    }
    global static void execute(Database.BatchableContext bc, List<Account_SID_SKU__c> accSKUs){
        MRRCalculationServices.recalculateNBAccountSIDDate(accSKUs);
    }
    global void finish(Database.BatchableContext bc){
        
    }
}