public with sharing class CommitSchedulerControllerExt {
  public String agreementString {get; set;}
  public Id agreementId {get; set;}
  public CommitSchedulerControllerExt( ApexPages.StandardController standardCont ) {
      agreementId = (Id) standardCont.getRecord().Id;
      agreementString = JSON.serialize(getAgreement(agreementId));
  }
  public class MissingInformationException extends System.Exception {}
  
  @RemoteAction
  public static void saveForecasts(String jsonString, String commitString, Id agreementId, String termsOfMonth, String totalCommit, String recordTypeId){
      Savepoint sp = Database.setSavepoint();
      Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Id = agreementId, Term_Range__c = termsOfMonth, Total_Committed_Revenue_Input__c = Decimal.valueOf(totalCommit));
      try{
          update agreement;
          List<Commit_Schedule__c> newForecasts = (List<Commit_Schedule__c>) JSON.deserialize(jsonString, List<Commit_Schedule__c>.class);
          List<Commit_Schedule__c> newProdCommit = (List<Commit_Schedule__c>) JSON.deserialize(commitString, List<Commit_Schedule__c>.class);
          List<Commit_Schedule__c> oldForecasts = [SELECT Id FROM Commit_Schedule__c WHERE Agreement__c =: agreementId AND RecordType.Name != 'Product Commit'];
          List<Commit_Schedule__c> oldProdCommit = [SELECT Id FROM Commit_Schedule__c WHERE Agreement__c =: agreementId AND RecordType.Name = 'Product Commit'];
          if(!newForecasts.isEmpty() || !newProdCommit.isEmpty()){
              List<Commit_Schedule__c> upsertForecasts = new List<Commit_Schedule__c>();
              List<Commit_Schedule__c> deleteForecasts = new List<Commit_Schedule__c>();
              for(Commit_Schedule__c schedule: newProdCommit){
                  schedule.RecordTypeId = recordTypeId;
                  schedule.Agreement__c = agreementId;
              }
              upsertForecasts = newForecasts;
              for(Integer i = oldForecasts.size() - 1; i >= 0; i--){
                  for(Commit_Schedule__c newSchedule :upsertForecasts){
                      if(oldForecasts[i].Id == newSchedule.Id){
                          oldForecasts.remove(i);
                          break;
                      }
                  }
              }
              deleteForecasts.addAll(oldForecasts);
              upsertForecasts.addAll(newProdCommit);
              for(Integer i = oldProdCommit.size() - 1; i >= 0; i--){
                  for(Commit_Schedule__c newSchedule :upsertForecasts){
                      if(oldProdCommit[i].Id == newSchedule.Id){
                          oldProdCommit.remove(i);
                          break;
                      }
                  }
              }
              deleteForecasts.addAll(oldProdCommit);
              delete deleteForecasts;
              upsert newForecasts;
          }
          else{
            delete oldForecasts;
          }
      }
          catch (DMLException e){
              throw new MissingInformationException('There is an error to update Forecasts: ' + e.getMessage());
              Database.rollback(sp);
          } 
      
  }
  
  @RemoteAction
  public static Apttus__APTS_Agreement__c getAgreement( Id agreementId )
  {
    Apttus__APTS_Agreement__c theAgreement = queryAgreement(agreementId);

    return theAgreement;
  }
  
  public String getCommitSchedules(){
      List<Commit_Schedule__c> productCommits = [SELECT Id, Start_Date__c, Product_Group__c, Commit_Amount__c, Commit_Frequency__c FROM Commit_Schedule__c WHERE Agreement__c =: agreementId AND RecordType.Name = 'Product Commit' ORDER BY Start_Date__c];
      return JSON.serialize(productCommits);
  }
  
  private static Apttus__APTS_Agreement__c queryAgreement( Id agreementId )
  {
    return [ SELECT Id, Name, Term_Range__c, Total_Committed_Revenue__c, Total_Committed_Revenue_Input__c, Commit_Frequency__c, Commit_Start_Month__c,
                ( SELECT Id, Commit_Amount__c, Start_Date__c, End_Date__c
                  FROM Commit_Schedules__r 
                  WHERE RecordType.Name != 'Product Commit'
                  ORDER BY Start_Date__c ASC NULLS LAST )
              FROM Apttus__APTS_Agreement__c WHERE Id = :agreementId ];
  }
  
  
}