/**********************************************************
//Created by: Gram Bischof 03/13/2020
//Class: EventRegStatsControllerTest
//Description: This is the Test class of EventRegStatsController
***********************************************************/
@isTest
public class EventRegStatsControllerTest {
    @testSetup
    public static void testSetup() {
        Account testAcct = new Account(Name = 'Test Account');
        insert testAcct;
        
        Contact testCon = new Contact(LastName = 'Test Con', AccountId = testAcct.Id);
        insert testCon;
        
        Event testEvent = new Event(WhatId = testAcct.Id, 
                                    Subject = 'Email: apex test', 
                                    StartDateTime = date.today().addDays(1), 
                                    Type = 'Class',
                                    Enrollment_Limit__c = 2,
                                    EndDateTime = date.today().addDays(1));
        insert testEvent;
        
        User testUSER = new user();
        testUSER.LastName = 'Test User 1';
        testUSER.Email = 'testUserForCom@test39.com';
        testUSER.ContactId = testCon.Id;
        testUSER.Alias = 'TestCom';
        testUSER.Username = 'testUserForCom@test39.com';
        testUSER.CommunityNickname = 'testComUser';
        testUSER.LocaleSidKey = 'en_US';
        testUSER.TimeZoneSidKey = 'GMT';
        testUSER.profileId = [SELECT Id FROM Profile WHERE Name='**Partner Community User Login**'].Id;
        testUSER.LanguageLocaleKey = 'en_US';
        testUSER.EmailEncodingKey = 'UTF-8';
        testUSER.UserPreferencesLightningExperiencePreferred = false;
        
        System.runAs(testUSER) {
            Partner_Certification__c testPC = new Partner_Certification__c();
            testPC.Name__c = 'PCName';
            testPC.Certification_Stage__c = 'Enrolled';
            insert testPC;
            
            Event_Certification__c testEC = new Event_Certification__c();
            testEC.Status__c = 'Enrolled';
            testEC.Event_ID__c = testEvent.id;
            testEC.Partner_Certification__c = testPC.Id;
            insert testEC;
        }
    }
    
    //Test case 1
    @isTest
    public static void getEventDetailsTest() {
        Event testEvent = [SELECT Id FROM Event];
        
        //Execution
        test.startTest();
        EventRegStatsController.wrapEventDetails testWrapDetail = EventRegStatsController.getEventDetails(testEvent.Id);
        test.stopTest();
        
        //Assertion
        System.assertEquals('1',testWrapDetail.remainingSeats);
        System.assertEquals(1,testWrapDetail.totalRegistered);
        System.assertEquals(0,testWrapDetail.certificationsCompleted);
    }
    
    //Test case 2
    @isTest
    public static void getEventDetailsTest1() {
        
        //setup
        Event testEvent = [SELECT Id FROM Event];
        
        Partner_Certification__c testPC = new Partner_Certification__c();
        testPC.Name__c = 'PCName';
        testPC.Certification_Stage__c = 'Enrolled';
        insert testPC;
        
        Event_Certification__c testEC = new Event_Certification__c();
        testEC.Status__c = 'Enrolled';
        testEC.Event_ID__c = testEvent.id;
        testEC.Partner_Certification__c = testPC.Id;
        insert testEC;
        
        //Execution
        test.startTest();
        EventRegStatsController.wrapEventDetails testWrapDetail = EventRegStatsController.getEventDetails(testEvent.Id);
        test.stopTest();
        
        //Assertion
        System.assertEquals('0',testWrapDetail.remainingSeats);
        System.assertEquals(2,testWrapDetail.totalRegistered);
        System.assertEquals(0,testWrapDetail.certificationsCompleted);
    }
    
    //Test case 3
    @isTest
    public static void getEventDetailsTest2() {
        
        Event testEvent = [SELECT Id FROM Event];
        
        Event_Certification__c testEC = [SELECT Id, Partner_Certification__c FROM  Event_Certification__c WHERE Event_ID__c =: testEvent.Id limit 1];
        
        Partner_Certification__c testPC = [SELECT Id, Certification_Stage__c FROM Partner_Certification__c WHERE Id =: testEC.Partner_Certification__c];
        
        testPC.Certification_Stage__c = 'Completed'; 
        //Execution
        test.startTest();
        update testPC;
        EventRegStatsController.wrapEventDetails testWrapDetail = EventRegStatsController.getEventDetails(testEvent.Id);
        test.stopTest();
        
        //Assertion
        System.assertEquals(1,testWrapDetail.certificationsCompleted);
        System.assertEquals(1,testWrapDetail.totalRegistered);
        System.assertEquals('1',testWrapDetail.remainingSeats);
    }
    
    @isTest
    public static void getEventDetailsTest3() {
        
        Event testEvent = [SELECT Id FROM Event];
        
        List<Event_Certification__c> testECList = [SELECT Id FROM  Event_Certification__c WHERE Event_ID__c =: testEvent.Id ];
        //Execution
        test.startTest();
        delete testECList;
        EventRegStatsController.wrapEventDetails testWrapDetail = EventRegStatsController.getEventDetails(testEvent.Id);
        test.stopTest();
        
        //Assertion
        System.assertEquals(0,testWrapDetail.certificationsCompleted);
        System.assertEquals(0,testWrapDetail.totalRegistered);
        System.assertEquals('2',testWrapDetail.remainingSeats);
    }
}