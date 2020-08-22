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
private class NPCLeadAutoConvertTest {

    static testmethod void BatchConvertNPCLead() {
		Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
		insert f;

        Profile p = [Select Id from Profile where name = 'Standard User'];
        Profile ap = [Select Id from Profile where name = 'System Administrator'];
        
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
        	Approved__c = true
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

        Map<Id,Lead> npcLeadMap = new Map<Id,Lead>();
        for (Lead x : l) { npcLeadMap.put(x.Id, x);}
        
        List<NPC_Routing__c> npc = new List<NPC_Routing__c>();
        npc.add(new NPC_Routing__c(Name = 'Other', ISO_Country_Code__c = 'OTHER', User_ID__c = u.Id));
        npc.add(new NPC_Routing__c(Name = 'EMEA', ISO_Country_Code__c = 'EMEA', User_ID__c = u.Id));
        insert npc;
        
        Test.startTest();
        NPCLeadAutoConvert n = new NPCLeadAutoConvert();
        n.processRecordsOlderThan = 1; // Use a future time so that test records will process
		Database.executeBatch(n, 5);
        Test.stopTest();
    }
}