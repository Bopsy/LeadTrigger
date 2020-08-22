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
private class AgreementAccountSidControllerTest {
	static Opportunity testOpp;
	static Account testAcc;
	static Apttus__APTS_Agreement__c testAgreement;
	static List<Account_SID__c> testSidList;
	static List<Opp_SID_SKU__c> testSkuList;

	static testMethod void noAgreementGivenException() {
		setupTestRecords();
		AgreementAccountSidController obj = new AgreementAccountSidController();
		System.debug('TEST METHOD: throwExceptionAccountSIDPage');
	}

	static testMethod void badSoqlException() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testAgreement.Id);
		AgreementAccountSidController obj = new AgreementAccountSidController();
		obj.sortField = 'Invalid_Field';
		obj.toggleSort();
		obj.runSearch();
		System.debug('TEST METHOD: badSoqlException');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void initialPage() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testAgreement.Id);
		AgreementAccountSidController obj = new AgreementAccountSidController();
		System.debug('TEST METHOD: assignedAccountSID');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void linkPrimaryAccountSID() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testAgreement.Id);
		AgreementAccountSidController obj = new AgreementAccountSidController();
		obj.recordId = testSidList[0].Id;
		obj.accountSID = testSidList[0].Account_SID__c;
		obj.linkAs = 'Primary';
		obj.link();
		System.debug('TEST METHOD: linkPrimaryAccountSID - link');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);

		Boolean hasPrimary = obj.hasPrimarySID;
		
		// Replace the primary
		obj.recordId = testSidList[1].Id;
		obj.accountSID = testSidList[1].Account_SID__c;
		obj.linkAs = 'Primary';
		obj.link();
		System.debug('TEST METHOD: linkPrimaryAccountSID - replace');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void linkFlexAccountSID() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testAgreement.Id);
		AgreementAccountSidController obj = new AgreementAccountSidController();
		obj.recordId = testSidList[0].Id;
		obj.accountSID = testSidList[0].Account_SID__c;
		obj.linkAs = 'Flex';
		obj.link();
		System.debug('TEST METHOD: linkFlexAccountSID - link');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);

		Boolean hasFlex = obj.hasFlexSID;

		Agreement_SID__c agreementSID =  [ SELECT Id FROM Agreement_SID__c LIMIT 1 ];		
		obj.recordId = agreementSID.Id;
		obj.unlink();
		System.debug('TEST METHOD: linkFlexAccountSID - unlink');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void linkAdditionalAccountSID() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testAgreement.Id);
		AgreementAccountSidController obj = new AgreementAccountSidController();
		obj.recordId = testSidList[0].Id;
		obj.accountSID = testSidList[0].Account_SID__c;
		obj.linkAs = 'Something Else';
		obj.link();
		System.debug('TEST METHOD: linkAdditionalAccountSID - link');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);

		Agreement_SID__c agreementSID =  [ SELECT Id FROM Agreement_SID__c LIMIT 1 ];		
		obj.recordId = agreementSID.Id;
		obj.unlink();
		System.debug('TEST METHOD: linkAdditionalAccountSID - unlink');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void searchPage() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testAgreement.Id);
		AgreementAccountSidController obj = new AgreementAccountSidController();
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDPage');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void searchAccountSIDNoMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testAgreement);
		AgreementAccountSidController obj = new AgreementAccountSidController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'none');
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDNoMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchAccountSIDOneMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testAgreement);
		AgreementAccountSidController obj = new AgreementAccountSidController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNTSID49');
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDOneMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchAccountSIDMultiMatch() {
		setupTestRecords();	
		Apexpages.StandardController con = new ApexPages.StandardController(testAgreement);
		AgreementAccountSidController obj = new AgreementAccountSidController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNTSID4');
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDMultiMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}	
	
	static testMethod void searchAccountSIDMaxMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testAgreement);
		AgreementAccountSidController obj = new AgreementAccountSidController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNTSID');
		obj.runSearch();
		System.debug('TEST METHOD: searchAccountSIDMaxMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void toggleSort() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testAgreement);
		AgreementAccountSidController obj = new AgreementAccountSidController(con);
		obj.sortField = 'Account_SID__c';
		obj.toggleSort();
		obj.runSearch();
	}
	
	static testMethod void nullSearchText() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testAgreement);
		AgreementAccountSidController obj = new AgreementAccountSidController(con);
		obj.searchText = null;
		String s = obj.searchText;
		obj.runSearch();
	}
	
	static testMethod void testDebug() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testAgreement);
		AgreementAccountSidController obj = new AgreementAccountSidController(con);
		String soql = obj.debugSoql;
		String params = obj.debugParameters;
	}

	static void setupTestRecords() {
		Account testAcc= new Account(Name = 'TestAcct');
		insert testAcc;
		Profiles_link_trial_account__c setting = new Profiles_link_trial_account__c();
        setting.name='System Administrator';
        insert setting;

		testOpp = new Opportunity(
			Name = 'TestOpp',
			AccountId = testAcc.Id,
			CloseDate = Date.today(),
			StageName = 'Pilot',
			Product__c = 'Client',
			Primary_Competitor__c = 'Agendi'
		);
		insert testOpp;

		testSidList = new List<Account_SID__c>();
		for (Integer i = 0; i<20; i++) {
			testSidList.add(new Account_SID__c(
				Name = 'TESTACCOUNTSID' + i,
				Account_SID__c = 'TESTACCOUNTSID' + i,
				Account_SID_Status__c = 'ACTIVE',
				Account__c = testAcc.Id,
				Account_SID_Created_Date__c = Date.today()
			));
		}
		insert testSidList;

        testSkuList = new List<Opp_SID_SKU__c>();
		for (Integer i = 0; i<20; i++) {
			testSkuList.add(new Opp_SID_SKU__c(
        		Opportunity__c = testOpp.Id,
				Account_SID__c = testSidList[i].Id
			));
		}
        insert testSkuList;

		testAgreement = new Apttus__APTS_Agreement__c(
			Related_Opportunity_APTS__c = testOpp.Id,
			Apttus__Account__c = testAcc.Id
		);
        insert testAgreement;
	}
}