@isTest
private class WholesaleUsageTest {

	private static testMethod void test() {
	    
	    Account testAcc = new Account(Name = 'testAcc');
	    insert testAcc;
	    
	    Opportunity opp = new Opportunity(Name = 'TestOpp', StageName = 'Incubate', CloseDate = Date.today(), Launch_Date__c = Date.today(), Amount = 1000);
	    insert opp;
	    
	    Opportunity placeholderOpp = new Opportunity(Name = 'Sales Ops Placeholder', StageName = 'Incubate', CloseDate = Date.today(), Launch_Date__c = Date.today(), Amount = 1000, RecordTypeId = '0121W000000MK5l');
	    insert placeholderOpp; 
	    
	    
	    User testUser = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        Wholesale_Usage__c testUsage = new Wholesale_Usage__c   (Date__c = Date.today(), Account_Name__c = 'Test Account', CRM_ID__c = '12345', Opp_Owner__c = testUser.Id, Revenue_Input__c = 100, Profit__c = 23, Margin__c = 30);
        
        Test.startTest();
            insert testUsage;
            Database.executeBatch(new BatchAssignWholesaleUsages());
        Test.stopTest();
	}

}