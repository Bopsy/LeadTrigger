trigger WholesaleUsageTrigger on Wholesale_Usage__c (before insert) {
    //WholesaleUsageServices.beforeInsert(trigger.new);
    Id oppId = [SELECT Id FROM Opportunity WHERE Name = 'Sales Ops Placeholder' LIMIT 1].Id;
    for(Wholesale_Usage__c usage: trigger.new){
        if(usage.Opportunity__c == null){
            usage.Opportunity__c = oppId;
        }
    }
}