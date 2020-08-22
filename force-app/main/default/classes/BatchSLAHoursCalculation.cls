/** * * * * * * * * * * * *
 *  Class Name:   BatchSLAHoursCalculation
 *  Purpose:      Batch class for SLA Hours calculation for MQL
 *  Author:       Purushottam Bhaigade
 *  Company:      GoNimbly
 *  Created Date: 26-Oct-2016
 *  Updated Date: 26-April-2017 - Jesse Zimmerman
 *  Type:         Batch Class
** * * * * * * * * * * * */
public with sharing class BatchSLAHoursCalculation implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

  Integer nDaysAgo = 1;
  public String query;
  String errors = '';

  // Parameterized constructor
  // @param: Integer value which is equivalent to days.
  // Ex: pass 1 to proccess records created whithin a day.
  public BatchSLAHoursCalculation(Integer daysBackDated)
  {
    daysBackDated = (daysBackDated == null) || (daysBackDated <= 0) ? 1 : daysBackDated;
    init(daysBackDated);
  }

  // default constructor
  public BatchSLAHoursCalculation()
  {
    init(nDaysAgo);
  }

  // Constructor support
  private void init(Integer daysBackDated)
  {
    query = ' SELECT Id,Name,CreatedDate,SLA_Start_Time__c,OwnerId,Dispositioned_Date__c'+
            ' FROM FSR__c'+
            ' WHERE LastModifiedDate = LAST_N_DAYS:'+ daysBackDated+
            ' AND SLA_Changed__c = True'+
            ' AND (SLA_Start_Time__c  = NULL'+
            ' OR (SLA_Start_Time__c != NULL'+
            ' AND Dispositioned_Date__c != NULL))'+
            'ORDER BY LastModifiedDate DESC';
  }

  // start method of the batch class
  public Database.QueryLocator start(Database.BatchableContext BC)
  {
    return Database.getQueryLocator(query);
  }

  //execute method of the batch class
  public void execute(Database.BatchableContext BC, List<FSR__c> scope)
  {
    Map<Id,FSR__c> mqlMap = new Map<Id,FSR__c>(scope);
    Map<Id,Id> mqlIdOwnerIdMap = new Map<Id,Id>();
    Map<Id,String> ownerIdTimeZoneMap = new Map<Id,String>();
    List<FSR__c> mqlListToUpdate = new List<FSR__c>();
    final DateTime HISTORIC_MONDAY = DateTime.newInstanceGMT(1996, 1, 8); // any monday in the past. needed by a formula

    for(FSR__c mqlRecord : scope)
    {
      mqlIdOwnerIdMap.put(mqlRecord.Id,mqlRecord.OwnerId);
    }

    String eastSidKey = 'America/New_York';
    String centralSidKey = 'America/Chicago';
    List<User> ownerList = [Select Id, UserRole.Name, TimeZoneSidKey from User where Id IN :mqlIdOwnerIdMap.values()];
    for(User owner :ownerList)
    {
      if(owner.UserRole.Name != null && owner.UserRole.Name.contains('East')){
          if(owner.UserRole.Name.contains('East II')){
            ownerIdTimeZoneMap.put(owner.Id, eastSidKey);
          }
          else{
            ownerIdTimeZoneMap.put(owner.Id, centralSidKey); 
          }
      }
      else{
        ownerIdTimeZoneMap.put(owner.Id, String.valueOf(owner.TimeZoneSidKey));
      }
    }

    Map<String, BusinessHours> timeZoneToBusinessHoursMap = BatchUtils.getBusinessHours(ownerIdTimeZoneMap.values());

    for(Id mqlId : mqlIdOwnerIdMap.keySet())
    {
      FSR__c mqlRecord = mqlMap.get(mqlId);
      Id ownerId = mqlIdOwnerIdMap.get(mqlId);

      if(!ownerIdTimeZoneMap.containsKey(ownerId) || ownerIdTimeZoneMap.get(ownerId) == null)
      {
        continue;
      }

      String timeZone = ownerIdTimeZoneMap.get(ownerId);
      BusinessHours bHours = timeZoneToBusinessHoursMap.get(timeZone);

      mqlRecord.SLA_8am_User_Timezone__c = BusinessHours.nextStartDate(bHours.id, HISTORIC_MONDAY);
      if(mqlRecord.SLA_Start_Time__c == NULL){
        Datetime targetTime = mqlRecord.CreatedDate;
        mqlRecord.SLA_Start_Time__c = BusinessHours.nextStartDate(bHours.id, targetTime) > targetTime ? BusinessHours.nextStartDate(bHours.id, targetTime) : targetTime;
      }else if(mqlRecord.SLA_Start_Time__c != NULL && mqlRecord.Dispositioned_Date__c != NULL){
        mqlRecord.SLA_Time_in_Hours_Batch__c = ((double)BusinessHours.diff(bHours.id, mqlRecord.SLA_Start_Time__c, mqlRecord.Dispositioned_Date__c) / 1000 / 60 / 60);
        mqlRecord.SLA_Changed__c = False;
      }
      mqlListToUpdate.add(mqlRecord);
    }

    List<Database.SaveResult> saveResults = Database.update(mqlListToUpdate, false);
    errors += checkForSaveResult(mqlListToUpdate, saveResults);
  }

  //finish method of the batch class
  public void finish(Database.BatchableContext BC)
  {
    BatchUtils.finish('BatchSLAHoursCalculation', BC.getJobId(), errors);
  }

  public void execute(SchedulableContext sc)
  {
    BatchSLAHoursCalculation newBatch = new BatchSLAHoursCalculation();
    Database.executeBatch(newBatch);
  }

  /** * * * * * * * * * * * *
  *  Method Name:  checkForSaveResult
  *  Purpose:      This Method returns process SaveResult and returns error if any
  *  Author:       Purushottam Bhaigade
  *  Company:      GoNimbly
  *  Created Date: 9-Nov-2016
  *  Type:         Method
  ** * * * * * * * * * * * */
  private static String checkForSaveResult(List<FSR__c> mqlListToUpdate, List<Database.SaveResult> saveResults)
  {
    String errorMsg = '';
    for (Integer saveResultIndex = 0; saveResultIndex < saveResults.size(); saveResultIndex++)
    {
      if (!saveResults[saveResultIndex].isSuccess())
      {
        Id recordId = mqlListToUpdate[saveResultIndex].Id;
        List<Database.Error> errorList = saveResults[saveResultIndex].getErrors();
        for(Integer errorIndex = 0; errorIndex < errorList.size(); errorIndex++)
        {
          String errorMessage = '\n\n The following error has occurred with id: ' + recordId;
          errorMessage += '\n' + errorList[errorIndex].getStatusCode() + ': ' + errorList[errorIndex].getMessage();
          errorMessage += '\n Fields that affected this error: ' + errorList[errorIndex].getFields();
          errorMessage += '\n -------------------------------------------------------';
          errorMsg += errorMessage;
        }
      }
    }
    return errorMsg;
  }
}