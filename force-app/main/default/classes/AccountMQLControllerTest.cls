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
private class AccountMQLControllerTest {
    static Account acc;
    static List<FSR__c> mqlList;

    static testMethod void pageLoad() {
        setupTestRecords();
        Apexpages.StandardController con = new ApexPages.StandardController(acc);
        AccountMQLController obj = new AccountMQLController(con);
        System.debug('TEST METHOD: pageLoad');
    }

    static testMethod void toggleSort() {
        setupTestRecords();
        Apexpages.StandardController con = new ApexPages.StandardController(acc);
        AccountMQLController obj = new AccountMQLController(con);
        obj.sortField = 'Name';
        List<FSR__c> fsrList = obj.mqlRelatedList;
        String field = obj.sortField;
        obj.toggleSort();
        fsrList = obj.mqlRelatedList;
    }

    static void setupTestRecords() {
        String timeZoneKey = 'America/Los_Angeles';
        User user = TestDataFactory.createUser();
        user.TimeZoneSidKey = timeZoneKey;
        insert user;

        acc = new Account(Name = 'Test Acc', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert acc;

        Contact con = new Contact(LastName = 'TestContact', AccountId = acc.Id);
        insert con;

        List<FSR__c> mqlList = TestDataFactory.createFSRList(5);
        for(FSR__c mql :mqlList) {
            mql.Contact__c = con.Id;
        }
        insert mqlList;
    }
}