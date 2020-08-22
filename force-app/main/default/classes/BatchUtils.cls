/** * * * * * * * * * * * *
*  Class Name:   BatchUtils
*  Purpose:      util class for batch classes
*  Author:       Purushottam Bhaigade
*  Company:      GoNimbly
*  Created Date: 26-Oct-2016
*  Type:         Util Class
** * * * * * * * * * * * */
public with sharing class BatchUtils {

  /** * * * * * * * * * * * *
  *  Method Name:   finish
  *  Purpose:      Batch clas finish method.
  *  Author:       Purushottam Bhaigade
  *  Company:      GoNimbly
  *  Created Date: 26-Oct-2016
  *  Type:         Method
  ** * * * * * * * * * * * */
  public static void finish(String className, Id jobId, String errors) {
    AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, ExtendedStatus,
                                  TotalJobItems
                           FROM AsyncApexJob WHERE Id = :jobId];
    sendEmail(className, asyncJob, errors);
  }

  /** * * * * * * * * * * * *
  *  Method Name:   sendEmail
  *  Purpose:      Method to send email on batch completion
  *  Author:       Purushottam Bhaigade
  *  Company:      GoNimbly
  *  Created Date: 26-Oct-2016
  *  Type:         Method
  ** * * * * * * * * * * * */
  private static void sendEmail(String className, AsyncApexJob asyncJob, String errors)
  {
    // Send an email to the Apex job's submitter notifying of job errors.
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    TwilioEmailSetting__c settings = TwilioEmailSetting__c.getOrgDefaults();
    String[] toAddresses = new String[] {settings.BatchEmails__c};
    mail.setToAddresses(toAddresses);
    mail.setSubject(className + asyncJob.Status);
    String textBody = ' The batch Apex job processed ' + asyncJob.TotalJobItems +
                      ' batche(s) with '+ asyncJob.NumberOfErrors +
                      ' failures.\n\nError Description:\n '+asyncJob.ExtendedStatus;
    if (String.isNotBlank(errors))
    {
      textBody += '\n\n\n Caught and Handled Errors \n' + errors;
    }
    mail.setPlainTextBody(textBody);
    if(String.isNotBlank(errors) && !System.Test.isRunningTest())
    {
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
  }

  /** * * * * * * * * * * * *
  *  Method Name:  getBusinessHours
  *  Purpose:      This Method returns map of timezone to businesshours
  *  Author:       Purushottam Bhaigade
  *  Company:      GoNimbly
  *  Created Date: 2-Nov-2016
  *  Type:         Method
  ** * * * * * * * * * * * */
  public static Map<String, BusinessHours> getBusinessHours(List<String> timeZoneList)
  {
    BusinessHours defaultBusinessHours = null;
    Map<String, BusinessHours> timeZoneToBusinessHoursMap = new Map<String, BusinessHours>();
    List<BusinessHours> bHoursList = [select Id,Name,TimeZoneSidKey,IsActive,IsDefault
                      from BusinessHours
                      where IsActive = true];

    for(BusinessHours bHour :bHoursList)
    {
      if(bHour.IsDefault)
      {
        defaultBusinessHours = bHour;
      }
      timeZoneToBusinessHoursMap.put(bHour.TimeZoneSidKey, bHour);
    }

    for(String timezone :timeZoneList)
    {
      //check if there is entry for timezone if there is no entry for time zone then add default business hour
      if(!timeZoneToBusinessHoursMap.containsKey(timezone))
      {
        timeZoneToBusinessHoursMap.put(timezone, defaultBusinessHours);
      }
    }
    return timeZoneToBusinessHoursMap;
  }

  /* * * * * * * * * * * * * *
  *  Method Name:  processSaveResult
  *  Purpose:      This Method process SaveResult and returns error if any
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 01-Mar-2017
  *  Type:         Method
  * * * * * * * * * * * * * */
  public static String processSaveResult(List<sObject> sObjectListToUpdate, List<Database.SaveResult> saveResults)
  {
    String errorMsg = '';
    for (Integer saveResultIndex = 0; saveResultIndex < saveResults.size(); saveResultIndex++)
    {
      if (!saveResults[saveResultIndex].isSuccess())
      {
        Id recordId = sObjectListToUpdate[saveResultIndex].Id;
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