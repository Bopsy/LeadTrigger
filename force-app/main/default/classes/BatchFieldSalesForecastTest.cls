@isTest
public class BatchFieldSalesForecastTest {

  static final Integer NUM_USERS = 15;
  static final Integer NUM_SUBORDINATES = 3;

  static List<User> testOwners;
  static List<User> oldManagers;
  static List<User> newManagers;
  static List<Field_Sales_Forecast__c> testForecasts;

  static void setup() {
    Profile standardProfile = [ SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1 ];
    oldManagers = createUsers( NUM_USERS, standardProfile.Id, true );
    testOwners = new List<User>();
    for( User aManager : oldManagers ) {
      List<User> newUsersForManager = createUsers( NUM_SUBORDINATES, standardProfile.Id, false );
      for( User aSubordinate : newUsersForManager ) {
        aSubordinate.ManagerId = aManager.Id;
      }
      testOwners.addAll( newUsersForManager );
    }
    System.runAs( ADMIN_USER ) {
      insert testOwners;
    }

    testForecasts = new List<Field_Sales_Forecast__c>();
    for( User aUser : testOwners ) {
      Field_Sales_Forecast__c newForecast = createFieldSalesForecast( aUser.Id, Date.today(), false );
      newForecast.Sales_Forecast_Amount__c = 100.0;
      newForecast.Stage__c = 'Some Stage';
      testForecasts.add( newForecast );
    }
    insert testForecasts;
    update testForecasts; // triggers update to manager forecasts

    newManagers = createUsers( NUM_USERS, standardProfile.Id, true );
    for( Integer userIndex = 0; userIndex < testOwners.size(); userIndex++ ) {
      testOwners[userIndex].ManagerId = newManagers[Math.mod(userIndex, newManagers.size())].Id;
    }
    update testOwners;
  }

  static testMethod void testScheduleBatch() {
    final String CRON_EXP = '0 0 0 * * ? *';
    setup();

    Test.startTest();

      String jobId = System.schedule( 'BatchFieldSalesForecastTest', CRON_EXP, new BatchFieldSalesForecast() );

      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
      System.assertEquals(CRON_EXP, ct.CronExpression);
      System.assertEquals(0, ct.TimesTriggered);

    Test.stopTest();
  }

  static testMethod void testExecuteBatch() {
    FieldSalesForecast.disableFuture = true;
    setup();

	// Reset runOnce mechanism so that it will not prevent running for the tests
	FieldSalesForecast.run.clear();
	
    List<Field_Sales_Forecast__c> previousManagerForecasts = [ SELECT Id, Submanager_Forecast_Total__c
                                                                FROM Field_Sales_Forecast__c
                                                                WHERE Forecast_Owner__c IN :oldManagers AND Stage__c != NULL ];
    System.assertEquals( NUM_USERS, previousManagerForecasts.size(), 'There should have been one Stage Forecast per Manager created' );
    for( Field_Sales_Forecast__c aForecast : previousManagerForecasts ) {
      System.assertNotEquals( 0, aForecast.Submanager_Forecast_Total__c, 'There should be subtotals on the old records' );
    }

    Test.startTest();

      BatchFieldSalesForecast newBatch = new BatchFieldSalesForecast();
      Database.executeBatch( newBatch );

    Test.stopTest();

    System.assert( String.isBlank( newBatch.errors ), 'There should be no errors: ' + newBatch.errors );
    List<Field_Sales_Forecast__c> updatedFieldSalesForecasts = [ SELECT Id, Forecast_Owner__c,
                                                                    Manager_Forecast__r.Forecast_Owner__c
                                                                  FROM Field_Sales_Forecast__c
                                                                  WHERE Id IN :testForecasts ];
    System.assertEquals( NUM_USERS * NUM_SUBORDINATES, updatedFieldSalesForecasts.size(), 'There should be one Forecast per subordinate' );
    Map<Id, User> ownersMap = new Map<Id, User>(testOwners);
    for( Field_Sales_Forecast__c aForecast : updatedFieldSalesForecasts ) {
      System.assertEquals( ownersMap.get( aForecast.Forecast_Owner__c ).ManagerId, aForecast.Manager_Forecast__r.Forecast_Owner__c,
        'The Manager Forecast should have been updated to look to the Forecast of the new Manager' );
    }

    List<Field_Sales_Forecast__c> oldForecasts = [ SELECT Id, Submanager_Forecast_Total__c
                                                    FROM Field_Sales_Forecast__c
                                                    WHERE Forecast_Owner__c IN :oldManagers AND Stage__c != NULL ];
    System.assertEquals( NUM_USERS, oldForecasts.size(), 'There should have been one Stage Forecast per Manager created' );
    for( Field_Sales_Forecast__c aForecast : oldForecasts ) {
      System.assertEquals( 0, aForecast.Submanager_Forecast_Total__c, 'Without subordinates, the subtotals should be 0' );
    }

    List<Field_Sales_Forecast__c> newForecasts = [ SELECT Id, Submanager_Forecast_Total__c
                                                    FROM Field_Sales_Forecast__c
                                                    WHERE Forecast_Owner__c IN :newManagers AND Stage__c != NULL ];
    System.assertEquals( NUM_USERS, newForecasts.size(), 'There should be one Stage Forecast per new Manager' );
    for( Field_Sales_Forecast__c aForecast : newForecasts ) {
      System.assertNotEquals( 0.0, aForecast.Submanager_Forecast_Total__c, 'With subordinates, the new Manager forecasts should have recalculated' );
    }
  }

  static testMethod void testExecute_AssignedManagerEdgeCase() {
    Profile standardProfile = [ SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1 ];
    List<User> testUsers = createUsers( NUM_USERS, standardProfile.Id, true );

    testForecasts = new List<Field_Sales_Forecast__c>();
    for( User anOwner : testUsers ) {
      Field_Sales_Forecast__c newForecast = createFieldSalesForecast( anOwner.Id, Date.today(), false );
      testForecasts.add( newForecast );
    }
    insert testForecasts;
    for( Field_Sales_Forecast__c newForecast : [ SELECT Id, Manager_Forecast__c FROM Field_Sales_Forecast__c WHERE Id IN :testForecasts ] ) {
      System.assertEquals( NULL, newForecast.Manager_Forecast__c );
    }

    User newManager = createUsers( 1, standardProfile.Id, true )[0];
    for( User aUser : testUsers ) {
      aUser.ManagerId = newManager.Id;
    }
    update testUsers;

    Test.startTest();

      BatchFieldSalesForecast newBatch = new BatchFieldSalesForecast();
      Database.executeBatch( newBatch );

    Test.stopTest();

    System.assert( String.isBlank( newBatch.errors ), 'There should have been no errors updating records: ' + newBatch.errors );

    List<Field_Sales_Forecast__c> updatedForecasts = [ SELECT Id, Manager_Forecast__r.Forecast_Owner__c FROM Field_Sales_Forecast__c WHERE Id IN :testForecasts ];
    System.assertEquals( NUM_USERS, updatedForecasts.size(), 'There should be one Forecast per Owner' );
    for( Field_Sales_Forecast__c aForecast : updatedForecasts ) {
      System.assertEquals( newManager.Id, aForecast.Manager_Forecast__r.Forecast_Owner__c, 'The Forecasts should have been updated with the new Manager' );
    }
  }


  static Integer userCounter = 0;
  static User ADMIN_USER = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1 ];

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

  private static Field_Sales_Forecast__c createFieldSalesForecast( Id forecastOwnerId, Date startDate, Boolean doInsert ) {
    Field_Sales_Forecast__c newForecast = new Field_Sales_Forecast__c();
    newForecast.Forecast_Owner__c = forecastOwnerId;
    newForecast.Start_Date__c = startDate.toStartOfMonth();
    newForecast.Stage__c = 'Some Stage';

    if( doInsert ) {
      insert newForecast;
    }

    return newForecast;
  }
}