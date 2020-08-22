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
private class OpportunityUseCaseTest {
	static Opportunity testOpp;
	static List<Account> accList;
	static List<Use_Case__c> ucList;
	
	static testMethod void pageAdjustSize() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		Apexpages.currentPage().getParameters().put('s', '3');
		OpportunityUseCaseController obj = new OpportunityUseCaseController();
		System.debug('TEST METHOD: pageAdjustSize');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void pageFullHeight() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		Apexpages.currentPage().getParameters().put('h', 'full');
		OpportunityUseCaseController obj = new OpportunityUseCaseController();
		System.debug('TEST METHOD: pageFullHeight');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void pagePixelHeight() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		Apexpages.currentPage().getParameters().put('h', '100px');
		OpportunityUseCaseController obj = new OpportunityUseCaseController();
		System.debug('TEST METHOD: pagePixelHeight');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void paginationControls() {
		setupTestRecords();
		Apexpages.currentPage().getParameters().put('id', testOpp.Id);
		OpportunityUseCaseController obj = new OpportunityUseCaseController();
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

	static testMethod void searchUseCasesPage() {
		setupTestRecords();
		OpportunityUseCaseController obj = new OpportunityUseCaseController();
		Apexpages.currentPage().getParameters().put('searchText', 'none');
		obj.runSearch();
		System.debug('TEST METHOD: searchUseCasesPage');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void searchUseCasesNoMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityUseCaseController obj = new OpportunityUseCaseController(con);
		Apexpages.currentPage().getParameters().put('searchText', 'none');
		obj.runSearch();
		System.debug('TEST METHOD: searchUseCasesNoMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchUseCasesOneMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityUseCaseController obj = new OpportunityUseCaseController(con);
		Apexpages.currentPage().getParameters().put('Industry__c', '\'Industry 1\'');
		Apexpages.currentPage().getParameters().put('Use_Case__c', '\'UseCase 1\'');
		Apexpages.currentPage().getParameters().put('Country__c', '\'Country 1\'');
		Apexpages.currentPage().getParameters().put('searchText', 'test');
		obj.runSearch();
		System.debug('TEST METHOD: searchUseCasesMultiMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}
	
	static testMethod void searchUseCasesMultiMatch() {
		setupTestRecords();	
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityUseCaseController obj = new OpportunityUseCaseController(con);
		Apexpages.currentPage().getParameters().put('Industry__c', '\'Industry 1\',\'Industry 2\'');
		obj.runSearch();
		System.debug('TEST METHOD: searchUseCasesMultiMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}	
	
	static testMethod void searchUseCasesMaxMatch() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityUseCaseController obj = new OpportunityUseCaseController(con);
		obj.runSearch();
		System.debug('TEST METHOD: searchUseCasesMaxMatch');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}

	static testMethod void searchUseCasesThrowException() {
		setupTestRecords();	
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityUseCaseController obj = new OpportunityUseCaseController(con);
		Apexpages.currentPage().getParameters().put('Industry__c', '\'Industry 1\'x\'Industry 2\'');
		obj.searchResults = null;
		obj.runSearch();
		System.debug('TEST METHOD: searchUseCasesThrowException');
		System.debug(obj.debugSoql);
		System.debug(obj.debugParameters);
	}	
		
	static testMethod void toggleSort() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityUseCaseController obj = new OpportunityUseCaseController(con);
		obj.sortField = 'Industry__c';
		obj.toggleSort();
		obj.runSearch();
	}
	
	static testMethod void nullSearchText() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityUseCaseController obj = new OpportunityUseCaseController(con);
		obj.searchText = null;
		String s = obj.searchText;
		obj.runSearch();
	}

	
	static testMethod void testPicklists() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityUseCaseController obj = new OpportunityUseCaseController(con);
		List<String> industries = obj.industries;
		List<String> useCases = obj.useCases;
		List<String> countries = obj.countries;
		
		String selectedIndustry = obj.selectedIndustry;
		String selectedUseCase = obj.selectedUseCase;
		String selectedCountry = obj.selectedCountry;
		
		List<SelectOption> industryOptions = obj.industryOptions;
		List<SelectOption> useCaseOptions = obj.useCaseOptions;
		List<SelectOption> countryOptions = obj.countryOptions;		
	}

	
	static testMethod void testDebug() {
		setupTestRecords();
		Apexpages.StandardController con = new ApexPages.StandardController(testOpp);
		OpportunityUseCaseController obj = new OpportunityUseCaseController(con);
		String soql = obj.debugSoql;
		String params = obj.debugParameters;
	}
			
	static void setupTestRecords() {
		List<String> countries = new List<String>();
        Schema.DescribeFieldResult field = Account.BillingCountryCode.getDescribe();
        for (Schema.PicklistEntry f : field.getPicklistValues())
          countries.add(f.getValue());

		accList = new List<Account>();
		for (Integer i = 0; i<10; i++) {
			accList.add(new Account(
				Name = 'TestAcct',
				Total_Amortized_Twilio_Usage_Last_Month__c = 100,
				BillingCountryCode = countries[i],
				Industry = 'Industry ' + i
			));
		}
		insert accList;

		ucList = new List<Use_Case__c>();
		for (Integer i = 0; i<10; i++) {
			ucList.add(new Use_Case__c(
				Account__c = accList[i].Id,
				Primary_Use_Case__c = false,
				Use_Case__c = 'UseCase ' + i,
				Use_Case_Notes__c = 'UseCaseNotes ' + i,
				Referenceable__c = true
			));
		}
		insert ucList;

		testOpp = new Opportunity(
			Name = 'TestOpp',
			AccountId = accList[0].Id,
			CloseDate = Date.today(),
			StageName = 'Pilot',
			FY_16_Use_Case__c = 'UseCase 1',
			Authy_Use_Case__c = 'Call Tracking',
			Product__c = 'Client',
			Primary_Competitor__c = 'Agendi',
			New_Business_Account_SID__c = '01234567890'
		);
		insert testOpp;

	}	
}