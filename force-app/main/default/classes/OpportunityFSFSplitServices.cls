public without sharing class OpportunityFSFSplitServices {
    
    class SplitException extends Exception{}
    
    public static void createSplits(List<Opportunity> records){
        List<Opportunity> opps = [SELECT OwnerId, Solution_Sales_Specialist__c, Deal__r.OwnerId, CloseDate, Amount, ForecastCategory, (SELECT Forecast_Amount__c, Start_Date__c, Field_Sales_Forecast__c FROM Forecast_Schedules__r) FROM Opportunity WHERE Id =: records];
        List<Opp_FSF_Split__c> deleteOppsplits = [SELECT Id FROM Opp_FSF_Split__c WHERE Opportunity__c =: opps];
        
        Set<Id> forecastOwners = new Set<Id>();
        Set<Date> startDates = new Set<Date>();
        
        for(Opportunity opp: opps){
            forecastOwners.add(opp.OwnerId);
            forecastOwners.add(opp.Deal__r.OwnerId);
            forecastOwners.add(opp.Solution_Sales_Specialist__c);
            startDates.add(getClosestQuarterStart(opp.CloseDate));
        }
        
        List<Field_Sales_Forecast__c> existingForecasts = [
        	SELECT Id, Start_Date__c, Forecast_Owner__c, Stage__c
            FROM Field_Sales_Forecast__c
            WHERE Forecast_Owner__c IN :forecastOwners
            AND Start_Date__c IN :startDates
    	];
    	
    	List<FS_FSF_Split__c> deleteFSSplits = [SELECT Id FROM FS_FSF_Split__c WHERE Forecast_Schedule__r.Opportunity__c =: opps];
    	Map<String, Field_Sales_Forecast__c> forecastsMap = new Map<String, Field_Sales_Forecast__c>();
        for( Field_Sales_Forecast__c aForecast : existingForecasts ) {
          String forecastKey = generateForecastKey( aForecast.Start_Date__c, aForecast.Forecast_Owner__c, aForecast.Stage__c );
          forecastsMap.put( forecastKey, aForecast );
        }
        
        List<Field_Sales_Forecast__c> newForecasts = new List<Field_Sales_Forecast__c>();
        List<Opp_FSF_Split__c> splits = new List<Opp_FSF_Split__c>();
        List<FS_FSF_Split__c> fsSplits = new List<FS_FSF_Split__c>();
        
        for(Opportunity opp: opps){
            Date targetDate = getClosestQuarterStart(opp.CloseDate);
            String targetForecastKey = generateForecastKey( targetDate, opp.OwnerId, opp.ForecastCategory );
            String dealForecastKey =  generateForecastKey( targetDate, opp.Deal__r.OwnerId, opp.ForecastCategory );
            if(forecastsMap.get(targetForecastKey) == null){
                Field_Sales_Forecast__c newForecast = new Field_Sales_Forecast__c(
        	        Forecast_Owner__c = opp.OwnerId,
        	        OwnerId = opp.OwnerId,
        	        Start_Date__c = targetDate,
        	        Stage__c = opp.ForecastCategory
                );
                newForecasts.add( newForecast );
                forecastsMap.put( targetForecastKey, newForecast );
            }
            if(forecastsMap.get(dealForecastKey) == null && opp.Deal__r.OwnerId != null){
                Field_Sales_Forecast__c newForecast = new Field_Sales_Forecast__c(
        	        Forecast_Owner__c = opp.Deal__r.OwnerId,
        	        OwnerId = opp.Deal__r.OwnerId,
        	        Start_Date__c = targetDate,
        	        Stage__c = opp.ForecastCategory
                );
                newForecasts.add( newForecast );
                forecastsMap.put( dealForecastKey, newForecast );
            }
        }
        Savepoint sp = Database.setSavepoint();
        insert newForecasts;
        
        for(Opportunity opp: opps){
            Date targetDate = getClosestQuarterStart(opp.CloseDate);
            String targetForecastKey = generateForecastKey( targetDate, opp.OwnerId, opp.ForecastCategory );
            String dealForecastKey =  generateForecastKey( targetDate, opp.Deal__r.OwnerId, opp.ForecastCategory );
            String solutionForecastKey = generateForecastKey( targetDate, opp.Solution_Sales_Specialist__c, opp.ForecastCategory );
            if(forecastsMap.get(targetForecastKey) != null){
                Opp_FSF_Split__c oppSplit = new Opp_FSF_Split__c(Opportunity__c = opp.Id, Type__c = 'Forecast', Amount__c = opp.Amount, Owner__c = opp.OwnerId, Field_Sales_Forecast__c = forecastsMap.get(targetForecastKey).Id);
                Opp_FSF_Split__c oppSplit2 = new Opp_FSF_Split__c(Opportunity__c = opp.Id, Type__c = 'Quota', Amount__c = opp.Amount, Owner__c = opp.OwnerId, Field_Sales_Forecast__c = forecastsMap.get(targetForecastKey).Id);
                splits.add(oppSplit);
                splits.add(oppSplit2);
            }
            if(opp.Solution_Sales_Specialist__c != null && opp.OwnerId != opp.Solution_Sales_Specialist__c && opp.Deal__r.OwnerId != opp.Solution_Sales_Specialist__c && forecastsMap.get(solutionForecastKey) != null){
                Opp_FSF_Split__c solutionOwnerSplit = new Opp_FSF_Split__c(Opportunity__c = opp.Id, Type__c = 'Quota', Amount__c = opp.Amount, Owner__c = opp.Solution_Sales_Specialist__c, Field_Sales_Forecast__c = forecastsMap.get(solutionForecastKey).Id);
                splits.add(solutionOwnerSplit);
            }
            else if(opp.Deal__r.OwnerId != null && opp.OwnerId != opp.Deal__r.OwnerId && forecastsMap.get(dealForecastKey) != null){
                Opp_FSF_Split__c dealOwnerSplit = new Opp_FSF_Split__c(Opportunity__c = opp.Id, Type__c = 'Quota', Amount__c = opp.Amount, Owner__c = opp.Deal__r.OwnerId, Field_Sales_Forecast__c = forecastsMap.get(dealForecastKey).Id);
                splits.add(dealOwnerSplit);
            }
            if(opp.Forecast_Schedules__r != null && !opp.Forecast_Schedules__r.isEmpty()){
                for(Forecast_Schedule__c schedule: opp.Forecast_Schedules__r){
                    if( schedule.Start_Date__c != null && schedule.Field_Sales_Forecast__c != null){
                        FS_FSF_Split__c fsSplit = new FS_FSF_Split__c(Forecast_Schedule__c = schedule.Id, Type__c = 'Forecast', Amount__c = schedule.Forecast_Amount__c, Owner__c = opp.OwnerId, Field_Sales_Forecast__c = schedule.Field_Sales_Forecast__c);
                        FS_FSF_Split__c fsSplit2 = new FS_FSF_Split__c(Forecast_Schedule__c = schedule.Id, Type__c = 'Quota', Amount__c = schedule.Forecast_Amount__c, Owner__c = opp.OwnerId, Field_Sales_Forecast__c = schedule.Field_Sales_Forecast__c);
                        fsSplits.add(fsSplit);
                        fsSplits.add(fsSplit2);
                    }
                    if(opp.Solution_Sales_Specialist__c != null && opp.OwnerId != opp.Solution_Sales_Specialist__c && opp.Deal__r.OwnerId != opp.Solution_Sales_Specialist__c && schedule.Field_Sales_Forecast__c != null ){
                        FS_FSF_Split__c solutionFSSplit = new FS_FSF_Split__c(Forecast_Schedule__c = schedule.Id, Type__c = 'Quota', Amount__c = schedule.Forecast_Amount__c, Owner__c = opp.Solution_Sales_Specialist__c, Field_Sales_Forecast__c = schedule.Field_Sales_Forecast__c);
                        fsSplits.add(solutionFSSplit);
                    }
                    else if(opp.Deal__r.OwnerId != null && opp.OwnerId != opp.Deal__r.OwnerId && schedule.Field_Sales_Forecast__c != null){
                        FS_FSF_Split__c dealFsSplit = new FS_FSF_Split__c(Forecast_Schedule__c = schedule.Id, Type__c = 'Quota', Amount__c = schedule.Forecast_Amount__c, Owner__c = opp.Deal__r.OwnerId, Field_Sales_Forecast__c = schedule.Field_Sales_Forecast__c);
                        fsSplits.add(dealFsSplit);
                    }
                }
            }
        }
        try{
            delete deleteFSSplits;
            delete deleteOppsplits;
            insert splits;
            insert fsSplits;
        }
        catch(DMLException e){
            Database.rollback(sp);
        }
    }
    
    public static void upsertDealSplits(List<Deal__c> records, Map<Id, Deal__c> oldMap){
        List<Deal__c> filteredDeals = new List<Deal__c>();
        for(Deal__c aDeal: records){
            Deal__c oldDeal;
            if(oldMap != null)
                 oldDeal = oldMap.get(aDeal.Id);
            if(oldDeal == null || oldDeal.OwnerId != aDeal.OwnerId){
                filteredDeals.add(aDeal);
            }
        }
        if(filteredDeals.isEmpty()) return;
        List<Opportunity> filteredOpps = [SELECT Id FROM Opportunity WHERE Deal__c =: filteredDeals];
        
        if(filteredOpps.isEmpty()) return;
        //SavePoint sp = Database.setSavepoint();
        
        //List<Opp_FSF_Split__c> deleteSplits = [SELECT Id FROM Opp_FSF_Split__c WHERE Opportunity__c =: filteredOpps];
        
        //List<FS_FSF_Split__c> deleteFSSplits = [SELECT Id FROM FS_FSF_Split__c WHERE Forecast_Schedule__r.Opportunity__c = :filteredOpps];
        
        createSplits(filteredOpps);
    }
    public static void upsertSplits(List<Opportunity> records, Map<Id, Opportunity> oldMap){
        
        List<Opportunity> filteredOpps = new List<Opportunity>();
        
        for(Opportunity opp: records){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(oldOpp.Contract_Terms_Months__c != opp.Contract_Terms_Months__c || oldOpp.Solution_Sales_Specialist__c != opp.Solution_Sales_Specialist__c || oldOpp.Deal__c != opp.Deal__c || oldOpp.Total_Scheduled_Forecast__c != opp.Total_Scheduled_Forecast__c || oldOpp.Amount != opp.Amount || oldOpp.CloseDate != opp.CloseDate || opp.OwnerId != oldOpp.OwnerId || oldOpp.StageName != opp.StageName){
                filteredOpps.add(opp);
            }
        }
        if(filteredOpps.isEmpty()) return;
        
        //SavePoint sp = Database.setSavepoint();
        
        //List<Opp_FSF_Split__c> deleteSplits = [SELECT Id FROM Opp_FSF_Split__c WHERE Opportunity__c =: filteredOpps];
        
        //List<FS_FSF_Split__c> deleteFSSplits = [SELECT Id FROM FS_FSF_Split__c WHERE Forecast_Schedule__r.Opportunity__c = :filteredOpps];
        
            //delete deleteSplits;
            //delete deleteFSSplits;
        createSplits(filteredOpps);
    }
    
    private static Date getClosestQuarterStart( Date someDate ) {
        return Date.newInstance( someDate.year(), (someDate.month()-1) / 3 * 3 + 1, 1 );
    }
    
    @future(callout=false)
    public static void futureCreateSplits( Set<Id> incomingOpportunities ) {
        List<Opportunity> opps = new List<Opportunity>();
        for(Id oppId: incomingOpportunities){
            opps.add(new Opportunity(Id = oppId));
        }
        createSplits(opps);
    }
    private static String generateForecastKey( Date startDate, Id ownerId, String stage) {
        return startDate.format() + ownerId + stage;
    }
}