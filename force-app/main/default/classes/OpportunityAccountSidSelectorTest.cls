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
private class OpportunityAccountSidSelectorTest {
	static Opportunity testOpp;
	static List<Account> accList;
	static List<Account_SID__c> sidList;
	static List<Account_SID__c> sidListWithNPCDate50;

	static testMethod void noOpptyGivenException() {
		setupTestRecords();
		OpportunityAccountSidController obj = new OpportunityAccountSidController();
		System.debug('TEST METHOD: throwExceptionAccountSIDPage');
	}

	static testMethod void badSoqlException() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityAccountSidController obj = new OpportunityAccountSidController();
		obj.sortField = 'Invalid_Field';
		obj.toggleSort();
		obj.runSearch();
		System.debug('TEST METHOD: badSoqlException');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void assignedAccountSID() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityAccountSidController obj = new OpportunityAccountSidController();
		Boolean result = obj.accountSIDAssigned;
		System.debug('TEST METHOD: assignedAccountSID');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void selectAccountSID() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityAccountSidController obj = new OpportunityAccountSidController();
/* REMOVED LIMITATION TO ONLY SHOW ACCCOUNT SID'S RELATED TO THE OPPORTUNITY
		obj.accountId = 'TESTACCOUNTSID0';
*/
		obj.isNewBusiness = true;
		obj.recordId = sidList[0].Id;
		obj.accountSID = sidList[0].Account_SID__c;
		obj.selectAccountSID();
		obj.save();
		System.debug('TEST METHOD: selectAccountSIDPage');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void selectAccountSIDNPCDate50() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityAccountSidController obj = new OpportunityAccountSidController();
/* REMOVED LIMITATION TO ONLY SHOW ACCCOUNT SID'S RELATED TO THE OPPORTUNITY
		obj.accountId = 'TESTACCOUNTSIDNPC500';
*/
		obj.isNewBusiness = false;
		obj.recordId = sidListWithNPCDate50[0].Id;
		obj.accountSID = sidListWithNPCDate50[0].Account_SID__c;
		obj.selectAccountSID();
		obj.save();  // Should trigger exception since no reason supplied

		obj.exceptionAccountSIDReason = 'TEST REASON';
		//obj.save();
		System.debug('TEST METHOD: selectAccountSIDPage');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void searchPage() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityAccountSidController obj = new OpportunityAccountSidController();
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDPage');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void searchAccountSIDNoMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityAccountSidController obj = new OpportunityAccountSidController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'none');
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDNoMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchAccountSIDOneMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityAccountSidController obj = new OpportunityAccountSidController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNTSID49');
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDOneMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchAccountSIDMultiMatch() {
		setupTestRecords();	
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityAccountSidController obj = new OpportunityAccountSidController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNTSID4');
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDMultiMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}	
	
	static testMethod void searchAccountSIDMaxMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityAccountSidController obj = new OpportunityAccountSidController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNTSID');
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDMaxMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void toggleSort() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityAccountSidController obj = new OpportunityAccountSidController(con);
		obj.sortField = 'Account_SID__c';
		obj.toggleSort();
		obj.runSearch();
	}
	
	static testMethod void nullSearchText() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityAccountSidController obj = new OpportunityAccountSidController(con);
		obj.searchText = null;
		String s = obj.searchText;
		obj.runSearch();
	}
	
	static testMethod void testDebug() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityAccountSidController obj = new OpportunityAccountSidController(con);
		String soql = obj.debugSoql;
		String params = obj.debugParameters;
	}

	static void setupTestRecords() {
		accList = new List<Account>();
		for (Integer i = 0; i<10; i++) {
			accList.add(new Account(
				Name = 'TestAcct'
			));
		}
		insert accList;

		sidList = new List<Account_SID__c>();
		for (Integer i = 0; i<50; i++) {
			sidList.add(new Account_SID__c(
				Name = 'TESTACCOUNTSID' + i,
				Account_SID__c = 'TESTACCOUNTSID' + i,
				Account_SID_Status__c = 'ACTIVE',
				Account__c = accList[0].Id,
				Account_SID_Created_Date__c = Date.today()
			));
		}
		insert sidList;

		sidListWithNPCDate50 = new List<Account_SID__c>();
		for (Integer i = 0; i<50; i++) {
			sidListWithNPCDate50.add(new Account_SID__c(
				Name = 'TESTACCOUNTSIDNPC50' + i,
				Account_SID__c = 'TESTACCOUNTSIDNPC50' + i,
				Account_SID_Status__c = 'ACTIVE',
				Account__c = accList[0].Id,
				NPC_Date_50__c = Date.today()
			));
		}
		insert sidListWithNPCDate50;

		testOpp = new Opportunity(
			Name = 'TestOpp',
			AccountId = accList[0].Id,
			CloseDate = Date.today(),
			StageName = 'Pilot',
			Product__c = 'Client',
			Primary_Competitor__c = 'Agendi'
		);
		insert testOpp;
	}

	/*
	 * Account SID SKU related test cases
	 */

	static Opportunity oppWithSKU;
	static Opportunity oppExWithSKU;
	static Account_SID__c sidWithSKUA;
	static Account_SID__c sidWithSKUB;
	static List<Account_SID_SKU__c> skuList;

	static testMethod void searchAccountSIDSKUMatch() {
		setupTestSKURecords();
		Apexpages.StandardController con = new ApexPages.StandardController(oppWithSKU);
		OpportunityAccountSidController obj = new OpportunityAccountSidController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNTSIDA');
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDSKUMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void selectAccountSIDSKU() {
		setupTestSKURecords();
		Apexpages.currentPage().getParameters().put('id', oppWithSKU.Id);
		OpportunityAccountSidController obj = new OpportunityAccountSidController();
		obj.isNewBusiness = true;
		obj.recordID = sidWithSKUA.Id;
		obj.accountSID = sidWithSKUA.Account_SID__c;
		obj.selectAccountSID();
		System.debug('TEST METHOD: selectAccountSIDSKU');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
			
	static void setupTestSKURecords() {
		AccountSID_to_SKU_Config__c config = new AccountSID_to_SKU_Config__c(MRR_Exception__c = 100);
		insert config;
		
		Decimal mrrEx = config.MRR_Exception__c;
		Decimal mrr = mrrEx - 1;
		
		List<AccountSID_to_SKU_Mappings__c> settings = new List<AccountSID_to_SKU_Mappings__c>();
		settings.add(new AccountSID_to_SKU_Mappings__c(Name = 'Programmable Messaging', Product_Name__c = 'Programmable Messaging', Account_SID_API_Name__c = 'Programmable_Messaging_MRR__c'));
		settings.add(new AccountSID_to_SKU_Mappings__c(Name = 'Support', Product_Name__c = 'Support', Account_SID_API_Name__c = 'Support_MRR__c'));
		insert settings;

        Account acc = new Account(Name = 'Test Acc', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert acc;

		sidWithSKUA = new Account_SID__c(
			Name = 'TESTACCOUNTSIDA',
			Account_SID__c = 'TESTACCOUNTSIDA',
			Account__c = acc.Id,
			Support_MRR__c = mrr,
			Programmable_Messaging_MRR__c = mrr
		);
		sidWithSKUB = new Account_SID__c(
			Name = 'TESTACCOUNTSIDB',
			Account_SID__c = 'TESTACCOUNTSIDB',
			Account__c = acc.Id,
			Support_MRR__c = mrr,
			Programmable_Messaging_MRR__c = mrr
		);
		insert new List<Account_SID__c> { sidWithSKUA, sidWithSKUB };
		System.debug('TESTACCOUNTSIDA: ' + sidWithSKUA);
		System.debug('TESTACCOUNTSIDB: ' + sidWithSKUB);

        oppWithSKU = new Opportunity(Name = 'Test Opp', StageName = 'Pipeline', CloseDate = Date.today());
        oppExWithSKU = new Opportunity(Name = 'Test Opp Exception', StageName = 'Pipeline', CloseDate = Date.today());
        insert new List<Opportunity>{ oppWithSKU, oppExWithSKU };

        Product2 prod = new Product2(Name = 'Forecast Lock');
        insert prod;

        PriceBookEntry pbe = new PriceBookEntry(Product2Id = prod.Id, UnitPrice = 1.0, Pricebook2Id = Test.getStandardPricebookId());
        insert pbe;
        
        Forecast_Schedule__c fs = new Forecast_Schedule__c (Opportunity__c = oppWithSKU.Id, Forecast_Amount__c = 100, Start_Date__c = Date.today());
        insert fs;

		Opportunity_Product__c op = new Opportunity_Product__c(
			Name = 'Test Opp Prod',
			Amount__c = 100,
			Opportunity__c = oppWithSKU.Id,
			Primary_Product__c = true,
			Product_Name__c = 'Support',
			Launch_Date__c = Date.today(),
			Contract_Terms_Months__c = 12
		);
		Opportunity_Product__c opEx = new Opportunity_Product__c(
			Name = 'Test Opp Prod Exception',
			Amount__c = 100,
			Opportunity__c = oppExWithSKU.Id,
			Primary_Product__c = true,
			Product_Name__c = 'Support',
			Launch_Date__c = Date.today(),
			Contract_Terms_Months__c = 12
		);
		insert new List<Opportunity_Product__c> { op, opEx };

		skuList = new List<Account_SID_SKU__c>();
		skuList.add(new Account_SID_SKU__c(
			Account_SID__c = sidWithSKUA.Id,
			Opportunity_Product__c = op.Id,
			MRR__c = mrr,
			Type__c = 'Exception'
		));
		skuList.add(new Account_SID_SKU__c(
			Account_SID__c = sidWithSKUA.Id,
			Opportunity_Product__c = opEx.Id,
			MRR__c = mrr+5,
			Type__c = 'Exception'
		));

		insert skuList;
	}
}