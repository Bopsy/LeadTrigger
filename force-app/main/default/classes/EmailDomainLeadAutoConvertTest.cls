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
private class EmailDomainLeadAutoConvertTest {

    static testmethod void BatchConvertEmailDomainLead() {
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

        User au = new User();
        au.ProfileId = ap.Id;
        au.Username = System.now().getTime() + 'eloqua@test.com';
        au.Alias = 'eloqua';
        au.Email='eloqua@test-12345.com';
        au.EmailEncodingKey='UTF-8';
        au.Firstname='Eloqua';
        au.Lastname='Marketing';
        au.LanguageLocaleKey='en_US';
        au.LocaleSidKey='en_US';
        au.TimeZoneSidKey='America/Chicago';
        insert au;
        
        List<Account> a = new List<Account>();
        a.add(new Account(
            Name = 'Test Account1',
            OwnerId = u.Id,
            Employee_Size__c = '0 - 50',
            Website = 'http://www.checkboxtest.com'
        ));
        a.add(new Account(
            Name = 'Test Account2',
            OwnerId = u.Id,
            Employee_Size__c = '0 - 50',
            Website = 'http://www.checkboxtest1.com'
        ));
        insert a;

        Email_Domain__c e = new Email_Domain__c(
        	Name = 'checkboxtest.com',
        	Account__c = a[0].Id,
        	Approved__c = false
        );
        insert e;
        
        List<Lead> l = new List<Lead>();
        l.add(new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test12345@checkboxtest.com',
            LeadSource = 'Full Service Request',
            Status = 'Open',
            OwnerId = u.Id
        ));
        l.add(new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test12345@npctest.com',
            LeadSource = 'Full Service Request',
            Status = 'Open',
            ISO_Country_Code__c = 'EMEA',
            NPC_Date_5__c = Date.today(),
            OwnerId = u.Id
        ));
        l.add(new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test12345@npctest.com',
            LeadSource = 'Full Service Request',
            Status = 'Open',
            ISO_Country_Code__c = 'APAC',
            NPC_Date_5__c = Date.today(),
            OwnerId = u.Id
        ));
        l.add(new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test12345@npctest.com',
            LeadSource = 'Full Service Request',
            Status = 'Responded',
            ISO_Country_Code__c = 'TEST',
            NPC_Date_5__c = Date.today(),
            OwnerId = u.Id
        ));
        insert l;

		DoNotAutoConvert__c dnac = new DoNotAutoConvert__c(Name = ap.Name, Profile_ID__c = ap.Id);
		insert dnac;
		
		e.Approved__c = true;
        update e;
		
        Test.startTest();
        EmailDomainLeadAutoConvert b = new EmailDomainLeadAutoConvert();
        b.processRecordsOlderThan = 1; // Use a future time so that test records will process
		Database.executeBatch(b, 5);
        Test.stopTest();
    }

    static testmethod void BatchConvertSpecificEmailDomainLead() {
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

        User au = new User();
        au.ProfileId = ap.Id;
        au.Username = System.now().getTime() + 'eloqua@test.com';
        au.Alias = 'eloqua';
        au.Email='eloqua@test-12345.com';
        au.EmailEncodingKey='UTF-8';
        au.Firstname='Eloqua';
        au.Lastname='Marketing';
        au.LanguageLocaleKey='en_US';
        au.LocaleSidKey='en_US';
        au.TimeZoneSidKey='America/Chicago';
        insert au;
        
        List<Account> a = new List<Account>();
        a.add(new Account(
            Name = 'Test Account1',
            OwnerId = u.Id,
            Employee_Size__c = '0 - 50',
            Website = 'http://www.checkboxtest.com'
        ));
        a.add(new Account(
            Name = 'Test Account2',
            OwnerId = u.Id,
            Employee_Size__c = '0 - 50',
            Website = 'http://www.checkboxtest1.com'
        ));
        insert a;

        Email_Domain__c e = new Email_Domain__c(
        	Name = 'checkboxtest.com',
        	Account__c = a[0].Id,
        	Approved__c = false
        );
        insert e;
        
        List<Lead> l = new List<Lead>();
        l.add(new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test12345@checkboxtest.com',
            LeadSource = 'Full Service Request',
            Status = 'Open',
            OwnerId = u.Id
        ));
        l.add(new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test12345@npctest.com',
            LeadSource = 'Full Service Request',
            Status = 'Open',
            ISO_Country_Code__c = 'EMEA',
            NPC_Date_5__c = Date.today(),
            OwnerId = u.Id
        ));
        l.add(new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test12345@npctest.com',
            LeadSource = 'Full Service Request',
            Status = 'Open',
            ISO_Country_Code__c = 'APAC',
            NPC_Date_5__c = Date.today(),
            OwnerId = u.Id
        ));
        l.add(new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test12345@npctest.com',
            LeadSource = 'Full Service Request',
            Status = 'Responded',
            ISO_Country_Code__c = 'TEST',
            NPC_Date_5__c = Date.today(),
            OwnerId = u.Id
        ));
        insert l;

		DoNotAutoConvert__c dnac = new DoNotAutoConvert__c(Name = ap.Name, Profile_ID__c = ap.Id);
		insert dnac;
		
		e.Approved__c = true;
        update e;
        
        Set<String> emailDomains = new Set<String>();
        emailDomains.add(e.name);
		
        Test.startTest();
        EmailDomainLeadAutoConvert b = new EmailDomainLeadAutoConvert(emailDomains);
        b.processRecordsOlderThan = 1; // Use a future time so that test records will process
		Database.executeBatch(b, 5);
        Test.stopTest();
    }
}