/* * * * * *
*
* Name:        BatchOpportunityToLFF (Batch class)
* Description: Query new Opportunity. Then is find Contact via Opportunity Contact Role
*              Find Contact which is primary or the oldest one.
               Does Contact have an Active LFF record?
                 if Yes, relate LFF to Opportunity
                 if No. Create LFF related to Opportunity.
* Created:     31-January-2016, 15:37 IST
* Change:      Added Status field in Campaign Member to filter records.
               All product matching logic, App LFF to UCI LFF only if their prodcuts match.
               22-Feb-2016, Ashwani @GoNimbly Jen
* Change II:   Updated this batch to only process Primary Opportunity Contact Roles.
               11-May-2016, Divesh Bafna @GoNimbly Michael NG
* Author:      Ashwani Soni
* Company:     GoNimbly, Ian
*
* * * */
public with sharing class BatchOpportunityToLFF implements Database.Batchable<sObject>, Schedulable
{
    private static DateTime sixMonthBefore = DateTime.now().addMonths(-6);
    public String query;

    Integer nDaysAgo = 1;
    Datetime daysAgo;

    // Parameterized constructor
    // @param: Integer value which is equivalent to days.
    // Ex: pass 1 to proccess records created whithin a day.
    public BatchOpportunityToLFF(Integer daysBackDated)
    {
        init(daysBackDated);
    }

    // default constructor
    public BatchOpportunityToLFF()
    {
        init(null);
    }

    // Constructor support
    private void init(Integer daysBackDated)
    {
        this.nDaysAgo = daysBackDated != null ? daysBackDated : 1;
        daysAgo = Datetime.now().addDays(nDaysAgo*(-1));
        query = 'SELECT id,LFF_Record__c, ( SELECT ContactId FROM OpportunityContactRoles WHERE isPrimary = TRUE Order By isPrimary, CreatedDate LIMIT 1)';
        query += ',(SELECT id,Closed_Won_Lost_Datetime__c,SAL_Rejected_Date__c,MQL_Rejected_Date__c,Inquiry_Date_Entered__c,Current_Funnel_Stage__c,lead__c,contact__c FROM Demand_Funnel_Reports__r) FROM Opportunity';
        query += ' WHERE CreatedDate >: daysAgo ';
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        Set<Id> contactIds = new Set<Id>();
        Map<id,Opportunity> oppMap = new Map<id,Opportunity>();
        Map<Id, Opportunity> oppToUpdate = new Map<Id, Opportunity>();

        for(Opportunity opp : (List<Opportunity>)scope)
        {
            if(opp.OpportunityContactRoles != null && opp.OpportunityContactRoles.size()>0)
            {
                contactIds.add(opp.OpportunityContactRoles[0].contactId);
            }
            oppMap.put(opp.id,opp);
        }

        // Linking
        List<Lifecycle_Field_Funnel__c> oppLFFsToUpsert = createContactLFFs(contactIds);
        upsert oppLFFsToUpsert;

        for(Lifecycle_Field_Funnel__c lff : oppLFFsToUpsert){
            if(oppMap.containsKey(lff.Opportunity__c))
            {
                oppMap.get(lff.Opportunity__c).LFF_Record__c = lff.Id;
                oppToUpdate.put(lff.Opportunity__c, oppMap.get(lff.Opportunity__c));
            }
        }

        if(!oppToUpdate.isEmpty()){
            update oppToUpdate.values();
        }
    }

    public void finish(Database.BatchableContext BC)
    {
        AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, ExtendedStatus,
                                  TotalJobItems
                           FROM AsyncApexJob WHERE Id = :BC.getJobId()];

        if(asyncJob.NumberOfErrors > 0 || System.Test.isRunningTest())
        {
            LffHelper.sendEmail(asyncJob, 'Opportunity Batch LFF ');
        }
        // No chaining required. This is the last batch of the chain
    }

    /*****
    *
    * Schedule Runner. Index 4
    *
    *****/
    public void execute(SchedulableContext sc)
    {
        // ==> 4
        // THIS batch
        Integer jobs = [Select count() From AsyncApexJob Where JobType = 'BatchApex' and ( Status = 'Queued' or Status = 'Processing' or Status = 'Preparing' )];
        if(jobs != null && jobs > 4 )
        {
            // try again in a minute
            Datetime sysTime = System.now().addSeconds( 60 );
            String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();

            BatchOpportunityToLFF scheduledBatch = new BatchOpportunityToLFF(nDaysAgo);
            System.schedule( 'Opportunity Batch LFF - Hourly ' + sysTime, chronExpression, scheduledBatch );
        }
        else
        {
            BatchOpportunityToLFF bat = new BatchOpportunityToLFF(nDaysAgo);
            database.executebatch(bat);
        }
    }

    private List<Lifecycle_Field_Funnel__c> createContactLFFs(Set<Id> contactIds)
    {
        List<Lifecycle_Field_Funnel__c> lffToUpsert = new List<Lifecycle_Field_Funnel__c>();
        for(Contact contactRecord : [SELECT id,Eloqua_Lead_Rating__c, AccountId,
                                        (SELECT id, OpportunityId, Opportunity.FY_16_Primary_Product__c
                                        FROM OpportunityContactRoles
                                        WHERE IsPrimary = TRUE
                                        ORDER BY isPrimary, CreatedDate),

                                        (SELECT id,name,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Lead__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,Opportunity__c,LFF_Active__c,LFF_Primary_Product__c,First_Touch_Campaign_Member_ID__c,Last_Touch_Campaign_Member_ID__c, First_Touch_Campaign__c, Last_Touch_Campaign__c, Use_Case_Interest__c, Use_Case_Interest__r.FY_16_Primary_Product__c, Current_Funnel_Stage__c, Inquiry_Date_Entered__c
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
            if(contactRecord.OpportunityContactRoles != null && contactRecord.OpportunityContactRoles.size()>0)
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

                Set<Id> allOppSet = new Set<id>();
                // Product Name, Set of Opportunity Id
                Map<String,Set<String>> opportunityProductsMap = new Map<String,Set<String>>();
                for(OpportunityContactRole oppcr : contactRecord.OpportunityContactRoles)
                {
                    allOppSet.add(oppcr.OpportunityId);
                    // Collect all product and their opportunity
                    if(oppcr.Opportunity.FY_16_Primary_Product__c!='')
                    {
                        if(opportunityProductsMap.containsKey(oppcr.Opportunity.FY_16_Primary_Product__c))
                        {
                            opportunityProductsMap.get(oppcr.Opportunity.FY_16_Primary_Product__c).add(oppcr.OpportunityId);
                        }
                        else
                        {
                            opportunityProductsMap.put(oppcr.Opportunity.FY_16_Primary_Product__c,new Set<String>{oppcr.OpportunityId});
                        }
                    }
                }

                // No LFF exist for the Lead of CampaignMember
                if(contactRecord.Demand_Funnel_Reports__r.size() == 0)
                {
                    for(OpportunityContactRole oppcr : contactRecord.OpportunityContactRoles)
                    {
                        // New LFF Record
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                        newLFF.Contact__c = contactRecord.id;
                        newLFF.Opportunity__c = oppcr.Opportunityid;
                        lffToUpsert.add(newLFF);
                    }
                }
                else
                {
                    Map<id,id> lffWithOpp = new Map<id,id>();
                    Map<String,List<String>> uciProductsMap = new Map<String,List<String>>();
                    for(Lifecycle_Field_Funnel__c lff : contactRecord.Demand_Funnel_Reports__r)
                    {
                        if(lff.Opportunity__c != null)
                        {
                            lffWithOpp.put(lff.id,lff.Opportunity__c);
                            allOppSet.remove(lff.Opportunity__c);
                        }
                    }

                    List<Id> allOpp = new List<Id>(allOppSet);
                    // Update LFF with Last Touch fields. Active LFF found for Leads of Campaign Member
                    for(Lifecycle_Field_Funnel__c lff : contactRecord.Demand_Funnel_Reports__r)
                    {
                        // update campaign member First Touch etc for active LFFs
                        if(lff.LFF_Active__c == true)
                        {
                            lff = createLFFRecord(lff,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                            //Active LFF don't have Opportunity and there are Opportunity which can be associated
                            if(!lffWithOpp.containsKey(lff.id) && allOpp.size()>0)
                            {
                                // Associate one Opportunity if UCI in NULL
                                if(lff.Use_Case_Interest__c == null)
                                {
                                    lff.Opportunity__c = allOpp.get(0);
                                    allOpp.remove(0);
                                }
                                else if(lff.Use_Case_Interest__r.FY_16_Primary_Product__c != null && opportunityProductsMap.containsKey(lff.Use_Case_Interest__r.FY_16_Primary_Product__c))
                                {
                                    //Check that UCI product is same as Opportunity Product (FY 16 Primery product field)
                                    Set<String> oppMatchingProduct = opportunityProductsMap.get(lff.Use_Case_Interest__r.FY_16_Primary_Product__c);
                                    if(oppMatchingProduct.contains(allOpp.get(0)))
                                    {
                                        lff.Opportunity__c = allOpp.get(0);
                                        // remove opp once it found its friend
                                        oppMatchingProduct.remove(allOpp.get(0));
                                        allOpp.remove(0);
                                    }
                                }
                            }
                            lffToUpsert.add(lff);
                        }
                    }

                    for(Id oppId : allOpp)
                    {
                        Lifecycle_Field_Funnel__c newLFF = createLFFRecord(null,latestCM,oldestCM, contactRecord.Eloqua_Lead_Rating__c);
                        newLFF.Contact__c = contactRecord.id;
                        newLFF.Opportunity__c = oppId;
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

        // SQL Interest Score should be updated when LFF is created for Opportunity
        newLFF.SQL_Interest_Score__c = rating;

        LffHelper.populateLFFRecord(newLFF, latestCM, oldestCM);

        return newLFF;
    }
}