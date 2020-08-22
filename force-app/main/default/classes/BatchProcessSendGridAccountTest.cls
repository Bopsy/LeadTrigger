@isTest
private class BatchProcessSendGridAccountTest {

	private static testMethod void testBatch() {
        Account testAccountWithEmailDomain = new Account(Name = 'test1');
        Account testAccountWithoutEmailDomain  = new Account(Name = 'test2');
        Account testAccountWithContact = new Account(Name = 'test3');
        insert new List<Account>{testAccountWithEmailDomain, testAccountWithoutEmailDomain, testAccountWithContact};
        
        Contact testContact = new Contact (AccountId = testAccountWithContact.Id, Email = 'tester@testcontact.com', LastName = 'Tester');
        insert testContact;
        
        Email_Domain__c testEmailDomain = new Email_Domain__c(Account__c = testAccountWithEmailDomain.Id, Name = 'tester.com', Unique_Name__c = 'tester.com');
        insert testEmailDomain;
        
        SendGrid_Account__c testSGAccountWithMatchEmail = new SendGrid_Account__c(SendGrid_Account_Name__c = 'tester', Billing_Email_Domain__c = 'tester.com', SendGrid_User_Id__c = '1234', MRR__c = 20);
        SendGrid_Account__c testSGAccountWithoutMatchEmail = new SendGrid_Account__c(SendGrid_User_Id__c = '12345', SendGrid_Account_Name__c = 'new SG account', Billing_Country__c = 'United States', SendGrid_Account_Website__c = 'stupidTester.com', Backend_Email_Domain__c = 'tester2.com', Billing_Email_Domain__c = 'tester1.com');
        SendGrid_Account__c testSGAccountWithContactMatchEmail = new SendGrid_Account__c(SendGrid_Account_Name__c = 'tester2', SendGrid_User_Id__c = '123456', SendGrid_Backend_Contact_Email__c = 'tester@testcontact.com');
        SendGrid_Account__c testSGAccountWithMRR = new SendGrid_Account__c(SendGrid_Account_Name__c = 'tester23', Billing_Email_Domain__c = 'test.com', SendGrid_User_Id__c = '1234', MRR__c = 20);
        insert new List<SendGrid_Account__c> {testSGAccountWithMatchEmail, testSGAccountWithoutMatchEmail, testSGAccountWithContactMatchEmail, testSGAccountWithMRR};
        
        insert new Free_Email_Domains__c(Name = 'test.com');
        
        test.startTest();
            Database.executeBatch(new BatchProcessSendGridAccount());
        test.stopTest();
	}

}