@isTest
private class ManagerForecastControllerTest {
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

  static testMethod void testOpportunity_PopulatesFieldSalesForecast() {
    setupHierarchy();

    List<Opportunity> testOpportunities = createOpportunities( NUM_OPPTIES, testSubmanagers[0].Id, false );
    for( Opportunity anOpportunity : testOpportunities ) {
      completeQualification( anOpportunity );
    }

    Test.startTest();

      insert testOpportunities;
      ManagerForecastController ctrl = new ManagerForecastController();
      ctrl.getAvailableUsers();
      ctrl.getRelatedOpps();
      ctrl.getSubManagerUserMap();
      Database.executeBatch(new BatchUpdateFieldSalesForecast());
    Test.stopTest();

  }
	

}