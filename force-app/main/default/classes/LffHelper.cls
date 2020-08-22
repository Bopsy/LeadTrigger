/* * * * * *
*
* Name:        LffHelper (Batch class)
* Description: Helper class to put common methods in on place
* Change:      Added Status field in Campaign Member to filter records. 22-Feb-2016, Ashwani @GoNimbly Jen
               Added logic to populate Campaign Member status on LFF. And added "Inquiry_Date_Entered__c" field
               to be populated only when new LFF is created. 04-March-2016, Ashwani @GoNimbly Jen
* Created:     17-February-2016, 11:03 PST
* Author:      Troy
* Company:     GoNimbly. Ian, Jen
*
* * * */
public with sharing class LffHelper 
{
    public static List<String> qualifiedStatuses = System.Label.Qualified_CMember_Statuses != '' 
                                             ? (new List<String>(System.Label.Qualified_CMember_Statuses.split(','))) 
                                             : new List<String>();
    public LffHelper() {}

    /*
     * Create or Update Lifecycle Field Funnel records.
     * @param 1: Lifecycle_Field_Funnel__c
     * @param 2: Most recent Campaign Member record for the Lead/Contact
     * @param 3: Oldest Campaing Member record for the Lead/Contact
     * @return : Updated LFF instance
    **/
    public static void populateLFFRecord(Lifecycle_Field_Funnel__c newLFF, CampaignMember latestCM, CampaignMember oldestCM)
    {
        /* * * * * *
        // change on 04-March-2016 : Ashwani Soni
        // When an LFF is created by a campaign member, Inquiry information is updated. 
        // When an LFF is created by MQL, SAL, SQL, we check for recent Campaign Member & Update
        // When a new Campaign Member is created and there is an existing LFF, we update First & Last Touch campaign info, and Inquiry info is left blank.
        //
        // All above is happening when the LFF is CREATED. 
        * * * */
        if(newLFF.id == null)
        {
            // Change 1
            // Here it is in latest CM. It happens only via MQL, SAL, SQL
            newLFF.Inquiry_Date_Entered__c = latestCM != null ? latestCM.CreatedDate : null;
        }
        
        // Change on 04-March-2016 : Ashwani Soni. Change 3
        //We need visibility into the status that the campaign member was in at time of LFF update
        if(newLFF.First_Touch_Campaign_Member_Status__c == null)
            newLFF.First_Touch_Campaign_Member_Status__c = oldestCM != null ? oldestCM.Status : null;
            
        if(newLFF.First_Touch_Campaign__c == null)
            newLFF.First_Touch_Campaign__c = oldestCM != null ? oldestCM.CampaignId : null;

        if(newLFF.First_Touch_Campaign_Member_ID__c == null)
            newLFF.First_Touch_Campaign_Member_ID__c = oldestCM != null ? oldestCM.id : null;

        if(newLFF.First_Touch_UTM_Content__c == null)
            newLFF.First_Touch_UTM_Content__c = oldestCM != null ? oldestCM.UTM_Content__c : null;

        if(newLFF.First_Touch_UTM_Medium__c == null)
            newLFF.First_Touch_UTM_Medium__c = oldestCM != null ? oldestCM.UTM_Medium__c : null;

        if(newLFF.First_Touch_UTM_Source__c == null)
            newLFF.First_Touch_UTM_Source__c = oldestCM != null ? oldestCM.UTM_Source__c : null;

        if(newLFF.First_Touch_UTM_Term__c == null)
            newLFF.First_Touch_UTM_Term__c = oldestCM != null ? oldestCM.UTM_Term__c : null;

        if(newLFF.First_Touch_Associated_Date__c == null)
            newLFF.First_Touch_Associated_Date__c = oldestCM != null ? oldestCM.createdDate : null;
            
        if(newLFF.First_Touch_Campaign_Type__c == null)
            newLFF.First_Touch_Campaign_Type__c = oldestCM != null ? oldestCM.Campaign.Type : null;
            
        if(newLFF.First_Touch_Campaign_Sub_Type__c == null)
            newLFF.First_Touch_Campaign_Sub_Type__c = oldestCM != null ? oldestCM.Campaign.SubType__c : null;
            
        if(newLFF.First_Touch_Product__c== null)
            newLFF.First_Touch_Product__c = oldestCM != null ? oldestCM.Campaign.Product_Type__c : null;            

        // Update Last Touch fields with most recent Campaign Member
        if(latestCM != null)
        {
            newLFF.Last_Touch_UTM_Content__c = latestCM.UTM_Content__c;
            newLFF.Last_Touch_UTM_Medium__c = latestCM.UTM_Medium__c;
            newLFF.Last_Touch_UTM_Source__c = latestCM.UTM_Source__c;
            newLFF.Last_Touch_UTM_Term__c = latestCM.UTM_Term__c;
            newLFF.Last_Touch_Associated_Date__c = latestCM.createdDate;
            newLFF.Last_Touch_Campaign_Member_ID__c = latestCM.id;
            newLFF.Last_Touch_Campaign__c = latestCM.CampaignId;
            
            newLFF.Last_Touch_Campaign_Product__c= latestCM.Campaign.Product_Type__c;
            newLFF.Last_Touch_Campaign_Sub_Type__c= latestCM.Campaign.SubType__c;
            newLFF.Last_Touch_Campaign_Type__c = latestCM.Campaign.Type;
            
            // Change on 04-March-2016 : Ashwani Soni
            //We need visibility into the status that the campaign member was in at time of LFF update
            newLFF.Last_Touch_Campaign_Member_Status__c = latestCM.Status;
            
            if(newLFF.Current_Funnel_Stage__c != '4 - SQL'){
            
                newLFF.Last_Touch_SQL_Campaign__c = latestCM.CampaignId;
                newLFF.Last_Touch_SQL_Campaign_Member_Status__c = latestCM.Status;                 
                newLFF.Last_Touch_SQL_Associated_Date__c = latestCM.createdDate;
                newLFF.Last_Touch_SQL_Campaign_Type__c = latestCM.Campaign.Type;
                newLFF.Last_Touch_SQL_Campaign_Sub_Type__c = latestCM.Campaign.SubType__c;
                newLFF.Last_SQL_Touch_UTM_Content__c = latestCM.UTM_Content__c;
                newLFF.Last_SQL_Touch_UTM_Medium__c = latestCM.UTM_Medium__c;
                newLFF.Last_SQL_Touch_UTM_Source__c = latestCM.UTM_Source__c;
                newLFF.Last_SQL_Touch_UTM_Term__c = latestCM.UTM_Term__c; 
                newLFF.Last_SQL_Touch_Product__c = latestCM.Campaign.Product_Type__c; 
                newLFF.Last_Touch_SQL_Campaign_Member_ID__c= latestCM.id;         
            }            
        }
        
    }

    public static void sendEmail(AsyncApexJob asyncJob, String sourceFile)
    {
        // Send an email to the Apex job's submitter notifying of job errors.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'twilio@gonimbly.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject(sourceFile + asyncJob.Status);
        mail.setPlainTextBody
           ('The batch Apex job processed ' + asyncJob.TotalJobItems +
           ' batche(s) with '+ asyncJob.NumberOfErrors +
           ' failures.\n\nError Description:\n '+asyncJob.ExtendedStatus);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}