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
private class OpportunityPassToPartnerSelectorTest {
	static Integer recordMax = 10;
		
	static Opportunity testOpp;
	static List<Account> accountList;
	static List<Contact> contactList;
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
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController();
		System.debug('TEST METHOD: noOpptyGivenException');
	}

	static testMethod void badSoqlException() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController();
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
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController();
		Boolean answer = obj.isLocked;
		System.debug('TEST METHOD: isLocked');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void selectItem() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController();
		obj.runSearch();
		//obj.recordID = obj.searchResultsPage[0].account.Id;

		// No selected item, Name, or Contact selected
		obj.save();

		// No Contact selected
		obj.selectItem();
		obj.save();

		// All require fields entered
		obj.selectedContact = obj.opportunityContactOptions[0].getValue();
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
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController();
		System.debug('TEST METHOD: pageAdjustSize');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void pageFullHeight() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		Apexpages.currentPage().getParameters().put('h', 'full');
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController();
		System.debug('TEST METHOD: pageFullHeight');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void pagePixelHeight() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		Apexpages.currentPage().getParameters().put('h', '100px');
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController();
		System.debug('TEST METHOD: pagePixelHeight');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void paginationControls() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController();
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
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'none');
		obj.runSearch();
		System.debug('TEST METHOD: searchNoMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void filterSelection() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
		Apexpages.currentPage().getParameters().put('Partner_Type__c', obj.partnerTypes.isEmpty() ? 'TEST' : obj.partnerTypes[0]);
		Apexpages.currentPage().getParameters().put('Partner_Use_Cases__c', obj.partnerUseCases.isEmpty() ? 'TEST' : obj.partnerUseCases[0]);
		Apexpages.currentPage().getParameters().put('Partner_Products__c', obj.partnerProducts.isEmpty() ? 'TEST' : obj.partnerProducts[0]);
		Apexpages.currentPage().getParameters().put('Buying_Process__c', obj.buyingProcesses.isEmpty() ? 'TEST' : obj.buyingProcesses[0]);
		obj.runSearch();
		System.debug('TEST METHOD: searchOneMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchOneMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNT0');
		obj.runSearch();
		System.debug('TEST METHOD: searchOneMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchMultiMatch() {
		setupTestRecords();	
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNT1');
		obj.runSearch();
		System.debug('TEST METHOD: searchMultiMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchMultiMatchPartnerDirectory() {
		setupTestRecords();	
		Test.setCurrentPageReference(new PageReference('Page.PartnerDirectory')); 
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNT1');
		obj.runSearch();
		System.debug('TEST METHOD: searchMultiMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}	
	
	static testMethod void searchMaxMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
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
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
		obj.sortField = 'Name';
		obj.toggleSort();
		obj.runSearch();
	}
	
	static testMethod void nullSearchText() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
		obj.searchText = null;
		String s = obj.searchText;
		obj.runSearch();
	}
	
	static testMethod void testPicklists() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
		List<String> partnerTypes = obj.partnerTypes;
		List<String> partnerUseCases = obj.partnerUseCases;
		List<String> partnerProducts = obj.partnerProducts;
		List<String> buyingProcesses = obj.buyingProcesses;
		
		String selectedPartnerTypes = obj.selectedPartnerTypes;
		String selectedPartnerUseCases = obj.selectedPartnerUseCases;
		String selectedPartnerProducts = obj.selectedPartnerProducts;
		String selectedBuyingProcesses = obj.selectedBuyingProcesses;
		
		List<SelectOption> partnerTypeOptions = obj.partnerTypeOptions;
		List<SelectOption> partnerUseCaseOptions = obj.partnerUseCaseOptions;
		List<SelectOption> partnerProductOptions = obj.partnerProductOptions;
		List<SelectOption> buyingProcessOptions = obj.buyingProcessOptions;		
	}
	
	static testMethod void testDebug() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityPassToPartnerController obj = new OpportunityPassToPartnerController(con);
		String soql = obj.debugSoql;
		String params = obj.debugParameters;
	}
			
	static void setupTestRecords() {
        Opportunity_to_PTP_Mappings__c setting = new Opportunity_to_PTP_Mappings__c();
        setting.Name = 'BDR_Notes__c';
        setting.PTP_API_Name__c = 'BDR_Notes__c';
        setting.Opportunity_API_Name__c = 'BDR_Notes__c';
        insert setting;
            
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
			Primary_Competitor__c = 'Agendi'
		);
		insert testOpp;
		
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
		
		List<PartnerPortalMappings__c> partnerPortalMappings = new List<PartnerPortalMappings__c>();
		for (Integer i = 0; i < recordMax; i++) {
			partnerPortalMappings.add(new PartnerPortalMappings__c(
				Name = 'PPM-' + i,
				Account_ID__c = accountList[i].Id,
				User_ID__c = userList[i].Id,
				Partner_ID__c = userPartnerList[i].Partner_ID__c
			));
			System.debug('PartnerPortalMappings__c(Name=' + partnerPortalMappings[i].Name
				+ ', AccountID=' + partnerPortalMappings[i].Account_ID__c 
				+ ', UserID=' + partnerPortalMappings[i].User_ID__c 
				+ ', PartnerID=' + partnerPortalMappings[i].Partner_ID__c + ')');
		}
		insert partnerPortalMappings;
	}
}