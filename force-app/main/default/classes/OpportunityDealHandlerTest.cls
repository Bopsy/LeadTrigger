@isTest
private class OpportunityDealHandlerTest {

	private static testMethod void testTeamMember() {
        User testUser = [SELECT Id FROM USER WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        Account testAcc = new Account(Name = 'testAcc');
        insert testAcc;
        Opportunity testOpp = new Opportunity(Name = 'testOpp', AccountId = testAcc.Id, StageName ='Incubate', CloseDate = Date.today(), FY_16_Primary_Product__c = 'Programmable Messaging', Contract_Terms_Months__c = 1, Amount = 1000, Launch_Date__c = Date.today());
        insert testOpp;
        Deal__c testDeal = [SELECT Id FROM Deal__c LIMIT 1];
        Test.startTest();
            testDeal.OwnerId = testUser.Id;
            update testDeal;
        Test.stopTest();
	}

}