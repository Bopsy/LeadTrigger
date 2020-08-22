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
private class BatchLinkAccountToAccountSIDTest {

    static testmethod void BatchLinkAccountToAccountSID() {
		Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
		insert f;

        Profile p = [Select Id, Name from Profile where name = 'Standard User'];
        Profile ap = [Select Id, Name from Profile where name = 'System Administrator'];
        
        User u = new User();
        u.ProfileId = p.Id;
        u.Username = System.now().getTime() + 'test@test.com';
        u.Alias = 'testtest';
        u.Email='test@test-lead-autoconvert-12345.com';
        u.EmailEncodingKey='UTF-8';
        u.Firstname='Test';
        u.Lastname='Test';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.TimeZoneSidKey='America/Chicago';
        insert u;

        List<Account> a = new List<Account>();
        a.add(new Account(
            Name = 'Test Account1',
            OwnerId = u.Id,
            Employee_Size__c = '0 - 50',
            Website = 'http://www.linkaccountsidtest1.com'
        ));
        a.add(new Account(
            Name = 'Test Account2',
            OwnerId = u.Id,
            Employee_Size__c = '0 - 50',
            Website = 'http://www.linkaccountsidtest2.com'
        ));
        insert a;

        List<Email_Domain__c> e = new List<Email_Domain__c>();
        // Email domain approved
        e.add(new Email_Domain__c(
        	Name = 'linkaccountsidtest1.com',
        	Account__c = a[0].Id,
        	Approved__c = true
        ));
        // Email domain not approved
        e.add(new Email_Domain__c(
        	Name = 'linkaccountsidtest2.com',
        	Account__c = a[0].Id,
        	Approved__c = false
        ));
        insert e;
        
        List<Account_SID__c> s = new List<Account_SID__c>();
        // Email domain approved
        s.add(new Account_SID__c(
	        Name = 'SID-1234567890',
	        OwnerUser_SID__c = '1234567890',
	        Account_SID_Status__c = 'ACTIVE',
	        OwnerUser_Email_Address__c = 'test12345@linkaccountsidtest1.com'
	        
        ));
        // Email domain approved by Account SID record not active
        s.add(new Account_SID__c(
	        Name = 'SID-2345678901',
	        OwnerUser_SID__c = '2345678901',
	        Account_SID_Status__c = 'INACTIVE',
	        OwnerUser_Email_Address__c = 'test12345@linkaccountsidtest1.com'
	        
        ));
        // Email domain not approved
        s.add(new Account_SID__c(
	        Name = 'SID-3456789012',
	        OwnerUser_SID__c = '3456789012',
	        Account_SID_Status__c = 'ACTIVE',
	        OwnerUser_Email_Address__c = 'test12345@linkaccountsidtest2.com'
	        
        )); 
        // Freemail Test
        s.add(new Account_SID__c(
	        Name = 'SID-3456789012',
	        OwnerUser_SID__c = '3456789012',
	        Account_SID_Status__c = 'ACTIVE',
	        OwnerUser_Email_Address__c = 'test12345@gmail.com'
	        
        )); 
        insert s;

        Test.startTest();
		Database.executeBatch(new BatchLinkAccountToAccountSID());
        Test.stopTest();
    }
}