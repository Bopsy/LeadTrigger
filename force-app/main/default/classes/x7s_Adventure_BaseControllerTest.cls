/*
 * Copyright (c) 2020. 7Summits Inc.
 */

@isTest
public with sharing class x7s_Adventure_BaseControllerTest {

    @testSetup
    public static void testSetup(){


        // Profile
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        //User to assign tasks
        User taskOwner = new User(LastName = 'LIVESTON',FirstName='JASON',Alias = 'jliv', Email = 'jason.liveston@asdf.com', Username = 'Adventure.Learning@Test.com',
        ProfileId = profileId.id,TimeZoneSidKey = 'GMT',LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8',LocaleSidKey = 'en_US');
        insert taskOwner;

        //Create test adventure
        Adventure__c testAdventure = new Adventure__c(Name = x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME, Title__c = x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME);
        insert testAdventure;

        //Create test Adventure Step
        Adventure_Step__c testAdventureStep = new Adventure_Step__c(Name = x7s_Adventure_TestConstants.TEST_ADVENTURE_STEP_NAME,
                Title__c = x7s_Adventure_TestConstants.TEST_ADVENTURE_STEP_NAME, Adventure__c = testAdventure.Id,
                Subtitle__c = x7s_Adventure_TestConstants.TEST_ADVENTURE_STEP_SUBTITLE, Description__c = x7s_Adventure_TestConstants.TEST_ADVENTURE_STEP_DESCRIPTION);
        insert testAdventureStep;

        //Create test Step Module
        Step_Module__c testStepModule = new Step_Module__c(Name = x7s_Adventure_TestConstants.TEST_STEP_MODULE_NAME,
                Title__c = x7s_Adventure_TestConstants.TEST_STEP_MODULE_NAME, Adventure_Step__c = testAdventureStep.Id);
        insert testStepModule;

        //Create test Module Task
        Module_Task__c testModuleTask = new Module_Task__c(Name = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME,
                Title__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME, Content_URL__c = x7s_Adventure_TestConstants.TEST_URL,
                Resource_Type__c = x7s_Adventure_TestConstants.TEST_RESOURCE_TYPE, Step_Module__c = testStepModule.Id,Owner__c = taskOwner.Id);
        insert testModuleTask;

    }

    @isTest
    public static void testGetAdventure(){


        User  testOwner = [SELECT Id FROM User LIMIT 1];
        List<Adventure__c> testAdventures = [SELECT Id FROM Adventure__c];

        x7s_Adventure_Response peakResponse = x7s_Adventure_BaseController.getAdventure(testAdventures[0].Id,testOwner.Id,'');
        System.assertEquals(x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME, peakResponse.peakResults[0].adventure.Name);


        x7s_Adventure_Response peakResponseWithoutOwnerId = x7s_Adventure_BaseController.getAdventure(testAdventures[0].Id,'','');
        System.assertEquals(x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME, peakResponseWithoutOwnerId.peakResults[0].adventure.Name);

    }
     @isTest
    public static void testcurrentUserRecentAdventure()
    {
        List<account> acList = TestDataFactory.createAccountList(1);
        insert acList;
        List<Contact> conList = TestDataFactory.createContactList(1);
        conList[0].AccountId=acList[0].id;
        insert conList;
          Adventure__c testAdventure = new Adventure__c(Name = x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME, Account__c =acList[0].id, Title__c = x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME);
        insert testAdventure; 
        Profile p1 = [SELECT Id FROM Profile WHERE Name='**Partner Community User Login**']; 
        User user1 = new User(Alias = 'TU0001', Email='TUser0001@testorg.com', 
                              EmailEncodingKey='UTF-8', LastName='TUser0001', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p1.Id, ContactId=conList[0].Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='TUser0001@testorg.com');
        insert user1;
        Id advId = null;
        System.runAs(user1){
            advId = x7s_Adventure_BaseController.currentUserRecentAdventure();
        }
        System.assertEquals(advId, testAdventure.id);
        
    }
    @isTest
    static void getConfigurationTest(){
        try{
         x7s_Adventure_Setting__mdt metadata = x7s_Adventure_BaseController.getConfiguration('wrong');
            System.assertEquals(metadata!=null,true);
        }
        catch(Exception ex)
        {
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
    }

}