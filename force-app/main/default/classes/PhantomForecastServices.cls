public without sharing class PhantomForecastServices {
    public static Id fsRTId = '0121W000000Dzxn';//'0120U0000008ibx';
    public static Id psRTId = '0121W000000Dzxo';//'0120U0000008ic7';
    public static Decimal MAX_MONTHS = 24;
    
    public static void createPhantomForecasts(List<Opportunity> opportunities){
        List<Forecast_Schedule__c> forecastSchedules = new List<Forecast_Schedule__c>();
        for(Opportunity opp : opportunities){
            if(opp.Contract_Terms_Months__c != null && opp.Launch_Date__c != null && opp.Number_of_Schedules__c < MAX_MONTHS){
                for(Integer i = Integer.valueOf(opp.Number_of_Schedules__c); i < MAX_MONTHS; i++){
                    Forecast_Schedule__c forecastSchedule = new Forecast_Schedule__c(Opportunity__c=opp.Id, RecordTypeId = fsRTId);
                    Date startDate = opp.Launch_Date__c.addMonths(i).toStartOfMonth();
                    Date endDate = startDate.addMonths(1).toStartOfMonth().addDays(-1);
                    forecastSchedule.Start_Date__c = startDate;
                    forecastSchedule.End_Date__c = endDate;
                    forecastSchedule.Forecast_Amount__c = 0;
                    forecastSchedules.add(forecastSchedule);
                }
            }
        }
        insert forecastSchedules;
        
        List<Opportunity_Product__c> products = [SELECT Opportunity__c FROM Opportunity_Product__c WHERE Opportunity__c =: opportunities];
        Map<Id, Set<Id>> oppProductMap = new Map<Id, Set<Id>>();
        List<Product_Schedule__c> insertProdSchedules = new List<Product_Schedule__c>();
        for(Opportunity_Product__c prod: products){
            Set<Id> productIds = oppProductMap.get(prod.Opportunity__c);
            if(productIds == null) productIds = new Set<Id>();
            productIds.add(prod.Id);
            oppProductMap.put(prod.Opportunity__c, productIds);
        }
        
        for(Forecast_Schedule__c sch: forecastSchedules){
            for(Id prodId: oppProductMap.get(sch.Opportunity__c)){
                if(prodId != null){
                     Product_Schedule__c prodSchedules = new Product_Schedule__c(Forecast_Schedule__c = sch.Id, RecordTypeId = psRTId);
                    prodSchedules.Opportunity_Product__c = prodId;
                    prodSchedules.Start_Date__c = sch.Start_Date__c;
                    prodSchedules.End_Date__c = sch.End_Date__c;
                    prodSchedules.New_Business_Forecast_Amount__c = sch.Forecast_Amount__c;
                    insertProdSchedules.add(prodSchedules);
                }
            }
        }
        
        if(!insertProdSchedules.isEmpty()){
            insert insertProdSchedules;
        }
    }
}