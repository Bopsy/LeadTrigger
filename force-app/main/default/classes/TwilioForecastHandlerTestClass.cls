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
private class TwilioForecastHandlerTestClass {

    static testMethod void accountCreation() {
    	Datetime now = Datetime.now();
	    Integer year = now.year();
	    Integer month = now.month(); 
		String current_months_year = String.valueOf(year);
		String current_months_month = now.format('MMMMM');
    
		Account a = new Account(Name = 'Test Account', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
		insert a;

		Lead l = new Lead(LastName = 'Test Lead', Company = 'Test Company', Account_SID__c = 'abcdef1234567891');
		insert l;
		
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
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567891',
			Product__c = 'Total Sales (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 40.00,
			Volume__c = 2,
			Currency__c = 'USD')
		);
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567891',
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
		TwilioForecastHandler.updateAccountMonthlyRollup(accountIds, current_months_month, current_months_year);
    }
}