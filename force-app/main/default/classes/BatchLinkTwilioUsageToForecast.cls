/** * * * * * * * * * * * *
 *
 *  Class Name:   BatchLinkTwilioUsageToForecast
 *  Purpose:      This class link Twilio usage with Forecast Schedule records.
 *                AccountSid on Opportunity is used to identify Twilio Usage.
 *  Author:       Ashwani Soni
 *  Company:      GoNimbly
 *  Created Date: 04-Nov-2015
 *  Changes:      Added the functionality for removing inappropriate Twilio Usage from Forecast Schedule; Divesh Bafna; May 2, 2016
 *  Type:         Batch class
 *
** * * * * * * * * * * * */

public with sharing class BatchLinkTwilioUsageToForecast implements Database.Batchable<sObject>,Schedulable
{
    // only processing records which have AccountSid__c, Month__c and Year__c

    List<String> salesOpertaionExceptionApprovalList = new List<String>{'SOPS Denied', 'Final Denied'};
    public String query = 'SELECT '+
                                    'id, '+
                                    'Start_Date__c, '+
                                    'Twilio_Usage__c, '+
                                    'Opportunity__r.New_Business_Account_SID__c, '+
                                    'Opportunity__r.Exception_Account_SID__c '+
                          'FROM Forecast_Schedule__c '+
                          'WHERE Start_Date__c != null '+
                          'AND Opportunity__r.StageName = \'Closed Won\' ';

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext info, List<sObject> scope)
    {
        List<Forecast_Schedule__c> fsList = new List<Forecast_Schedule__c>();
        Set<String> accountSids = new Set<String>();

        for(Forecast_Schedule__c fs : (List<Forecast_Schedule__c>)scope)
        {
            if(fs.Opportunity__r.New_Business_Account_SID__c == null && fs.Opportunity__r.Exception_Account_SID__c == null)
            {
                continue;
            }

            if(fs.Opportunity__r.New_Business_Account_SID__c != null)
            {
                accountSids.add(fs.Opportunity__r.New_Business_Account_SID__c);
            }
            else if(fs.Opportunity__r.Exception_Account_SID__c != null)
            {
                accountSids.add(fs.Opportunity__r.Exception_Account_SID__c);
            }
            else
            {
                continue;
            }
            fsList.add(fs);
        }

        List<Twilio_Usage__c> twiUsgList = [SELECT id, AccountSid__c, Month__c, Year__c
                                                      FROM Twilio_Usage__c
                                                      WHERE AccountSid__c IN:accountSids
                                                      AND Month__c!= null AND Year__c != null
                                                      LIMIT 50000];

        //Key: {{Twilio Usage's Account SID }}-{{MonthNumber}}-{{YearNumber}} value:{{Twilio_Usage__c}}

        Map<String,Twilio_Usage__c> twiUsgMonthYearMap = new Map<String,Twilio_Usage__c>();
        for(Twilio_Usage__c twiUsg: twiUsgList  )
        {
            // ACeA...-12-2015
            String monthYearStr = twiUsg.AccountSid__c +'-'+twiUsg.Month__c+'-'+twiUsg.Year__c ;
            twiUsgMonthYearMap.put(monthYearStr,twiUsg);
        }

        for(Forecast_Schedule__c forecastSch :fsList)
        {
            // ACeA...-01-2015
            String monthYearStr = '';
            if(forecastSch.Opportunity__r.New_Business_Account_SID__c != null)
            {
                monthYearStr +=forecastSch.Opportunity__r.New_Business_Account_SID__c;
            }
            else if(forecastSch.Opportunity__r.Exception_Account_SID__c != null)
            {
                monthYearStr +=forecastSch.Opportunity__r.Exception_Account_SID__c;
            }

            monthYearStr +='-'+forecastSch.Start_Date__c.month()+'-'+forecastSch.Start_Date__c.year();

            if(twiUsgMonthYearMap.containsKey(monthYearStr))
            {
                forecastSch.Twilio_Usage__c = twiUsgMonthYearMap.get(monthYearStr).id;
            }
            else
            {
                forecastSch.Twilio_Usage__c = null;
            }
            twiUsgMonthYearMap.remove(monthYearStr);
        }

        if(fsList.size()>0)
        {
            update fsList;
        }
    }

    public void execute(SchedulableContext SC)
    {
        BatchLinkTwilioUsageToForecast bat = new BatchLinkTwilioUsageToForecast();
        database.executebatch(bat);
    }

    public void finish(Database.BatchableContext info)
    {
        AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, ExtendedStatus,
                                  TotalJobItems
                           FROM AsyncApexJob WHERE Id = :info.getJobId()];

        if(asyncJob.NumberOfErrors > 0 || System.Test.isRunningTest())
        {
            LffHelper.sendEmail(asyncJob, 'BatchLinkTwilioUsageToForecast ');
        }
    }
}