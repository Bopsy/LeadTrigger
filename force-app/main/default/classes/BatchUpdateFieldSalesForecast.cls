global class BatchUpdateFieldSalesForecast implements Database.Batchable<SObject>{
    
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Booking_Notes__c FROM Field_Sales_Forecast__c]);
    }
    
    global void execute(Database.BatchableContext bc, List<Field_Sales_Forecast__c> forecasts){
        Map<Id, String> oldNotesMap = new Map<Id, String>();
        for(Field_Sales_Forecast__c forecast: forecasts){
            oldNotesMap.put(forecast.Id, forecast.Booking_Notes__c);
            forecast.Booking_Notes__c = 'Updated by batch';
        }
        Database.update(forecasts);
        
        for(Field_Sales_Forecast__c forecast: forecasts){
            forecast.Booking_Notes__c = oldNotesMap.get(forecast.Id);
        }
        
        Database.update(forecasts);
        
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}