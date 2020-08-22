@isTest
public with sharing class Peak_BaseControllerTest {

    @testSetup static void testSetup() {
        Contact testContact = Peak_TestUtils.createTestContact();
    }

    @isTest
    public static void testGetSitePrefix() {
    	system.assert(Peak_BaseController.getSitePrefix() != null);
    }

    // Test finding a user
    @isTest
    public static void testUser(){
        List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];

        User testUser = Peak_TestUtils.createStandardUserNoContact();

        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        }catch(Exception e){
            testUser.ContactId = NULL;
            insert testUser;
        }

        test.startTest();

        System.runAs(testUser) {
            System.assertEquals(false,Peak_BaseController.isGuestUser());
        }

        Test.stopTest();

    }

    // Test running as a guest
    @isTest
    public static void testGuest(){
        // Set up and run as guest user 
        User guestUser = Peak_TestUtils.createGuestUser();

        System.runAs(guestUser) {
            System.assertEquals(true,Peak_BaseController.isGuestUser());
        }
    }

}