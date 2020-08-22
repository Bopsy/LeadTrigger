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
private class TwilioForecastTrendUpdateTest {

    static testMethod void batchNoArgsTest() {
    	Datetime now = Datetime.now();
	    Integer year = now.year();
	    Integer month = now.month(); 
		String current_months_year = String.valueOf(year);
		String current_months_month = now.format('MMMMM');
    
		Account a = new Account(Name = 'Test Account', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
		insert a;

		List<Twilio_Usage__c> u = new List<Twilio_Usage__c>();
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Total Sales (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 40.00,
			Volume__c = 2,
			Currency__c = 'USD')
		);
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Usage - Short Codes Random (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 20.00,
			Volume__c = 1,
			Currency__c = 'USD')
		);

		insert u;
		
		List<Twilio_Forecast__c> results = [
			SELECT Id, Name
			FROM Twilio_Forecast__c
			WHERE Account__c = :a.Id AND Fiscal_Year__c = :current_months_year
		];
		
		System.assertEquals(12, results.size());
		
		Set<Id> accountIds = new Set<Id>();
		accountIds.add(a.Id);
		Database.executeBatch(new TwilioForecastTrendUpdate(), 200);
    }

    static testMethod void batchSpecificYearTest() {
    	Datetime now = Datetime.now();
	    Integer year = now.year();
	    Integer month = now.month(); 
		String current_months_year = String.valueOf(year);
		String current_months_month = now.format('MMMMM');
    
		Account a = new Account(Name = 'Test Account', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
		insert a;

		List<Twilio_Usage__c> u = new List<Twilio_Usage__c>();
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Total Sales (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 40.00,
			Volume__c = 2,
			Currency__c = 'USD')
		);
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Usage - Short Codes Random (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 20.00,
			Volume__c = 1,
			Currency__c = 'USD')
		);

		insert u;
		
		List<Twilio_Forecast__c> results = [
			SELECT Id, Name
			FROM Twilio_Forecast__c
			WHERE Account__c = :a.Id AND Fiscal_Year__c = :current_months_year
		];
		
		System.assertEquals(12, results.size());
		
		Set<Id> accountIds = new Set<Id>();
		accountIds.add(a.Id);
		Database.executeBatch(new TwilioForecastTrendUpdate(current_months_year), 200);
    }

    static testMethod void batchSpecificAccountsTest() {
    	Datetime now = Datetime.now();
	    Integer year = now.year();
	    Integer month = now.month(); 
		String current_months_year = String.valueOf(year);
		String current_months_month = now.format('MMMMM');
    
		Account a = new Account(Name = 'Test Account', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
		insert a;

		List<Twilio_Usage__c> u = new List<Twilio_Usage__c>();
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Total Sales (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 40.00,
			Volume__c = 2,
			Currency__c = 'USD')
		);
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Usage - Short Codes Random (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 20.00,
			Volume__c = 1,
			Currency__c = 'USD')
		);

		insert u;
		
		List<Twilio_Forecast__c> results = [
			SELECT Id, Name
			FROM Twilio_Forecast__c
			WHERE Account__c = :a.Id AND Fiscal_Year__c = :current_months_year
		];
		
		System.assertEquals(12, results.size());
		
		Set<Id> accountIds = new Set<Id>();
		accountIds.add(a.Id);
		Database.executeBatch(new TwilioForecastTrendUpdate(accountIds), 200);
    }

    static testMethod void batchSpecificAccountsAndYearTest() {
    	Datetime now = Datetime.now();
	    Integer year = now.year();
	    Integer month = now.month(); 
		String current_months_year = String.valueOf(year);
		String current_months_month = now.format('MMMMM');
    
		Account a = new Account(Name = 'Test Account', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
		insert a;
		
		List<Twilio_Usage__c> u = new List<Twilio_Usage__c>();
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Total Sales (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 40.00,
			Volume__c = 2,
			Currency__c = 'USD')
		);
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Usage - Short Codes Random (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 20.00,
			Volume__c = 1,
			Currency__c = 'USD')
		);

		insert u;
		
		List<Twilio_Forecast__c> results = [
			SELECT Id, Name
			FROM Twilio_Forecast__c
			WHERE Account__c = :a.Id AND Fiscal_Year__c = :current_months_year
		];
		
		System.assertEquals(12, results.size());
		
		Set<Id> accountIds = new Set<Id>();
		accountIds.add(a.Id);
		Database.executeBatch(new TwilioForecastTrendUpdate(accountIds, current_months_year), 200);
    }

    static testMethod void batchImportTest() {
    	Datetime now = Datetime.now();
	    Integer year = now.year();
	    Integer month = now.month(); 
		String current_months_year = String.valueOf(year);
		String current_months_month = now.format('MMMMM');
    
		List<Account> accounts = new List<Account>();
		for (Integer i = 1; i <= 500; i++) {
			accounts.add(new Account(Name = 'Test Account ' + i, Employee_Size__c = '0 - 50', Account_SID__c = 'testsite00' + i));
		}
		insert accounts;

		List<Twilio_Usage__c> usages = new List<Twilio_Usage__c>();
		Set<Id> accountIds = new Set<Id>();
		for (Account a : accounts) {
			accountIds.add(a.Id);
			for (Integer i = 1; i <= 2; i++) {
				usages.add(new Twilio_Usage__c(
					AccountSid__c = a.Account_SID__c,
					Product__c = 'Total Sales (Amortized)',
					Month__c = month,
					Year__c = year,
					Total__c = 40.00,
					Volume__c = 2,
					Currency__c = 'USD')
				);
				
				usages.add(new Twilio_Usage__c(
					AccountSid__c = a.Account_SID__c,
					Product__c = 'Usage - Short Codes Random (Amortized)',
					Month__c = month,
					Year__c = year,
					Total__c = 20.00,
					Volume__c = 1,
					Currency__c = 'USD')
				);
			}
		}
		insert usages;
		
		Database.executeBatch(new TwilioForecastTrendUpdate(), accounts.size());
    }

}