/** * * * * * * * * * * * *
*  Class Name:   BatchLFFProcessing
*  Purpose:      Test class to LFF Processing Batch
*  Author:       Vivek Somani
*  Company:      Go Nimbly
*  Created Date: 1-Mar-2017
*  Type:         Test Class
** * * * * * * * * * * * */
@isTest
private class BatchLFFProcessingTest {

  private static List<Account> accountList = new List<Account>();
  private static List<Contact> contactList = new List<Contact>();
  private static List<Lifecycle_Field_Funnel__c> lifecycleFieldFunnelList = new List<Lifecycle_Field_Funnel__c>();
  private static List<FSR__c> mqlList = new List<FSR__c>();
  private static List<Opportunity> opportunityList = new List<Opportunity>();

  /* * * * * * * * * * * * *
  *  Method Name:  setup
  *  Purpose:      This method is used to create the test data.
  *  Author:       Vivek Somani
  *  Company:      Go Nimbly
  *  Created Date: 01-Mar-2017
  * * * * * * * * * * * * */
  static void setup(Integer counter)
  {
    // Create sample data for Account
    accountList = TestDataFactory.createAccountList(counter);

    // Create sample data for Contact
    contactList = TestDataFactory.createContactList(counter);

    // Create sample data for Opportunity
    opportunityList = TestDataFactory.createOpportunityList(counter);
    for(Opportunity opportunity : opportunityList)
    {
      opportunity.StageName = 'Pre SQL';
    }
    insert opportunityList;

    //create sample data for LFF
    lifecycleFieldFunnelList = TestDataFactory.createlFFList(counter);
  }

  /* * * * * * * * * * * * *
  *  Method Name:  assignLookupsAndInsert
  *  Purpose:      Inserts accounts as they are; Adds accounts and signup date to contacts and inserts;
  *                Adds accounts and contacts to LFF's and inserts
  *  Author:       Mitch Conquer
  *  Company:      Go Nimbly
  *  Created Date: 30-Jun-2017
  * * * * * * * * * * * * */
  static void assignLookupsAndInsert()
  {
    insert accountList;

    Integer j = 0;
    for(Contact contact : contactList)
    {
      contact.AccountId = accountList[j].Id;
      j++;
    }
    insert contactList;

    Integer k = 0;
    for(Lifecycle_Field_Funnel__c lifecycleFieldFunnel : lifecycleFieldFunnelList)
    {
      lifecycleFieldFunnel.Account__c = accountList[k].Id;
      lifecycleFieldFunnel.Contact__c = contactList[k].Id;
      lifecycleFieldFunnel.Inquiry_Date_Entered__c = System.now();
      lifecycleFieldFunnel.Last_Touch_SQL_Campaign_Type__c = 'Test';
      k++;
    }
    insert lifecycleFieldFunnelList;
  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchLFFProcessing_inbound_self1
  *  Purpose:      This method is used to call the BatchLFFProcessing to test a condition
  *                for 'INBOUND SELF-SERVE' using the NPC5 date
  *  Author:       Mitch Conquer
  *  Company:      Go Nimbly
  *  Created Date: 30-Jun-2017
  * * * * * * * * * * * * */
  @isTest static void batchLFFProcessing_inbound_self1() {
    Integer counter = 20;

    // create test data for batch
    setup(counter);

    // updating test data for satisfying test confition
    Date oneMonthAgo = System.now().addMonths(-1).Date();
    Date today = System.now().Date();
    for(Account account : accountList)
    {
      account.First_NPC_5_Date__c = oneMonthAgo;
    }
    for(Lifecycle_Field_Funnel__c lff : lifecycleFieldFunnelList)
    {
      lff.First_Touch_Associated_Date__c = today;
    }

    assignLookupsAndInsert();

    Test.startTest();

      BatchLFFProcessing testBatch = new BatchLFFProcessing();
      database.executebatch(testBatch);

    Test.stopTest();

    // assert checking if LFF_Source_Text__c is updated for all LFF records
    List<Lifecycle_Field_Funnel__c>  lffUpdatedList = [SELECT Id, LFF_Source_Text__c FROM Lifecycle_Field_Funnel__c WHERE LFF_Source_Text__c != NULL];
    System.assertEquals(counter, lffUpdatedList.size());

    // assert checking if correct LFF Source Text is populated in LFF records
    for(Integer i = 0 ;i < lffUpdatedList.size() ; i++)
    {
      System.assertEquals('INBOUND SELF-SERVE', lffUpdatedList[i].LFF_Source_Text__c, 'LFF source should be populated with "INBOUND SELF-SERVE" in LFF Source Text field if NPC5 Date is the earliest');
    }
  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchLFFProcessing_inbound_self2
  *  Purpose:      This method is used to call the BatchLFFProcessing to test a condition
  *                for 'INBOUND SELF-SERVE' using the signup date
  *  Author:       Mitch Conquer
  *  Company:      Go Nimbly
  *  Created Date: 30-Jun-2017
  * * * * * * * * * * * * */
  @isTest static void batchLFFProcessing_inbound_self2() {
    Integer counter = 20;

    // create test data for batch
    setup(counter);

    // updating test data for satisfying test confition
    Date oneMonthAgo = System.now().addMonths(-1).Date();
    Date today = System.now().Date();
    for(Contact contact : contactList)
    {
      contact.Sign_Up_Date__c = oneMonthAgo;
    }
    for(Lifecycle_Field_Funnel__c lff : lifecycleFieldFunnelList)
    {
      lff.First_Touch_Associated_Date__c = today;
    }

    assignLookupsAndInsert();

    Test.startTest();

      BatchLFFProcessing testBatch = new BatchLFFProcessing();
      database.executebatch(testBatch);

    Test.stopTest();

    // assert checking if LFF_Source_Text__c is updated for all LFF records
    List<Lifecycle_Field_Funnel__c>  lffUpdatedList = [SELECT Id, LFF_Source_Text__c FROM Lifecycle_Field_Funnel__c WHERE LFF_Source_Text__c != NULL];
    System.assertEquals(counter, lffUpdatedList.size());

    // assert checking if correct LFF Source Text is populated in LFF records
    for(Integer i = 0 ;i < lffUpdatedList.size() ; i++)
    {
      System.assertEquals('INBOUND SELF-SERVE', lffUpdatedList[i].LFF_Source_Text__c, 'LFF source should be populated with "INBOUND SELF-SERVE" in LFF Source Text field if SIGNUP Date is the earliest');
    }
  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchLFFProcessing_inbound_field1
  *  Purpose:      This method is used to call the BatchLFFProcessing to test a condition
  *                for 'INBOUND FIELD' using the first touch date
  *  Author:       Mitch Conquer
  *  Company:      Go Nimbly
  *  Created Date: 30-Jun-2017
  * * * * * * * * * * * * */
  @isTest static void batchLFFProcessing_inbound_field1() {
    Integer counter = 20;

    // create test data for batch
    setup(counter);

    // updating test data for satisfying test confition
    Date oneMonthAgo = System.now().addMonths(-1).Date();
    Date today = System.now().Date();
    for(Lifecycle_Field_Funnel__c lff : lifecycleFieldFunnelList)
    {
      lff.First_Touch_Associated_Date__c = oneMonthAgo;
    }
    for(Contact contact : contactList)
    {
      contact.Sign_Up_Date__c = today;
    }

    assignLookupsAndInsert();

    Test.startTest();

      BatchLFFProcessing testBatch = new BatchLFFProcessing();
      database.executebatch(testBatch);

    Test.stopTest();

    // assert checking if LFF_Source_Text__c is updated for all LFF records
    List<Lifecycle_Field_Funnel__c>  lffUpdatedList = [SELECT Id, LFF_Source_Text__c FROM Lifecycle_Field_Funnel__c WHERE LFF_Source_Text__c != NULL];
    System.assertEquals(counter, lffUpdatedList.size());

    // assert checking if correct LFF Source Text is populated in LFF records
    for(Integer i = 0 ;i < lffUpdatedList.size() ; i++)
    {
      System.assertEquals('INBOUND FIELD', lffUpdatedList[i].LFF_Source_Text__c, 'LFF source should be populated with "INBOUND FIELD" in LFF Source Text field if FIRST_TOUCH Date is the earliest');
    }
  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchLFFProcessing_inbound_field2
  *  Purpose:      This method is used to call the BatchLFFProcessing to test a condition
  *                for 'INBOUND FIELD' using the MQL date
  *  Author:       Mitch Conquer
  *  Company:      Go Nimbly
  *  Created Date: 30-Jun-2017
  * * * * * * * * * * * * */
  @isTest static void batchLFFProcessing_inbound_field2() {
    Integer counter = 20;

    // create test data for batch
    setup(counter);

    // updating test data for satisfying test confition
    Date oneMonthAgo = System.now().addMonths(-1).Date();
    Date today = System.now().Date();
    for(Contact contact : contactList)
    {
      contact.Sign_Up_Date__c = today;
    }

    mqlList = TestDataFactory.createFSRList(counter);
    insert mqlList;
    for(FSR__c mql : mqlList)
    {
      Test.setCreatedDate(mql.id, oneMonthAgo);
    }
    update mqlList;

    Integer k = 0;
    for(Lifecycle_Field_Funnel__c lifecycleFieldFunnel : lifecycleFieldFunnelList)
    {
      lifecycleFieldFunnel.MQL__c = mqlList[k].Id;
      k++;
    }

    assignLookupsAndInsert();

    Test.startTest();

      BatchLFFProcessing testBatch = new BatchLFFProcessing();
      database.executebatch(testBatch);

    Test.stopTest();

    // assert checking if LFF_Source_Text__c is updated for all LFF records
    List<Lifecycle_Field_Funnel__c>  lffUpdatedList = [SELECT Id, LFF_Source_Text__c FROM Lifecycle_Field_Funnel__c WHERE LFF_Source_Text__c != NULL];
    System.assertEquals(counter, lffUpdatedList.size());

    // assert checking if correct LFF Source Text is populated in LFF records
    for(Integer i = 0 ;i < lffUpdatedList.size() ; i++)
    {
      System.assertEquals('INBOUND FIELD', lffUpdatedList[i].LFF_Source_Text__c, 'LFF source should be populated with "INBOUND FIELD" in LFF Source Text field if MQL Date is the earliest');
    }
  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchLFFProcessing_outbound_sal1
  *  Purpose:      This method is used to call the BatchLFFProcessing to test a condition
  *                for 'OUTBOUND SALES' using the SAL date
  *  Author:       Mitch Conquer
  *  Company:      Go Nimbly
  *  Created Date: 30-Jun-2017
  * * * * * * * * * * * * */
  @isTest static void batchLFFProcessing_outbound_sal1() {
    Integer counter = 20;

    // Create test data for batch
    setup(counter);

    // Update test data
    Date oneMonthAgo = System.now().addMonths(-1).Date();
    Date today = System.now().Date();

    for(Contact contact : contactList)
    {
      contact.Sign_Up_Date__c = today;
    }

    mqlList = TestDataFactory.createFSRList(counter);
    insert mqlList;
    for(FSR__c mql : mqlList)
    {
      Test.setCreatedDate(mql.id, today);
    }
    update mqlList;

    for(Opportunity opp : opportunityList)
    {
      Test.setCreatedDate(opp.id, oneMonthAgo);
    }
    update opportunityList;

    Integer k = 0;
    for(Lifecycle_Field_Funnel__c lff : lifecycleFieldFunnelList)
    {
      lff.MQL__c = mqlList[k].Id;
      lff.Opportunity__c = opportunityList[k].Id;
      k++;
    }

    assignLookupsAndInsert();

    Test.startTest();

      BatchLFFProcessing testBatch = new BatchLFFProcessing();
      database.executebatch(testBatch);

    Test.stopTest();

    // assert checking if LFF_Source_Text__c is updated for all LFF records
    List<Lifecycle_Field_Funnel__c>  lffUpdatedList = [SELECT Id, LFF_Source_Text__c FROM Lifecycle_Field_Funnel__c WHERE LFF_Source_Text__c != NULL];
    System.assertEquals(counter, lffUpdatedList.size());

    // assert checking if correct LFF Source Text is populated in LFF records
    for(Integer i = 0 ;i < lffUpdatedList.size() ; i++)
    {
      System.assertEquals('OUTBOUND SALES', lffUpdatedList[i].LFF_Source_Text__c, 'LFF source should be populated with "OUTBOUND SALES" in LFF Source Text field if SAL Date is the earliest and the opportunity and LFF Qualified_Role__c is not "BDR" or "SDR"');
    }
  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchLFFProcessing_outbound_sal2
  *  Purpose:      This method is used to call the BatchLFFProcessing to test a condition
  *                for 'OUTBOUND XDR' using the SAL date
  *  Author:       Mitch Conquer
  *  Company:      Go Nimbly
  *  Created Date: 30-Jun-2017
  * * * * * * * * * * * * */
  @isTest static void batchLFFProcessing_outbound_sal2() {
    Integer counter = 20;

    // Create test data for batch
    setup(counter);

    // Update test data
    Date oneMonthAgo = System.now().addMonths(-1).Date();
    Date today = System.now().Date();

    for(Contact contact : contactList)
    {
      contact.Sign_Up_Date__c = today;
    }

    Integer k = 0;
    for(Lifecycle_Field_Funnel__c lff : lifecycleFieldFunnelList)
    {
      Test.setCreatedDate(opportunityList[k].id, oneMonthAgo);
      // Update approximately half of the roles as 'BDR' and half as 'SDR'
      opportunityList[k].Qualified_Role__c = k / counter < 0.5 ? 'BDR Test' : 'SDR Test';
      lff.Opportunity__c = opportunityList[k].Id;
      k++;
    }
    update opportunityList;

    assignLookupsAndInsert();

    Test.startTest();

      BatchLFFProcessing testBatch = new BatchLFFProcessing();
      database.executebatch(testBatch);

    Test.stopTest();

    // assert checking if LFF_Source_Text__c is updated for all LFF records
    List<Lifecycle_Field_Funnel__c>  lffUpdatedList = [SELECT Id, LFF_Source_Text__c FROM Lifecycle_Field_Funnel__c WHERE LFF_Source_Text__c != NULL];
    System.assertEquals(counter, lffUpdatedList.size());

    // assert checking if correct LFF Source Text is populated in LFF records
    for(Integer i = 0 ;i < lffUpdatedList.size() ; i++)
    {
      System.assertEquals('OUTBOUND XDR', lffUpdatedList[i].LFF_Source_Text__c, 'LFF source should be populated with "OUTBOUND XDR" in LFF Source Text field if SAL Date is the earliest and the opportunity and LFF Qualified_Role__c is "BDR" or "SDR"');
    }
  }


  /* * * * * * * * * * * * *
  *  Method Name:  batchLFFProcessing_outbound_sql1
  *  Purpose:      This method is used to call the BatchLFFProcessing to test a condition
  *                for 'OUTBOUND SALES' using the SQL date
  *  Author:       Mitch Conquer
  *  Company:      Go Nimbly
  *  Created Date: 30-Jun-2017
  * * * * * * * * * * * * */
  @isTest static void batchLFFProcessing_outbound_sql1() {
    Integer counter = 20;

    // Create test data for batch
    setup(counter);

    // Update test data
    Date oneMonthAgo = System.now().addMonths(-1).Date();
    Date today = System.now().Date();

    for(Contact contact : contactList)
    {
      contact.Sign_Up_Date__c = today;
    }

    mqlList = TestDataFactory.createFSRList(counter);
    insert mqlList;
    for(FSR__c mql : mqlList)
    {
      Test.setCreatedDate(mql.id, today);
    }
    update mqlList;

    for(Opportunity opp : opportunityList)
    {
      opp.SQL_Date_Entered__c = oneMonthAgo;
    }
    update opportunityList;

    Integer k = 0;
    for(Lifecycle_Field_Funnel__c lff : lifecycleFieldFunnelList)
    {
      lff.MQL__c = mqlList[k].Id;
      lff.Opportunity__c = opportunityList[k].Id;
      k++;
    }

    assignLookupsAndInsert();

    Test.startTest();

      BatchLFFProcessing testBatch = new BatchLFFProcessing();
      database.executebatch(testBatch);

    Test.stopTest();

    // assert checking if LFF_Source_Text__c is updated for all LFF records
    List<Lifecycle_Field_Funnel__c>  lffUpdatedList = [SELECT Id, LFF_Source_Text__c FROM Lifecycle_Field_Funnel__c WHERE LFF_Source_Text__c != NULL];
    System.assertEquals(counter, lffUpdatedList.size());

    // assert checking if correct LFF Source Text is populated in LFF records
    for(Integer i = 0 ;i < lffUpdatedList.size() ; i++)
    {
      System.assertEquals('OUTBOUND SALES', lffUpdatedList[i].LFF_Source_Text__c, 'LFF source should be populated with "OUTBOUND SALES" in LFF Source Text field if SQL Date is the earliest and the opportunity and LFF Qualified_Role__c is not "BDR" or "SDR"');
    }
  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchLFFProcessing_outbound_sql2
  *  Purpose:      This method is used to call the BatchLFFProcessing to test a condition
  *                for 'OUTBOUND XDR' using the SQL date
  *  Author:       Mitch Conquer
  *  Company:      Go Nimbly
  *  Created Date: 30-Jun-2017
  * * * * * * * * * * * * */
  @isTest static void batchLFFProcessing_outbound_sql2() {
    Integer counter = 20;

    // Create test data for batch
    setup(counter);

    // Update test data
    Date oneMonthAgo = System.now().addMonths(-1).Date();
    Date today = System.now().Date();

    for(Contact contact : contactList)
    {
      contact.Sign_Up_Date__c = today;
    }

    Integer k = 0;
    for(Lifecycle_Field_Funnel__c lff : lifecycleFieldFunnelList)
    {

      opportunityList[k].SQL_Date_Entered__c = oneMonthAgo;
      // Update approximately half of the roles as 'BDR' and half as 'SDR'
      opportunityList[k].Qualified_Role__c = k / counter < 0.5 ? 'BDR Test' : 'SDR Test';
      lff.Opportunity__c = opportunityList[k].Id;
      k++;
    }
    update opportunityList;

    assignLookupsAndInsert();

    Test.startTest();

      BatchLFFProcessing testBatch = new BatchLFFProcessing();
      database.executebatch(testBatch);

    Test.stopTest();

    // assert checking if LFF_Source_Text__c is updated for all LFF records
    List<Lifecycle_Field_Funnel__c>  lffUpdatedList = [SELECT Id, LFF_Source_Text__c FROM Lifecycle_Field_Funnel__c WHERE LFF_Source_Text__c != NULL];
    System.assertEquals(counter, lffUpdatedList.size());

    // assert checking if correct LFF Source Text is populated in LFF records
    for(Integer i = 0 ;i < lffUpdatedList.size() ; i++)
    {
      System.assertEquals('OUTBOUND XDR', lffUpdatedList[i].LFF_Source_Text__c, 'LFF source should be populated with "OUTBOUND XDR" in LFF Source Text field if SQL Date is the earliest and the opportunity and LFF Qualified_Role__c is "BDR" or "SDR"');
    }
  }


  /* * * * * * * * * * * * *
  *  Method Name:  batchLFFProcessing_schedule
  *  Purpose:      This method is used to start the execution of BatchLFFProcessing batch class through scheduling
  *  Author:       Vivek Somani
  *  Company:      Go Nimbly
  *  Created Date: 01-Mar-2017
  * * * * * * * * * * * * */
  static testMethod void batchLFFProcessing_schedule()
  {
    Integer counter = 20;
    String jobId;
    String CRON_EXP = '0 0 * * * ?';

    // create test data for batch
    setup(counter);

    Test.startTest();
     jobId = System.schedule('BatchLFFProcessing - Hourly Test', CRON_EXP, new BatchLFFProcessing());
    Test.stopTest();

    // Get the information from the CronTrigger API object
    CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

    // Verify the expressions are the same
    System.assertEquals(CRON_EXP, cronTrigger.CronExpression);
  }
}