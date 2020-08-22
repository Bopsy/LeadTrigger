@isTest
public with sharing class BopsyChangeOpportunityOwnerCntrlTest {

    @testSetup
    public static void setup(){
        profile p = [select id, name from profile where name = 'Partners & Alliances - Sales'];
        insert new ByPassValidationRuleForOpp__c(SetupOwnerId=p.id);
    }
    
    public static testmethod void testUpdateOwner(){
        Account testAccount = new Account(Name='Test');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(AccountId=testAccount.id,Name='Test Opp',StageName='Incubate',closeDate=Date.today().addMonths(3));
        insert testOpp;
        
        User u = new user();
        u.LastName = 'Test Code';
        u.Email = 'testpartner@testownertwil83.com';
        u.Alias = 'Tcode';
        u.Username = 'testpartner@testclaendertwil.com';
        u.CommunityNickname = 'test12';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'GMT';
        u.profileId = [SELECT Id FROM Profile WHERE Name='Partners & Alliances - Sales'].Id;
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.UserPreferencesLightningExperiencePreferred = false;
        
        Test.startTest();
        	ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        	BopsyChangeOpportunityOwnerController bcoo = new BopsyChangeOpportunityOwnerController(sc);
        	bcoo.opp = testOpp;
        	bcoo.changeOwner();
        Test.stopTest();
    }
    
    public static testmethod void verifyProfileAccess() {
        Boolean noAccessToAdmin = BopsyChangeOpportunityOwnerController.getProfileInfo();
        System.assertEquals(noAccessToAdmin, false);
    }

    public static testmethod void verifyUserList() {
        String firstName = UserInfo.getFirstName();
        List<BopsyChangeOpportunityOwnerController.UserOption> uoList = BopsyChangeOpportunityOwnerController.findUser(firstName);
        System.assert(uoList.size()>0);
    }

    public static testmethod void verifyUserAssignment() {
        Id superNetworkRecordAcc = [SELECT id FROM RecordType WHERE DeveloperName='Super_Network_Provider' AND SobjectType='Account'].Id;
        
        Account acc = new Account(RecordTypeId=superNetworkRecordAcc,Name='Community Account');
        insert acc;

        Opportunity testOpp = new Opportunity(
			Name = 'TestOppOwnerChange',
			AccountId = acc.Id,
			CloseDate = Date.today(),
			StageName = 'Pilot',
			Use_Case1__c = 'Call Tracking',
			Authy_Use_Case__c = 'Call Tracking',
			Product__c = 'Client',
			Primary_Competitor__c = 'Agendi',
			New_Business_Account_SID__c = '01234567890'
		);

        insert testOpp;

        User u = new user();
        u.LastName = 'Test Code';
        u.Email = 'testpartner@testownertwil83.com';
        u.Alias = 'Tcode';
        u.Username = 'testpartner@testclaendertwil.com';
        u.CommunityNickname = 'test12';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'GMT';
        u.profileId = [SELECT Id FROM Profile WHERE Name='Partners & Alliances - Sales'].Id;
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.UserPreferencesLightningExperiencePreferred = false;
        
        System.runAs(u) {
            BopsyChangeOpportunityOwnerController.assign(UserInfo.getUserId(), testOpp.Id);
        }
    }
    
}