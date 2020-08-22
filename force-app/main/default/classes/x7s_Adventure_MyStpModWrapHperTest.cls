/*
 * Copyright (c) 2020. 7Summits Inc.
 */
@isTest
public with sharing class x7s_Adventure_MyStpModWrapHperTest {



    @testSetup
    public static void testSetup(){

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
                Step_Module__c = testStepModule.Id);
        insert testModuleTask;
        Module_Task__c testModuleTask_1 = new Module_Task__c(Name = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME,
                Title__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME, Content_URL__c = x7s_Adventure_TestConstants.TEST_URL,
                Resource_Type__c = x7s_Adventure_TestConstants.TEST_RESOURCE_TYPE,Completed__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_Completed,
                Step_Module__c = testStepModule.Id);
        insert testModuleTask_1;
        Module_Task__c testModuleTask_2 = new Module_Task__c(Name = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME,
                Title__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_NAME, Content_URL__c = x7s_Adventure_TestConstants.TEST_URL,
                Resource_Type__c = x7s_Adventure_TestConstants.TEST_RESOURCE_TYPE,Completed__c = x7s_Adventure_TestConstants.TEST_MODULE_TASK_Completed,
                Step_Module__c = testStepModule.Id);
        insert testModuleTask_2;

    }

    @isTest
    public static void x7s_AdventureMyStepModuleWrapperHelperTest(){

        Step_Module__c testModule = [SELECT Id,Adventure_Step__c,title__c,Description_Label__c,Description_URL__c,Tooltip_Description__c,Order__c FROM Step_Module__c LIMIT 1];
        List<Module_Task__c> testModuleTask = [SELECT Id,Completed__c FROM Module_Task__c where Step_Module__c =:testModule.Id];

        x7s_Adventure_StepModuleWrapper TestStepModule = x7s_Adventure_MyStepModuleWrapperHelper.createWrapper(testModule, testModuleTask);
        System.assertEquals(TestStepModule.taskProgress,100);
        System.assertEquals( TestStepModule.completedFlag, true);
        
    }





}