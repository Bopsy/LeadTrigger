public without sharing class PassToPartnerForecastController {
  public String oppString {get; set;}
  public Decimal sharePercentage {get; set;}
  public Id oppId {get; set;}
  public PassToPartnerForecastController( ApexPages.StandardController standardCont ) {
      Id ptpId = (Id) standardCont.getRecord().Id;
      Pass_to_Partner__c ptp = [SELECT Opportunity__c, Partner_Account__r.Partner_Revenue_Share__c FROM Pass_to_Partner__c WHERE Id = : ptpId];
      oppId = ptp.Opportunity__c;
      sharePercentage = ptp.Partner_Account__r.Partner_Revenue_Share__c;
      oppString = JSON.serialize(getOpportunity(oppId));
  }
  public class MissingInformationException extends System.Exception {}
  @RemoteAction
  public static void saveForecasts(String jsonString, Id oid){
      List<Forecast_Schedule__c> newForecasts = (List<Forecast_Schedule__c>) JSON.deserialize(jsonString, List<Forecast_Schedule__c>.class);
      
      List<Forecast_Schedule__c> oldForecasts = [SELECT Id FROM Forecast_Schedule__c WHERE Opportunity__c =: oid];
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
          }
          catch (DMLException e){
              throw new MissingInformationException('There is an error to delete old Forecasts: ' + e.getMessage()); 
          }
          try{
              upsert newForecasts;
              //update updateOpp;
          }
          catch (DMLException e){
              throw new MissingInformationException('There is an error to upsert new Forecasts: ' + e.getMessage());
              Database.rollback(sp);
          } 
      }
      else{
          try{
              delete oldForecasts;
          }
          catch (DMLException e){
              throw new MissingInformationException('There is an error to delete old Forecasts: ' + e.getMessage()); 
          }
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
                ( SELECT Id, Forecast_Usage__c, Share_Percent__c, Forecast_Amount__c, Start_Date__c, End_Date__c, Forecasted_Amount_at_Close__c, Is_Pilot__c, License_Fee__c
                  FROM Forecast_Schedules__r ORDER BY Start_Date__c ASC NULLS LAST )
              FROM Opportunity WHERE Id = :opportunityId ];
  }
  
}