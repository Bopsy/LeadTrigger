/******************************************
//Created By: Gram Bischof
//Last Modified by: Gram bischof {13/02/2020}
//Description: This is the test class of LeadLookupController
//
*******************************************/
@isTest
public class LeadLookupControllerTest {
    
    //Setup Method
    @testSetup
    private static void setupTestRecords() {
        
        Account testAccount = new Account();
        testAccount.name = 'acntName'; 
        insert testAccount;
        
        Contact testcontact = new Contact();
        testcontact.LastName = 'conlastname';
        testcontact.AccountId = testAccount.Id;
        testcontact.Email = 'email@email.com';
        insert testcontact;
        
        Email_Domain__c testemaildomain = new Email_Domain__c();
        testemaildomain.Name = 'http://www.54.com';
        testemaildomain.Account__c = testAccount.Id;
        testemaildomain.Approved__c  = true;
        insert testemaildomain;
        
        Lead testleadobj = new Lead();
        testleadobj.Email = 'email@email.com';
        testleadobj.Status = 'Opportunity';
        testleadobj.LastName = 'lastname';
        testleadobj.Company = 'company';
        insert testleadobj;
    }   
    
    static testMethod void TestGetLeadStatus(){
        //setup
        Account testaccnt = [SELECT Id FROM Account];
        Contact testcont = [SELECT Id FROM Contact];
        Lead testLead = [SELECT Id FROM Lead];
        //Execution
        test.startTest();
        String ReturnLeadStatus = LeadLookupController.getLeadStatus(String.valueOf(testLead.Id));
        test.stopTest();
        //Assertion
        system.assert(ReturnLeadStatus == 'Opportunity');
    }
    
    static testMethod void TestgetContactVal(){
        //Setup
        Account testaccnt = [SELECT Id FROM Account];
        Contact testcont = [SELECT Id FROM Contact];
        Lead testLead = [SELECT Id FROM Lead];
        
        //Execution
        test.startTest();
       // String getcontname = LeadLookupController.getContactVal(String.valueOf(testLead.Id));
        List<Contact> ReturnContact = LeadLookupController.getContactVal(String.valueOf(testLead.Id));
        test.stopTest();
        //Assertion
        system.assert(ReturnContact[0].Name == 'conlastname');
    } 
    static testMethod void TestgetAccntApprove(){
        //Setup
        Account testaccnt = [SELECT Id FROM Account];
        Contact testcont = [SELECT Id FROM Contact];
        Lead testLead = [SELECT Id FROM Lead];
        
        Email_Domain__c testemaildomain = new Email_Domain__c();
        testemaildomain.Name = 'http://www.email.com';
        testemaildomain.Account__c = testaccnt.Id;
        testemaildomain.Approved__c = true;
        insert testemaildomain;
        //Execution
        test.startTest();
       // String getacntname = LeadLookupController.getAccntApprove(String.valueOf(testLead.Id));
         List<Account> returnApproveAcnt = LeadLookupController.getAccntApprove(String.valueOf(testLead.Id));
        test.stopTest();
        //Assertion
        system.assert(returnApproveAcnt[0].Name == 'acntName');
    } 
    
    static testMethod void TestgetselectOptions(){
        //Setup
        Account testaccnt = [SELECT Id FROM Account];
        Contact testcont = [SELECT Id FROM Contact];
        Lead testLead = [SELECT Id FROM Lead];
        Email_Domain__c testdomain = [SELECT Id FROM Email_Domain__c limit 1];
        //Execution
        test.startTest();
        List<String> returnSelectList = LeadLookupController.getselectOptions();
        test.stopTest();
        //Assertion
        system.assert(returnSelectList.size() > 0);
    } 
    
    static testMethod void TestgetContacttypelist(){
        //Setup
        Account testaccnt = [SELECT Id FROM Account];
        Contact testcont = [SELECT Id FROM Contact];
        Lead testLead = [SELECT Id FROM Lead];
        Email_Domain__c testdomain = [SELECT Id FROM Email_Domain__c limit 1];
        //Execution
        test.startTest();
        List<String> returnContactList = LeadLookupController.getContacttypelist();
        test.stopTest();
        //Assertion
        system.assert(returnContactList.size() > 0);
    } 
    
    static testMethod void TestInsertAccntData(){
        //Setup
        Account testaccnt = [SELECT Id, Name FROM Account];
        // Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('FY 16 Account Record Type').getRecordTypeId();
        
        Contact testcont = [SELECT Id FROM Contact];
        Lead testLead = [SELECT Id FROM Lead];
        Email_Domain__c testdomain = [SELECT Id FROM Email_Domain__c limit 1];
        //Execution
        test.startTest();
        Account returntestaccnt = LeadLookupController.InsertAccntData('acntname','FY 16 Account Record Type');
        test.stopTest();
        //Assertion
        system.assert(returntestaccnt != null);
    } 
    
    static testMethod void TestInsertContData(){
        //Setup
        Account testaccnt = [SELECT Id FROM Account];
        //Contact testcont = [SELECT ID FROM Contact];
        Contact testcont = new Contact();
        testcont.LastName = 'conlastname';
        testcont.AccountId = testaccnt.Id;
        testcont.Email = 'email@email.com';
        
        Lead testLead = [SELECT Id FROM Lead];
        Email_Domain__c testdomain = [SELECT Id FROM Email_Domain__c limit 1];
        //Execution
        test.startTest();
        Contact returntestcont = LeadLookupController.InsertContData(testcont,testaccnt);
        test.stopTest();
        //Assertion
        system.assert(returntestcont != null);
    } 
    
    static testMethod void TestfetchAccount(){
        //Setup
        Account testaccnt = [SELECT Id FROM Account];
        Contact testcont = [SELECT Id FROM Contact];
        Lead testLead = [SELECT Id FROM Lead];
        Email_Domain__c testdomain = [SELECT Id FROM Email_Domain__c limit 1];
        //Execution
        test.startTest();
        List<account> getfetchaccnt = LeadLookupController.fetchAccount('acnt',testLead.Id);
        test.stopTest();
        //Assertion
        system.assert(getfetchaccnt != null);
    } 
    
    static testMethod void TestfetchContact(){
        //Setup
        Account testaccnt = [SELECT Id FROM Account];
        Contact testcont = [SELECT Id FROM Contact];
        Lead testLead = [SELECT Id FROM Lead];
        Email_Domain__c testdomain = [SELECT Id FROM Email_Domain__c limit 1];
        //Execution
        test.startTest();
        List<contact> getfetchcontact = LeadLookupController.fetchContact('con',String.valueOf(testaccnt.Id));
        test.stopTest();
        //Assertion
        system.assert(getfetchcontact != null);
    } 
    
    static testMethod void TestConvertLead(){
        //Setup
        Account testaccnt = [SELECT Id FROM Account];
        Contact testcont = [SELECT Id FROM Contact];
        Lead testLead = [SELECT Id FROM Lead];
        Email_Domain__c testdomain = [SELECT Id FROM Email_Domain__c limit 1];
        //Execution
        test.startTest();
        LeadLookupController.ConvertLead(String.valueOf(testLead.Id), String.valueOf(testcont.Id), String.valueOf(testaccnt.Id) , 'Opportunity');
        test.stopTest();
        //Assertion
        Lead testAssertLead = [SELECT Id, IsConverted FROM Lead WHERE id =:testLead.Id];
        system.assert(testAssertLead.IsConverted == true);
    } 
}