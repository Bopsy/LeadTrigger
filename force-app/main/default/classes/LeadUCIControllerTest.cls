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
private class LeadUCIControllerTest {
        
	static Profile p;
	static User u;
	
	static Account acc;
	static Contact con;
	
	static Lead testLead;
	static FSR__c testMQL;
	static Use_Case_Interest__c testUCI;
    
    static testMethod void noLeadException() {
        setupTestRecords();
        //MQLTerritorySearchController obj = new MQLTerritorySearchController();
        System.debug('TEST METHOD: noOpptyGivenException');
    }

    static testMethod void searchItem() {
        setupTestRecords();

        Apexpages.currentPage().getParameters().put('id', testMQL.Id);
        Test.startTest();
            Apexpages.StandardController con = new ApexPages.StandardController(testMQL);
            MQLTerritorySearchController obj = new MQLTerritorySearchController(con);
            UCISearchController obj2 = new UCISearchController();
        
            Apexpages.StandardController con2 = new ApexPages.StandardController(testUCI);
            UCITerritorySearchController obj3 = new UCITerritorySearchController(con2);
            Apexpages.currentPage().getParameters().put('employeeSize', 'Under 1,000');
            Apexpages.currentPage().getParameters().put('state', 'California');
            Apexpages.currentPage().getParameters().put('country', 'United States');
            Apexpages.currentPage().getParameters().put('zipCode', '');
            obj.authyProduct = true;
            obj2.authyProduct = true;
            obj3.authyProduct = true;
            obj.runSearch();
            obj2.runSearch();
            obj3.runSearch();
            List<SelectOption> opt1 = obj2.employeeSizeOptions;
            List<SelectOption> opt2 = obj3.employeeSizeOptions;
        Test.stopTest();
    }

    static testMethod void testPicklists() {
        setupTestRecords();
        Apexpages.StandardController con = new ApexPages.StandardController(testMQL);
        MQLTerritorySearchController obj = new MQLTerritorySearchController(con);

        List<SelectOption> employeeSizeOptions = obj.employeeSizeOptions;
        System.assertEquals(false, employeeSizeOptions.isEmpty());
    }
    
    static void setupTestRecords() {
		p = [Select Id from Profile where name = 'Standard User'];

		// Test Standard User
		u = new User();
		u.ProfileId = p.Id;
		u.Username = System.now().getTime() + 'test@twilio.com.uci.test';
		u.Alias = 'testtest';
		u.Email='test@test-uci-12345.com';
		u.EmailEncodingKey='UTF-8';
		u.Firstname='Test';
		u.Lastname='Test';
		u.LanguageLocaleKey='en_US';
		u.LocaleSidKey='en_US';
		u.TimeZoneSidKey='America/Chicago';
		
		//runAs
		insert u;
		System.debug('Created test user: ' + u.Id);

		// Custom Settings config for Use Case Interest
		Use_Case_Interest_Settings__c setting = new Use_Case_Interest_Settings__c();
		setting.Name = 'FY_16_Primary_Product__c';
		setting.Opportunity_Field__c = 'FY_16_Primary_Product__c';
		setting.Use_Case_Interest_Field__c = 'FY_16_Primary_Product__c';
		insert setting;		
		
		Use_Case_Interest_Settings__c setting2 = new Use_Case_Interest_Settings__c();
		setting2.Name = 'Amount';
		setting2.Opportunity_Field__c = 'Amount';
		setting2.Use_Case_Interest_Field__c = 'Volume__c';
		insert setting2;		
        
        Use_Case_Interest_Settings__c setting3 = new Use_Case_Interest_Settings__c();
		setting3.Name = 'Solution Category';
		setting3.Opportunity_Field__c = 'Solution_Category__c';
		setting3.Use_Case_Interest_Field__c = 'Solution_Category__c';
		insert setting3;		
		
		acc = new Account(
			Name='ABC Infotech',
			BillingPostalCode = '94403',
			BillingState = 'California',
			BillingCountry = 'United States',
			Employee_Size__c = '0-50'
		);
		insert acc;	    
		System.debug('Created test account: ' + acc.Id + ' / ' + acc.Name);
		
		con = new Contact(
			FirstName='Dummy',
			LastName='Contact',
			AccountId = acc.id
		);
		insert con;		
		System.debug('Created test contact: ' + con.Id + ' / ' + con.LastName);
		
		Opportunity_Routing_Rules__c rule = new Opportunity_Routing_Rules__c(
			Country__c = 'United States',
			State__c = 'California',
			Zip_Code__c = '.*',
			Employee_Size__c = 'Under 1,000',
			Opportunity_Owner__c = u.Id
		);
		insert rule;

        testLead = new Lead(
            LastName = 'TESTCONTACT',
            Company = 'TESTCOMPANY',
            PostalCode = '',
            State = 'California',
            Country = 'United States',
            Employee_Size__c = '501 - 1,000'
        );
        insert testLead;
        
        testMQL = new FSR__c(
            Lead__c = testLead.Id
        );
        insert testMQL;
        
        testUCI = new Use_Case_Interest__c(
            Lead__c = testLead.Id,
            MQL__c = testMQL.Id
        );
        insert testUCI;
    }
}