global class BatchCreateDealProducts implements Database.Batchable<SObject>{
    global Database.queryLocator start(Database.BatchableContext bc){
        Date closeDate = Date.newInstance(2015, 1, 1);
        return Database.getQueryLocator([SELECT Id, AccountId, Account.FY_17_AE_Owner_Preliminary__c, Launch_Date__c, OwnerId, FY_16_Primary_Product__c, Amount, CloseDate, Contract_Terms_Months__c, (SELECT Forecast_Amount__c, Start_Date__c, End_Date__c FROM Forecast_Schedules__r), (SELECT Id FROM Opportunity_Products__r WHERE Primary_Product__c = true) FROM Opportunity WHERE Deal__c = null AND CloseDate >=:closeDate]);
        
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> opportunities){
        Map<Id, Deal__c> insertOppToDealMap = new Map<Id, Deal__c>();
        Map<Id, Opportunity_Product__c> insertOppProducts = new  Map<Id, Opportunity_Product__c>();
        
        for(Opportunity opp: opportunities){
            Deal__c newDeal = new Deal__c(Name = 'Test', OwnerId = opp.Account.FY_17_AE_Owner_Preliminary__c == null ? opp.OwnerId : opp.Account.FY_17_AE_Owner_Preliminary__c, Account__c = opp.AccountId, Close_Date__c = opp.CloseDate);
            insertOppToDealMap.put(opp.Id, newDeal);
            if(opp.Opportunity_Products__r == null || opp.Opportunity_Products__r.isEmpty()){
                Opportunity_Product__c newProduct = new Opportunity_Product__c(Name = opp.FY_16_Primary_Product__c, Amount__c = opp.Amount, Opportunity__c = opp.Id, Primary_Product__c = true, Product_Name__c = opp.FY_16_Primary_Product__c, Launch_Date__c = opp.Launch_Date__c, Contract_Terms_Months__c = opp.Contract_Terms_Months__c);
                insertOppProducts.put(opp.Id, newProduct);
            }
        }
        
        Database.insert(insertOppToDealMap.values(), false);
        
        List<Opportunity> updateOpps = new List<Opportunity>();
        for(Id oppId: insertOppToDealMap.keySet()){
            if(insertOppToDealMap.get(oppId) != null && insertOppToDealMap.get(oppId).Id != null){
                Opportunity updateOpp = new Opportunity(Id = oppId, Deal__c = insertOppToDealMap.get(oppId).Id);
                updateOpps.add(updateOpp);
            }
        }
        
        //Database.update(updateOpps, false);
        update updateOpps;
        //Database.insert(insertOppProducts.values(), false);
        insert insertOppProducts.values();
        
        List<Product_Schedule__c> schedules = new List<Product_Schedule__c>();
        for(Opportunity opp: opportunities){
            if(opp.Forecast_Schedules__r != null && !opp.Forecast_Schedules__r.isEmpty() && insertOppProducts.get(opp.Id) != null && insertOppProducts.get(opp.Id).Id != null){
                for(Forecast_Schedule__c schedule: opp.Forecast_Schedules__r){
                    Product_schedule__c newSchedule = new Product_Schedule__c(Forecast_Amount__c = schedule.Forecast_Amount__c, Start_Date__c = schedule.Start_Date__c, End_Date__c = schedule.End_Date__c, Opportunity_Product__c = insertOppProducts.get(opp.Id).Id, Forecast_Schedule__c = schedule.Id);
                    schedules.add(newSchedule);
                }
            }
        }
        
        Database.insert(schedules, false);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}