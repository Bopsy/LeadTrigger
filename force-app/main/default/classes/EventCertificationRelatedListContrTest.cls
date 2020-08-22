/**********************************************************
Created by: Gram Bischof 03/13/2020
Class: EventCertificationRelatedListContrTest
Description: This is the Test class of EventCertificationRelatedListContr
***********************************************************/
@isTest
public class EventCertificationRelatedListContrTest {
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
            Account testAcc2 = new Account(Name = 'Test Enroll Account');
            insert testAcc2;
            
            Contact testCon2 = new Contact(LastName = 'Test Enroll Con', Email = 'test@test.com', AccountId = testAcc2.Id);
            insert testCon2;
            
            Partner_Certification__c testPC = new Partner_Certification__c();
            testPC.Name__c = 'PCName';
            testPC.Account__c = testAcc2.Id;
            testPC.Contact__c = testCon2.Id;
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
        List<EventCertificationRelatedListContr.EventCertificationWrapper> testWrapDetailList = EventCertificationRelatedListContr.getRelatedListRecord(testEvent.Id);
        test.stopTest();
        
        //Assertion
        System.assertEquals(1,testWrapDetailList.size());
        System.assertEquals('Test Enroll Account',testWrapDetailList[0].theAccntName);
        System.assertEquals('Test Enroll Con',testWrapDetailList[0].theContactName);
        System.assertEquals('test@test.com',testWrapDetailList[0].theContactEmail);
        System.assertEquals('Enrolled',testWrapDetailList[0].thePartnerCertStage);
    }
    
    //Test case 2
    @isTest
    public static void getEventDetailsTest1() {
        
        //setup
        Event testEvent = [SELECT Id FROM Event];
        
        Account testAcc2 = new Account(Name = 'Test Enroll Account');
        insert testAcc2;
        
        Contact testCon2 = new Contact(LastName = 'Test Enroll Con', Email = 'test@test1.com', AccountId = testAcc2.Id);
        insert testCon2;
        
        Partner_Certification__c testPC = new Partner_Certification__c();
        testPC.Name__c = 'PCName';
        testPC.Account__c = testAcc2.Id;
        testPC.Contact__c = testCon2.Id;
        testPC.Certification_Stage__c = 'Enrolled';
        insert testPC;
        
        Event_Certification__c testEC = new Event_Certification__c();
        testEC.Status__c = 'Enrolled';
        testEC.Event_ID__c = testEvent.id;
        testEC.Partner_Certification__c = testPC.Id;
        insert testEC;
        
        //Execution
        test.startTest();
        List<EventCertificationRelatedListContr.EventCertificationWrapper> testWrapDetailList = EventCertificationRelatedListContr.getRelatedListRecord(testEvent.Id);
        test.stopTest();
        
        //Assertion
        System.assertEquals(2,testWrapDetailList.size());
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
        List<EventCertificationRelatedListContr.EventCertificationWrapper> testWrapDetailList = EventCertificationRelatedListContr.getRelatedListRecord(testEvent.Id);
        test.stopTest();
        
        //Assertion
        System.assertEquals(1,testWrapDetailList.size());
        System.assertEquals('Test Enroll Account',testWrapDetailList[0].theAccntName);
        System.assertEquals('Test Enroll Con',testWrapDetailList[0].theContactName);
        System.assertEquals('test@test.com',testWrapDetailList[0].theContactEmail);
        System.assertEquals('Completed',testWrapDetailList[0].thePartnerCertStage);
    }
    
    @isTest
    public static void getEventDetailsTest3() {
        
        Event testEvent = [SELECT Id FROM Event];
        
        List<Event_Certification__c> testECList = [SELECT Id FROM  Event_Certification__c WHERE Event_ID__c =: testEvent.Id ];
        //Execution
        test.startTest();
        delete testECList;
        List<EventCertificationRelatedListContr.EventCertificationWrapper> testWrapDetailList = EventCertificationRelatedListContr.getRelatedListRecord(testEvent.Id);
        test.stopTest();
        
        //Assertion
        System.assertEquals(0,testWrapDetailList.size());
    }
}