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
private class PartnerDealSubmissionTest {
/*
	public static String leadRecTypeName = 'Twilio Lead';

	public static String assignedAccountName = 'Twilio Incoming Partner Deals';
	public static String intialOwnerName = 'Website Inbound Queue';
	public static String partnerOppRecTypeName = 'Partner Opportunity';
	public static String partnerApprovalProcessName = 'Partner_Opportunity_Flow';

	public static String openDealOpportunityStage = 'Use Case Confirmed';
	public static String closedDealOpportunityStage = 'Closed Won';

	public static String ppOpenDealLeadSource = 'PPortal - Open Deal Reg';
	public static String ppClosedDealLeadSource = 'PPortal - Closed Deal Reg';
	public static String wfOpenDealLeadSource = 'WebForm - Open Deal Reg';
	public static String wfClosedDealLeadSource = 'WebForm - Closed Deal Reg';


	private static User portalAccountOwner { get; set; }
	private static List<User> partnerPortalUsers { get; set; }
	private static List<Lead> leads { get; set; }

    static testMethod void PartnerDealSubmissionSuccessful() {
        Test.startTest();
//
// Changed run as user to be the existing "Sales Operations" user so it would be exempted
// from the following Lead validation rules:
//
//    Consolidated_Last_Lead_Source_Edit_Rules
//    Consolidation_of_LeadSource_Edit_Rules
//    Partner_Pass_No_SQL_required_fields
//
		User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

        System.RunAs(au) {
			setupTestRecords(true);
        }
        Test.stopTest();
    }

    static testMethod void PartnerDealSubmissionNotWeb2Lead() {
        Test.startTest();
//
// Changed run as user to be the existing "Sales Operations" user so it would be exempted
// from the following Lead validation rules:
//
//    Consolidated_Last_Lead_Source_Edit_Rules
//    Consolidation_of_LeadSource_Edit_Rules
//    Partner_Pass_No_SQL_required_fields
//
//		User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

//        System.RunAs(au) {
			setupTestRecords(false);
//        }
        Test.stopTest();
    }
    
    private static void setupTestRecords(Boolean web2LeadGenerated) {
    	User runningUser = [ select Id, Name from User where Id = :UserInfo.getUserId() ];
		
		Id initialOwnerId = null;
		List<Group> initialOwnerQueue = [ SELECT Id, Name FROM Group WHERE Name = :intialOwnerName AND Type = 'Queue' ];
		if (initialOwnerQueue.isEmpty()) {
			System.debug('=========> ERROR: "' + intialOwnerName + '" user is not found.  PartnerDealSubmission trigger aborting...');
			return;
		} else {
			initialOwnerId = initialOwnerQueue[0].Id;
		}

		//Create portal account owner
		UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
		Profile profile1 = [Select Id from Profile where name = 'System Administrator'];

		portalAccountOwner = new User();
		portalAccountOwner.UserRoleId = portalRole.Id;
		portalAccountOwner.ProfileId = profile1.Id;
		portalAccountOwner.Username = System.now().getTime() + 'test@test.com';
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
		List<Account> portalAccounts = new List<Account>();
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
		portalAccounts.add(new Account(
			Name = assignedAccountName,
			Employee_Size__c = '0 - 50',
			OwnerId = portalAccountOwner.Id
		));
		insert(portalAccounts);
		    	
		//Create contact
		List<Contact> contacts = new List<Contact>();
		contacts.add(new Contact(
		   	FirstName = 'TestContact12345',
		    Lastname = 'TestContact12345',
			AccountId = portalAccounts[0].Id,
		    Title = 'Test Title',
		    Phone = '555-555-1212',
		    Email = System.now().getTime() + 'test12345@test.com',
		    Preferred_Email__c = System.now().getTime() + 'test12345@test.com'
		));
		contacts.add(new Contact(
		   	FirstName = 'TestContact23456',
		    Lastname = 'TestContact23456',
			AccountId = portalAccounts[1].Id,
		    Title = 'Test Title',
		    Phone = '555-555-1212',
		    Email = System.now().getTime() + 'test23456@test.com',
		    Preferred_Email__c = System.now().getTime() + 'test23456@test.com'
		));
		insert(contacts);
		    	
		//Create user
		Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE 'Partner Community User' Limit 1];
		partnerPortalUsers = new List<User>();
		partnerPortalUsers.add(new User(
			Username = System.now().getTime() + 'test12345@test.com',
			ContactId = contacts[0].Id,
			ProfileId = portalProfile.Id,
			Alias = 'test123',
			Email = 'test12345@test.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'test12345',
			CommunityNickname = 'test12345',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			LanguageLocaleKey = 'en_US',
			PAM__c = runningUser.Name
		));
		partnerPortalUsers.add(new User(
			Username = System.now().getTime() + 'test23456@test.com',
			ContactId = contacts[1].Id,
			ProfileId = portalProfile.Id,
			Alias = 'test234',
			Email = 'test23456@test.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'test23456',
			CommunityNickname = 'test23456',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			LanguageLocaleKey = 'en_US',
			PAM__c = runningUser.Name
		));

		// Need to exeucte within System.runAs() to avoid the following error:
		// MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)
		System.runAs ( runningUser ) {
			insert(partnerPortalUsers);
		}
		partnerPortalUsers = [ SELECT Id, Partner_ID__c FROM User WHERE Username = :partnerPortalUsers[0].Username OR Username = :partnerPortalUsers[1].Username ];
			
	    // Since the controller "addField()" cannot be used when tests are running we need to
	    // insert and the requery the lead so that it has all the fields needed by the controller.
//		List<Lead> leads;
		Id leadRecTypeId = Schema.SObjectType.Lead.RecordTypeInfosByName.get(leadRecTypeName).RecordTypeId;
		leads = new List<Lead>();
		leads.add(new Lead(
			FirstName = 'none',
			LastName = 'none',
			Email = 'none@none.com',
			City = 'none',
			StateCode = 'CA',
			CountryCode = 'US',
			LeadSource = (web2LeadGenerated ? ppClosedDealLeadSource : 'Other'),
			Zendesk__notes__c = 'none',
			Partner_ID__c = partnerPortalUsers[0].Partner_ID__c,
			Company = 'TestCompany12345',
			Account_SID__c = '1234567890',
			Status = 'Open',
			Partner_Portal_Lead__c = true
		));
		leads.add(new Lead(
			FirstName = 'TestFirstName',
			LastName = 'TestLastName',
			Email = 'test@email.com',
			City = 'TestCity',
			StateCode = 'CA',
			CountryCode = 'US',
			LeadSource = (web2LeadGenerated ? ppOpenDealLeadSource : 'Other'),
			Zendesk__notes__c = 'TestNotes',
			Partner_ID__c = partnerPortalUsers[0].Partner_ID__c,
			Company = 'TestCompany23456',
			Account_SID__c = '2345678901',
			Status = 'Open',
			Partner_Portal_Lead__c = true
		));
		leads.add(new Lead(
			FirstName = 'none',
			LastName = 'none',
			Email = 'none@none.com',
			City = 'none',
			StateCode = 'CA',
			CountryCode = 'US',
			LeadSource = (web2LeadGenerated ? wfClosedDealLeadSource : 'Other'),
			Zendesk__notes__c = 'none',
			Partner_ID__c = partnerPortalUsers[1].Partner_ID__c,
			Company = 'TestCompany12345',
			Account_SID__c = '1234567890',
			Status = 'Open',
			Partner_Portal_Lead__c = true
		));
		leads.add(new Lead(
			FirstName = 'TestFirstName',
			LastName = 'TestLastName',
			Email = 'test@email.com',
			City = 'TestCity',
			StateCode = 'CA',
			CountryCode = 'US',
			LeadSource = (web2LeadGenerated ? wfOpenDealLeadSource : 'Other'),
			Zendesk__notes__c = 'TestNotes',
			Partner_ID__c = partnerPortalUsers[1].Partner_ID__c,
			Company = 'TestCompany23456',
			Account_SID__c = '2345678901',
			Status = 'Open',
			Partner_Portal_Lead__c = true
		));
		insert(leads);

		// Similate the lead owner assignment
		leads[0].OwnerId = initialOwnerId;
		leads[1].OwnerId = initialOwnerId;
		leads[2].OwnerId = initialOwnerId;
		leads[3].OwnerId = initialOwnerId;
		update(leads);
//		lead = [
//			SELECT Id, Name, LastName, Company, Status, LeadSource, OwnerId, CreatedDate, RecordTypeId, Account_SID__c
//			FROM Lead
//			WHERE Id = :leads.Id
//			LIMIT 1
//		];
    }    
*/
}