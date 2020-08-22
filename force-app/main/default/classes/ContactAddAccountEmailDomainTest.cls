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
private class ContactAddAccountEmailDomainTest {

    static testMethod void contactCreateWithEmail() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;

        Account a = new Account(Name = 'Test Account 1', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert a;

        Email_Domain__c e = new Email_Domain__c(Name = 'test-account-12345.com', Account__c = a.Id);
        insert e;
        
        Contact c = new Contact(LastName = 'Test Contact 1', AccountId = a.Id, Email = 'test@test-account-54321.com');

        Test.startTest();
        insert c;   
        Test.stopTest();   
    }

    static testMethod void contactCreateWithPreferredEmail() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;

        Account a = new Account(Name = 'Test Account 1', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert a;

        Email_Domain__c e = new Email_Domain__c(Name = 'test-account-12345.com', Account__c = a.Id);
        insert e;
        
        Contact c = new Contact(LastName = 'Test Contact 1', AccountId = a.Id, Preferred_Email__c = 'test@test-account-54321.com');

        Test.startTest();
        insert c;   
        Test.stopTest();   
    }
    
    static testMethod void contactUpdateEmail() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;

        Account a = new Account(Name = 'Test Account 1', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert a;

        Email_Domain__c e = new Email_Domain__c(Name = 'test-account-12345.com', Account__c = a.Id);
        insert e;
        
        Contact c = new Contact(LastName = 'Test Contact 1');
        insert c;   

        Test.startTest();
        c.AccountId = a.Id;
        c.Email = 'test@test-account-54321.com'; 
        update c;   
        Test.stopTest();   
    }

    static testMethod void contactUpdatePreferredEmail() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;

        Account a = new Account(Name = 'Test Account 1', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert a;

        Email_Domain__c e = new Email_Domain__c(Name = 'test-account-12345.com', Account__c = a.Id);
        insert e;
        
        Contact c = new Contact(LastName = 'Test Contact 1');
        insert c;   

        Test.startTest();
        c.AccountId = a.Id;
        c.Preferred_Email__c = 'test@test-account-54321.com';
        update c;   
        Test.stopTest();   
    }

    static testMethod void contactWithAlreadyAssociatedEmail() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;

        Account a = new Account(Name = 'Test Account 1', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert a;

        Email_Domain__c e = new Email_Domain__c(Name = 'test-account-12345.com', Account__c = a.Id);
        insert e;
        
        Contact c = new Contact(LastName = 'Test Contact 1', AccountId = a.Id, Email = 'test@test-account-12345.com');

        Test.startTest();
        insert c;   
        Test.stopTest();   
    }

    
}