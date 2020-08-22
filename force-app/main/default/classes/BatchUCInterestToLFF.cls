/****
*
* Name:        BatchUCInterestToLFF (Batch class)
* Description: Query Use Case Interest records with no Active related LFF records. Create LFF records.
* Created :    21-January-2016, 11:48
* Change:      Added Status field in Campaign Member to filter records. 22-Feb-2016, Ashwani @GoNimbly Jen
               Remove Status__c field check from code. 19-July-2016, Purushottam @GoNimbly Troy
* Author:      Ashwani Soni, Troy Conquer
* Company:     GoNimbly, Ian
*
* * * */
public with sharing class BatchUCInterestToLFF implements Database.Batchable<sObject>, Schedulable
{
    public String query;
    static DateTime sixMonthBefore = DateTime.now().addMonths(-6);
    Integer nDaysAgo = 1;
    Datetime daysAgo;

    // Set of eligible Lifecycle_Field_Funnel__c.Current_Funnel_Stage__c
    Set<String> funnelStages = new Set<String>{ System.Label.LFF_Current_Funnel_Stage_Inquiry,
                                                System.Label.LFF_Current_Funnel_Stage_MQL };

    // default constructor
    public BatchUCInterestToLFF()
    {
        init(null);
    }

    // Parameterized constructor
    // @param: Integer value which is equivalent to days.
    // Ex: pass 1 to proccess records created whithin a day.
    public BatchUCInterestToLFF(Integer daysBackDated)
    {
        init(daysBackDated);
    }

    // constructor support
    private void init(Integer daysBackDated)
    {
        this.nDaysAgo = daysBackDated != null ? daysBackDated : nDaysAgo;
        daysAgo = Datetime.now().addDays(nDaysAgo*(-1));

        query =  'SELECT id,Lead__r.Eloqua_Lead_Rating__c,Lead__c, Contact__c,Opportunity__c,Lead__r.IsConverted,(SELECT id,Closed_Won_Lost_Datetime__c,SAL_Rejected_Date__c,MQL_Rejected_Date__c,Inquiry_Date_Entered__c,Current_Funnel_Stage__c,lead__c,contact__c FROM Demand_Funnel_Reports__r) ';
        query += 'FROM Use_Case_Interest__c '+
                 'WHERE CreatedDate >: daysAgo ';
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        Set<Id> leadIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        for(Use_Case_Interest__c uci : (List<Use_Case_Interest__c>)scope)
        {
            if(uci.Contact__c != null)
            {
                contactIds.add(uci.Contact__c);
            }
            else if(uci.Lead__c != null && !uci.Lead__r.IsConverted)
            {
                leadIds.add(uci.Lead__c);
            }
        }

        List<Lifecycle_Field_Funnel__c> leadLFFsToUpsert = createLeadLFFs(leadIds);

        List<Lifecycle_Field_Funnel__c> contactLFFsToUpsert = createContactLFFs(contactIds);


        upsert leadLFFsToUpsert;
        upsert contactLFFsToUpsert;
    }

    public void finish(Database.BatchableContext BC)
    {
        // ==> 4
        processBatchChain(false);

        AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, ExtendedStatus,
                              TotalJobItems
                       FROM AsyncApexJob WHERE Id = :BC.getJobId()];

        if(asyncJob.NumberOfErrors > 0 || System.Test.isRunningTest())
        {
            LffHelper.sendEmail(asyncJob, 'Use Case Interest (UCI) Batch LFF ');
        }
    }

    /*****
    *
    * Schedule Runner. Index 3
    *
    *****/
    public void execute(SchedulableContext sc)
    {
        // ==> 3
        processBatchChain(true);
    }

    private List<Lifecycle_Field_Funnel__c> createLeadLFFs(Set<Id> leadIds)
    {
        List<Lifecycle_Field_Funnel__c> lffToUpsert = new List<Lifecycle_Field_Funnel__c>();

        for(Lead leadRecord : [SELECT id,Eloqua_Lead_Rating__c,
                                (SELECT id
                                 FROM Use_Case_Interests__r
                                 ORDER BY CreatedDate DESC),

                                (SELECT id,name,Lead__c,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,Current_Funnel_Stage__c,LFF_Active__c,First_Touch_Campaign_Member_ID__c,Last_Touch_Campaign_Member_ID__c, First_Touch_Campaign__c, Last_Touch_Campaign__c, Use_Case_Interest__c, Inquiry_Date_Entered__c
                                 FROM Demand_Funnel_Reports__r
                                 ORDER BY CreatedDate),

                                (SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c, CampaignId, LeadId, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, Status, CreatedDate
                                 FROM CampaignMembers
                                 WHERE Campaign.Is_Marketing_Campaign_Type__c = TRUE
                                 AND Status in:LffHelper.qualifiedStatuses
                                 AND CreatedDate >=:sixMonthBefore
                                 ORDER BY CreatedDate)
                              FROM Lead
                              WHERE Id in:leadIds])
        {
            if(leadRecord.Use_Case_Interests__r != null && leadRecord.Use_Case_Interests__r.size()>0)
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


                Set<Id> allUCISet = new Set<id>();
                Set<Id> uciProcessed = new Set<id>();
                for(Use_Case_Interest__c uci : leadRecord.Use_Case_Interests__r)
                {
                    allUCISet.add(uci.id);
                }

                // No LFF exist for the Lead of CampaignMember
                if(leadRecord.Demand_Funnel_Reports__r.size() == 0)
                {
                    for(Use_Case_Interest__c uci : leadRecord.Use_Case_Interests__r)
                    {
                        // New LFF Record
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, leadRecord.Eloqua_Lead_Rating__c);
                        newLFF.Lead__c = leadRecord.id;
                        newLFF.Use_Case_Interest__c = uci.id;
                        lffToUpsert.add(newLFF);
                    }
                }
                else
                {
                    Map<id,id> lffWithUCI = new Map<id,id>();
                    for(Lifecycle_Field_Funnel__c lff : leadRecord.Demand_Funnel_Reports__r)
                    {
                        if(lff.Use_Case_Interest__c != null)
                        {
                            lffWithUCI.put(lff.id,lff.Use_Case_Interest__c);
                            allUCISet.remove(lff.Use_Case_Interest__c);
                        }
                    }

                    List<Id> allUCI = new List<Id>(allUCISet);
                    // Update LFF with Last Touch fields. Active LFF found for Leads of Campaign Member
                    for(Lifecycle_Field_Funnel__c lff : leadRecord.Demand_Funnel_Reports__r)
                    {
                        // update campaign member First Touch etc for active LFFs
                        if(lff.LFF_Active__c == true)
                        {
                            lff = createLFFRecord(lff,latestCM,oldestCM, leadRecord.Eloqua_Lead_Rating__c);
                            //Active LFF don't have UCI and there are UCI which can be associated
                            // 4 -SQL cannot have new UCI association
                            if(!lffWithUCI.containsKey(lff.id) && allUCI.size()>0 && funnelStages.contains(lff.Current_Funnel_Stage__c) )
                            {
                                // Associate one UCI
                                lff.Use_Case_Interest__c = allUCI.get(0);
                                allUCI.remove(0);
                                uciProcessed.add(lff.Use_Case_Interest__c);
                            }
                            lffToUpsert.add(lff);
                        }
                    }

                    for(Id uciId : allUCI)
                    {
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, leadRecord.Eloqua_Lead_Rating__c);
                        newLFF.Lead__c = leadRecord.id;
                        newLFF.Use_Case_Interest__c = uciId;
                        lffToUpsert.add(newLFF);
                    }
                }
            }
        }

        return lffToUpsert;
    }

    private List<Lifecycle_Field_Funnel__c> createContactLFFs(Set<Id> contactIds)
    {
        List<Lifecycle_Field_Funnel__c> lffToUpsert = new List<Lifecycle_Field_Funnel__c>();

        for(Contact contactRecord : [SELECT id,Eloqua_Lead_Rating__c, AccountId,
                                (SELECT id
                                 FROM Use_Case_Interests__r
                                 ORDER BY CreatedDate DESC),

                                (SELECT id,name,Lead__c,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,Current_Funnel_Stage__c,LFF_Active__c,First_Touch_Campaign_Member_ID__c,Last_Touch_Campaign_Member_ID__c, First_Touch_Campaign__c, Last_Touch_Campaign__c, Use_Case_Interest__c
                                 FROM Demand_Funnel_Reports__r
                                 ORDER BY CreatedDate),

                                (SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c, CampaignId, LeadId, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c,Status, CreatedDate
                                 FROM CampaignMembers
                                 WHERE Campaign.Is_Marketing_Campaign_Type__c = TRUE
                                 AND Status in:LffHelper.qualifiedStatuses
                                 AND CreatedDate >=:sixMonthBefore
                                ORDER BY CreatedDate)
                              FROM Contact
                              WHERE Id in:contactIds])
        {
            if(contactRecord.Use_Case_Interests__r != null && contactRecord.Use_Case_Interests__r.size()>0)
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

                Set<Id> allUCISet = new Set<id>();
                Set<Id> uciProcessed = new Set<id>();
                for(Use_Case_Interest__c uci : contactRecord.Use_Case_Interests__r)
                {
                    allUCISet.add(uci.id);
                }

                // No LFF exist for the Lead of CampaignMember
                if(contactRecord.Demand_Funnel_Reports__r.size() == 0)
                {
                    for(Use_Case_Interest__c uci : contactRecord.Use_Case_Interests__r)
                    {
                        // New LFF Record
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                        newLFF.Contact__c = contactRecord.id;
                        newLFF.Account__c = contactRecord.AccountId;
                        newLFF.Use_Case_Interest__c = uci.id;
                        lffToUpsert.add(newLFF);
                    }
                }
                else
                {
                    Map<id,id> lffWithUCI = new Map<id,id>();
                    for(Lifecycle_Field_Funnel__c lff : contactRecord.Demand_Funnel_Reports__r)
                    {
                        if(lff.Use_Case_Interest__c != null)
                        {
                            lffWithUCI.put(lff.id,lff.Use_Case_Interest__c);
                            allUCISet.remove(lff.Use_Case_Interest__c);
                        }
                    }

                    List<Id> allUCI = new List<Id>(allUCISet);
                    // Update LFF with Last Touch fields. Active LFF found for Leads of Campaign Member
                    for(Lifecycle_Field_Funnel__c lff : contactRecord.Demand_Funnel_Reports__r)
                    {
                        // update campaign member First Touch etc for active LFFs
                        if(lff.LFF_Active__c == true)
                        {
                            lff = createLFFRecord(lff,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                            //Active LFF don't have UCI and there are UCI which can be associated.
                            // 4 -SQL cannot have new UCI association
                            if(!lffWithUCI.containsKey(lff.id) && allUCI.size()>0 && funnelStages.contains(lff.Current_Funnel_Stage__c) )
                            {
                                // Associate one UCI
                                lff.Use_Case_Interest__c = allUCI.get(0);
                                allUCI.remove(0);
                                uciProcessed.add(lff.Use_Case_Interest__c);
                            }
                            lffToUpsert.add(lff);
                        }

                    }


                    for(Id uciId : allUCI)
                    {
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                        newLFF.Contact__c = contactRecord.id;
                        newLFF.Account__c = contactRecord.AccountId;
                        newLFF.Use_Case_Interest__c = uciId;
                        lffToUpsert.add(newLFF);
                    }
                }
            }
        }
        return lffToUpsert;
    }

    /*
     * Create or Update Lifecycle Field Funnel records.
     * @param 1: Lifecycle_Field_Funnel__c
     * @param 2: Most recent Campaign Member record for the Lead/Contact
     * @param 3: Oldest Campaing Member record for the Lead/Contact
     * @param 4: Inquiry Interest Score. Either use Contact or Lead. Depending on batch type it update MQL/SAL Interest score also
     * @return : Updated LFF instance
    **/
    private Lifecycle_Field_Funnel__c createLFFRecord(Lifecycle_Field_Funnel__c lff, CampaignMember latestCM, CampaignMember oldestCM, String rating)
    {
        // Assign exsting LFF or create new instance of LFF
        Lifecycle_Field_Funnel__c newLFF = lff != null ? lff : (new Lifecycle_Field_Funnel__c ());

        // SAL Interest Score should be updated when LFF is created for UCI
        newLFF.SAL_Interest_Score__c = rating ;

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
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(nDaysAgo);
            database.executebatch(bat);
        }
        else
        {
            // @param: Integer equivalent to day.
            // Next batch
            BatchOpportunityToLFF bat = new BatchOpportunityToLFF(nDaysAgo);
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
            BatchUCInterestToLFF scheduledBatch = new BatchUCInterestToLFF(nDaysAgo);
            System.schedule( 'UCI Batch - Hourly LFF ' + sysTime, chronExpression, scheduledBatch );
        }
        else
        {
            // @param: Integer equivalent to day.
            // schedule Next batch
            BatchOpportunityToLFF scheduledBatch = new BatchOpportunityToLFF(nDaysAgo);
            System.schedule( 'Opportunity Batch LFF - Hourly ' + sysTime, chronExpression, scheduledBatch );
        }
    }

}