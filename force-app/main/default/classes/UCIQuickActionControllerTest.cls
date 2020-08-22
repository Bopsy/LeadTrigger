/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  UCIQuickActionControllerTest
*
* @description 	  Test class for UCIQuickActionController.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2018-03-13
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class UCIQuickActionControllerTest {

    static FSR__c mqlRelatedToContact;
    static FSR__c mqlRelatedToLead;
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

    }
    
    static testMethod void UCIQuickActionControllerTest1() {
        setupTestRecords();
        FSR__c mql = [Select Id, contact__r.Name, contact__c, contact__r.account.Id, Lead__c , Lead__r.name from FSR__c limit 1];
        Test.startTest();
        UCIQuickActionController.wrappClass wrap = UCIQuickActionController.getMQLobject(mql.Id);
        system.assertEquals(mql.Contact__c, wrap.Contact);
        system.assertEquals(mql.Lead__c, wrap.Lead);
        Test.stopTest();
    }
}