/*
 * Copyright (c) 2020. 7Summits Inc.
 */
@isTest
public with sharing class x7s_Adventure_ModuleTasksTest {
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
                Resource_Type__c = x7s_Adventure_TestConstants.TEST_RESOURCE_TYPE,Completed__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_Completed,
                Step_Module__c = testStepModule.Id,Owner__c = taskOwner.Id);
        insert testModuleTask;
        Module_Task__c testModuleTask_1 = new Module_Task__c(Name = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME,
                Title__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME, Content_URL__c = x7s_Adventure_TestConstants.TEST_URL,
                Resource_Type__c = x7s_Adventure_TestConstants.TEST_RESOURCE_TYPE,Completed__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_Completed,
                Step_Module__c = testStepModule.Id,Owner__c = taskOwner.Id);
        insert testModuleTask_1;
        Module_Task__c testModuleTask_2 = new Module_Task__c(Name = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME,
                Title__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME, Content_URL__c = x7s_Adventure_TestConstants.TEST_URL,
                Resource_Type__c = x7s_Adventure_TestConstants.TEST_RESOURCE_TYPE,Completed__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_Completed,
                Step_Module__c = testStepModule.Id,Owner__c = taskOwner.Id);
        insert testModuleTask_2;

    }

    @isTest
    public static void myModuleTaskWrapperHplTest(){
       
        User ownerId = [SELECT ID FROM USER WHERE Email ='jason.liveston@asdf.com' LIMIT 1];
        Adventure__c myAdventure = [SELECT ID FROM Adventure__c WHERE Name =:x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME LIMIT 1];
       
        List<Module_Task__c> tasksList = [SELECT Id,Completed__c FROM Module_Task__c WHERE Owner__c =: ownerId.Id]; 

    

        Boolean TestTaskCompleted = x7s_Adventure_ModuleTasks.taskCompleted(tasksList[0].Id,false);
        System.assertEquals(TestTaskCompleted,false);


       List<Step_Module__c> selectedModule = [SELECT Id,Completed__c FROM Step_Module__c ];       
       Step_Module__c testModule = x7s_Adventure_ModuleTasks.getModuleTaskProgress(selectedModule[0].Id);
       System.assertEquals(testModule.Completed__c,false);


        x7s_Adventure_MyModuleTaskWrapper testResult = x7s_Adventure_ModuleTasks.getMyModuleTaskProgress(selectedModule[0].Id,ownerId.Id);
        System.assertEquals(testResult.TaskProgress,67);
        System.assertEquals( testResult.Completed, false);


        x7s_Adventure_MyProgress testMyAdventureMyProgress = x7s_Adventure_ModuleTasks.getMyAdventureProgress(myAdventure.Id,ownerId.Id);
        System.assertEquals( testMyAdventureMyProgress.totalCompletedTasks, 2);
        System.assertEquals( testMyAdventureMyProgress.totalTasksAssigned, 3);


        x7s_Adventure_MyProgress testAdventureMyProgress = x7s_Adventure_ModuleTasks.getAdventureProgress(myAdventure.Id);
        System.assertEquals( testAdventureMyProgress.totalCompletedTasks, 2);
        System.assertEquals( testAdventureMyProgress.totalTasksAssigned, 3);

        

        
    }
}