global class BatchCalculateLaunchDate implements Database.Batchable<SObject>, Schedulable{
    
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCalculateLaunchDate());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        Date qualifiedDate = Date.newInstance(2017, 1, 1);
        return Database.getQueryLocator([SELECT New_Business_Account_SID_Lookup__c, FY_16_Primary_Product__c, Exception_Account_SID_Lookup__c, CloseDate, Launch_Date__c, eARR_post_Launch__c, (SELECT Product_Name__c FROM Opportunity_Products__r) FROM Opportunity WHERE CloseDate >= :qualifiedDate AND StageName = 'Closed Won']);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> opps){
        calculateLaunchDate(opps);
    }
    
    global static void calculateLaunchDate(List<Opportunity> opps){
        Map<Id, Id> oppToAccountSIDMap = new Map<Id, Id>();
        Map<Id, Set<String>> oppToProductMap = new Map<Id, Set<String>>();
        
        for(Opportunity opp: opps){
            if(opp.New_Business_Account_SID_Lookup__c != null){
                oppToAccountSIDMap.put(opp.Id, opp.New_Business_Account_SID_Lookup__c);
            }
            else if(opp.Exception_Account_SID_Lookup__c != null){
                oppToAccountSIDMap.put(opp.Id, opp.Exception_Account_SID_Lookup__c);
            }
            if(opp.Opportunity_Products__r != null && !opp.Opportunity_Products__r.isEmpty()){
                Set<String> productNames = new Set<String>();
                for(Opportunity_Product__c prod: opp.Opportunity_Products__r){
                    productNames.add(prod.Product_Name__c);
                }
                oppToProductMap.put(opp.Id, productNames);
            }
        }
        
        List<Id> sidIDs = oppToAccountSIDMap.values();
        String queryString = 'SELECT Id, (SELECT ';
        
        Map<String, String> productToUsageFieldName = new Map<String, String>();
        Set<String> queryFields = new Set<String>();
        for(AccountSID_to_SKU_Mappings__c setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
            if(setting.Usage_Field__c != null && !queryFields.contains(setting.Usage_Field__c)){
                queryFields.add(setting.Usage_Field__c);
                queryString += setting.Usage_Field__c + ', ';
                productToUsageFieldName.put(setting.Product_Name__c, setting.Usage_Field__c);
            }
        }
        
        queryString += 'Usage_Date__c FROM Twilio_Usages__r ORDER BY Usage_Date__c) FROM Account_SID__c WHERE Id =: sidIDs';
        
        List<Account_SID__c> sids = (List<Account_SID__c>) Database.query(queryString);
        
        Map<Id, Account_SID__c> accountSIDMap = new Map<Id, Account_SID__c>();
        
        for(Account_SID__c sid: sids){
            accountSIDMap.put(sid.Id, sid);
        }
        
        for(Opportunity opp: opps){
            Decimal eARRValue = 0;
            if(opp.eARR_post_Launch__c != null)
                eARRValue = opp.eARR_post_Launch__c * 0.05;
            Decimal totalRunningRate = 0;
            Date currentMonthDate = Date.today().toStartOfMonth();
            Date previousMonthDate = Date.today().addMonths(-1).toStartOfMonth();
            Date realLaunchDate = null;
            Account_SID__c sid = accountSIDMap.get(oppToAccountSIDMap.get(opp.Id));
            
            Set<String> productNames = oppToProductMap.get(opp.Id);
            if(sid != null && sid.Twilio_Usages__r != null && !sid.Twilio_Usages__r.isEmpty()){
                for(Twilio_Usage__c usage: sid.Twilio_Usages__r){
                    totalRunningRate = 0;
                    if(productNames != null){
                        for(String productName: productNames){
                            if(productName != null && productToUsageFieldName.get(productName) != null ){
                                Object runningRate = usage.get(productToUsageFieldName.get(productName));
                                if(runningRate != null)
                                    totalRunningRate += (Decimal) runningRate;
                            }
                        }
                    }
                    if(totalRunningRate >= eARRvalue && realLaunchDate == null){
                        realLaunchDate = usage.Usage_Date__c;
                    }
                    if(usage.Usage_Date__c == currentMonthDate){
                        if(productToUsageFieldName.get(opp.FY_16_Primary_Product__c) != null){
                            Object productUsage = usage.get(productToUsageFieldName.get(opp.FY_16_Primary_Product__c));
                            opp.Primary_Product_Usage_This_Month__c = productUsage == null ? 0 : (Decimal) productUsage;
                        }
                    }
                    if(usage.Usage_Date__c == previousMonthDate){
                        if(productToUsageFieldName.get(opp.FY_16_Primary_Product__c) != null){
                            Object productUsage = usage.get(productToUsageFieldName.get(opp.FY_16_Primary_Product__c));
                            opp.Primary_Product_Usage_Last_Month__c = productUsage == null ? 0 : (Decimal) productUsage;
                        }
                    }
                }
            }
            opp.Real_Launch_Date__c = realLaunchDate;
        }
        Database.update(opps, false);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}