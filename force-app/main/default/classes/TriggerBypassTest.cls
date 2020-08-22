/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           TriggerBypassTest
*
* @description    TriggerBypassTest
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu     <jayu@twilio.com>
* @modifiedBy     Jason Yu     <jayu@twilio.com>
* @version        1.0
* @created        2019-08-23
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class TriggerBypassTest {
    static testMethod void ensure_User_Bypasses_Contact_Trigger(){
        Trigger_Bypass_Settings__c trigBypass = new Trigger_Bypass_Settings__c(SetupOwnerId = UserInfo.getUserId(), 
                                                                               Contact__c = TRUE);
        insert trigBypass;
        
        Account acc = new Account();
        acc.name = 'AccountTest';
        acc.Account_SID__c = 'Inactive';
        insert acc;
        
        Account_SID__c aSID = new Account_SID__c();
        aSID.name = 'SID';
        aSID.Account__c = acc.id;
        aSID.OwnerUser_SID__c = '1234567';
        aSID.Account_SID__c = '1234567SID';
        aSID.OwnerUser_Email_Address__c = 'cont@xyz.com';
        insert aSID;
        
        acc.Account_SID__c = aSID.Account_SID__c;
        update acc;
        
        Contact testCont = new Contact(LastName = 'TestCont');
        insert testCont;
        
        testCont.Account_SID__c = aSID.Id;
        test.startTest();
        update testCont;
        test.stopTest();
        
        Contact reviewCont = [SELECT Id, AccountId FROM Contact WHERE Id = :testCont.id];
        System.assertEquals(null, reviewCont.AccountId);
    }
    static testMethod void ensure_User_Does_Not_Bypass_Contact_Trigger(){
        Account acc = new Account();
        acc.name = 'AccountTest';
        acc.Account_SID__c = 'Inactive';
        insert acc;
        
        Account_SID__c aSID = new Account_SID__c();
        aSID.name = 'SID';
        aSID.Account__c = acc.id;
        aSID.OwnerUser_SID__c = '1234567';
        aSID.Account_SID__c = '1234567SID';
        aSID.OwnerUser_Email_Address__c = 'cont@xyz.com';
        insert aSID;
        
        acc.Account_SID__c = aSID.Account_SID__c;
        update acc;
        
        Contact testCont = new Contact(LastName = 'TestCont',
                                       Email = 'testCont@AccountTest.com');
        Contact testCont2 = new Contact(LastName = 'TestCont2',
                                       Email = 'testCont2@AccountTest.com',
                                       AccountId = acc.Id);
        insert testCont;
        insert testCont2;
        
        testCont.Account_SID__c = aSID.Id;
        test.startTest();
        update testCont;
        test.stopTest();
        
        Contact reviewCont = [SELECT Id, AccountId FROM Contact WHERE Id = :testCont.id];
        System.assertNotEquals(null, reviewCont.AccountId);
    }
    
    static testMethod void ensure_User_Bypasses_Lead_Trigger(){
        Trigger_Bypass_Settings__c trigBypass = new Trigger_Bypass_Settings__c(SetupOwnerId = UserInfo.getUserId(), 
                                                                               Lead__c = TRUE);
        insert trigBypass;
        
        Lead testLead1 = new Lead(LastName = 'Test1',
                                  Company = 'Test Company',
                                  Email = 'testDuplicateEmail@testcompany.com',
                                  HasOptedOutOfEmail = TRUE);
        insert testLead1;
        
        Lead testLead2 = new Lead(LastName = 'Test2',
                                  Company = 'Test Company',
                                  Email = 'testDuplicateEmail@testcompany.com');
        test.startTest();
        insert testLead2;
        test.stopTest();
        
        Lead reviewLead = [SELECT HasOptedOutOfEmail FROM Lead WHERE Id = :testLead2.Id];
        System.assertEquals(FALSE, reviewLead.HasOptedOutOfEmail);
    }
    
    static testMethod void ensure_User_Does_Not_Bypass_Lead_Trigger(){
        Lead testLead1 = new Lead(LastName = 'Test1',
                                  Company = 'Test Company',
                                  Email = 'testDuplicateEmail@testcompany.com',
                                  HasOptedOutOfEmail = TRUE);
        insert testLead1;
        
        Lead testLead2 = new Lead(LastName = 'Test2',
                                  Company = 'Test Company',
                                  Email = 'testDuplicateEmail@testcompany.com');
        test.startTest();
        insert testLead2;
        test.stopTest();
        
        Lead reviewLead = [SELECT HasOptedOutOfEmail FROM Lead WHERE Id = :testLead2.Id];
        System.assertEquals(TRUE, reviewLead.HasOptedOutOfEmail);
    }
}