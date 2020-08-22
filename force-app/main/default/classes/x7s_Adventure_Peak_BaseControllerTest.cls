/*
 * Copyright (c) 2020. 7Summits Inc.
 */

@isTest
public with sharing class x7s_Adventure_Peak_BaseControllerTest
{

    @testSetup static void testSetup() {
        Contact testContact = x7s_Adventure_TestUtils.createTestContact();
    }

    @isTest
    public static void testGetSitePrefix() {
    	system.assert(x7s_Adventure_Peak_BaseController.getSitePrefix() != null);
    }

    // Test finding a user
    @isTest
    public static void testUser(){
         List<Account> accList = testdatafactory.createAccountList(1);
        insert accList;
        List<Contact> testContacts = testdatafactory.createContactList(1);
        testContacts[0].AccountId = accList[0].id;
        insert testContacts;
        Profile p1 = [SELECT Id FROM Profile WHERE Name='**Partner Community User Login**']; 
        User testUser = new User(Alias = 'TU0001', Email='TUser0001@testorg.com', 
                                 EmailEncodingKey='UTF-8', LastName='TUser0001', LanguageLocaleKey='en_US', 
                                 LocaleSidKey='en_US', ProfileId = p1.Id, ContactId=testContacts[0].Id,
                                 TimeZoneSidKey='America/Los_Angeles', UserName='TUser0001@testorg.com');
        
        
        insert testUser;

        test.startTest();

        System.runAs(testUser) {
            System.assertEquals(false, x7s_Adventure_Peak_BaseController.isGuestUser());
        }

        Test.stopTest();

    }

    // Test running as a guest
    @isTest
    public static void testGuest(){
        // Set up and run as guest user 
        User guestUser = x7s_Adventure_TestUtils.createGuestUser();

        System.runAs(guestUser) {
            System.assertEquals(true, x7s_Adventure_Peak_BaseController.isGuestUser());
        }
    }

    // test current year
    @isTest
    public static void testGetYear() {
        x7s_Adventure_Peak_BaseController currentYear = new x7s_Adventure_Peak_BaseController();

        Integer reqYear = x7s_Adventure_Peak_BaseController.getYear();
        System.assert(reqYear != null);
    }

}