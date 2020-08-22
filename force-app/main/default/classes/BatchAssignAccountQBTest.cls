@isTest
private class BatchAssignAccountQBTest {
    
    static Profile p;
	static User u;
	
	static Account acc;
	static Contact con;
	
    private static void testSetup() {
	
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
		
		acc = new Account(Name='ABC Infotech', BillingPostalCode = '94403', BillingState = 'California', BillingCountry = 'United States', Employee_Size__c = '0-50');
		insert acc;	    
		System.debug('Created test account: ' + acc.Id + ' / ' + acc.Name);
		
		con = new Contact(FirstName='Dummy',LastName='Contact',AccountId = acc.id );
		insert con;		
		System.debug('Created test contact: ' + con.Id + ' / ' + con.LastName);
		
		Account_Quarterback_Routing__c rule = new Account_Quarterback_Routing__c(Country__c = 'United States', State__c = 'California', Zip_Code__c = '.*', Employee_Size__c = '2,501+', Quarterback__c = u.Id);
		insert rule;
		
	}
	
	private static testMethod void testBatch() {
    	testSetup();
	
		Test.startTest();
		
		    Database.executeBatch(new BatchAssignAccountQuarterback(), 200);
		
		Test.stopTest();
	}

}