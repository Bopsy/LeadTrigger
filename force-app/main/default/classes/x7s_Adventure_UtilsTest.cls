/*
 * Copyright (c) 2020. 7Summits Inc.
 */
@isTest
public with sharing class x7s_Adventure_UtilsTest
{

    @testSetup
    static void testSetup() {
        Contact testContact = x7s_Adventure_TestUtils.createTestContact();
    }

    // Test building a formatted string from a set of strings
    @isTest
    public static void testBuildStringFromSet(){
        Set<String> sourceSet = new Set<String>();
        sourceSet.add('Hello');
        sourceSet.add('There');
        system.assertEquals('Hello, There', x7s_Adventure_Utils.buildStringFromSet(sourceSet)); // test that this is building a string from a set properly
    }

  

    @isTest
    public static void testIsNullOrEmpty() {
        // Assert return true for empty list
        List<String> stringList = new List<String>();
        system.assertEquals(x7s_Adventure_Utils.isNullOrEmpty(stringList),true);

        // Assert return false for not empty list
        stringList.add(x7s_Adventure_TestConstants.ACCOUNT_NAME);
        system.assertEquals(x7s_Adventure_Utils.isNullOrEmpty(stringList),false);
    }

    @isTest
    public static void testGetSitePrefix() {
        system.assert(x7s_Adventure_Utils.getSitePrefix() != null);
    }

    @isTest
    public static void testCreateAttachment() {
        // Set up and run as a standard user
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
        
        Attachment testAttachment = x7s_Adventure_TestUtils.createAttachment(testUser.Id);
        system.assert(testAttachment != null);
    }
    
    @isTest
    public static void testGetPicklistValues(){
        List<String> options = x7s_Adventure_Utils.getPicklistValues('User','LanguageLocaleKey');
        System.assert(options.size()>0);
    }

    @isTest
    public static void testCreateListFromMultiPicklist(){

        String multiPicklistString = 'string1;string2;string3';

        List<String> multiPicklistList = x7s_Adventure_Utils.createListFromMultiPicklist(multiPicklistString);

        system.assertEquals(multiPicklistList.get(0), 'string1');
        system.assertEquals(multiPicklistList.get(1), 'string2');
        system.assertEquals(multiPicklistList.get(2), 'string3');

    }

    @isTest
    public static void testDoesStringContainListItem(){

        List<String> compareList = new List<String>();
        compareList.add('string1');
        compareList.add('string2');

        //Assert list contains target string
        system.assert(x7s_Adventure_Utils.doesStringContainListItem(compareList, 'string1'));

        //Assert list does not contain target string
        system.assert(!x7s_Adventure_Utils.doesStringContainListItem(compareList, 'string3') );
    }

    @isTest
    public static void testGetYear() {
        x7s_Adventure_Utils currentYear = new x7s_Adventure_Utils();

        Integer reqYear = x7s_Adventure_Utils.getYear();
        System.assert(reqYear != null);
    }
    @isTest
    public static void testGetUSer1() {
      
        User newUser = x7s_Adventure_Utils.getUSer();
        System.assert(newUser != null);
    }
     @isTest
     static void testGeustUSer1() {
      
       Boolean test = x7s_Adventure_Utils.isGuestUser();
        System.assert(test != null);
    }
}