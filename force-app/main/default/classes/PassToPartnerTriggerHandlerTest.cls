/**********************************************************
Class: PassToPartnerTriggerHandlerTest
Last Modified By: Gram Bischof {04/17/2020}
Description: This is Test class for the PassToPartnerTriggerHandler      
***********************************************************/
@isTest
public class PassToPartnerTriggerHandlerTest {
    
    @testSetup static void setup() {
        //create portal account two
        //create two contact for portal user.
        //then create two Opportunity with assign upper accountId
        
         //Here we query the user profile
            Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            //Here we insert the user.
            User users = new User(
                ProfileId = profile1.Id,
                UserRoleId = portalRole.id,
                Username = System.now().millisecond() + 'sfdc@bopsy.com',
                Alias = 'testing',
                email='sfdc@bopsy.com',
                EmailEncodingKey='UTF-8',
                Firstname='Bopsy',
                Lastname='Test',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Chicago'
            );
            Database.insert(users);
            System.runAs (users) {
                
                //Here we insert the account with partner enable.
                List<Account> accountList=new List<Account>();
                for(Integer i=1;i<=3;i++)
                {
                    accountList.add( new Account(
                    name = 'testAccount'+i	,
                    Partner_Type__c = 'Consulting',
                    PAE__c = users.id,
                    PAM__c = users.id
                    ));
                }
                insert accountList;
                
                // isPartner = True only allowed on update after creation
                for(Account acct: accountList) acct.isPartner = True;
                update accountList;
                
                
                //Here we create the contact on the related list account.
                List<Contact> contactList=new List<Contact>();                
                for(Account acct : accountList){
                    contactList.add( new Contact(
                   	LastName = 'testcon',
                    AccountId = acct.id,
                    Title = 'test title',
                    Contact_Type__c = 'Billing Contact',
                    Preferred_Email__c = acct.Name + '@test.com',
                    Account_Admin__c = true
                    ));  
                    
                    contactList.add( new Contact(
                   	LastName = 'testcon2',
                    AccountId = acct.id,
                    Title = 'test title 2',
                    Contact_Type__c = 'Billing Contact',
                    Preferred_Email__c = acct.Name + '2@test.com',
                    Account_Admin__c = true
                    ));  
                }
                insert contactList;
                system.debug('contactList------'+contactList);
                
                Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%**Partner Community User Login**%' Limit 1];
                List<User> userList=new List<User>();
                Integer itr = 0;
                for(Contact con:contactList)
                {  system.debug('users----------'+System.now().millisecond()+'Bopsy'+contact.LastName+'@gmail.com');
                 
                 User user1 = new User(
                     Username ='McTesty'+itr+'@test.com',
                     ContactId = con.Id,
                     ProfileId = portalProfile.Id,
                     Alias = 'test123',
                     Email = con.Preferred_Email__c,
                     EmailEncodingKey = 'UTF-8',
                     LastName = 'McTesty'+itr,
                     CommunityNickname = 'test12345'+itr,
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US'
                 );
                 System.debug('username::'+user1.Username);
                 
                 userList.add(user1);
                 itr++;
                }
                
                insert userList;
            }
        
    }
    
    public static testMethod  void  testCreateSharingForCommunityUser() {
        // Get Setup records
        List<Account> testAccounts = [Select id From Account];
        //create pass to partner of any record type
        List<Pass_to_Partner__c> dealRegs = new List<Pass_to_Partner__c>();
        for(Account acct: testAccounts){
            dealRegs.add(new Pass_to_Partner__c(
            	Name = 'Test',
                Launch_Date__c = date.today(),
                Partner_Account__c = acct.id,
                RecordTypeId = Schema.SObjectType.Pass_to_Partner__c.getRecordTypeInfosByName().get('Deal Registration').getRecordTypeId()
            ));
        }
        
        Test.startTest();
        	insert dealRegs;
        Test.stopTest();
        //assert that another portal user also see the pass to partner
        Profile p = [Select id From Profile Where Name LIKE '%**Partner Community User Login**%' Limit 1]; 
        List<User> portalUsers = [Select id From User Where profileid = :p.id];
        List<Pass_to_Partner__share> shares = [Select id,ParentId,UserOrGroupId From Pass_to_Partner__share Where ParentId IN :dealRegs];
        Map<Id,List<Pass_to_Partner__share>> accountIdToShareMap = new Map<Id,List<Pass_to_Partner__share>>();
        for(Pass_to_Partner__share share: shares){
            if(!accountIdToShareMap.containskey(share.ParentId)) accountIdToShareMap.put(share.ParentId, new List<Pass_to_Partner__share>());
            accountIdToShareMap.get(share.ParentId).add(share);
        }
        for(Id accountId : accountIdToShareMap.keySet()){
            System.assertEquals(accountIdToShareMap.get(accountID).size(),3); //GroupId, User1 and User2
        }
        
    }
    
    public static testMethod  void  testCreateSharingForCommunityUserAsPortalUser() {
        // Get Setup records
        List<Account> testAccounts = [Select id From Account];
        User portalUser = [Select id,isPortalEnabled,isActive,ContactId From User Where Username ='McTesty1@test.com'];
        Contact testcontact = [Select id,AccountId From Contact Where Id = :portalUser.ContactId];
        System.debug(portalUser);
        System.debug(testContact);
        //create pass to partner of any record type
        List<Pass_to_Partner__c> dealRegs = new List<Pass_to_Partner__c>();
        for(Account acct: testAccounts){
            if(acct.Id != testcontact.AccountID) continue;
            dealRegs.add(new Pass_to_Partner__c(
            	Name = 'Test',
                Launch_Date__c = date.today(),
                Partner_Account__c = acct.id,
                RecordTypeId = Schema.SObjectType.Pass_to_Partner__c.getRecordTypeInfosByName().get('Deal Registration').getRecordTypeId()
            ));
        }
        
        Test.startTest();
            System.runAs(portalUser){
                insert dealRegs;
            }
        Test.stopTest();
        //assert that another portal user also see the pass to partner
        Profile p = [Select id From Profile Where Name LIKE '%**Partner Community User Login**%' Limit 1]; 
        List<User> portalUsers = [Select id From User Where profileid = :p.id AND ID NOT IN :new List<User>{portalUser}];
        Map<Id,User> portalUserMap = new Map<Id,User>(portalUsers);
        List<Pass_to_Partner__share> shares = [Select id,ParentId,UserOrGroupId,AccessLevel From Pass_to_Partner__share Where ParentId IN :dealRegs AND UserOrGroupID IN :portalUserMap.keySet()];
        Map<Id,List<Pass_to_Partner__share>> accountIdToShareMap = new Map<Id,List<Pass_to_Partner__share>>();
        for(Pass_to_Partner__share share: shares){
            if(!accountIdToShareMap.containskey(share.ParentId)) accountIdToShareMap.put(share.ParentId, new List<Pass_to_Partner__share>());
            accountIdToShareMap.get(share.ParentId).add(share);
        }
        System.debug(shares);
        System.assertEquals(shares.size(),1);
    }
    
    public static testMethod void testcopyFieldsFromOpportunityForInsert() {
        
        List<Account> testAcntList = [SELECT Id FROM Account];
        
        Opportunity_to_PTP_Mappings__c setting = new Opportunity_to_PTP_Mappings__c();
        setting.Name = 'BDR_Notes__c';
        setting.PTP_API_Name__c = 'BDR_Notes__c';
        setting.Opportunity_API_Name__c = 'BDR_Notes__c';
        insert setting;
        
        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'TestOpp';
        testOpp.AccountId = testAcntList[0].Id;
        testOpp.CloseDate = system.today();
        testOpp.StageName = 'Incubate';
        testOpp.BDR_Notes__c = 'NotesofOpp';
        insert testOpp;
        
        Pass_To_Partner__c testPTP = new Pass_To_Partner__c();
        testPTP.Opportunity__c = testOpp.Id;
        testPTP.Partner_Status__c = 'Accepted';
        testPTP.FY_16_Primary_Product_Input__c = 'Support';
        testPTP.BDR_Notes__c = 'NotesOfPtp';
        testPTP.FY_16_Use_Case_Input__c = 'SIP Trunking';
        testPTP.Use_Case_Category_Input__c = 'SIP Trunking';
        insert testPTP;
        
        List<Pass_To_Partner__c> testPTPList = new List<Pass_To_Partner__c>();
        testPTPList.add(testPTP);
        test.startTest();
        PassToPartnerTriggerHandler.copyFieldsFromOpportunity(testPTPList);
        test.stopTest();
        
        //Assertion
        List<Pass_To_Partner__c> testPtpListAssertion =[SELECT Id, BDR_Notes__c FROM Pass_To_Partner__c];
        system.assertEquals('NotesofOpp', testPtpList[0].BDR_Notes__c);
     }
    
    public static testMethod void testcopyFieldsFromOpportunityForUpdate() {
        
        List<Account> testAcntList = [SELECT Id FROM Account];
        
        Opportunity_to_PTP_Mappings__c setting = new Opportunity_to_PTP_Mappings__c();
        setting.Name = 'BDR_Notes__c';
        setting.PTP_API_Name__c = 'BDR_Notes__c';
        setting.Opportunity_API_Name__c = 'BDR_Notes__c';
        insert setting;
        
        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'TestOpp';
        testOpp.AccountId = testAcntList[0].Id;
        testOpp.CloseDate = system.today();
        testOpp.StageName = 'Incubate';
        testOpp.BDR_Notes__c = 'NotesofOpp';
        insert testOpp;
        Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>();
        oldMap.put(testOpp.Id, testOpp);
        
        testOpp.StageName = 'pipeline';
        update testOpp;
        
        Map<Id,Opportunity> newMap = new Map<Id,Opportunity>([SELECT Id FROM Opportunity]);
        List<Pass_To_Partner__c> testReturnPtp = PassToPartnerTriggerHandler.copyFieldsFromOpportunity(oldMap,newMap);
        
        Pass_To_Partner__c testPTP = new Pass_To_Partner__c();
        testPTP.Opportunity__c = testOpp.Id;
        testPTP.Partner_Status__c = 'Accepted';
        testPTP.FY_16_Primary_Product_Input__c = 'Support';
        testPTP.BDR_Notes__c = 'NotesOfPtp';
        testPTP.FY_16_Use_Case_Input__c = 'SIP Trunking';
        testPTP.Use_Case_Category_Input__c = 'SIP Trunking';
        insert testPTP;
        
        Map<Id,Pass_To_Partner__c> oldMapPTP = new Map<Id,Pass_To_Partner__c>();
        oldMapPTP.put(testPTP.Id, testPTP);
        
        testPTP.FY_16_Primary_Product_Input__c = 'Authy - Software';
        update testPTP;
        Map<Id,Pass_To_Partner__c> newMapPtp = new Map<Id,Pass_To_Partner__c>([SELECT Id,Opportunity__c FROM Pass_To_Partner__c]);
        
        test.startTest();
        PassToPartnerTriggerHandler.copyFieldsFromOpportunity(oldMapPTP,newMapPtp);
        test.stopTest();
        
        //Assertion
        List<Pass_To_Partner__c> testPtpList = [SELECT Id, BDR_Notes__c FROM Pass_To_Partner__c];
        system.assertEquals('NotesOfPtp', testPtpList[0].BDR_Notes__c);
    }
}