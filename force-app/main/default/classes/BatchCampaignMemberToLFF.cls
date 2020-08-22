/* * * * * *
*
* Name:        BatchCampaignMemberToLFF (Batch class)
* Description: Query new Campaign Members related to "Marketing Campaigns". Create LFF records.
*              Disregard Campaign Members related to an Active LFF record.
               Does Lead have an Active LFF record?
                 if Yes, relate LFF to Campaign Member
                 if No. Create LFF related to Campaign Member.
               Does Contact have an Active LFF record?
                 if Yes, relate LFF to Campaign Member
                 if No. Create LFF related to Campaign Member.
               Note: LFF don't have lookup to Campaign Member. It is a text field.
* Change:      Added Status field in Campaign Member to filter records. 22-Feb-2016, Ashwani @GoNimbly Jen
               Change Query from init method. Replace CreatedDate from where clause with Campaign_Member_Updated_Date__c 26-May-2016, Purushottam
* Created:     21-January-2016, 15:37 IST
* Author:      Ashwani Soni
* Company:     GoNimbly, Ian, Jen
*
* * * */
public with sharing class BatchCampaignMemberToLFF implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    public String errors = '';
    public String query;
    Integer nDaysAgo = 1;
    Datetime daysAgo;

    private static List<String> qualifiedStatuses = LffHelper.qualifiedStatuses;

    // default constructor
    public BatchCampaignMemberToLFF()
    {
        init(null);
    }

    // Parameterized constructor
    // @param: Integer value which is equivalent to days.
    // Ex: pass 1 to proccess records created whithin a day.
    public BatchCampaignMemberToLFF(Integer daysBackDated)
    {
        init(daysBackDated);
    }

    // Constructor support
    private void init(Integer daysBackDated)
    {
        this.nDaysAgo = daysBackDated != null ? daysBackDated : nDaysAgo;
        daysAgo = Datetime.now().addDays(nDaysAgo*(-1));
        query = ' SELECT id, LeadId, ContactId, Member_Type__c '+
                ' FROM CampaignMember WHERE Campaign.Is_Marketing_Campaign_Type__c = TRUE'+
                ' AND Status in:qualifiedStatuses'+
                ' AND LastModifiedDate >: daysAgo';
    }


    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();

        // Collect Lead and Contact Ids of Campaign Members
        for(CampaignMember cm : (List<CampaignMember>) scope)
        {
            if(cm.Member_Type__c == 'Lead')
            {
                leadIds.add(cm.LeadId);
            }
            else
            {
                contactIds.add(cm.ContactId);
            }
        }

        List<Lifecycle_Field_Funnel__c> lffToUpsertLead = new List<Lifecycle_Field_Funnel__c>();
        for(Lead leadRecord : [SELECT id,name, Eloqua_Lead_Rating__c,
                               (SELECT id,name,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_UTM_Content__c ,First_Touch_Campaign_Member_Status__c ,Lead__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,First_Touch_Campaign_Member_ID__c,Last_Touch_Campaign_Member_ID__c, First_Touch_Campaign__c, Last_Touch_Campaign__c, LFF_Active__c, Current_Funnel_Stage__c, Inquiry_Date_Entered__c from Demand_Funnel_Reports__r WHERE LFF_Active__c = TRUE ORDER BY CreatedDate),
                               (SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c, CampaignId, LeadId, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, CreatedDate, Status from CampaignMembers WHERE Campaign.Is_Marketing_Campaign_Type__c = TRUE AND Status in:qualifiedStatuses ORDER BY CreatedDate)
                               from Lead WHERE Id in:leadIds])
        {
            CampaignMember latestCM = null;
            CampaignMember oldestCM = null;

            // Additional Campaign Memeber exist. Find Recent and Old CampaignMember
            if(leadRecord.CampaignMembers.size() > 1)
            {
                oldestCM = leadRecord.CampaignMembers[0];
                latestCM = leadRecord.CampaignMembers[leadRecord.CampaignMembers.size() - 1];
            }
            else if(leadRecord.CampaignMembers.size() == 1) // One Campaign Member exist for Lead
            {
                oldestCM = leadRecord.CampaignMembers[0];
                latestCM = leadRecord.CampaignMembers[0];
            }

            // No LFF exist for the Lead of CampaignMember. No Active or Inactive LFF exists
            if(leadRecord.Demand_Funnel_Reports__r.size() == 0)
            {
                 Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null, null,leadRecord.id,latestCM,oldestCM, leadRecord.Eloqua_Lead_Rating__c);
                 newLFF.Lead__c = leadRecord.id;
                 lffToUpsertLead.add(newLFF);
            }
            else
            {
                // Update LFF with Last Touch fields. Active LFF found for Leads of Campaign Member
                for(Lifecycle_Field_Funnel__c lff : leadRecord.Demand_Funnel_Reports__r)
                {
                    // modify active LFFs only
                    if(lff.LFF_Active__c == true)
                    {
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(lff, null,leadRecord.id,latestCM,oldestCM, leadRecord.Eloqua_Lead_Rating__c);
                        newLFF.Lead__c = leadRecord.id;
                    }
                    lffToUpsertLead.add(lff);
                }
            }


        }

        List<Lifecycle_Field_Funnel__c> lffToUpsertContact = new List<Lifecycle_Field_Funnel__c>();
        for(Contact contactRecord : [SELECT id,name, Eloqua_Lead_Rating__c,
                               (SELECT id,name,Lead__c,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_Status__c ,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,First_Touch_Campaign_Member_ID__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c, Last_Touch_Campaign__c, LFF_Active__c, Current_Funnel_Stage__c, Inquiry_Date_Entered__c from Demand_Funnel_Reports__r WHERE LFF_Active__c = TRUE ORDER BY CreatedDate),
                               (SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,CampaignId, ContactId,UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, CreatedDate, Status from CampaignMembers WHERE Campaign.Is_Marketing_Campaign_Type__c = TRUE AND Status in:qualifiedStatuses ORDER BY CreatedDate)
                               from Contact WHERE Id in:contactIds])
        {
            CampaignMember latestCM = null;
            CampaignMember oldestCM = null;

            // Additional Campaign Memeber exist. Find Recent and Old CampaignMember
            if(contactRecord.CampaignMembers.size() > 1)
            {
                oldestCM = contactRecord.CampaignMembers[0];
                latestCM = contactRecord.CampaignMembers[contactRecord.CampaignMembers.size() - 1];
            }
            else if(contactRecord.CampaignMembers.size() == 1) // // One Campaign Member exist for Contact
            {
                latestCM = contactRecord.CampaignMembers[0];
                oldestCM = contactRecord.CampaignMembers[0];
            }

            // No LFF exist for the Contact of CampaignMember. No active or inactive LFF exist
            if(contactRecord.Demand_Funnel_Reports__r.size() == 0)
            {
                 Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null, contactRecord.id,null,latestCM,oldestCM,contactRecord.Eloqua_Lead_Rating__c);
                 newLFF.Contact__c = contactRecord.id;
                 lffToUpsertContact.add(newLFF);
            }
            else
            {
                // Update LFF with Last Touch fields. Active LFF found for Contacts of Campaign Member
                for(Lifecycle_Field_Funnel__c lff : contactRecord.Demand_Funnel_Reports__r)
                {
                    // modify active LFFs only
                    if(lff.LFF_Active__c == true)
                    {
                        lff = createLFFRecord(lff, contactRecord.id,null,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                        lFF.Contact__c = contactRecord.id;
                    }
                    lffToUpsertContact.add(lff);
                }
            }


        }
        // Update and Insert LFF Lead
        if(lffToUpsertLead.size()>0)
        {
            List<Database.UpsertResult> results = Database.upsert(lffToUpsertLead, FALSE);
            for(Integer index = 0; index < results.size(); index++)
            {
                if(!results[index].isSuccess())
                {
                    String errorMessage = 'LFF Upsert failed for Id ' + lffToUpsertLead[index].Id + ' and Lead ' + lffToUpsertLead[index].Lead__c;
                    for(Database.Error anError : results[index].getErrors())
                    {
                        errorMessage += '\n' + anError.getMessage();
                    }
                    this.errors += '\n' + errorMessage;
                }
            }
        }

        // Update and Insert LFF Contact
        if(lffToUpsertContact.size()>0)
        {
            List<Database.UpsertResult> results = Database.upsert(lffToUpsertContact, FALSE);
            for(Integer index = 0; index < results.size(); index++)
            {
                if(!results[index].isSuccess())
                {
                    String errorMessage = 'LFF Upsert failed for Id ' + lffToUpsertContact[index].Id + ' and Contact ' + lffToUpsertContact[index].Contact__c;
                    for(Database.Error anError : results[index].getErrors())
                    {
                        errorMessage += '\n' + anError.getMessage();
                    }
                    this.errors += '\n' + errorMessage;
                }
            }
        }
    }

    public void finish(Database.BatchableContext BC)
    {
        // ==> 2
        // Schedule or run Next batch BatchMQLeadToLFF
        processBatchChain(false);

        if(!String.isBlank(this.errors) && !System.Test.isRunningTest())
        {
            BatchUtils.finish('Campaign Member Batch LFF', BC.getJobId(), this.errors);
        }
    }

    /*****
    *
    * Schedule Runner. Index 1
    *
    *****/
    public void execute(SchedulableContext sc)
    {
        // ==> 1
        // Schedule or run THIS batch BatchCampaignMemberToLFF
        processBatchChain(true);
    }

    /*
     * Create or Update Lifecycle Field Funner records.
     * @param 1: Lifecycle_Field_Funnel__c
     * @param 2: Id of Contact object
     * @param 3: Id of Lead object
     * @param 4: Most recent Campaign Member record for the Lead/Contact
     * @param 5: Oldest Campaing Member record for the Lead/Contact
     * @param 6: Inquiry Interest Score. Either use Contact or Lead
     * @return : Updated LFF instance
    **/
    private Lifecycle_Field_Funnel__c createLFFRecord(Lifecycle_Field_Funnel__c lff, Id contactId, Id LeadId, CampaignMember latestCM, CampaignMember oldestCM, String rating)
    {
        // Assign exsting LFF or create new instance of LFF
        Lifecycle_Field_Funnel__c newLFF = lff != null ? lff : (new Lifecycle_Field_Funnel__c ());
        newLFF.Inquiry_Interest_Score__c = rating;
        LffHelper.populateLFFRecord(newLFF, latestCM, oldestCM);
        return newLFF;
    }

    /* * *
    *
    *   @param: Boolean value decide whether the current batch should run or the next batch
    *   Used to schedule/run current/next batch
    *
    */
    private void processBatchChain(Boolean isCurrentBatch)
    {
        Integer jobs = [Select count() From AsyncApexJob Where JobType = 'BatchApex' and ( Status = 'Queued' or Status = 'Processing' or Status = 'Preparing' )];
        if(jobs != null && jobs > 4 )
        {
            scheduleBatch(isCurrentBatch);
        }
        else
        {
            runBatch(isCurrentBatch);
        }
    }

    /* * *
    *
    *   @param: Boolean value decide whether the current batch should run or the next batch
    *
    */
    private void runBatch(Boolean isCurrentBatch)
    {
        if(isCurrentBatch)
        {
            BatchCampaignMemberToLFF bat = new BatchCampaignMemberToLFF(nDaysAgo);
            database.executebatch(bat);
        }
        else
        {
            // @param: Integer equivalent to day.
            // Next batch
            BatchMQLeadToLFF bat = new BatchMQLeadToLFF(nDaysAgo);
            database.executebatch(bat);
        }
    }

    /* * *
    *
    *   @param: Boolean value decide whether the current batch should schedule or the next batch
    *
    */
    private void scheduleBatch(Boolean isCurrentBatch)
    {
        // try again in a minute
        Datetime sysTime = System.now().addSeconds( 60 );
        String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        if(isCurrentBatch)
        {
            BatchCampaignMemberToLFF scheduledBatch = new BatchCampaignMemberToLFF(nDaysAgo);
            System.schedule( 'CM Batch - Hourly ' + sysTime, chronExpression, scheduledBatch );
        }
        else
        {
            // @param: Integer equivalent to day.
            // schedule Next batch
            BatchMQLeadToLFF scheduledBatch = new BatchMQLeadToLFF(nDaysAgo);
            System.schedule( 'MQL Batch - Hourly ' + sysTime, chronExpression, scheduledBatch );
        }
    }

}