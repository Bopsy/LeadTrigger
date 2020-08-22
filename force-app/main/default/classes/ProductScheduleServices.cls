public without sharing class ProductScheduleServices {
    public static Boolean bypassTrigger = false;
    
    public static void afterInsert(List<Product_Schedule__c> newRecords){
        if(bypassTrigger) return;
        List<Product_Schedule__c> filteredRecords = newRecords.deepClone(true,true, true);
        populatePrevMonths(filteredRecords);
    }
    
    public static void afterUpdate(List<Product_Schedule__c> newRecords, Map<Id, Product_Schedule__c> oldMap){
        if(bypassTrigger) return;
        List<Product_Schedule__c> filteredRecords = new List<Product_Schedule__c>();
        
        for(Product_Schedule__c schedule: newRecords){
            Product_Schedule__c oldRec = oldMap.get(schedule.Id);
            if(oldRec.Start_Date__c != schedule.Start_Date__c && schedule.Previous_Month_Forecast__c == null){
                filteredRecords.add(schedule.clone(true,true));    
            }
        }
        
        populatePrevMonths(newRecords);
    }
    
    public static void populatePrevMonths(List<Product_Schedule__c> schedules){
        Set<Id> oppProdIds = new Set<Id>();
        List<Product_Schedule__c> updateSchedules = new List<Product_Schedule__c>();
        for(Product_Schedule__c schedule: schedules){
            oppProdIds.add(schedule.Opportunity_Product__c);
        }
        
        for(Opportunity_Product__c prod: [SELECT Id, (SELECT Id FROM Product_Schedules__r ORDER BY Month_Number__c) FROM Opportunity_Product__c WHERE Id =: oppProdIds]){
            if(prod.Product_Schedules__r != null && prod.Product_Schedules__r.size() > 1){
                List<Product_Schedule__c> prodSchedules = prod.Product_Schedules__r;
                for(Integer i = 1; i < prodSchedules.size(); i++){
                    prodSchedules[i].Previous_Month_Forecast__c = prodSchedules[i - 1].Id;
                    updateSchedules.add(prodSchedules[i]);
                }
            }
        }
        
        bypassTrigger = true;
        update updateSchedules;
        
    }
}