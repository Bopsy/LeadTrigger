/*
 * Copyright (c) 2020. 7Summits Inc.
 */
@IsTest
public with sharing class x7s_Adventure_CloneProjectAssignmentTest { 
        

    @isTest
    public static void test_AdventureClonePojectAssignment() {

        //Create test adventure
        Account testAccount = new Account(Name = x7s_Adventure_CloneTestConstants.ACCOUNT_NAME);
        insert testAccount;        


        //Create test adventure
        Adventure__c testAdventure = new Adventure__c(Name = x7s_Adventure_CloneTestConstants.TEST_ADVENTURE_NAME, Title__c = x7s_Adventure_CloneTestConstants.TEST_ADVENTURE_NAME,
        Account__c= testAccount.Id,Template__c =x7s_Adventure_CloneTestConstants.TEST_TEMPLATE_NAME);
        insert testAdventure;
      

        //Create ContentVersion
   
        ContentVersion testContentVersion = new ContentVersion(Title = x7s_Adventure_CloneTestConstants.TEST_CONTENTVERSION_TITLE,PathOnClient = x7s_Adventure_CloneTestConstants.TEST_CONTENTVERSION_PATHONCLIENT,VersionData = x7s_Adventure_CloneTestConstants.TEST_CONTENTVERSION_VERSIONDARA,IsMajorVersion = x7s_Adventure_CloneTestConstants.TEST_CONTENTVERSION_ISMAJORVERSION);
        Insert testContentVersion;

        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:testContentVersion.Id].ContentDocumentId; 
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink(LinkedEntityId = testAdventure.Id,ContentDocumentId = conDocId,shareType = 'V');
        Insert cdl;
        
        //Create test Adventure Step
        Adventure_Step__c testAdventureStep = new Adventure_Step__c(Name = x7s_Adventure_CloneTestConstants.TEST_ADVENTURE_STEP_NAME,
                Title__c = x7s_Adventure_CloneTestConstants.TEST_ADVENTURE_STEP_NAME, Adventure__c = testAdventure.Id,
                Subtitle__c = x7s_Adventure_CloneTestConstants.TEST_ADVENTURE_STEP_SUBTITLE, Description__c = x7s_Adventure_CloneTestConstants.TEST_ADVENTURE_STEP_DESCRIPTION);
        insert testAdventureStep;

        //Create test Step Module
        Step_Module__c testStepModule = new Step_Module__c(Name = x7s_Adventure_CloneTestConstants.TEST_STEP_MODULE_NAME,
                Title__c = x7s_Adventure_CloneTestConstants.TEST_STEP_MODULE_NAME, Adventure_Step__c = testAdventureStep.Id);
        insert testStepModule;

        //Create test Module Task
        Module_Task__c testModuleTaskFirst = new Module_Task__c(Name = x7s_Adventure_CloneTestConstants.TEST_MODULE_TASK_NAME,
                Title__c = x7s_Adventure_CloneTestConstants.TEST_MODULE_TASK_NAME, Content_URL__c = x7s_Adventure_CloneTestConstants.TEST_URL,
                Resource_Type__c = x7s_Adventure_CloneTestConstants.TEST_RESOURCE_TYPE, Step_Module__c = testStepModule.Id,Restrict_to_User__c =x7s_Adventure_CloneTestConstants.TEST_MODULE_TASK_RESTRICTTOUSER);
        insert testModuleTaskFirst;

        Module_Task__c testModuleTaskSecond = new Module_Task__c(Name = x7s_Adventure_CloneTestConstants.TEST_MODULE_TASK_NAME,
        Title__c = x7s_Adventure_CloneTestConstants.TEST_MODULE_TASK_NAME, Content_URL__c = x7s_Adventure_CloneTestConstants.TEST_URL,
        Resource_Type__c = x7s_Adventure_CloneTestConstants.TEST_RESOURCE_TYPE, Step_Module__c = testStepModule.Id,Restrict_to_User__c =x7s_Adventure_CloneTestConstants.TEST_MODULE_TASK_RESTRICTTOUSER);
        insert testModuleTaskSecond;

        Adventure__c testClone = [Select Id,Name,Title__c from Adventure__c where Id =: testAdventure.Id];
        List<Adventure__c> testAdventures = [SELECT Id, Name FROM Adventure__c where Id =:testAdventure.Id]; 
        Integer adventureCount = [SELECT Count() FROM Adventure__c];
        Integer stepsCount = [SELECT Count() FROM Adventure_Step__c];
        Integer moduleCount = [SELECT Count() FROM Step_Module__c];
        Integer tasksCount = [SELECT Count() FROM Module_Task__c];

        Test.startTest();
        x7s_Adventure_CloneProjectAssignment.cloneAdventure(testAdventure.Id);
        System.assertEquals([SELECT Count() FROM Adventure__c],adventureCount+1);
        System.assertEquals([SELECT Count() FROM Adventure_Step__c],stepsCount+1);
        System.assertEquals([SELECT Count() FROM Step_Module__c],moduleCount+1);
        System.assertEquals([SELECT Count() FROM Module_Task__c],tasksCount+2);
        Test.stopTest(); 
 
       
    }
      @isTest
    public static void test_getConfiguration(){
         Test.startTest();
        try{
             x7s_Adventure_Setting__mdt testMdt = x7s_Adventure_CloneProjectAssignment.getConfiguration();
             System.assertEquals(testMdt!=null,true);
        }
        catch(Exception e)
        {
            System.assertEquals(e.getMessage(), 'Script-thrown exception');
        }
        Test.stopTest();
       
    }




}