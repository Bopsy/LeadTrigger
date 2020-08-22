@isTest
private class BatchLinkTwilioUsageToForecast_Test{

    static final Date TARGET_DATE = Date.today();

    public static List<Twilio_Usage__c> TwList = new List<Twilio_Usage__c>();
    public static List<account> accList = new List<account>();
    public static List<opportunity> oppList = new List<opportunity>();
    public static integer numOfRec = 15;
    public static boolean isExceptionAccount = false;
    public static boolean isBothBlank = false;

    static void createData(){
       accList = TestDataFactory.createAccountList(numOfRec);
       insert accList;

       oppList = new List<Opportunity>();
       for( Account anAccount : accList )
       {
          Opportunity newOpportunity = TestDataFactory.createOpportunityList(1)[0];
          newOpportunity.AccountId = anAccount.Id;

          if(!isBothBlank){
              if(isExceptionAccount){
                newOpportunity.Exception_Account_SID__c = 'TestSID' + anAccount.Id;
                newOpportunity.Exception_Account_SID_Reason__c = 'test exception account';
              }else{
                newOpportunity.New_Business_Account_SID__c = 'TestSID' + anAccount.Id;
              }
          }else{
              newOpportunity.Exception_Account_SID__c = null;
              newOpportunity.New_Business_Account_SID__c = null;
          }
          newOpportunity.StageName = 'Closed Won';
          newOpportunity.Sales_Operations_Exception_Approval__c = 'Approved';
          newOpportunity.Compensation_Status__c = 'Standard Payout';
          oppList.add( newOpportunity );
       }
       insert oppList;

       List<Twilio_Usage__c> testUsages = new List<Twilio_Usage__c>();
       for( Opportunity anOpportunity : oppList )
       {
          Twilio_Usage__c newUsage = TestDataFactory.createTwilioUsages(1)[0];
          if(!isBothBlank){
              if(isExceptionAccount){
                newUsage.AccountSid__c = anOpportunity.Exception_Account_SID__c;
              }else{
                newUsage.AccountSid__c = anOpportunity.New_Business_Account_SID__c;
              }
          }
          else{
              newUsage.AccountSid__c = 'test';
          }

          newUsage.Month__c = TARGET_DATE.month();
          newUsage.Year__c = TARGET_DATE.year();
          newUsage.CounterKey__c = '' + anOpportunity.Id + anOpportunity.AccountId;
          testUsages.add( newUsage );
       }
       insert testUsages;

       Product2 testProduct = new Product2();
       testProduct.Name = 'Forecast Lock' ;
       insert testProduct;

       PricebookEntry testPB = new PricebookEntry();
       testPB.Product2Id = testProduct.Id;
       testPB.IsActive = TRUE;
       testPB.UnitPrice = 1.0;
       testPB.Pricebook2Id = Test.getStandardPricebookId();
       insert testPB;
    }

    static testMethod void newBusinessAccountTest(){
        isBothBlank = false;
        isExceptionAccount = false;
        createData();

        List<Forecast_Schedule__c> testSchedules = new List<Forecast_Schedule__c>();
        for( Opportunity anOpportunity : oppList )
        {
          Forecast_Schedule__c newSchedule = new Forecast_Schedule__c();
          newSchedule.Opportunity__c = anOpportunity.Id;
          newSchedule.Start_Date__c = TARGET_DATE;
          newSchedule.Forecast_Amount__c = 1.0;
          testSchedules.add( newSchedule );
        }
        insert testSchedules;

        List<Forecast_Schedule__c> unlinkedSchedules = new List<Forecast_Schedule__c>();
        for( Opportunity anOpportunity : oppList )
        {
          Forecast_Schedule__c newSchedule = new Forecast_Schedule__c();
          newSchedule.Opportunity__c = anOpportunity.Id;
          newSchedule.Start_Date__c = TARGET_DATE.addMonths(1);
          newSchedule.Forecast_Amount__c = 1.0;
          unlinkedSchedules.add( newSchedule );
        }
        insert unlinkedSchedules;

        test.startTest();
            BatchLinkTwilioUsageToForecast BLTF = new BatchLinkTwilioUsageToForecast();
            database.executebatch(BLTF);
        test.stopTest();

        list<Forecast_Schedule__c> FSlist = [select id, Opportunity__r.New_Business_Account_SID__c,
                                                Start_Date__c, Twilio_Usage__r.Month__c, Twilio_Usage__r.Year__c,
                                                Twilio_Usage__r.AccountSid__c
                                              from Forecast_Schedule__c];
        system.assertequals(numOfRec * 2, FSlist.size(), 'There should be as many Schedules retrieved as created');
        for( Forecast_Schedule__c aSchedule : FSlist )
        {
          if( aSchedule.Start_Date__c == TARGET_DATE )
          {
            System.assertEquals( aSchedule.Start_Date__c.month(), aSchedule.Twilio_Usage__r.Month__c, 'The Usage should match the Schedules month' );
            System.assertEquals( aSchedule.Start_Date__c.year(), aSchedule.Twilio_Usage__r.Year__c, 'The Usage should match the Schedules year' );
            System.assertEquals( aSchedule.Opportunity__r.New_Business_Account_SID__c, aSchedule.Twilio_Usage__r.AccountSid__c, 'The Usage should match the Schedules Account SID' );
          }
          else
          {
            System.assertEquals( NULL, aSchedule.Twilio_Usage__c, 'Schedules without a Usage should not have the lookup populated' );
          }
        }
    }

    static testMethod void exceptionAccountTest(){
        isBothBlank = false;
        isExceptionAccount = true;
        createData();

        List<Forecast_Schedule__c> testSchedules = new List<Forecast_Schedule__c>();
        for( Opportunity anOpportunity : oppList )
        {
          Forecast_Schedule__c newSchedule = new Forecast_Schedule__c();
          newSchedule.Opportunity__c = anOpportunity.Id;
          newSchedule.Start_Date__c = TARGET_DATE;
          newSchedule.Forecast_Amount__c = 1.0;
          testSchedules.add( newSchedule );
        }
        insert testSchedules;

        List<Forecast_Schedule__c> unlinkedSchedules = new List<Forecast_Schedule__c>();
        for( Opportunity anOpportunity : oppList )
        {
          Forecast_Schedule__c newSchedule = new Forecast_Schedule__c();
          newSchedule.Opportunity__c = anOpportunity.Id;
          newSchedule.Start_Date__c = TARGET_DATE.addMonths(1);
          newSchedule.Forecast_Amount__c = 1.0;
          unlinkedSchedules.add( newSchedule );
        }
        insert unlinkedSchedules;

        test.startTest();
            BatchLinkTwilioUsageToForecast BLTF = new BatchLinkTwilioUsageToForecast();
            database.executebatch(BLTF);
        test.stopTest();

        list<Forecast_Schedule__c> FSlist = [select id, Opportunity__r.Exception_Account_SID__c,
                                                Start_Date__c, Twilio_Usage__r.Month__c, Twilio_Usage__r.Year__c,
                                                Twilio_Usage__r.AccountSid__c
                                              from Forecast_Schedule__c];
        system.assertequals(numOfRec * 2, FSlist.size(), 'There should be as many Schedules retrieved as created');
        for( Forecast_Schedule__c aSchedule : FSlist )
        {
          if( aSchedule.Start_Date__c == TARGET_DATE )
          {
            System.assertEquals( aSchedule.Start_Date__c.month(), aSchedule.Twilio_Usage__r.Month__c, 'The Usage should match the Schedules month' );
            System.assertEquals( aSchedule.Start_Date__c.year(), aSchedule.Twilio_Usage__r.Year__c, 'The Usage should match the Schedules year' );
            System.assertEquals( aSchedule.Opportunity__r.Exception_Account_SID__c, aSchedule.Twilio_Usage__r.AccountSid__c, 'The Usage should match the Schedules Account SID' );
          }
          else
          {
            System.assertEquals( NULL, aSchedule.Twilio_Usage__c, 'Schedules without a Usage should not have the lookup populated' );
          }
        }
    }

    static testMethod void blankExceptionAndBusinessAccountTest(){
        isBothBlank = true;
        createData();

        test.startTest();
            BatchLinkTwilioUsageToForecast BLTF = new BatchLinkTwilioUsageToForecast();
            database.executebatch(BLTF);
        test.stopTest();

        list<Forecast_Schedule__c> FSlist = [select id, Opportunity__r.Exception_Account_SID__c,
                                                Start_Date__c, Twilio_Usage__r.Month__c, Twilio_Usage__r.Year__c,
                                                Twilio_Usage__r.AccountSid__c
                                              from Forecast_Schedule__c];
        system.assertEquals(0, FSlist.size());
    }
}