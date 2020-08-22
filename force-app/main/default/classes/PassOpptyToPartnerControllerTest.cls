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
private class PassOpptyToPartnerControllerTest {
	public static String opptyUseCaseDepPicklist = 'Conference Calling';
	public static String opptySolutionAreaDepPicklist = 'Sales Communications';

	private static User portalAccountOwner { get; set; }
	private static List<User> partnerPortalUsers { get; set; }
	private static List<Account> portalAccounts { get; set; }
	private static List<Contact> contacts { get; set; }
	
    static testMethod void PassOpptyToPartnerSuccessful() {
		setupTestRecords(false);
		
		PageReference testPage = Page.PassOpptyToPartner;
        Test.setCurrentPage(testPage);
        ApexPages.StandardController con = new ApexPages.StandardController(portalAccounts[0]);
        ApexPages.currentPage().getParameters().put('id', portalAccounts[0].Id);
        PassOpptyToPartnerController pcon = new PassOpptyToPartnerController(con);
        
        Test.startTest();
        
    	System.assertEquals(pcon.canPassToPartner, true);
    	System.assertEquals(pcon.step, 1);

        pcon.selectedContact = contacts[0].Id;
        PageReference step2 = pcon.gotoStep2();
		System.assertEquals(pcon.step, 2);

        pcon.selectedPartner = partnerPortalUsers[0].Id;
        pcon.partnerAssignment.Use_Case1__c = opptyUseCaseDepPicklist;
		PageReference step3 = pcon.gotoStep3();
		System.assertEquals(pcon.step, 2);

        pcon.partnerAssignment.Solution_Area__c = opptySolutionAreaDepPicklist;
		step3 = pcon.gotoStep3();
		System.assertEquals(pcon.step, 3);

        Test.stopTest();
    }
    
    static testMethod void PassOpptyToPartnerAccountHasNoContacts() {
    	setupTestRecords(true);
    
		PageReference testPage = Page.PassOpptyToPartner;
        Test.setCurrentPage(testPage);
        ApexPages.StandardController con = new ApexPages.StandardController(portalAccounts[1]);
        ApexPages.currentPage().getParameters().put('id', portalAccounts[1].Id);
        PassOpptyToPartnerController pcon = new PassOpptyToPartnerController(con);
        
        Test.startTest();
    	System.assertEquals(pcon.canPassToPartner, false);
    	System.assertEquals(pcon.step, 1);

    	Test.stopTest();
    }

    static testMethod void PassOpptyToPartnerNoContactGiven() {
    	setupTestRecords(true);
    
		PageReference testPage = Page.PassOpptyToPartner;
        Test.setCurrentPage(testPage);
        ApexPages.StandardController con = new ApexPages.StandardController(portalAccounts[0]);
        ApexPages.currentPage().getParameters().put('id', portalAccounts[0].Id);
        PassOpptyToPartnerController pcon = new PassOpptyToPartnerController(con);
        
        Test.startTest();
    	System.assertEquals(pcon.canPassToPartner, true);
    	System.assertEquals(pcon.step, 1);

        PageReference step2 = pcon.gotoStep2();
		System.assertEquals(pcon.step, 1);

    	Test.stopTest();
    }

    static testMethod void PassOpptyToPartnerNoPartnerGiven() {
    	setupTestRecords(false);
    
		PageReference testPage = Page.PassOpptyToPartner;
        Test.setCurrentPage(testPage);
        ApexPages.StandardController con = new ApexPages.StandardController(portalAccounts[0]);
        ApexPages.currentPage().getParameters().put('id', portalAccounts[0].Id);
        PassOpptyToPartnerController pcon = new PassOpptyToPartnerController(con);
        
        Test.startTest();
        
    	System.assertEquals(pcon.canPassToPartner, true);
    	System.assertEquals(pcon.step, 1);

        pcon.selectedContact = contacts[0].Id;
        PageReference step2 = pcon.gotoStep2();
		System.assertEquals(pcon.step, 2);

        PageReference step3 = pcon.gotoStep3();
		System.assertEquals(pcon.step, 2);
		
	    Test.stopTest();
    }

    static testMethod void PassOpptyToPartnerMiscellaneous() {
    	setupTestRecords(false);
    
		PageReference testPage = Page.PassOpptyToPartner;
        Test.setCurrentPage(testPage);
        ApexPages.StandardController con = new ApexPages.StandardController(portalAccounts[0]);
        ApexPages.currentPage().getParameters().put('id', portalAccounts[0].Id);
        PassOpptyToPartnerController pcon = new PassOpptyToPartnerController(con);
        
        Test.startTest();
        
    	System.assertEquals(pcon.canPassToPartner, true);
    	System.assertEquals(pcon.step, 1);
    	System.assertEquals(pcon.getStep1(), true);
    	System.assertEquals(pcon.getStep2(), false);
    	System.assertEquals(pcon.getStep3(), false);

        pcon.selectedContact = contacts[0].Id;
        PageReference step2 = pcon.gotoStep2();
		System.assertEquals(pcon.step, 2);
    	System.assertEquals(pcon.getStep1(), false);
    	System.assertEquals(pcon.getStep2(), true);
    	System.assertEquals(pcon.getStep3(), false);

		pcon.gotoStep1();
    	System.assertEquals(pcon.step, 1);
    	System.assertEquals(pcon.getStep1(), true);
    	System.assertEquals(pcon.getStep2(), false);
    	System.assertEquals(pcon.getStep3(), false);

        pcon.selectedPartner = partnerPortalUsers[0].Id;
        pcon.partnerAssignment.Use_Case1__c = opptyUseCaseDepPicklist;
        pcon.partnerAssignment.Solution_Area__c = opptySolutionAreaDepPicklist;
		PageReference step3 = pcon.gotoStep3();
		System.assertEquals(pcon.step, 3);
    	System.assertEquals(pcon.getStep1(), false);
    	System.assertEquals(pcon.getStep2(), false);
    	System.assertEquals(pcon.getStep3(), true);
		
	    Test.stopTest();
    }

    private static void setupTestRecords(Boolean excludeLeadRequiredFields) {
    	User runningUser = [ select Id from User where Id = :UserInfo.getUserId() ];

		//Create portal account owner
		UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
		Profile profile1 = [Select Id from Profile where name = 'System Administrator'];

		portalAccountOwner = new User();
		portalAccountOwner.UserRoleId = portalRole.Id;
		portalAccountOwner.ProfileId = profile1.Id;
		portalAccountOwner.Username = System.now().getTime() + System.now().millisecond() + 'testtwilio@test.com';
	   	portalAccountOwner.Alias = 'testtest';
		portalAccountOwner.Email='test@test.com';
		portalAccountOwner.EmailEncodingKey='UTF-8';
		portalAccountOwner.Firstname='Test';
		portalAccountOwner.Lastname='Test';
		portalAccountOwner.LanguageLocaleKey='en_US';
		portalAccountOwner.LocaleSidKey='en_US';
		portalAccountOwner.TimeZoneSidKey='America/Chicago';

		// Need to exeucte within System.runAs() to avoid the following error:
		// MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)
		System.runAs ( runningUser ) {
			insert(portalAccountOwner);
		}
		
		//Create account
		portalAccounts = new List<Account>();
		portalAccounts.add(new Account(
			Name = 'TestAccount12345',
			Employee_Size__c = '0 - 50',
			OwnerId = portalAccountOwner.Id
		));
		portalAccounts.add(new Account(
			Name = 'TestAccount23456',
			Employee_Size__c = '0 - 50',
			OwnerId = portalAccountOwner.Id
		));
		insert(portalAccounts);
		    	
		//Create contact
		contacts = new List<Contact>();
		contacts.add(new Contact(
		   	FirstName = 'TestContact12345',
		    Lastname = 'TestContact12345',
			AccountId = portalAccounts[0].Id,
		    Title = 'Test Title',
		    Phone = '555-555-1212',
		    Email = System.now().millisecond() + 'test12345@test.com',
		    Preferred_Email__c = System.now().millisecond() + 'test12345@test.com'
		));
		contacts.add(new Contact(
		   	FirstName = 'TestContact23456',
		    Lastname = 'TestContact23456',
			AccountId = portalAccounts[0].Id,
		    Title = 'Test Title',
		    Phone = '555-555-1212',
		    Email = System.now().millisecond() + 'test23456@test.com',
		    Preferred_Email__c = System.now().millisecond() + 'test23456@test.com'
		));
		insert(contacts);
		    	
		//Create user
		Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE 'Partner Community User' Limit 1];
		partnerPortalUsers = new List<User>();
		partnerPortalUsers.add(new User(
			Username = System.now().millisecond() + 'test12345@test.com',
			ContactId = contacts[0].Id,
			ProfileId = portalProfile.Id,
			Alias = 'test123',
			Email = 'test12345@test.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'test12345',
			CommunityNickname = 'test12345',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			LanguageLocaleKey = 'en_US'
		));
		partnerPortalUsers.add(new User(
			Username = System.now().millisecond() + 'test23456@test.com',
			ContactId = contacts[1].Id,
			ProfileId = portalProfile.Id,
			Alias = 'test234',
			Email = 'test23456@test.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'test23456',
			CommunityNickname = 'test23456',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			LanguageLocaleKey = 'en_US'
		));

		// Need to exeucte within System.runAs() to avoid the following error:
		// MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)
		System.runAs ( runningUser ) {
			insert(partnerPortalUsers);
		}
    }
}