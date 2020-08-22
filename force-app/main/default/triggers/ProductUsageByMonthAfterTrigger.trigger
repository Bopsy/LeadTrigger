trigger ProductUsageByMonthAfterTrigger on Product_Usage_By_Month__c (after insert, after update, before insert,before update, after delete, after undelete) {
    if(trigger.isAfter){
        if (Trigger.isInsert) {
            ProductUsageService.summarizeProductUsages(Trigger.new);
            update ProductUsageLookupService.populatePrevMonthLookup(trigger.new.deepClone(true, true));
            ProductUsageLookupService.updateTotalCompensableRevenue(trigger.new);
    
        } else if (Trigger.isDelete) {
            ProductUsageService.summarizeProductUsages(Trigger.old);
            ProductUsageLookupService.updateTotalCompensableRevenue(trigger.old);
    
        } else if (Trigger.isUpdate) {
            List<Product_Usage_By_Month__c> recordsToUpdate = new List<Product_Usage_By_Month__c>();
            for (Product_Usage_By_Month__c u : Trigger.old) {
                if (u.Usage_API_Field__c != Trigger.newMap.get(u.Id).Usage_API_Field__c) {
                    recordsToUpdate.add(u);
                }
            }
            ProductUsageService.summarizeProductUsages(recordsToUpdate);
            List<Product_Usage_By_Month__c> recordsToUpdate2 = new List<Product_Usage_By_Month__c>();
            for(Product_Usage_By_Month__c u: trigger.new){
                if(u.Rep_Switchboard__c == Trigger.oldMap.get(u.Id).Rep_Switchboard__c){
                    recordsToUpdate2.add(u);
                }
            }
            update ProductUsageLookupService.populatePrevMonthLookup(recordsToUpdate2.deepClone(true, true));
            ProductUsageLookupService.updateTotalCompensableRevenue(recordsToUpdate2);
        } else if(trigger.isUndelete){
            ProductUsageService.summarizeProductUsages(Trigger.new);
        }
    }
    else if(trigger.isBefore){
        
        List<Product_Usage_By_Month__c> productUsageByMonth = trigger.new;
        Set<Id> productScheduleIds = new Set<Id>();
        Set<Id> twilioUsageIds = new Set<Id>();
        Map<String, String> productsToSummarize = new Map<String,String>();
        for (Product_Usage_By_Month__c u : productUsageByMonth) {
            productScheduleIds.add(u.Product_Schedule__c);
            twilioUsageIds.add(u.Twilio_Usage__c);
            
            if (u.Usage_API_Field__c != null) {
                productsToSummarize.put(u.Usage_API_Field__c, u.Usage_API_Field__c);
            }
        }
        
        Map<Id,Product_Schedule__c> productScheduleMap = new Map<Id,Product_Schedule__c>([
            SELECT Id, Opportunity_Product__r.Product_Name__c, Actual_Usage__c
            FROM Product_Schedule__c
            WHERE Id = :productScheduleIds
        ]);
        
        for (AccountSID_to_SKU_Mappings__c setting : AccountSID_to_SKU_Mappings__c.getAll().values()) {
            if(setting.Year__c == 2018 && !setting.SendGrid_Product__c){
                if(setting.Usage_Field__c != null){
                    productsToSummarize.put(setting.Product_Name__c, setting.Usage_Field__c);
                }
            }
        }
        for (AccountSID_to_SKU_Mappings__c setting : AccountSID_to_SKU_Mappings__c.getAll().values()) {
            if(!productsToSummarize.containsKey(setting.Product_Name__c) && !setting.SendGrid_Product__c){
                if(setting.Usage_Field__c != null){
                    productsToSummarize.put(setting.Product_Name__c, setting.Usage_Field__c);
                }
            }
        }
        String fields = String.join(productsToSummarize.values(), ', ');
        String queryString = 'SELECT Id, ' + fields + ' FROM Twilio_Usage__c WHERE Id IN :twilioUsageIds';
        Map<Id,Twilio_Usage__c> twilioUsageMap = new Map<Id,Twilio_Usage__c>();
        twilioUsageMap.putAll((List<Twilio_Usage__c>)Database.query(queryString));
        
        for (Product_Usage_By_Month__c u : productUsageByMonth) {
            if (productScheduleMap.containsKey(u.Product_Schedule__c) && twilioUsageMap.containsKey(u.Twilio_Usage__c)) {
                Product_Schedule__c productSchedule = productScheduleMap.get(u.Product_Schedule__c);
                Twilio_Usage__c twilioUsage = twilioUsageMap.get(u.Twilio_Usage__c);
                if (u.Usage_API_Field__c != null) {
                    String usageField = productsToSummarize.get(u.Usage_API_Field__c);
                     u.Actual_Usage__c = twilioUsage.get(usageField) == null ? 0.0 : (Decimal)twilioUsage.get(usageField);
                }
                else if (productsToSummarize.containsKey(productSchedule.Opportunity_Product__r.Product_Name__c)) {
                    String usageField = productsToSummarize.get(productSchedule.Opportunity_Product__r.Product_Name__c);
                    u.Actual_Usage__c = twilioUsage.get(usageField) == null ? 0.0 : (Decimal)twilioUsage.get(usageField);
                }
            }
        }
        
        
    }
}