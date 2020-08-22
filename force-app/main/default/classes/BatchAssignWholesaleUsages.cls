global class BatchAssignWholesaleUsages implements Database.Batchable<SObject>, Schedulable{
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchAssignWholesaleUsages(), 20);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        Id oppId = [SELECT Id FROM Opportunity WHERE Name = 'Sales Ops Placeholder' LIMIT 1].Id;
        return Database.getQueryLocator([SELECT Account__c, CRM_ID__c, Account_Name__c, Conversion_Rate__c, Cost__c, Date__c, External_Id__c, Managed_By__c, Margin__c, Opportunity__c, Profit__c, Revenue_Input__c, Volume__c FROM Wholesale_USage__c WHERE Opportunity__c = :oppId]);
    }
    
    global void execute(Database.BatchableContext bc, List<Wholesale_Usage__c> usages){
        for(Wholesale_Usage__c usage: usages){
            usage.Opportunity__c = null;
        }
        WholesaleUsageServices.beforeInsert(usages);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}