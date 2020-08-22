public with sharing class NewForecastSchedulerController {
  public String oppString {get; set;}
  public NewForecastSchedulerController( ApexPages.StandardController standardCont ) {
      Id oppId = (Id) standardCont.getRecord().Id;
      oppString = JSON.serialize(getOpportunity(oppId));
  }
  public class MissingInformationException extends System.Exception {}
  @RemoteAction
  public static void saveForecasts(String jsonString, Id oppId){
      List<Forecast_Schedule__c> newForecasts = (List<Forecast_Schedule__c>) JSON.deserialize(jsonString, List<Forecast_Schedule__c>.class);
      
      List<Forecast_Schedule__c> oldForecasts = [SELECT Id FROM Forecast_Schedule__c WHERE Opportunity__c =: oppId];
      if(!newForecasts.isEmpty()){
          //Opportunity updateOpp = new Opportunity(Id = newForecasts[0].Opportunity__c, Launch_Date__c = newForecasts[0].Start_Date__c);
          List<Forecast_Schedule__c> upsertForecasts = new List<Forecast_Schedule__c>();
          List<Forecast_Schedule__c> deleteForecasts = new List<Forecast_Schedule__c>();
          Savepoint sp = Database.setSavepoint();
          if(oldForecasts.isEmpty() || oldForecasts == null){
              upsertForecasts = newForecasts;
          }
          else{
              for(Integer i = 0; i < oldForecasts.size(); i++){
                 if(i < newForecasts.size()){
                    newForecasts[i].Id = oldForecasts[i].Id;
                    upsertForecasts.add(newForecasts[i]);
                 }
                 else{
                    deleteForecasts.add(oldForecasts[i]);
                 }
              }
              
              for(Integer i = oldForecasts.size(); i < newForecasts.size(); i++){
                  newForecasts[i].Id = null;
                  upsertForecasts.add(newForecasts[i]);
              }
          }
          try{
              delete deleteForecasts;
              upsert newForecasts;
              //update updateOpp;
          }
          catch (DMLException e){
              throw new MissingInformationException('There is an error to update Forecasts: ' + e.getMessage());
              Database.rollback(sp);
          } 
      }
      else{
        delete oldForecasts;
      }
  }
  
  @RemoteAction
  public static Opportunity getOpportunity( Id opportunityId )
  {
    Opportunity theOpportunity = queryOpportunity( opportunityId );

    return theOpportunity;
  }

  private static Opportunity queryOpportunity( Id opportunityId )
  {
    return [ SELECT Id, Name, StageName, Amount, Launch_Date__c, Contract_Terms_Months__c,
                ( SELECT Id, Forecast_Amount__c, Start_Date__c, End_Date__c, Forecasted_Amount_at_Close__c, Is_Pilot__c
                  FROM Forecast_Schedules__r ORDER BY Start_Date__c ASC NULLS LAST )
              FROM Opportunity WHERE Id = :opportunityId ];
  }
  
}