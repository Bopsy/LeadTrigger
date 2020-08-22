/** * * * * * * * * * * * *
 *
 *  Class Name:   BatchLinkAccountSidToTwilioUsage
 *  Purpose:      This class link AccountSid with TwilioUsage object's records.
 *                AccountSid field on AccountSid is used to link contact,lead and accountsid lookup on TwilioUsage.
 *                Part of "Twilio Multi-User Code Update Project v2.1"
 *  Author:       Ashwani Soni
 *  Company:      GoNimbly, Zack
 *  Created Date: 04-Feb-2016
 *  Changes:      Changed with new req. "Twilio Multi-User Code Update Project v2.1" on 09-Feb-2015
 *  Type:         Batch class
 *
** * * * * * * * * * * * */

public with sharing class BatchLinkAccountSidToTwilioUsage implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    /*****
    * Ashwani: 08 March 2016.
    * WARNING: This object has more than 10 million records. Query must be very optimized.
    * return records order by created date in ascending order. Oldest will be the first.
    ****/
    public String query = 'SELECT Id, IsDeleted, AccountSid__c, Usage_Account_SID_Match_AccountSID_SID__c,'
                            + ' Usage_Account_Match_AccountSID_Account__c, Related_Account_SID__c, Lead__c, Contact__c'
                            + ' FROM Twilio_Usage__c '
                            + ' WHERE Month__c IN ({0})'
                            + ' AND AccountSid__c != NULL'
                            + ' AND Related_Account_Sid__c = NULL'
                            + ' AND Year__c IN (2020)'
                            + ' AND CreatedDate > 2019-10-01T00:00:00+0000'
                            + ' AND Finance_Amortized_Billings__c != 0'
                            + ' LIMIT 25000';
    public String monthsString;
    public List<String> errors;

    public BatchLinkAccountSidToTwilioUsage()
    {
        this.monthsString = '' + Date.today().month();
        this.errors = new List<String>();
    }

    public BatchLinkAccountSidToTwilioUsage(List<Integer> monthsToProcess)
    {
        this();
        this.monthsString = String.join(monthsToProcess, ', ');
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        this.query = String.format(this.query, new List<String>{ this.monthsString });
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext info, List<sObject> scope)
    {
        // Link Account Sid lookup on Twilio Usage with matching Account Sid record.
        List<Twilio_Usage__c> twUsageList = UtilityLinkAccountSidToTwilioUsage.LinkAccountSidToTwilioUsage( (List<Twilio_Usage__c>)scope );

        // updare list if it has records
        if(twUsageList != null && twUsageList.size() > 0)
        {
            List<Database.SaveResult> updateResults = Database.update(twUsageList, false);
            for(Integer index = 0; index < updateResults.size(); index++)
            {
                if(!updateResults[index].isSuccess())
                {
                    for( Database.Error anError : updateResults[index].getErrors() )
                    {
                        this.errors.add(twUsageList[index].Id + ': ' + anError.getMessage());
                    }
                }
            }
        }
    }

    // Schedulable
    public void execute(SchedulableContext sc)
    {
        Database.executeBatch(new BatchLinkAccountSidToTwilioUsage(new List<Integer>{ 1, 2, 3 }));
        Database.executeBatch(new BatchLinkAccountSidToTwilioUsage(new List<Integer>{ 4, 5, 6 }));
        Database.executeBatch(new BatchLinkAccountSidToTwilioUsage(new List<Integer>{ 7, 8, 9 }));
        Database.executeBatch(new BatchLinkAccountSidToTwilioUsage(new List<Integer>{ 10, 11, 12 }));
    }

    // Post batch processes. Send email in case of any error.
    public void finish(Database.BatchableContext BC)
    {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        /*if(this.errors.size() > 0)
        {
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, ExtendedStatus,
                                      TotalJobItems, CreatedBy.Email
                               FROM AsyncApexJob WHERE Id = :BC.getJobId()];

            // Send an email to the Apex job's submitter notifying of job error.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] { a.CreatedBy.Email };
            mail.setToAddresses(toAddresses);
            mail.setSubject('Linking Twilio Usages with AccountSid ' + a.Status);
            mail.setPlainTextBody
               ('The batch Apex job processed ' + a.TotalJobItems +
               ' batch(es) with ' + a.NumberOfErrors +
               ' failures.\n\nError Description:\n ' + a.ExtendedStatus +
               ' Details:\n' + String.join(this.errors, '\n'));

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }*/
    }


}