/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  EmailDomainTriggerHandlerTest
*
* @description 	  Test class that contains the unit test related to email domain object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2018-01-28
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class EmailDomainTriggerHandlerTest {
    
    //Method to cover positive test case
    static testmethod void EmailDomainTriggerHandlerPositiveCase(){
        Email_Domain_Blacklist__c objBlacklistProfile = new Email_Domain_Blacklist__c(Name = 'System Admin (Custom)');
        insert objBlacklistProfile;
        
        Email_Domain_Blacklist__c objBlacklistRole = new Email_Domain_Blacklist__c(Name = 'Sales Operations');
        insert objBlacklistRole;
        
        Profile systemAdm = [Select Id, Name from Profile where name = 'System Administrator'];
        
        User user1 = new user();
        user1.ProfileId = systemAdm.Id;
        user1.Username = System.now().getTime() + 'test@test.com';
        user1.Alias = 'testtest';
        user1.Email='test@test-emaildomain.com';
        user1.EmailEncodingKey='UTF-8';
        user1.Firstname='Test';
        user1.Lastname='Test';
        user1.LanguageLocaleKey='en_uS';
        user1.LocaleSidKey='en_US';
        user1.TimeZoneSidKey='America/Chicago';
        insert user1;
        
        test.startTest();
        system.runAs(user1){
            List<Account> lstAcnt = new List<Account>();
            lstAcnt.add(new Account(
                Name = 'Test Account1',
                OwnerId = user1.Id
            ));
            lstAcnt.add(new Account(
                Name = 'Test Account2',
                OwnerId = user1.Id
            ));
            insert lstAcnt;
            Email_Domain__c ed1 = new Email_Domain__c(
                Name = 'test7.com',
                Account__c = lstAcnt[0].Id
            );
            insert ed1;
            Email_Domain__c emailDomain = [Select Id,approved__c from Email_Domain__c where name='test7.com'];
            system.assert(emailDomain.Approved__c==true);
        }
        
        test.stopTest();
        
    }
    
    //Method to cover negative test case
    static testmethod void EmailDomainTriggerHandlerNegativeCase(){
        Email_Domain_Blacklist__c objBlacklistProfile = new Email_Domain_Blacklist__c(Name = 'System Admin (Custom)');
        insert objBlacklistProfile;
        
        Email_Domain_Blacklist__c objBlacklistRole = new Email_Domain_Blacklist__c(Name = 'Sales Operations');
        insert objBlacklistRole;
        
        Profile custom = [Select Id, Name from Profile where name = 'System Admin (Custom)'];
        Profile systemAdm = [Select Id, Name from Profile where name = 'System Administrator'];
        String roleId = [Select Id, Name from userrole WHERE name= 'Sales Operations' LIMIT 1].Id;
        
        test.startTest();
        User user1 = new user();
        user1.ProfileId = custom.Id;
        user1.Username = System.now().getTime() + 'test@test.com';
        user1.Alias = 'testtest';
        user1.Email='test@test-emaildomain.com';
        user1.EmailEncodingKey='UTF-8';
        user1.Firstname='Test';
        user1.Lastname='Test';
        user1.LanguageLocaleKey='en_uS';
        user1.LocaleSidKey='en_US';
        user1.TimeZoneSidKey='America/Chicago';
        insert user1;
        
        system.runAs(user1){
            User user2 = new user();
            user2.ProfileId = systemAdm.Id;
            user2.Username = System.now().getTime() + 'test@test.com';
            user2.Alias = 'testtest';
            user2.Email='test@test-emaildomain.com';
            user2.EmailEncodingKey='UTF-8';
            user2.Firstname='Test';
            user2.Lastname='Test';
            user2.LanguageLocaleKey='en_uS';
            user2.LocaleSidKey='en_US';
            user2.TimeZoneSidKey='America/Chicago';
            user2.UserRoleId= roleid;
            insert user2;
            
            List<Account> lstAcnt = new List<Account>();
            lstAcnt.add(new Account(
                Name = 'Test Account1',
                OwnerId = user1.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.checkboxtest.com'
            ));
            lstAcnt.add(new Account(
                Name = 'Test Account2',
                OwnerId = user1.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.checkboxtest1.com'
            ));
            insert lstAcnt;
            
            Email_Domain__c ed1 = new Email_Domain__c(
                Name = 'checkboxtest1.com',
                Account__c = lstAcnt[0].Id
            );
            insert ed1;
            Email_Domain__c emailDomain1 = [Select Id,approved__c from Email_Domain__c where name='checkboxtest1.com'];
            system.assert(emailDomain1.Approved__c==false);
            system.runAs(user2){
                Email_Domain__c ed2 = new Email_Domain__c(
                    Name = 'checkboxtest2.com',
                    Account__c = lstAcnt[0].Id
                );
                insert ed2;
                Email_Domain__c emailDomain2 = [Select Id,approved__c from Email_Domain__c where name='checkboxtest2.com'];
                system.assert(emailDomain2.Approved__c==false);
            }
        }
        test.stopTest();
    }
    
    /*Method to cover positive and negative test case*/
    static testmethod void EmailDomainTriggerHandlerBulkCase(){
        Email_Domain_Blacklist__c objBlacklistProfile = new Email_Domain_Blacklist__c(Name = 'System Admin (Custom)');
        insert objBlacklistProfile;
        
        Email_Domain_Blacklist__c objBlacklistRole = new Email_Domain_Blacklist__c(Name = 'Sales Operations');
        insert objBlacklistRole;
        
        Profile custom = [Select Id, Name from Profile where name = 'System Admin (Custom)'];
        Profile systemAdm = [Select Id, Name from Profile where name = 'System Administrator'];
        String roleId = [Select Id, Name from userrole WHERE name= 'Sales Development Manager' LIMIT 1].Id;
        
        test.startTest();
        User user1 = new user();
        user1.ProfileId = custom.Id;
        user1.Username = System.now().getTime() + 'test@test.com';
        user1.Alias = 'testtest';
        user1.Email='test@test-emaildomain.com';
        user1.EmailEncodingKey='UTF-8';
        user1.Firstname='Test';
        user1.Lastname='Test';
        user1.LanguageLocaleKey='en_uS';
        user1.LocaleSidKey='en_US';
        user1.TimeZoneSidKey='America/Chicago';
        insert user1;
        
        system.runAs(user1){
            User user2 = new user();
            user2.ProfileId = systemAdm.Id;
            user2.Username = System.now().getTime() + 'test@test.com';
            user2.Alias = 'testtest';
            user2.Email='test@test-emaildomain.com';
            user2.EmailEncodingKey='UTF-8';
            user2.Firstname='Test';
            user2.Lastname='Test';
            user2.LanguageLocaleKey='en_uS';
            user2.LocaleSidKey='en_US';
            user2.TimeZoneSidKey='America/Chicago';
            user2.UserRoleId= roleid;
            insert user2;
            
            User user3 = new user();
            user3.ProfileId = systemAdm.Id;
            user3.Username = System.now().getTime() + 'test@test.com';
            user3.Alias = 'testtest';
            user3.Email='test@test-emaildomain.com';
            user3.EmailEncodingKey='UTF-8';
            user3.Firstname='Test';
            user3.Lastname='Test';
            user3.LanguageLocaleKey='en_uS';
            user3.LocaleSidKey='en_US';
            user3.TimeZoneSidKey='America/Chicago';
            user3.UserRoleId=roleid;
            insert user3;
            
            
            List<Account> lstAcnt = new List<Account>();
            lstAcnt.add(new Account(
                Name = 'Test Account1',
                OwnerId = user1.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.checkboxtest.com'
            ));
            lstAcnt.add(new Account(
                Name = 'Test Account2',
                OwnerId = user1.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.checkboxtest1.com'
            ));
            insert lstAcnt;
            
            List<Email_Domain__c> lstED= new List<Email_Domain__c>();
            for(integer i=0;i<=100;i++){
                Email_Domain__c ed2 = new Email_Domain__c(
                    Name = 'checkboxtest'+i+'.com',
                    Account__c = lstAcnt[0].Id
                );
                lstED.add(ed2);
            }
            insert lstED;
            List<Email_Domain__c> lstEDnew= [Select Id,approved__c from Email_Domain__c];  
            system.debug('++lst' +lstEDnew);
            system.assert(lstEDnew[2].approved__c==false);
            
            system.runAs(user3){
                List<Email_Domain__c> lstED1= new List<Email_Domain__c>();
                for(integer i=101;i<=200;i++){
                    Email_Domain__c ed2 = new Email_Domain__c(
                        Name = 'checkboxtest'+i+'.com',
                        Account__c = lstAcnt[0].Id
                    );
                    lstED1.add(ed2);
                }
                insert lstED1;
                List<Email_Domain__c> lstEDnew1= [Select Id,approved__c,name from Email_Domain__c where name='checkboxtest109.com'];
                system.assert(lstEDnew1[0].approved__c==true);
            }
        }
        test.stopTest();
    }
}