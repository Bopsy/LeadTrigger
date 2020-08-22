/* * * * * *
*
* Name:        BatchMQLeadToLFF (Batch class)
* Description: Query new MQL records with no "Active" related LFF records for their Lead/Contact.
*               - Create LFF records.
*               - Update Campaign First Touch and Last Touch which are within 6 months
*               - Update Lead/Contact's Interest Rating
*               - If LFF is new Update Lead/Contact's Interest Score
*              If there is existing MQL and LFF make sure LFF has most recent MQL and Last Touch Campaign fields.
*              Active LFF are those one which have Active == TRUE
* Created:     21-January-2016, 11:46
* Change:      Added Status field in Campaign Member to filter records. 22-Feb-2016, Ashwani @GoNimbly Jen
* Author:      Ashwani Soni
* Company:     GoNimbly, Ian
*
* * * */
public with sharing class BatchMQLeadToLFF implements Database.Batchable<sObject>, Schedulable
{
    public String query;
    Integer nDaysAgo = 1;
    Datetime daysAgo;

    // default constructor.
    public BatchMQLeadToLFF()
    {
        init(null);
    }

    // Parameterized constructor
    // @param: Integer value which is equivalent to days.
    // Ex: pass 1 to proccess records created whithin a day.
    public BatchMQLeadToLFF(Integer daysBackDated)
    {
       init(daysBackDated);
    }

    // Constructor support
    private void init(Integer daysBackDated)
    {
        this.nDaysAgo = daysBackDated != null ? daysBackDated : nDaysAgo;
        this.daysAgo = Datetime.now().addDays(this.nDaysAgo*(-1));
        // Note: MQL object has API name FSR__c
        query = 'SELECT id,Lead__c, Lead__r.IsConverted,MQL_Status__c, Contact__c, (SELECT id,Closed_Won_Lost_Datetime__c,SAL_Rejected_Date__c,MQL_Rejected_Date__c,Inquiry_Date_Entered__c,Current_Funnel_Stage__c,lead__c,contact__c FROM Lifecycle_Field_Funnels__r) FROM FSR__c '+
                ' WHERE CreatedDate >: daysAgo ';
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        Set<Id> leadIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for(FSR__c fsr : (List<FSR__c>)scope)
        {
            if(fsr.Contact__c != null)
            {
                contactIds.add(fsr.Contact__c);
            }
            else if(fsr.Lead__c != null && !fsr.Lead__r.IsConverted)
            {
                leadIds.add(fsr.Lead__c);
            }
        }

        DateTime sixMonthBefore = DateTime.now().addMonths(-6);

        List<Lifecycle_Field_Funnel__c> lffToUpsertLead = new List<Lifecycle_Field_Funnel__c>();
        for(Lead leadRecord : [SELECT id,name, Eloqua_Lead_Rating__c,
                                (SELECT id, Contact__c, Lead__c
                                FROM FSRs__r
                                ORDER BY CreatedDate DESC),

                                (SELECT id,name,Lead__c,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,LFF_Active__c,First_Touch_Campaign_Member_ID__c,Last_Touch_Campaign_Member_ID__c, First_Touch_Campaign__c, Last_Touch_Campaign__c, MQL__c, Current_Funnel_Stage__c, Inquiry_Date_Entered__c
                                FROM Demand_Funnel_Reports__r
                                ORDER BY CreatedDate),

                                (SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c, CampaignId, LeadId, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c,Status, CreatedDate
                                FROM CampaignMembers
                                WHERE Campaign.Is_Marketing_Campaign_Type__c = TRUE
                                AND Status in:LffHelper.qualifiedStatuses
                                AND CreatedDate >=:sixMonthBefore
                                ORDER BY CreatedDate)
                              FROM Lead
                              WHERE Id in:leadIds])
        {
            if(leadRecord.FSRs__r != null && leadRecord.FSRs__r.size()>0)
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

                Set<Id> allMqlSet = new Set<id>();
                Set<Id> mqlProcessed = new Set<id>();
                for(FSR__c mql : leadRecord.FSRs__r)
                {
                    allMqlSet.add(mql.id);
                }

                // No LFF exist for the Lead of CampaignMember
                if(leadRecord.Demand_Funnel_Reports__r.size() == 0)
                {
                    for(FSR__c mql : leadRecord.FSRs__r)
                    {
                        // New LFF Record
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, leadRecord.Eloqua_Lead_Rating__c);
                        newLFF.Lead__c = leadRecord.id;
                        newLFF.MQL__c = mql.id;
                        lffToUpsertLead.add(newLFF);
                    }
                }
                else
                {
                    Map<id,id> lffWithMQL = new Map<id,id>();
                    for(Lifecycle_Field_Funnel__c lff : leadRecord.Demand_Funnel_Reports__r)
                    {
                        if(lff.MQL__c != null)
                        {
                            lffWithMQL.put(lff.id,lff.MQL__c);
                            allMqlSet.remove(lff.MQL__c);
                        }
                    }

                    List<Id> allMQL = new List<Id>(allMQLSet);
                    // Update LFF with Last Touch fields. Active LFF found for Leads of Campaign Member
                    for(Lifecycle_Field_Funnel__c lff : leadRecord.Demand_Funnel_Reports__r)
                    {
                        // update campaign member First Touch etc for active LFFs
                        if(lff.LFF_Active__c == true)
                        {
                            lff = createLFFRecord(lff,latestCM,oldestCM, leadRecord.Eloqua_Lead_Rating__c);

                            //Active LFF don't have MQL and there are MQL which can be associated
                            if(!lffWithMQL.containsKey(lff.id) && allMql.size()>0 && lff.Current_Funnel_Stage__c == System.Label.LFF_Current_Funnel_Stage_Inquiry)
                            {
                                // Associate one MQL
                                lff.MQL__c = allMql[0];
                                allMql.remove(0);
                                mqlProcessed.add(lff.MQL__c);
                            }
                            lffToUpsertLead.add(lff);
                        }

                    }


                    for(Id mqlId : allMQL)
                    {
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, leadRecord.Eloqua_Lead_Rating__c);
                        newLFF.Lead__c = leadRecord.id;
                        newLFF.MQL__c = mqlId;
                        lffToUpsertLead.add(newLFF);
                    }
                }
            }

        }

        List<Lifecycle_Field_Funnel__c> lffToUpsertContact = new List<Lifecycle_Field_Funnel__c>();
        for(Contact contactRecord : [SELECT id,name, Eloqua_Lead_Rating__c, AccountId,
                                     (SELECT id, Contact__c, Lead__c FROM FSRs__r ORDER BY CreatedDate DESC),
                                     (SELECT id,name,Lead__c,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,LFF_Active__c, First_Touch_Campaign_Member_ID__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c, Last_Touch_Campaign__c, MQL__c,Current_Funnel_Stage__c, Inquiry_Date_Entered__c from Demand_Funnel_Reports__r ORDER BY CreatedDate),
                                     (SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,CampaignId, ContactId,UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, Status, CreatedDate from CampaignMembers WHERE Campaign.Is_Marketing_Campaign_Type__c = TRUE AND Status in:LffHelper.qualifiedStatuses AND CreatedDate >=:sixMonthBefore ORDER BY CreatedDate)
                                    FROM Contact
                                    WHERE Id in:contactIds])
        {
            if(contactRecord.FSRs__r != null && contactRecord.FSRs__r.size()>0)
            {

                CampaignMember latestCM = null;
                CampaignMember oldestCM = null;

                // Additional Campaign Memeber exist. Find Recent and Old CampaignMember
                if(contactRecord.CampaignMembers.size() > 1)
                {
                    oldestCM = contactRecord.CampaignMembers[0];
                    latestCM = contactRecord.CampaignMembers[contactRecord.CampaignMembers.size() - 1];
                }
                else if(contactRecord.CampaignMembers.size() == 1) // One Campaign Member exist for Lead
                {
                    oldestCM = contactRecord.CampaignMembers[0];
                    latestCM = contactRecord.CampaignMembers[0];
                }

                Set<Id> allMqlSet = new Set<id>();
                Set<Id> mqlProcessed = new Set<id>();
                for(FSR__c mql : contactRecord.FSRs__r)
                {
                    allMqlSet.add(mql.id);
                }

                // No LFF exist for the Lead of CampaignMember
                if(contactRecord.Demand_Funnel_Reports__r.size() == 0)
                {
                    for(FSR__c mql : contactRecord.FSRs__r)
                    {
                        // New LFF Record
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                        newLFF.Contact__c = contactRecord.id;
                        newLFF.MQL__c = mql.id;
                        lffToUpsertContact.add(newLFF);
                    }
                }
                else
                {
                    Map<id,id> lffWithMQL = new Map<id,id>();
                    for(Lifecycle_Field_Funnel__c lff : contactRecord.Demand_Funnel_Reports__r)
                    {
                        if(lff.MQL__c != null)
                        {
                            lffWithMQL.put(lff.id,lff.MQL__c);
                            allMqlSet.remove(lff.MQL__c);
                        }
                    }

                    List<Id> allMQL = new List<Id>(allMQLSet);

                    // Set of eligible Lifecycle_Field_Funnel__c.Current_Funnel_Stage__c
                    Set<String> funnelStages = new Set<String>{ System.Label.LFF_Current_Funnel_Stage_Inquiry };

                    // Update LFF with Last Touch fields. Active LFF found for Leads of Campaign Member
                    for(Lifecycle_Field_Funnel__c lff : contactRecord.Demand_Funnel_Reports__r)
                    {
                        // update campaign member First Touch etc for active LFFs
                        if(lff.LFF_Active__c == true)
                        {
                            lff = createLFFRecord(lff,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                            //Active LFF don't have MQL and there are MQL with State 1-Inquiry which can be associated
                            if(!lffWithMQL.containsKey(lff.id) && allMql.size()>0 && funnelStages.contains(lff.Current_Funnel_Stage__c) )
                            {
                                // Associate one MQL
                                lff.MQL__c = allMql[0];
                                allMql.remove(0);
                                mqlProcessed.add(lff.MQL__c);
                            }
                            lffToUpsertContact.add(lff);
                        }

                    }


                    for(Id mqlId : allMQL)
                    {
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                        newLFF.Contact__c = contactRecord.id;
                        newLFF.MQL__c = mqlId;
                        lffToUpsertContact.add(newLFF);
                    }
                }
            }
        }

        upsert lffToUpsertContact;
        upsert lffToUpsertLead;

    }

    public void finish(Database.BatchableContext BC)
    {
        // ==> 3
        processBatchChain(false);

        AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, ExtendedStatus,
                              TotalJobItems
                       FROM AsyncApexJob WHERE Id = :BC.getJobId()];

        if(asyncJob.NumberOfErrors > 0 || System.Test.isRunningTest())
        {
            LffHelper.sendEmail(asyncJob, 'Marketing Qualified Lead (MQL) Batch LFF ');
        }
    }

    /*****
    *
    * Schedule Runner. Index 2
    *
    *****/
    public void execute(SchedulableContext sc)
    {
        // ==> 2
        processBatchChain(true);
    }

    /*
     * Create or Update Lifecycle Field Funnel records.
     * @param 1: Lifecycle_Field_Funnel__c
     * @param 2: Most recent Campaign Member record for the Lead/Contact
     * @param 3: Oldest Campaing Member record for the Lead/Contact
     * @param 4: Inquiry Interest Score. Either use Contact or Lead
     * @return : Updated LFF instance
    **/
    private Lifecycle_Field_Funnel__c createLFFRecord(Lifecycle_Field_Funnel__c lff, CampaignMember latestCM, CampaignMember oldestCM, String rating)
    {
        // Assign exsting LFF or create new instance of LFF
        Lifecycle_Field_Funnel__c newLFF = lff != null ? lff : (new Lifecycle_Field_Funnel__c ());

        // MQL Interest Score should be updated when LFF is created for MQL
        newLFF.MQL_Interest_Score__c = rating;

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
        if(jobs != null &&  jobs > 4 )
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
            BatchMQLeadToLFF bat = new BatchMQLeadToLFF(nDaysAgo);
            database.executebatch(bat);
        }
        else
        {
            // @param: Integer equivalent to day.
            // Next batch
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(nDaysAgo);
            database.executebatch(bat);
        }
    }

    /* * *
    *
    *   @param: Boolean value decide whether the current batch should Schedule or the next batch
    *
    */
    private void scheduleBatch(Boolean isCurrentBatch)
    {
        // try again in a minute
        Datetime sysTime = System.now().addSeconds( 60 );
        String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        if(isCurrentBatch)
        {
            BatchMQLeadToLFF scheduledBatch = new BatchMQLeadToLFF(nDaysAgo);
            System.schedule( 'MQL Batch - Hourly ' + sysTime, chronExpression, scheduledBatch );
        }
        else
        {
            // @param: Integer equivalent to day.
            // Next batch
            BatchUCInterestToLFF scheduledBatch = new BatchUCInterestToLFF(nDaysAgo);
            System.schedule( 'UCI Batch - Hourly ' + sysTime, chronExpression, scheduledBatch );
        }
    }

}