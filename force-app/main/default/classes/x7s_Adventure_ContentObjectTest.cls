/*
 * Copyright (c) 2020. 7Summits Inc.
 */

@IsTest
private class x7s_Adventure_ContentObjectTest
{

    @testSetup
    static void testSetup() {
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
                Resource_Type__c = x7s_Adventure_TestConstants.TEST_RESOURCE_TYPE, Step_Module__c = testStepModule.Id);
        insert testModuleTask;
    }

    @isTest
    public static void testPeak_ContentObject() {

        List<Adventure__c> testAdventures = [SELECT Id, Name FROM Adventure__c];
        List<Adventure_Step__c> testAdventureSteps = [SELECT Id, Name, title__c, subtitle__c, description__c, Order__c, Icon_Image__c,
                    (SELECT Id FROM ContentDocumentLinks) FROM Adventure_Step__c];

        List<Step_Module__c> testStepModules = [SELECT Id, Name, Adventure_Step__c, title__c,Order__c,
                Description_Label__c,Description_URL__c,Tooltip_Description__c,Task_Progress__c,Completed__c FROM Step_Module__c];

        List<Module_Task__c> testStepModuleTasks = [SELECT Id, Name FROM Module_Task__c];

        x7s_Adventure_StepModuleWrapper testStepWrapper = x7s_Adventure_StepModuleWrapperHelper.createWrapper(testStepModules[0], testStepModuleTasks);
        List<x7s_Adventure_StepModuleWrapper> testWrapperList = new List<x7s_Adventure_StepModuleWrapper>();
        testWrapperList.add(testStepWrapper);

        x7s_Adventure_StepWrapper testWrapper = x7s_Adventure_StepWrapperHelper.createWrapper(testAdventureSteps[0], testWrapperList);
        List<x7s_Adventure_StepWrapper> stepWrapperList = new List<x7s_Adventure_StepWrapper>();
        stepWrapperList.add(testWrapper);

        Test.startTest();

        x7s_Adventure_ContentObject peakContentObject = new x7s_Adventure_ContentObject();
        peakContentObject.adventure = testAdventures[0];
        peakContentObject.adventureStepWrapper = stepWrapperList;

        System.debug('ADVENTURE ==' + peakContentObject.adventureStepWrapper);


        System.assertEquals(peakContentObject.adventure.Name, x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME);
        System.assertEquals(peakContentObject.adventureStepWrapper[0].Id, testAdventureSteps[0].Id);

        Test.stopTest();
    }

}