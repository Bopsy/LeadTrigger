/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class MQLActivitiesControllerTest {
    static FSR__c mqlRelatedToContact;
    static FSR__c mqlRelatedToLead;
    static List<Task> tskList;

    static testMethod void mqlRelatedToContact() {
        setupTestRecords();
        System.debug('TEST METHOD: mqlRelatedToContact');

        Apexpages.StandardController con = new ApexPages.StandardController(mqlRelatedToContact);
        MQLActivitiesController obj = new MQLActivitiesController(con);

        Test.startTest();
        List<ActivityRecord> activities = obj.activities;
        System.assertEquals(2,activities.size());
        Test.stopTest();

    }

    static testMethod void mqlRelatedToLead() {
        setupTestRecords();
        System.debug('TEST METHOD: mqlRelatedToLead');

        Apexpages.StandardController con = new ApexPages.StandardController(mqlRelatedToLead);
        MQLActivitiesController obj = new MQLActivitiesController(con);

        Test.startTest();
        List<ActivityRecord> activities = obj.activities;
        System.assertEquals(2,activities.size());
        Test.stopTest();
    }

    static void setupTestRecords() {
        String timeZoneKey = 'America/Los_Angeles';
        User user = TestDataFactory.createUser();
        user.TimeZoneSidKey = timeZoneKey;
        insert user;

        Account acc = new Account(Name = 'Test Acc', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert acc;

        Contact con = new Contact(LastName = 'TestContact', AccountId = acc.Id);
        insert con;

        Lead ld = new Lead(LastName = 'TestLead', Company = 'Test Company');
        insert ld;

        List<FSR__c> mqlList = TestDataFactory.createFSRList(2);
        mqlRelatedToContact = mqlList[0];
        mqlRelatedToContact.Contact__c = con.Id;

        mqlRelatedToLead = mqlList[1];
        mqlRelatedToLead.Lead__c = ld.Id;
        insert mqlList;

        Task contactTsk1 = new Task(WhoId = con.Id, WhatId = acc.Id, Subject = 'Email: contact test', ActivityDate = date.today().addDays(1), Status = 'Not Started');
        Task contactTsk2 = new Task(WhoId = con.Id, WhatId = acc.Id, Subject = 'Call: contact test', ActivityDate = date.today().addDays(-1), Status = 'Completed');
        Task leadTsk1 = new Task(WhoId = ld.Id, Subject = 'Email: lead test', ActivityDate = date.today().addDays(1), Status = 'Not Started');
        Task leadTsk2 = new Task(WhoId = ld.Id, Subject = 'Call: lead test', ActivityDate = date.today().addDays(-1), Status = 'Completed');
        tskList = new List<Task>{ contactTsk1, contactTsk2, leadTsk1, leadTsk2 };
        insert tskList;

    }
}