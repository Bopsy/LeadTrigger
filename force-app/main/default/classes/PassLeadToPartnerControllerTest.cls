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
private class PassLeadToPartnerControllerTest {
	public static String leadRecTypeName = 'Twilio Lead';
	

	private static User portalAccountOwner { get; set; }
	private static List<User> partnerPortalUsers { get; set; }
	private static Lead lead { get; set; }
	
	
    static testMethod void PassLeadToPartnerSuccessful() {
		setupTestRecords(false);
		
        ApexPages.StandardController con = new ApexPages.StandardController(lead);
        PassLeadToPartnerController pcon = new PassLeadToPartnerController(con);
        
        Test.startTest();
		System.assertEquals(pcon.canPassToPartner, true);

        pcon.selectedPartners[0] = partnerPortalUsers[0].Id;
        pcon.partnerAssignments[0].Partner_Notes__c = 'Test Note';
        
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
	    	System.assertEquals(pcon.canPassToPartner, true);
        	System.assertEquals(pcon.canSave, true);
	        PageReference result = pcon.save();
			System.assertEquals(pcon.canSave, false);
//        }
        Test.stopTest();
    }

    static testMethod void PassLeadToPartnerDuplicatePartnerFailure() {
    	setupTestRecords(false);
    
        ApexPages.StandardController con = new ApexPages.StandardController(lead);
        PassLeadToPartnerController pcon = new PassLeadToPartnerController(con);
        
        Test.startTest();
   		System.assertEquals(pcon.canPassToPartner, true);

        pcon.selectedPartners[0] = partnerPortalUsers[0].Id;
        pcon.partnerAssignments[0].Partner_Notes__c = 'Test Note';
        
        pcon.selectedPartners[1] = partnerPortalUsers[0].Id;
        pcon.partnerAssignments[1].Partner_Notes__c = 'Test Note';

        System.assertEquals(pcon.canPassToPartner, true);
      	System.assertEquals(pcon.canSave, true);
        PageReference result = pcon.save();
      	System.assertEquals(pcon.canSave, true);
      	Test.stopTest();
    }
    
    static testMethod void PassLeadToPartnerMissingRequireLeadFieldsFailure() {
    	setupTestRecords(true);
    
        ApexPages.StandardController con = new ApexPages.StandardController(lead);
        PassLeadToPartnerController pcon = new PassLeadToPartnerController(con);
        
        Test.startTest();
      	System.assertEquals(pcon.canPassToPartner, false);
    	Test.stopTest();
    }

    
    static testMethod void PassLeadToPartnerWrongAccountTypeFailure() {
    	setupTestRecords(false);
    
        ApexPages.StandardController con = new ApexPages.StandardController(lead);
        PassLeadToPartnerController pcon = new PassLeadToPartnerController(con);

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
	        Test.startTest();
	   		System.assertEquals(pcon.canPassToPartner, true);
	
	        pcon.selectedPartners[0] = partnerPortalUsers[0].Id;
	        pcon.partnerAssignments[1].Partner_Notes__c = 'Test Note';
	        pcon.partnerAssignments[0].Account_Type__c = 'Wrong Type';
	        
	        System.assertEquals(pcon.canPassToPartner, true);
	      	System.assertEquals(pcon.canSave, true);
	        PageReference result = pcon.save();
	      	System.assertEquals(pcon.canSave, false);
	      	Test.stopTest();
//        }
    }
    
    static testMethod void PassLeadToPartnerNoPartnerFailure() {
    setupTestRecords(false);
    
        ApexPages.StandardController con = new ApexPages.StandardController(lead);
        PassLeadToPartnerController pcon = new PassLeadToPartnerController(con);
        
        Test.startTest();
      	System.assertEquals(pcon.canPassToPartner, true);
      	System.assertEquals(pcon.canSave, true);
        PageReference result = pcon.save();
      	System.assertEquals(pcon.canSave, true);
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
		// Default account to assign incoming leads
		portalAccounts.add(new Account(
			Name = 'Twilio Incoming Partner Deals',
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
			LanguageLocaleKey = 'en_US'
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
			LanguageLocaleKey = 'en_US'
		));

		// Need to exeucte within System.runAs() to avoid the following error:
		// MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)
		System.runAs ( runningUser ) {
			insert(partnerPortalUsers);
		}
			
	    // Since the controller "addField()" cannot be used when tests are running we need to
	    // insert and the requery the lead so that it has all the fields needed by the controller.
		Lead l;
		Id leadRecTypeId = Schema.SObjectType.Lead.RecordTypeInfosByName.get(leadRecTypeName).RecordTypeId;
		if (excludeLeadRequiredFields) {
			l = new Lead(
				FirstName = 'TestLead',
				LastName = 'TestLead',
				Company = 'TestCompany',
				 Status = 'Contacted',
				LeadSource = 'Other',
				RecordTypeId = leadRecTypeId,
				Partner_Portal_Lead__c = true
			);
		} else {
			l = new Lead(
				FirstName = 'TestLead',
				LastName = 'TestLead',
				Company = 'TestCompany',
				Status = 'Sales Qualified',
				LeadSource = 'Other',
				OwnerId = partnerPortalUsers[0].Id,
				RecordTypeId = leadRecTypeId,
				Partner_Portal_Lead__c = true
			);
		}

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
			insert(l);
//        }

		lead = [
			SELECT Id, Name, FirstName, LastName, Company, Status, Email, Phone, LeadSource, OwnerId, CreatedDate, RecordTypeId,
				Account_Type__c, Twilio_Account_Manager__c, Account_SID__c, Use_Case__c, Solution_Area__c
			FROM Lead
			WHERE Id = :l.Id
			LIMIT 1
		];
    }
}