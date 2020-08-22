/** * * * * * * * * * * * *
*  Class Name:   BatchLFFDataToOpportunityTest
*  Purpose:      Test class for BatchLFFDataToOpportunity
*  Author:       Mitch Conquer
*  Company:      Go Nimbly
*  Created Date: 27-Sep-2017
*  Type:         Test Class
** * * * * * * * * * * * */

@isTest
private class BatchLFFDataToOpportunityTest {
  static Integer qty = 20;
  static List<Campaign> testCampaigns;
  static List<Campaign> testSqlCampaigns;
  static List<Opportunity> testOpportunities;
  static List<Lifecycle_Field_Funnel__c> testLffs;
  
  static void testSetup() {
    // Setup Campaigns
    testCampaigns = TestDataFactory.createCampaignList(qty);
    testSqlCampaigns = TestDataFactory.createCampaignList(qty);
    List<Campaign> allCampaigns = new List<Campaign>();
    allCampaigns.addAll(testCampaigns);
    allCampaigns.addAll(testSqlCampaigns);
    insert allCampaigns;

    // Setup Opportunities
    testOpportunities = TestDataFactory.createOpportunityList(qty);
    insert testOpportunities;

    testLffs = lffsWithCampaigns(
      testCampaigns,
      testSqlCampaigns,
      testOpportunities
    );
    insert testLffs;
  }

  // Return list of LFFs that have First Campaign Type/Id and Last SQL Campaign
  // Type/Id fields filled out
  static List<Lifecycle_Field_Funnel__c> lffsWithCampaigns(
    List<Campaign> stdCampaigns,
    List<Campaign> sqlCampaigns,
    List<Opportunity> oppties
  ) {
    List<Lifecycle_Field_Funnel__c> newLffs = 
      TestDataFactory.createLFFList(qty);
    for (Integer i = 0; i < newLffs.size(); i++) {
      Lifecycle_Field_Funnel__c lff = newLffs[i];
      Id stdCampaignId = stdCampaigns[i].Id;
      Id sqlCampaignId = sqlCampaigns[i].Id;
      lff.First_Touch_Campaign__c = stdCampaignId;
      lff.First_Touch_Campaign_Type__c = 'std campaign ' + stdCampaignId;
      lff.Last_Touch_SQL_Campaign__c = sqlCampaignId;
      lff.Last_Touch_SQL_Campaign_Type__c = 'sql campaign ' + sqlCampaignId;
      lff.Opportunity__c = oppties[i].Id;
    }
    return newLffs;
  }

  // Functional Test: LFF fields should map to opportunity fields
  static testmethod void testLFFDataMapsToOppFields() {
    testSetup();

    Test.startTest();
      BatchLFFDataToOpportunity testBatch = new BatchLFFDataToOpportunity();
      database.executebatch(testBatch);
    Test.stopTest();

    List<Opportunity> updatedOpporunities = [SELECT Id, First_Touch_Campaign__c,
      First_Touch_Campaign_Type__c, Last_Touch_SQL_Campaign__c,
      Last_Touch_SQL_Campaign_Type__c FROM Opportunity];

    Boolean atLeastOneOpp = updatedOpporunities.size() > 0;
    System.assert(
        atLeastOneOpp,
        'Test should create and return at least one opportunity'
      );

    for (Integer i = 0; i < updatedOpporunities.size(); i++) {
      Opportunity testOpp = updatedOpporunities[i];
      Lifecycle_Field_Funnel__c expectedLff = testLffs[i];

      System.assertEquals(
        expectedLff.First_Touch_Campaign__c,
        testOpp.First_Touch_Campaign__c,
        'LFF First_Touch_Campaign__c should be mapped to Opportunity'
      );
      System.assertEquals(
        expectedLff.First_Touch_Campaign_Type__c,
        testOpp.First_Touch_Campaign_Type__c,
        'LFF First_Touch_Campaign_Type__c should be mapped to Opportunity'
      );
      System.assertEquals(
        expectedLff.Last_Touch_SQL_Campaign__c,
        testOpp.Last_Touch_SQL_Campaign__c,
        'LFF Last_Touch_SQL_Campaign__c should be mapped to Opportunity'
      );
      System.assertEquals(
        expectedLff.Last_Touch_SQL_Campaign_Type__c,
        testOpp.Last_Touch_SQL_Campaign_Type__c,
        'LFF Last_Touch_SQL_Campaign_Type__c should be mapped to Opportunity'
      );
      System.assertEquals(
        expectedLff.Opportunity__c,
        testOpp.Id,
        'LFF Opportunity__c should equal the Opportunity Id'
      );
    }
  }

  // Functional Test: Batch should use most recently updated LFF
  static testmethod void testLFFDataToOpportunityUsesMostRecentLffs() {
    testSetup();

    List<Lifecycle_Field_Funnel__c> newerLffs = lffsWithCampaigns(
      testSqlCampaigns,
      testCampaigns,
      testOpportunities
    );
    insert newerLffs;

    for(Lifecycle_Field_Funnel__c lff : newerLffs) {
      Test.setCreatedDate(lff.Id, DateTime.now().addDays(2));
    }

    Test.startTest();
      BatchLFFDataToOpportunity testBatch = new BatchLFFDataToOpportunity();
      database.executebatch(testBatch);
    Test.stopTest();

    List<Opportunity> updatedOpporunities = [SELECT Id, First_Touch_Campaign__c,
      First_Touch_Campaign_Type__c, Last_Touch_SQL_Campaign__c,
      Last_Touch_SQL_Campaign_Type__c FROM Opportunity];

    Boolean atLeastOneOpp = updatedOpporunities.size() > 0;
    System.assert(
        atLeastOneOpp,
        'Test should create and return at least one opportunity'
      );

    for (Integer i = 0; i < updatedOpporunities.size(); i++) {
      Opportunity testOpp = updatedOpporunities[i];
      Lifecycle_Field_Funnel__c expectedLff = newerLffs[i];
      Lifecycle_Field_Funnel__c unexpectedLff = testLffs[i];

      System.assertNotEquals(
        unexpectedLff.First_Touch_Campaign__c,
        testOpp.First_Touch_Campaign__c,
        'Opporutunity First_Touch_Campaign__c field should not be  from older LFF'
      );
      System.assertNotEquals(
        unexpectedLff.First_Touch_Campaign_Type__c,
        testOpp.First_Touch_Campaign_Type__c,
        'Opporutunity First_Touch_Campaign_Type__c field should not be from older LFF'
      );
      System.assertNotEquals(
        unexpectedLff.Last_Touch_SQL_Campaign__c,
        testOpp.Last_Touch_SQL_Campaign__c,
        'Opporutunity Last_Touch_SQL_Campaign__c field should not be from older LFF'
      );
      System.assertNotEquals(
        unexpectedLff.Last_Touch_SQL_Campaign_Type__c,
        testOpp.Last_Touch_SQL_Campaign_Type__c,
        'Opporutunity Last_Touch_SQL_Campaign_Type__c field should not be from older LFF'
      );
      System.assertEquals(
        expectedLff.First_Touch_Campaign__c,
        testOpp.First_Touch_Campaign__c,
        'Opportunity First_Touch_Campaign__c should match the newer field'
      );
      System.assertEquals(
        expectedLff.First_Touch_Campaign_Type__c,
        testOpp.First_Touch_Campaign_Type__c,
        'Opportunity First_Touch_Campaign_Type__c should match the newer field'
      );
      System.assertEquals(
        expectedLff.Last_Touch_SQL_Campaign__c,
        testOpp.Last_Touch_SQL_Campaign__c,
        'Opportunity Last_Touch_SQL_Campaign__c should match the newer field'
      );
      System.assertEquals(
        expectedLff.Last_Touch_SQL_Campaign_Type__c,
        testOpp.Last_Touch_SQL_Campaign_Type__c,
        'Opportunity Last_Touch_SQL_Campaign_Type__c should match the newer field'
      );
    }
  }
}