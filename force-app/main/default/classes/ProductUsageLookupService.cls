public without sharing class ProductUsageLookupService {
     static Integer MAX_BLOCK_MONTH_NUMBER = 13;
     public static Boolean bypassTrigger = false;
     final static Set<String> UNBLOCK_RECORD_TYPES = new Set<String>{'Renegotiation Opportunity', 'Programmable Wireless'};
     
     public static void updateTotalCompensableRevenue (List<Product_Usage_By_Month__c> usages){
         Set<Id> productScheduleIds = new Set<Id>();
         
         for(Product_Usage_By_Month__c usage: usages){
             productScheduleIds.add(usage.Product_Schedule__c);
         }
         List<Product_Schedule__c> schedules = [SELECT Id, (SELECT Id, Blocked_Usage__c, Compensable_Blocked_Usage__c, Actual_Usage__c, Compensable_MRR__c, Rep_IPR_Eligibility__c, MRR__c FROM Product_Usage_By_Months__r) FROM Product_Schedule__c WHERE Id =: productScheduleIds]; 
         for(Product_Schedule__c schedule: schedules){
             schedule.Total_Compensable_Actual__c = 0;
             schedule.Total_Compensable_Actual_Dedupe__c = 0;
             schedule.MRR_Baseline_Dedupe__c = 0;
             schedule.Compensable_MRR_Dedupe__c = 0;
             schedule.Actual_Usage__c = 0;
             if(schedule.Product_Usage_By_Months__r != null && !schedule.Product_Usage_By_Months__r.isEmpty()){
                 for(Product_Usage_By_Month__c usage: schedule.Product_Usage_By_Months__r){
                    if(usage.Blocked_Usage__c == null){
                        schedule.Total_Compensable_Actual__c += usage.Actual_Usage__c == null ? 0 : usage.Actual_Usage__c;
                        schedule.MRR_Baseline_Dedupe__c += usage.MRR__c == null ? 0: usage.MRR__c;
                    }
                    if(usage.Rep_IPR_Eligibility__c){
                        schedule.Total_Compensable_Actual_Dedupe__c += usage.Actual_Usage__c == null ? 0 : usage.Actual_Usage__c;
                        schedule.Compensable_MRR_Dedupe__c += usage.Compensable_MRR__c == null ? 0: usage.Compensable_MRR__c;
                    }
                    schedule.Actual_Usage__c += usage.Actual_Usage__c == null ? 0 : usage.Actual_Usage__c;
                 }
             }
         }
         update schedules;
     }
     
     
     public static List<Product_Usage_By_Month__c> populatePrevMonthLookup (List<Product_Usage_By_Month__c> productUsages){
        if(bypassTrigger) return new List<Product_Usage_By_Month__c>();
        productUsages = [SELECT Product_Schedule__r.Opportunity_Product__c, Twilio_Usage__r.Related_Account_SID__c FROM Product_Usage_By_Month__c WHERE Id =: productUsages];
        Set<Id> sidIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        for(Product_Usage_By_Month__c usage: productUsages){
            sidIds.add(usage.Twilio_Usage__r.Related_Account_SID__c);
            prodIds.add(usage.Product_Schedule__r.Opportunity_Product__c);
        }

        productUsages = [SELECT Can_Block__c, Compensable_Can_Block__c, Account_SID_SKU__c, Product_Schedule__r.Opportunity_Product__r.Opportunity__r.CreatedDate, Product_Schedule__r.Opportunity_Product__r.Opportunity__r.RecordType.Name, Product_Schedule__r.Opportunity_Product__c, Product_Schedule__r.Opportunity_Product__r.Product_Name__c, 
                        Twilio_Usage__c, Product_Schedule__r.Opportunity_Product__r.Opportunity__r.StageName, Twilio_Usage__r.Related_Account_SID__c, 
                        Product_Schedule__r.Start_Date__c, Month_Number__c 
                        FROM Product_Usage_By_Month__c 
                        WHERE (Product_Schedule__r.Opportunity_Product__c =: prodIds OR Twilio_Usage__r.Related_Account_SID__c =: sidIds) 
                            AND Product_Schedule__c != null AND Twilio_Usage__c != null 
                        ORDER BY Product_Schedule__r.Start_Date__c];
       
        Map<String, List<Product_Usage_By_Month__c>> usageMap = new Map<String, List<Product_Usage_By_Month__c>>();
        Map<String, List<Product_Usage_By_Month__c>> usageMap2 = new Map<String, List<Product_Usage_By_Month__c>>();
        
        for(Product_Usage_By_Month__c usage: productUsages){
            String keyString = usage.Product_Schedule__r.Opportunity_Product__c + '-' + usage.Twilio_Usage__r.Related_Account_SID__c;
            String keyString2 = usage.Product_Schedule__r.Opportunity_Product__r.Product_Name__c + '-' + usage.Twilio_Usage__c; //+ '-' + usage.Product_Schedule__r.Start_Date__c;
            List<Product_Usage_By_Month__c> usages = usageMap.get(keyString);
            List<Product_Usage_By_Month__c> usages2 = usageMap2.get(keyString2);
            if(usages == null) usages = new List<Product_Usage_By_Month__c>();
            if(usages2 == null) usages2 = new List<Product_Usage_By_Month__c>();
            usages.add(usage);
            usageMap.put(keyString, usages);
            if(usage.Month_Number__c <= MAX_BLOCK_MONTH_NUMBER){
                usages2.add(usage);
                usageMap2.put(keyString2, usages2);
            }
        }
        
        Map<String, Id> skuIdMap = new Map<String, Id>();
        
        for(Account_SID_SKU__c sku: [SELECT Account_SID__c, Opportunity_Product__c FROM Account_SID_SKU__c WHERE Account_SID__c =: sidIds OR Opportunity_Product__c =: prodIds]){
            String keyString = sku.Opportunity_Product__c + '-' + sku.Account_SID__c;
            skuIdMap.put(keyString, sku.Id);
        }
        
        Map<Id, Product_Usage_By_Month__c> result = new Map<Id, Product_Usage_By_Month__c>();
        for(String keyString : usageMap.keySet()){
            List<Product_Usage_By_Month__c> usages = usageMap.get(keyString);
            Id skuId = skuIdMap.get(keyString);
            if(usages != null && usages.size() > 1){
                if(usages[0].Account_SID_SKU__c == null && skuId != null) usages[0].Account_SID_SKU__c = skuId;
                result.put(usages[0].Id, usages[0]);
                for(Integer i = 1; i < usages.size(); i++){
                    if(usages[i].Account_SID_SKU__c == null && skuId != null) usages[i].Account_SID_SKU__c = skuId;
                    usages[i].Last_Month_Usage__c = usages[i-1].Id;
                    result.put(usages[i].Id, usages[i]);
                }
            }
        }
        
        List<Product_Usage_By_Month__c> testUsages = new List<Product_Usage_By_Month__c>();
        //system.assert(false,  usageMap2.get('Programmable Messaging-a0e1k0000009dCIAAY'));
        for(String keyString: usageMap2.keySet()){
            List<Product_Usage_By_Month__c> usages = usageMap2.get(keyString);
            Map<Decimal, Product_Usage_By_Month__c> usageMonthNumberMap = new Map<Decimal, Product_Usage_By_Month__c>();
            if(usages != null && usages.size() > 1){
                for(Integer i = 0; i < usages.size(); i++){
                    Product_Usage_By_Month__c sameMonthUsage = usageMonthNumberMap.get(usages[i].Month_Number__c);
                    if(sameMonthUsage != null ){
                        if(sameMonthUsage.Compensable_Can_Block__c && usages[i].Product_Schedule__r.Opportunity_Product__r.Opportunity__r.CreatedDate > sameMonthUsage.Product_Schedule__r.Opportunity_Product__r.Opportunity__r.CreatedDate){
                            usages[i].Compensable_Blocked_Usage__c = sameMonthUsage.Id;sameMonthUsage.Compensable_Blocked_Usage__c = null;
                            if(sameMonthUsage.Can_Block__c){usages[i].Blocked_Usage__c = sameMonthUsage.Id;sameMonthUsage.Blocked_Usage__c = null;}
                            result.put(usages[i].Id, usages[i]);result.put(sameMonthUsage.Id, sameMonthUsage);continue;
                        }
                        else if(usages[i].Compensable_Can_Block__c){
                            usages[i].Compensable_Blocked_Usage__c = null;sameMonthUsage.Compensable_Blocked_Usage__c = usages[i].Id;
                            if(usages[i].Can_Block__c){usages[i].Blocked_Usage__c = null;sameMonthUsage.Blocked_Usage__c = usages[i].Id;}
                            result.put(usages[i].Id, usages[i]);result.put(sameMonthUsage.Id, sameMonthUsage);
                        }
                    }
                    usageMonthNumberMap.put(usages[i].Month_Number__c, usages[i]);
                }
                List<Decimal> monthNumbers = new List<Decimal>(usageMonthNumberMap.keySet());monthNumbers.sort();
                for(Integer i = 0; i < monthNumbers.size()-1; i++){
                    Product_Usage_By_Month__c usage = usageMonthNumberMap.get(monthNumbers[i]); 
                    if(result.containsKey(usage.Id)){usage = result.get(usage.Id);}
                    Product_Usage_By_Month__c newUsage = usageMonthNumberMap.get(monthNumbers[i+1]);
                    if(newUsage.Compensable_Can_Block__c && newUsage.Product_Schedule__r.Opportunity_Product__r.Opportunity__r.StageName == 'Closed Won' && !UNBLOCK_RECORD_TYPES.contains(newUsage.Product_Schedule__r.Opportunity_Product__r.Opportunity__r.RecordType.Name)){
                        usage.Compensable_Blocked_Usage__c = newUsage.Id;
                        if(newUsage.Can_Block__c) usage.Blocked_Usage__c = newUsage.Id;
                        result.put(usage.Id, usage);testUsages.add(usage);
                    }
                }
            }
        }
        bypassTrigger = true;
        
        return result.values();
    }

}