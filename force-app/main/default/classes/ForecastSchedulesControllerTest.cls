@isTest
private class ForecastSchedulesControllerTest
{
  static final Decimal TEST_AMOUNT = 1000.0;
  static final Integer CONTRACT_TERMS_MONTHS = 6;
  static final String DELETE_SCHEDULE_ERROR = 'List has no rows for assignment to SObject';
  static final String GETOPPORTUNITY_EXCEPTION = 'Launch Date and Contract Terms must be set on the Opportunity.';
  static Opportunity testOpportunity;

  @testSetup
  static void setup()
  {
    Product2 testProduct = new Product2();
    testProduct.Name = 'Forecast Lock';
    insert testProduct;

    PricebookEntry testPB = new PricebookEntry();
    testPB.Product2Id = testProduct.Id;
    testPB.IsActive = TRUE;
    testPB.UnitPrice = 1.0;
    testPB.Pricebook2Id = Test.getStandardPricebookId();
    insert testPB;

    testOpportunity = TestDataFactory.createOpportunityList(1)[0];
    testOpportunity.Launch_Date__c = Date.today();
    testOpportunity.Contract_Terms_Months__c = CONTRACT_TERMS_MONTHS;
    testOpportunity.Amount = TEST_AMOUNT * CONTRACT_TERMS_MONTHS;
    insert testOpportunity;
  }

  static testMethod void testGetOpportunity_NoSchedules()
  {
    testOpportunity = [ SELECT Id FROM Opportunity LIMIT 1 ];

    Test.startTest();

      Opportunity returnedOpportunity = ForecastSchedulesController.getOpportunity( testOpportunity.Id );

    Test.stopTest();

    System.assertEquals( testOpportunity.Id, returnedOpportunity.Id, 'The specified Opportunity should have been returned' );
    System.assertEquals( CONTRACT_TERMS_MONTHS, returnedOpportunity.Forecast_Schedules__r.size(), 'Opportunities without schedules should have them created' );
    for( Forecast_Schedule__c aSchedule : returnedOpportunity.Forecast_Schedules__r )
    {
      System.assertEquals( TEST_AMOUNT, aSchedule.Forecast_Amount__c, 'Each Forecast should have received an equal proportion of the Amount' );
    }
  }

  static testMethod void testGetOpportunity_ExistingSchedules()
  {
    testOpportunity = [ SELECT Id FROM Opportunity LIMIT 1 ];

    List<Forecast_Schedule__c> existingSchedules = TestDataFactory.createForecastSchedules( CONTRACT_TERMS_MONTHS - 1, testOpportunity.Id, Date.today(), 1.0 );
    insert existingSchedules;
    System.debug('existingSchedules.size() = ' + existingSchedules.size());

    Test.startTest();

      Opportunity returnedOpportunity = ForecastSchedulesController.getOpportunity( testOpportunity.Id );

    Test.stopTest();

    System.assertEquals( testOpportunity.Id, returnedOpportunity.Id, 'The specified Opportunity should have been returned' );
    System.assertEquals( existingSchedules.size(), returnedOpportunity.Forecast_Schedules__r.size(), 'Opportunities with schedules should have existing Schedules returned' );
    Map<Id, Forecast_Schedule__c> retrievedSchedules = new Map<Id, Forecast_Schedule__c>( returnedOpportunity.Forecast_Schedules__r );
    for (Forecast_Schedule__c f : retrievedSchedules.values()) {
      System.debug('retrievedSchedules(' + f.Id + ', Start_Date__c=' + f.Start_Date__c + ')');	
    }
    for( Forecast_Schedule__c aSchedule : existingSchedules )
    {
      System.debug('existingSchedules(' + aSchedule.Id + ', Start_Date__c=' + aSchedule.Start_Date__c + ')');	
      System.assert( retrievedSchedules.containsKey( aSchedule.Id ), 'Every pre-existing Schedule should have been retrieved' );
    }
  }

  static testMethod void testUpdateForecasts()
  {
    final Decimal NEW_AMOUNT = 1500.0;
    testOpportunity = [ SELECT Id FROM Opportunity LIMIT 1 ];

    List<Forecast_Schedule__c> testSchedules = TestDataFactory.createForecastSchedules( CONTRACT_TERMS_MONTHS, testOpportunity.Id, Date.today(), 1.0 );
    insert testSchedules;

    for( Forecast_Schedule__c aSchedule : testSchedules )
    {
      aSchedule.Forecast_Amount__c = NEW_AMOUNT;
    }

    Test.startTest();

      List<Forecast_Schedule__c> updatedSchedules = ForecastSchedulesController.updateForecasts( testSchedules );

    Test.stopTest();

    Map<Id, Forecast_Schedule__c> updatedMap = new Map<Id, Forecast_Schedule__c>( updatedSchedules );
    System.assertEquals( testSchedules.size(), updatedMap.size(), 'The updated Schedules should have been returned' );

    Map<Id, Forecast_Schedule__c> databaseMap = new Map<Id, Forecast_Schedule__c>( [ SELECT Id, Forecast_Amount__c FROM Forecast_Schedule__c ]);
    System.assertEquals( testSchedules.size(), databaseMap.size(), 'The updated Schedules should still be in the database' );

    for( Forecast_Schedule__c aSchedule : testSchedules )
    {
      System.assert( updatedMap.containsKey( aSchedule.Id ), 'Every Schedule passed in to be updated should be returned' );
      System.assertEquals( NEW_AMOUNT, updatedMap.get( aSchedule.Id ).Forecast_Amount__c, 'The updated Amount should be on the Forecast' );

      System.assert( databaseMap.containsKey( aSchedule.Id ), 'Every Schedule should still be in the database' );
      System.assertEquals( NEW_AMOUNT, databaseMap.get( aSchedule.Id ).Forecast_Amount__c, 'The updated Amount should have been saved' );
    }
  }

  static testMethod void testNewSchedule()
  {
    final Date LATEST_DATE = Date.today().addMonths(2);
    testOpportunity = [ SELECT Id FROM Opportunity LIMIT 1 ];

    Forecast_Schedule__c existingForecast = TestDataFactory.createForecastSchedules( 1, testOpportunity.Id, LATEST_DATE, 1.0 )[0];
    insert existingForecast;

    Test.startTest();

      Forecast_Schedule__c newSchedule = ForecastSchedulesController.newSchedule( testOpportunity.Id );

    Test.stopTest();

    System.assertEquals( testOpportunity.Id, newSchedule.Opportunity__c, 'The new Schedule should look up to the passed Opportunity' );
    System.assertEquals( LATEST_DATE.addMonths(1).toStartOfMonth(), newSchedule.Start_Date__c, 'The Schedule should have a defaulted Start Date' );

    Forecast_Schedule__c createdSchedule = [ SELECT Id, Start_Date__c, Opportunity__c FROM Forecast_Schedule__c WHERE Id = :newSchedule.Id ];
    System.assertEquals( testOpportunity.Id, createdSchedule.Opportunity__c, 'The Schedule should have created for the passed Opportunity' );
    System.assertEquals( LATEST_DATE.addMonths(1).toStartOfMonth(), createdSchedule.Start_Date__c, 'The Schedule should have a Start Date saved' );
  }

  static testMethod void testDeleteSchedulePositive()
  {
    testOpportunity = [ SELECT Id FROM Opportunity LIMIT 1 ];

    Forecast_Schedule__c existingForecast = TestDataFactory.createForecastSchedules( 1, testOpportunity.Id, Date.today(), 1.0 )[0];
    insert existingForecast;

    Test.startTest();

      Forecast_Schedule__c deletedSchedule = ForecastSchedulesController.deleteSchedule( existingForecast.Id );

    Test.stopTest();

    List<Forecast_Schedule__c> deletedForecasts = [ SELECT Id FROM Forecast_Schedule__c ];
    System.assertEquals( 0, deletedForecasts.size(), 'There should be no more Schedules' );

    System.assertEquals( existingForecast.Id, deletedSchedule.Id, 'The deleted Schedule should have been returned on success' );
  }


  /* * * * * * * * * * * * *
  *  Method Name:  testDeleteScheduleNegative
  *  Purpose:      This method is used to do negatie test for the deleteSchedule
  *  Author:       Purushottam Bhaigade
  *  Company:      GoNimbly
  *  Created Date: 14-July-2016
  * * * * * * * * * * * * */
  static testMethod void testDeleteScheduleNegative()
  {
    testOpportunity = [ SELECT Id FROM Opportunity LIMIT 1 ];
    String errorMessage = '';
    Forecast_Schedule__c existingForecast = TestDataFactory.createForecastSchedules( 1, testOpportunity.Id, Date.today(), 1.0 )[0];
    insert existingForecast;

    Forecast_Schedule__c scheduleToDelete = [ SELECT Id FROM Forecast_Schedule__c WHERE Id = :existingForecast.Id ];

    Test.startTest();
      try
      {
        delete scheduleToDelete;
        Forecast_Schedule__c deletedSchedule = ForecastSchedulesController.deleteSchedule( existingForecast.Id );
      }catch(Exception ex)
      {
        errorMessage = ex.getMessage();
      }
    Test.stopTest();

    System.assertEquals(errorMessage,DELETE_SCHEDULE_ERROR);
  }


  /* * * * * * * * * * * * *
  *  Method Name:  testGetOpportunityNegative
  *  Purpose:      This method is used to do negatie test for the getOpportunity
  *  Author:       Purushottam Bhaigade
  *  Company:      GoNimbly
  *  Created Date: 14-July-2016
  * * * * * * * * * * * * */
  /*static testMethod void testGetOpportunityNegative()
  {
    Opportunity testOpportunityLocal =  new Opportunity();
    testOpportunityLocal.Launch_Date__c = NULL;
    testOpportunityLocal.Contract_Terms_Months__c = NULL;
    testOpportunityLocal.Amount = TEST_AMOUNT * CONTRACT_TERMS_MONTHS;
    insert testOpportunityLocal;

    String errorMessage = '';
    //Forecast_Schedule__c existingForecast = TestDataFactory.createForecastSchedules( 1, testOpportunity.Id, Date.today(), 1.0 )[0];
    //insert existingForecast;

    Test.startTest();
      try
      {
        ForecastSchedulesController.getOpportunity( testOpportunityLocal.Id );
      }catch(Exception ex)
      {
        errorMessage = ex.getMessage();
      }
    Test.stopTest();

    System.assertEquals(errorMessage,GETOPPORTUNITY_EXCEPTION);
  }*/

}