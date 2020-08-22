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
private class OpportunityShortCodeSelectorTest {
	static Integer recordMax = 10;
		
	static Opportunity testOpp, testOppNoAccountSID;
	static List<Account> accountList;
	static List<Contact> contactList;
	static List<Account_SID__c> sidList;
	static List<Short_Code__c> shortCodeList;
	static List<User> userList;

	static testMethod void unsetContactTrigger() {
		setupTestRecords();
		Pass_To_Partner__c p = new Pass_To_Partner__c(
			Opportunity__c = testOpp.Id,
			Partner_Status__c = 'Open',
			Contact__c = contactList[0].Id
		);
		insert p;
		p.Partner_Status__c = 'Declined';
		update p;
		System.debug('TEST METHOD: unsetContactTrigger');
	}

	static testMethod void noOpptyGivenException() {
		setupTestRecords();
		OpportunityShortCodeController obj = new OpportunityShortCodeController();
		System.debug('TEST METHOD: noOpptyGivenException');
	}

	static testMethod void badSoqlException() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityShortCodeController obj = new OpportunityShortCodeController();
		obj.sortField = 'Invalid_Field';
		obj.toggleSort();
		obj.runSearch();
		System.debug('TEST METHOD: badSoqlException');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void isLocked() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityShortCodeController obj = new OpportunityShortCodeController();
		Boolean answer = obj.isLocked;
		System.debug('TEST METHOD: isLocked');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void selectItem() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityShortCodeController obj = new OpportunityShortCodeController();
		obj.runSearch();
		obj.recordID = obj.searchResultsPage[0].sc.Id;

		obj.selectItem();
		obj.save();

		Boolean answer = obj.isLocked;
		System.debug('TEST METHOD: selectItem');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void pageAdjustSize() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		Apexpages.currentPage().getParameters().put('s', '3');
		OpportunityShortCodeController obj = new OpportunityShortCodeController();
		System.debug('TEST METHOD: pageAdjustSize');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void pageFullHeight() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		Apexpages.currentPage().getParameters().put('h', 'full');
		OpportunityShortCodeController obj = new OpportunityShortCodeController();
		System.debug('TEST METHOD: pageFullHeight');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void pagePixelHeight() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		Apexpages.currentPage().getParameters().put('h', '100px');
		OpportunityShortCodeController obj = new OpportunityShortCodeController();
		System.debug('TEST METHOD: pagePixelHeight');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void paginationControls() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityShortCodeController obj = new OpportunityShortCodeController();
		obj.runSearch();
		Boolean hasNext = obj.hasNext;
		Boolean hasPrevious = obj.hasPrevious;
		obj.first();
		obj.next();
		obj.last();
		obj.previous();
		System.debug('TEST METHOD: paginationControls');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void searchNoMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityShortCodeController obj = new OpportunityShortCodeController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'none');
		obj.runSearch();
		System.debug('TEST METHOD: searchNoMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchOneMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityShortCodeController obj = new OpportunityShortCodeController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNT0');
		obj.runSearch();
		System.debug('TEST METHOD: searchOneMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchMultiMatch() {
		setupTestRecords();	
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityShortCodeController obj = new OpportunityShortCodeController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNT1');
		obj.runSearch();
		System.debug('TEST METHOD: searchMultiMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}	
	
	static testMethod void searchMaxMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityShortCodeController obj = new OpportunityShortCodeController(con);
		obj.maxSearchResults = recordMax - 1;
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNT');
		obj.runSearch();
		System.debug('TEST METHOD: searchMaxMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void toggleSort() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityShortCodeController obj = new OpportunityShortCodeController(con);
		obj.sortField = 'Name';
		obj.toggleSort();
		obj.runSearch();
	}
	
	static testMethod void nullSearchText() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityShortCodeController obj = new OpportunityShortCodeController(con);
		obj.searchText = null;
		String s = obj.searchText;
		obj.runSearch();
	}
	
	static testMethod void testDebug() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityShortCodeController obj = new OpportunityShortCodeController(con);
		String soql = obj.debugSoql;
		String sids = obj.debugAccountSIDs;
		String params = obj.debugParameters;
	}
			
	static void setupTestRecords() {
		accountList = new List<Account>();
		for (Integer i = 0; i < recordMax; i++) {
			accountList.add(new Account(
				Name = 'TESTACCOUNT' + i,
				//Partner_Account_Level__c = 'Tier 1',
				Partner_ID__c = 'ABC000' + i
			));
		}
		insert accountList;

		contactList = new List<Contact>();
		for (Integer i = 0; i < recordMax; i++) {
			contactList.add(new Contact(
				LastName = 'TESTCONTACT' + i,
				AccountID = accountList[i].Id
			));
		}
		insert contactList;

		sidList = new List<Account_SID__c>();
		for (Integer i = 0; i<50; i++) {
			sidList.add(new Account_SID__c(
				Name = 'TESTACCOUNTSID' + i,
				Account_SID__c = 'TESTACCOUNTSID' + i,
				Account_SID_Status__c = 'ACTIVE',
				Account__c = accountList[0].Id,
				Account_SID_Created_Date__c = Date.today()
			));
		}
		insert sidList;

		Profile p = [Select ID, Name from Profile Where Name = '**Partner Community DREG & PTP'];
		userList = new List<User>();
		for (Integer i = 0; i < recordMax; i++) {
			String email = 'test_' + i + '@test-' + math.random() + '.com';
		    userList.add(new User(
		        UserName = email,
		        FirstName = 'TEST-FIRST' + i,
		        LastName = 'TEST-LAST' + i,
		        Alias = 'test',
		        Email = email,
		        CommunityNickName = 'T' + i + string.valueOf(math.random()).substring(0,4),
		        ProfileID = p.id,
		        TimeZoneSidKey = 'America/New_York', 
		        LocaleSidKey = 'en_US', 
		        EmailEncodingKey = 'UTF-8', 
		        LanguageLocaleKey = 'en_US',
		        ContactId = contactList[i].Id
		    ));
		}
		insert userList;

		// Query the created users to get the Partner_ID__c that was auto-generated.
		List<Id> ids = new List<Id>();
		for (User u : userList) { ids.add(u.Id); }
		List<User> userPartnerList = [ SELECT Id, Partner_ID__c FROM User WHERE Id IN :ids ];

		testOpp = new Opportunity(
			Name = 'TestOpp',
			AccountId = accountList[0].Id,
			CloseDate = Date.today(),
			StageName = 'Pilot',
			Product__c = 'Client',
			Primary_Competitor__c = 'Agendi',
			New_Business_Account_SID_Lookup__c = sidList[0].Id
		);
		insert testOpp;

		testOppNoAccountSID = new Opportunity(
			Name = 'TestOpp',
			AccountId = accountList[0].Id,
			CloseDate = Date.today(),
			StageName = 'Pilot',
			Product__c = 'Client',
			Primary_Competitor__c = 'Agendi'
		);
		insert testOppNoAccountSID;

		List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
		opportunityContactRoles.add(new OpportunityContactRole(
			OpportunityId = testOpp.Id,
			ContactId = contactList[0].Id
		));
		insert opportunityContactRoles;
		
		// Updated the accounts with the Partner ID auto-generated on the User record.
		for (Integer i = 0; i < recordMax; i++) {
			accountList[i].Partner_ID__c = userPartnerList[i].Partner_ID__c;
		}
		update accountList;

		shortCodeList = new List<Short_Code__c>();
		for (Integer i = 0; i < recordMax; i++) {
			shortCodeList.add(new Short_Code__c(
				Account_SID__c = 'TESTACCOUNTSID' + i,
				Short_Code_App_Sid__c = 'SHORTCODEAPPSID' + i,
				Application_Status__c = 'Not Approved'
			));
		}
		insert shortCodeList;
	}
}