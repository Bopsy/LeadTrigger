@isTest
private class BatchCreateSplitsTest {

	private static testMethod void testBatch() {
        Account testAcct = new Account( Name = 'TestAcct' );
		insert testAcct;
		
		List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
		Opportunity testOpp = new Opportunity(
			Name = 'TestOpp',
			AccountId = testAcct.Id,
			CloseDate = Date.today(),
			StageName = 'Incubate',
			Solution_Sales_Specialist__c = users[0].Id
		);
		
		insert testOpp;
		Test.startTest();
		    Database.executeBatch(new BatchCreateSplits());
		Test.stopTest();
	}

}