@isTest
private class FieldSalesForecastTest {

  static final Integer NUM_OPPTIES = 12;
  static final Profile STANDARD_PROFILE = [ SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1 ];
  static final User ADMIN_USER = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = True LIMIT 1 ];
  static final RecordType NEW_BUSINESS_OPPORTUNITY = [ SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Outbound_Opportunity' LIMIT 1 ];
  static final Integer NUM_SUBORDINATES = 2;

  static Integer userCounter = 0;

  static User testTopLevelManager;
  static List<User> testManagers;
  static List<User> testSubmanagers;
  static Contact testChampion;


  static void setupHierarchy() {
    testTopLevelManager = createUsers( 1, STANDARD_PROFILE.Id, true )[0];

    testManagers = createUsers( NUM_SUBORDINATES, STANDARD_PROFILE.Id, false );
    for( User aManager : testManagers ) {
      aManager.ManagerId = testTopLevelManager.Id;
    }
    System.runAs( ADMIN_USER ) {
      insert testManagers;
    }

    testSubmanagers = new List<User>();
    for( User aManager : testManagers ) {
      for( User aSubmanager : createUsers( NUM_SUBORDINATES, STANDARD_PROFILE.Id, false ) ) {
        aSubmanager.ManagerId = aManager.Id;
        testSubmanagers.add( aSubmanager );
      }
    }
    System.runAs( ADMIN_USER ) {
      insert testSubmanagers;
    }

    testChampion = new Contact( LastName = 'Test Champion' );
    insert testChampion;
  }

  public static testMethod void testOpportunity_PopulatesFieldSalesForecast() {
    setupHierarchy();

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }

    Test.startTest();

      insert testOpportunities;
      FieldSalesForecast.getForecastCategoryValue('Closed');

    Test.stopTest();

    List<Opportunity> updatedOpportunities = [ SELECT Id, Field_Sales_Forecast__c, CloseDate FROM Opportunity ];
    //System.assertEquals( NUM_OPPTIES, updatedOpportunities.size(), 'There should be as many opportunities as created' );

    Set<Id> fieldSalesForecastIds = new Set<Id>();
    for( Opportunity anOpportunity : updatedOpportunities ) {
      //System.assertNotEquals( NULL, anOpportunity.Field_Sales_Forecast__c, 'The opportunity should have a Field Sales Forecast associated' );
      fieldSalesForecastIds.add( anOpportunity.Field_Sales_Forecast__c );
    }
    Map<Id, Field_Sales_Forecast__c> fieldSalesForecasts = new Map<Id, Field_Sales_Forecast__c>([ SELECT Id, Start_Date__c FROM Field_Sales_Forecast__c
                                                                                                  WHERE Id IN :fieldSalesForecastIds ]);
    for( Opportunity anOpportunity : updatedOpportunities ) {
      Field_Sales_Forecast__c forecast = fieldSalesForecasts.get( anOpportunity.Field_Sales_Forecast__c );
      //System.assertEquals( forecast.Start_Date__c, getClosestQuarterStart( anOpportunity.CloseDate ), 'The opportunity should look up to the appropriate quarter forecast' );
    }
  }

  public static testMethod void testOpportunity_DeleteFieldSalesForecast() {
    setupHierarchy();

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }

    insert testOpportunities;

    List<Opportunity> updatedOpportunities = [ SELECT Id, Field_Sales_Forecast__c, CloseDate FROM Opportunity ];
    //System.assertEquals( NUM_OPPTIES, updatedOpportunities.size(), 'There should be as many opportunities as created' );

    Set<Id> fieldSalesForecastIds = new Set<Id>();
    for( Opportunity anOpportunity : updatedOpportunities ) {
      //System.assertNotEquals( NULL, anOpportunity.Field_Sales_Forecast__c, 'The opportunity should have a Field Sales Forecast associated' );
      fieldSalesForecastIds.add( anOpportunity.Field_Sales_Forecast__c );
    }
    Map<Id, Field_Sales_Forecast__c> fieldSalesForecasts = new Map<Id, Field_Sales_Forecast__c>([ SELECT Id, Start_Date__c FROM Field_Sales_Forecast__c
                                                                                                  WHERE Id IN :fieldSalesForecastIds ]);
    for( Opportunity anOpportunity : updatedOpportunities ) {
      Field_Sales_Forecast__c forecast = fieldSalesForecasts.get( anOpportunity.Field_Sales_Forecast__c );
      //System.assertEquals( forecast.Start_Date__c, getClosestQuarterStart( anOpportunity.CloseDate ), 'The opportunity should look up to the appropriate quarter forecast' );
    }

    Test.startTest();

      delete fieldSalesForecasts.get( updatedOpportunities[0].Field_Sales_Forecast__c );

    Test.stopTest();

    Opportunity opp = [ SELECT Id, Field_Sales_Forecast__c FROM Opportunity WHERE Id = :updatedOpportunities[0].Id LIMIT 1 ];
    //System.assertEquals( NULL, opp.Field_Sales_Forecast__c, 'The opportunity should look up to a Field Sales Forecast' );
  }

  public static testMethod void testOpportunity_GetOpportunitiesByForecastKeyMap() {
    setupHierarchy();

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }

    insert testOpportunities;

    Test.startTest();

      Map<String, List<Opportunity>> opportunitiesByForecastKey = FieldSalesForecast.getOpportunitiesByForecastKeyMap(testOpportunities);

    Test.stopTest();
  }

  public static testMethod void testOpportunity_GetOpportunitiesByFieldSalesForecastIdMap() {
    setupHierarchy();

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }

    insert testOpportunities;

    Set<Id> ids = new Set<Id>();
    for (Opportunity o : testOpportunities) { ids.add(o.Id); }
    Map<Id, Opportunity> testOpportunitiesMap = new Map<Id, Opportunity>([ SELECT Id, Field_Sales_Forecast__c FROM Opportunity WHERE Id IN :ids ]);
    
    Test.startTest();

      Map<Id, List<Opportunity>> opportunitiesByForecastKey = FieldSalesForecast.getOpportunitiesByFieldSalesForecastIdMap(testOpportunities, testOpportunitiesMap);

    Test.stopTest();
  }

  public static testMethod void testOpportunity_GetSalesForecastsByManagerForecastKey() {
    setupHierarchy();

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }

    insert testOpportunities;

    List<Opportunity> updatedOpportunities = [ SELECT Id, Field_Sales_Forecast__c, CloseDate FROM Opportunity ];
    //System.assertEquals( NUM_OPPTIES, updatedOpportunities.size(), 'There should be as many opportunities as created' );

    Set<Id> fieldSalesForecastIds = new Set<Id>();
    for( Opportunity anOpportunity : updatedOpportunities ) {
      //System.assertNotEquals( NULL, anOpportunity.Field_Sales_Forecast__c, 'The opportunity should have a Field Sales Forecast associated' );
      fieldSalesForecastIds.add( anOpportunity.Field_Sales_Forecast__c );
    }

    List<Field_Sales_Forecast__c> fieldSalesForecasts = [ SELECT Id, Start_Date__c, Forecast_Owner__c, Stage__c FROM Field_Sales_Forecast__c
                                                          WHERE Id IN :fieldSalesForecastIds ];

    Set<Id> forecastOwners = new Set<Id>();
    for( Field_Sales_Forecast__c aForecast : fieldSalesForecasts ) {
      forecastOwners.add( aForecast.Forecast_Owner__c );
    }

    Map<Id, Id> managerIdsMap = new Map<Id, Id>();
    for( User aForecastOwner : [ SELECT Id, ManagerId FROM User WHERE Id IN :forecastOwners ] ) {
      managerIdsMap.put( aForecastOwner.Id, aForecastOwner.ManagerId );
    }    

    Test.startTest();

      Map<String, List<Field_Sales_Forecast__c>> opportunitiesByForecastKey = FieldSalesForecast.getSalesForecastsByManagerForecastKey(fieldSalesForecasts, managerIdsMap);

    Test.stopTest();
  }

  public static testMethod void testOpportunity_GetSalesForecastsByOverrideForecastKey() {
    setupHierarchy();

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }

    insert testOpportunities;
 
    List<Opportunity> updatedOpportunities = [ SELECT Id, Field_Sales_Forecast__c, CloseDate FROM Opportunity ];
    //System.assertEquals( NUM_OPPTIES, updatedOpportunities.size(), 'There should be as many opportunities as created' );

    Set<Id> fieldSalesForecastIds = new Set<Id>();
    for( Opportunity anOpportunity : updatedOpportunities ) {
      //System.assertNotEquals( NULL, anOpportunity.Field_Sales_Forecast__c, 'The opportunity should have a Field Sales Forecast associated' );
      fieldSalesForecastIds.add( anOpportunity.Field_Sales_Forecast__c );
    }

    List<Field_Sales_Forecast__c> fieldSalesForecasts = [ SELECT Id, Start_Date__c, Forecast_Owner__c, Stage__c FROM Field_Sales_Forecast__c
                                                          WHERE Id IN :fieldSalesForecastIds ];
    
    Test.startTest();

      Map<String, List<Field_Sales_Forecast__c>> opportunitiesByForecastKey = FieldSalesForecast.getSalesForecastsByOverrideForecastKey(fieldSalesForecasts);

    Test.stopTest();
  }

  public static testMethod void testOpportunity_UpdatesFieldSalesForecast() {
    final Decimal NEW_AMOUNT = 5000.0;
    setupHierarchy();

    List<Opportunity> testOpportunities = new List<Opportunity>();
    for( User aSubmanager : testSubmanagers ) {
      List<Opportunity> opportunitiesForManager = createOpportunities( 2, aSubmanager.Id, false );
      opportunitiesForManager[0].Amount = 1000.0;
      completeQualification(opportunitiesForManager[0]);
      opportunitiesForManager[1].Amount = 2000.0;
      completeQualification(opportunitiesForManager[1]);
      testOpportunities.addAll( opportunitiesForManager );
    }
    insert testOpportunities;

    Test.startTest();

      for( Opportunity anOpportunity : testOpportunities ) {
        anOpportunity.Amount = NEW_AMOUNT;
      }
      update testOpportunities;

    Test.stopTest();

    List<Opportunity> createdOpportunities = [ SELECT Id, Field_Sales_Forecast__c, Amount FROM Opportunity ];
    //System.assertEquals( 2 * testSubmanagers.size(), createdOpportunities.size(), 'There should as many opportunities retrieved as created' );

    Map<Id, Decimal> forecastSums = new Map<Id, Decimal>();
    for( Opportunity anOpportunity : createdOpportunities ) {
      //System.assertNotEquals( NULL, anOpportunity.Field_Sales_Forecast__c, 'Every Opportunity should have a forecast' );
      if( !forecastSums.containsKey( anOpportunity.Field_Sales_Forecast__c ) ) {
        forecastSums.put( anOpportunity.Field_Sales_Forecast__c, 0.0 );
      }
      forecastSums.put( anOpportunity.Field_Sales_Forecast__c, forecastSums.get(anOpportunity.Field_Sales_Forecast__c) + anOpportunity.Amount );
    }

    List<Field_Sales_Forecast__c> forecasts = [ SELECT Id, Contract_Value_Amount__c FROM Field_Sales_Forecast__c WHERE Id IN :forecastSums.keySet() ];
    //System.assertEquals( forecastSums.size(), forecasts.size(), 'There should be as many forecasts retrieved as opportunities look up to' );
    for( Field_Sales_Forecast__c aForecast : forecasts ) {
      //System.assertEquals( forecastSums.get( aForecast.Id ), aForecast.Contract_Value_Amount__c, 'The TCV amount should be the sum of all opportunities under that forecast' );
    }
  }

  public static testMethod void testOpportunity_OmitFromManagerForecast() {
    setupHierarchy();

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
      anOpportunity.Omit_From_Manager_Forecast__c = true;
    }

    Test.startTest();

      insert testOpportunities;

    Test.stopTest();

    List<Opportunity> updatedOpportunities = [ SELECT Id, Field_Sales_Forecast__c FROM Opportunity ];
    //System.assertEquals( NUM_OPPTIES, updatedOpportunities.size(), 'There should be as many opportunities as created' );
    for( Opportunity anOpportunity : updatedOpportunities ) {
      //System.assertEquals( NULL, anOpportunity.Field_Sales_Forecast__c, 'Opportunities with the Omit checkbox checked should not look up to a Forecast' );
    }
  }

  // marked as see all data due to dependence on pricebook.isstandard for schedules
  /*@isTest(SeeAllData=true)
  public static void testForecastSchedule_PopulatesFieldSalesForecast() {
    final Integer NUM_SCHEDULES = 6;
    setupHierarchy();

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }
    insert testOpportunities;

    List<Forecast_Schedule__c> testSchedules = new List<Forecast_Schedule__c>();
    for( Opportunity anOpportunity : testOpportunities ) {
      testSchedules.addAll( createSchedules( NUM_SCHEDULES, anOpportunity.Id, 100.0, anOpportunity.CloseDate, false ) );
    }

    Test.startTest();

      insert testSchedules;

    Test.stopTest();

    List<Forecast_Schedule__c> createdSchedules = [ SELECT Id, Field_Sales_Forecast__c, Start_Date__c FROM Forecast_Schedule__c WHERE Id IN :testSchedules ];
    //System.assertEquals( NUM_OPPTIES * NUM_SCHEDULES, createdSchedules.size(), 'There should be as many schedules retrieved as created' );

    Set<Id> forecastIds = new Set<Id>();
    for( Forecast_Schedule__c aSchedule : createdSchedules ) {
      //System.assertNotEquals( NULL, aSchedule.Field_Sales_Forecast__c );
      forecastIds.add( aSchedule.Field_Sales_Forecast__c );
    }
    Map<Id, Field_Sales_Forecast__c> relatedForecasts = new Map<Id, Field_Sales_Forecast__c>([ SELECT Id, Start_Date__c FROM Field_Sales_Forecast__c WHERE Id IN :forecastIds ]);
    //System.assertEquals( forecastIds.size(), relatedForecasts.size(), 'There should be as many forecasts retrieved as schedules relate to' );
    for( Forecast_Schedule__c aSchedule : createdSchedules ) {
      Field_Sales_Forecast__c relatedForecast = relatedForecasts.get( aSchedule.Field_Sales_Forecast__c );
      //System.assertEquals( relatedForecast.Start_Date__c, getClosestQuarterStart( aSchedule.Start_Date__c ), 'The Schedule should look up to the forecast for the correct quarter' );
    }
  }*/

  // marked as see all data due to dependence on pricebook.isstandard for schedules
  /*@isTest(SeeAllData=true)
  public static void testForecastSchedule_UpdatesScheduledAmount() {
    final Integer NUM_SCHEDULES = 6;
    setupHierarchy();
    ForecastSchedule.forecastLineitemRecalc = true; // suppress unrelated forecast schedule functionality

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }
    insert testOpportunities;

    List<Forecast_Schedule__c> testSchedules = new List<Forecast_Schedule__c>();
    for( Opportunity anOpportunity : testOpportunities ) {
      testSchedules.addAll( createSchedules( NUM_SCHEDULES, anOpportunity.Id, 0.0, anOpportunity.CloseDate, false ) );
    }
    insert testSchedules;

    Test.startTest();

      for( Forecast_Schedule__c aSchedule : testSchedules ) {
        aSchedule.Forecast_Amount__c = 100.0;
      }
      update testSchedules;

    Test.stopTest();

    List<Forecast_Schedule__c> updatedSchedules = [ SELECT Id, Forecast_Amount__c, Field_Sales_Forecast__c FROM Forecast_Schedule__c WHERE Id IN :testSchedules ];
    //System.assertEquals( NUM_OPPTIES * NUM_SCHEDULES, updatedSchedules.size(), 'There should be as many schedules retrieved as created' );

    Map<Id, Decimal> forecastSums = new Map<Id, Decimal>();
    for( Forecast_Schedule__c aSchedule : updatedSchedules ) {
      //System.assertNotEquals( NULL, aSchedule.Field_Sales_Forecast__c );
      if( !forecastSums.containsKey( aSchedule.Field_Sales_Forecast__c ) ) {
        forecastSums.put( aSchedule.Field_Sales_Forecast__c, 0.0 );
      }
      forecastSums.put( aSchedule.Field_Sales_Forecast__c, forecastSums.get( aSchedule.Field_Sales_Forecast__c ) + aSchedule.Forecast_Amount__c );
    }
    List<Field_Sales_Forecast__c> relatedForecasts = [ SELECT Id, Sales_Forecast_Amount__c FROM Field_Sales_Forecast__c WHERE Id IN :forecastSums.keySet() ];
    //System.assertEquals( forecastSums.size(), relatedForecasts.size(), 'There should be as many forecasts as how many the schedules look up to' );
    for( Field_Sales_Forecast__c aForecast : relatedForecasts ) {
      //System.assertEquals( forecastSums.get( aForecast.Id ), aForecast.Sales_Forecast_Amount__c, 'The Schedule Amount on forecasts should be the sum of schedules looking up to it' );
    }
  }

  // marked as see all data due to dependence on pricebook.isstandard for schedules
  @isTest(SeeAllData=true)
  public static void testForecastSchedule_OpportunityChangesStage() {
    final Integer NUM_SCHEDULES = 6;
    final Decimal FORECAST_AMOUNT = 10.0;
    setupHierarchy();
    ForecastSchedule.forecastLineitemRecalc = true; // suppress unrelated forecast schedule functionality

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }
    insert testOpportunities;

    List<Forecast_Schedule__c> testSchedules = new List<Forecast_Schedule__c>();
    for( Opportunity anOpportunity : testOpportunities ) {
      testSchedules.addAll( createSchedules( 1, anOpportunity.Id, FORECAST_AMOUNT, anOpportunity.CloseDate, false ) );
    }
    insert testSchedules;

    Test.startTest();

      for( Opportunity anOpportunity : testOpportunities ) {
        completeGoNoGo( anOpportunity );
      }
      update testOpportunities;

    Test.stopTest();

    List<Field_Sales_Forecast__c> pipelineForecasts = [ SELECT Id, Sales_Forecast_Amount__c FROM Field_Sales_Forecast__c
                                                        WHERE Stage__c = 'Pipeline' AND Forecast_Owner__c = :testSubmanagers[0].Id ];
    //System.assertEquals( 1, pipelineForecasts.size(), 'The Forecast should have been forecasts created for the Opportunities' );
    //System.assertEquals( 0.0, pipelineForecasts[0].Sales_Forecast_Amount__c, 'Without any Opportunities the Forecast should be zeroed out' );

    List<Field_Sales_Forecast__c> bestcaseForecasts = [ SELECT Id, Sales_Forecast_Amount__c FROM Field_Sales_Forecast__c
                                                      WHERE Stage__c = 'BestCase' AND Forecast_Owner__c = :testSubmanagers[0].Id ];
    //System.assertEquals( 1, bestcaseForecasts.size(), 'There should be a forecast created for the Opportunities moving to a new stage' );
    //System.assertEquals( NUM_OPPTIES * FORECAST_AMOUNT, bestcaseForecasts[0].Sales_Forecast_Amount__c, 'The Forecast should have the sum of all schedules looking to it' );
  }*/

  public static testMethod void testFieldSalesForecast_PopulateLookups() {
    final String STAGE = 'some stage';
    setupHierarchy();

    List<Field_Sales_Forecast__c> testForecasts = new List<Field_Sales_Forecast__c>();
    for( User testUser : testSubmanagers ) {
      Field_Sales_Forecast__c newForecast = createFieldSalesForecast( testUser.Id, getClosestQuarterStart( Date.today() ), false );
      newForecast.Stage__c = STAGE;
      testForecasts.add( newForecast );
    }

    Test.startTest();

      insert testForecasts;

    Test.stopTest();

    List<Field_Sales_Forecast__c> createdForecasts = [ SELECT Id, Manager_Forecast__r.Forecast_Owner__c,
                                                        Forecast_Owner__r.ManagerId, Stage__c, Manager_Forecast__r.Stage__c,
                                                        Start_Date__c, Manager_Forecast__r.Start_Date__c
                                                       FROM Field_Sales_Forecast__c WHERE Id IN :testForecasts ];
    //System.assertEquals( testForecasts.size(), createdForecasts.size(), 'There should be as many forecasts retrieved as created' );
    for( Field_Sales_Forecast__c aForecast : createdForecasts ) {
      //System.assertEquals( aForecast.Manager_Forecast__r.Forecast_Owner__c, aForecast.Forecast_Owner__r.ManagerId, 'Forecasts should look up to the owners managers forecasts' );
      //System.assertEquals( aForecast.Stage__c, aForecast.Manager_Forecast__r.Stage__c, 'The manager forecast should be of the same stage' );
      //System.assertEquals( aForecast.Start_Date__c, aForecast.Manager_Forecast__r.Start_Date__c, 'The manager forecast should have the same start date' );
    }
  }

  public static testMethod void testFieldSalesForecast_UpdatesManagerForecast() {
    setupHierarchy();

    List<Field_Sales_Forecast__c> testForecasts = new List<Field_Sales_Forecast__c>();
    for( User testUser : testSubmanagers ) {
      Field_Sales_Forecast__c newForecast = createFieldSalesForecast( testUser.Id, getClosestQuarterStart( Date.today() ), false );
      newForecast.Stage__c = 'some stage';
      testForecasts.add( newForecast );
    }
    insert testForecasts;

    Test.startTest();

      for( Field_Sales_Forecast__c aForecast : testForecasts ) {
        aForecast.Sales_Forecast_Override__c = 1000.0;
      }
      update testForecasts;

    Test.stopTest();

    List<Field_Sales_Forecast__c> createdForecasts = [ SELECT Id, Manager_Forecast__c, Sales_Forecast_Override__c
                                                       FROM Field_Sales_Forecast__c WHERE Id IN :testForecasts ];
    //System.assertEquals( testForecasts.size(), createdForecasts.size(), 'There should be as many forecasts retrieved as created' );

    Map<Id, Decimal> overrideByManagerForecast = new Map<Id, Decimal>();
    for( Field_Sales_Forecast__c aForecast : createdForecasts ) {
      if( !overrideByManagerForecast.containsKey( aForecast.Manager_Forecast__c ) ) {
        overrideByManagerForecast.put( aForecast.Manager_Forecast__c, 0.0 );
      }
      overrideByManagerForecast.put( aForecast.Manager_Forecast__c, overrideByManagerForecast.get( aForecast.Manager_Forecast__c ) + aForecast.Sales_Forecast_Override__c );
    }
    List<Field_Sales_Forecast__c> updatedManagerForecasts = [ SELECT Id, Submanager_Modified_Forecast__c
                                                              FROM Field_Sales_Forecast__c
                                                              WHERE Id IN :overrideByManagerForecast.keySet() ];
    for( Field_Sales_Forecast__c aForecast : updatedManagerForecasts ) {
      //System.assertEquals( overrideByManagerForecast.get( aForecast.Id ), aForecast.Submanager_Modified_Forecast__c, 'Modified forecasts should roll up to the manager forecast' );
    }
  }

  public static testMethod void testFieldSalesForecast_UpdateOverrideForecast() {
    final Decimal OVERRIDE_AMOUNT_1 = 1000.0;
    final Decimal OVERRIDE_AMOUNT_2 = 2000.0;
    setupHierarchy();

    List<Field_Sales_Forecast__c> testManagerForecasts = new List<Field_Sales_Forecast__c>();
    for( User testUser : testManagers ) {
      Field_Sales_Forecast__c newForecast = createFieldSalesForecast( testUser.Id, getClosestQuarterStart( Date.today() ), false );
      newForecast.Stage__c = 'stage 1';
      newForecast.Sales_Forecast_Override__c = OVERRIDE_AMOUNT_1;
      testManagerForecasts.add( newForecast );

      Field_Sales_Forecast__c anotherForecast = createFieldSalesForecast( testUser.Id, getClosestQuarterStart( Date.today() ), false );
      anotherForecast.Stage__c = 'stage 2';
      anotherForecast.Sales_Forecast_Override__c = OVERRIDE_AMOUNT_2;
      testManagerForecasts.add( anotherForecast );
    }
    insert testManagerForecasts;

    Test.startTest();

      update testManagerForecasts;

    Test.stopTest();

    List<Field_Sales_Forecast__c> createdForecasts = [ SELECT Id, Manager_Forecast__r.Override_Forecast__c FROM Field_Sales_Forecast__c WHERE Id IN :testManagerForecasts ];
    //System.assertEquals( testManagerForecasts.size(), createdForecasts.size(), 'There should be as many forecasts retireved as created' );

    Set<Id> overrideForecastIds = new Set<Id>();
    for( Field_Sales_Forecast__c aForecast : createdForecasts ) {
      overrideForecastIds.add( aForecast.Manager_Forecast__r.Override_Forecast__c );
    }
    List<Field_Sales_Forecast__c> overrideForecast = [ SELECT Id, Manager_Modified_Forecast_Rollup__c FROM Field_Sales_Forecast__c WHERE Id IN :overrideForecastIds ];
    //System.assertEquals( 1, overrideForecast.size(), 'The forecasts should have rolled up to the topmost manager override forecast' );
    //System.assertEquals( (OVERRIDE_AMOUNT_1 + OVERRIDE_AMOUNT_2) * testManagers.size(), overrideForecast[0].Manager_Modified_Forecast_Rollup__c, 'The modified forecasts should have rolled up' );
  }


  private static List<Opportunity> createOpportunities( Integer numOpportunities, Id ownerId, Boolean doInsert ) {
    List<Opportunity> testOpportunities = new List<Opportunity>();
    for( Integer index = 0; index < numOpportunities; index++ ) {
      Opportunity newOpportunity = new Opportunity();
      newOpportunity.Name = 'Test Opportunity ' + index;
      newOpportunity.CloseDate = Date.today();
      newOpportunity.StageName = 'Incubate';
      newOpportunity.Launch_Date__c = Date.today().addMonths(2);
      newOpportunity.RecordTypeId = NEW_BUSINESS_OPPORTUNITY.Id;
      newOpportunity.Amount = 1000.0;
      newOpportunity.OwnerId = ownerId;

      completeIncubate(newOpportunity);

      testOpportunities.add( newOpportunity );
    }

    if( doInsert ) {
      insert testOpportunities;
    }

    return testOpportunities;
  }

  private static void completeIncubate( Opportunity incomingOpportunity ) {
    incomingOpportunity.FY_16_Primary_Product__c = 'Programmable Voice';
    incomingOpportunity.FY_16_Use_Case__c = 'Click-to-Call';
    incomingOpportunity.Primary_Competitor__c = 'No competitor';
    incomingOpportunity.Competitive_Takeout__c = 'NO';
    incomingOpportunity.ProjectedVolume__c = 1000.0;
    incomingOpportunity.Project_Timeframe__c = Date.today().addMonths(1);
  }

  // this is the minimum for Opportunities to receive a Field Sales Forecast
  private static void completeQualification( Opportunity incomingOpportunity ) {
    incomingOpportunity.Documented_Decision_Making_Process__c = 'Not Required';
    incomingOpportunity.Customer_s_use_case_metrics_identified__c = 'Not Required';
    incomingOpportunity.Technical_Champion__c = testChampion.Id;
    incomingOpportunity.Project_Sponsor__c = testChampion.Id;
    incomingOpportunity.Is_there_a_compelling_event__c = 'No';
    incomingOpportunity.Compelling_Event_Details__c = 'Compelling details';
    incomingOpportunity.Use_Case_Requirements__c = 'Requirement details';
  }

  private static void completeGoNoGo( Opportunity incomingOpportunity ) {
    incomingOpportunity.POC_Outcome_Metrics_Review_with_Champion__c = 'Yes';
    incomingOpportunity.POC_Review__c = Date.today();
    incomingOpportunity.Technical_Win__c = 'Yes';
  }

  private static List<Forecast_Schedule__c> createSchedules( Integer numSchedules, Id opportunityId, Decimal amount, Date startDate, Boolean doInsert ) {
    List<Forecast_Schedule__c> testSchedules = new List<Forecast_Schedule__c>();
    for( Integer index = 0; index < numSchedules; index++ ) {
      Forecast_Schedule__c newSchedule = new Forecast_Schedule__c();
      newSchedule.Opportunity__c = opportunityId;
      newSchedule.Start_Date__c = startDate.addMonths(index);
      newSchedule.Forecast_Amount__c = amount;

      testSchedules.add( newSchedule );
    }

    if( doInsert ) {
      insert testSchedules;
    }

    return testSchedules;
  }

  private static Field_Sales_Forecast__c createFieldSalesForecast( Id forecastOwnerId, Date startDate, Boolean doInsert ) {
    Field_Sales_Forecast__c newForecast = new Field_Sales_Forecast__c();
    newForecast.Forecast_Owner__c = forecastOwnerId;
    newForecast.Start_Date__c = startDate.toStartOfMonth();

    if( doInsert ) {
      insert newForecast;
    }

    return newForecast;
  }

  private static List<User> createUsers( Integer numUsers, Id profileId, Boolean doInsert ) {
    List<User> testUsers = new List<User>();
    for( Integer index = 0; index < numUsers; index++ ) {
      User newUser = new User();
      newUser.LastName = 'TUser';
      newUser.Alias = 'TestU' + index;
      newUser.Email = 'testUser' + userCounter++ + System.now().getTime() + '@example.com.test';
      newUser.Username = newUser.Email;
      newUser.ProfileId = profileId;
      newUser.LocaleSidKey = 'en_US';
      newUser.LanguageLocaleKey = 'en_US';
      newUser.TimezoneSidKey = 'America/New_York';
      newUser.EmailEncodingKey = 'UTF-8';

      testUsers.add( newUser );
    }

    if( doInsert ) {
      System.runAs( ADMIN_USER ) {
        insert testUsers;
      }
    }

    return testUsers;
  }

  private static Date getClosestQuarterStart( Date someDate ) {
    return Date.newInstance( someDate.year(), (someDate.month()-1) / 3 * 3 + 1, 1 );
  }
}