@isTest
private class OpportunityFSFSplitServicesTest {

	private static testMethod void createSplitsTest() {
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        
        Product2 newProd = new Product2(Name = 'Forecast Lock');
        insert newProd;
        PriceBookEntry pbe = new PriceBookEntry(Product2Id = newProd.Id, PriceBook2Id = Test.getStandardPricebookId(), UnitPrice = 1.0);
        insert pbe;
        Deal__c testDeal = new Deal__c(Name ='Test Deal', OwnerId = testUsers[0].Id);
        insert testDeal;
        
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', StageName = 'Incubate', CloseDate = Date.today(), Deal__c = testDeal.Id, Amount = 120, OwnerId = testUsers[1].Id);
        insert testOpp;
        
        Forecast_Schedule__c testForecast = new Forecast_Schedule__c(Opportunity__c = testOpp.Id, Start_Date__c = Date.today(), Forecast_Amount__c = 10);
        insert testForecast;
        
        Test.startTest();
            OpportunityFSFSplitServices.createSplits(new List<Opportunity>{testOpp});
        Test.stopTest();
	}
    
    private static testMethod void upsertSplitsTest() {
        
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        
        Product2 newProd = new Product2(Name = 'Forecast Lock');
        insert newProd;
        PriceBookEntry pbe = new PriceBookEntry(Product2Id = newProd.Id, PriceBook2Id = Test.getStandardPricebookId(), UnitPrice = 1.0);
        insert pbe;
        Deal__c testDeal = new Deal__c(Name ='Test Deal', OwnerId = testUsers[0].Id);
        insert testDeal;
        
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', StageName = 'Incubate', CloseDate = Date.today(), Deal__c = testDeal.Id, Amount = 120, OwnerId = testUsers[1].Id);
        insert testOpp;
        
        Forecast_Schedule__c testForecast = new Forecast_Schedule__c(Opportunity__c = testOpp.Id, Start_Date__c = Date.today(), Forecast_Amount__c = 10);
        insert testForecast;
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{testOpp.Id => testOpp.clone(true, true, true, true)};
        
        testOpp.Amount = 130;
        List<Opportunity> newRecords = new List<Opportunity>{testOpp};
        
        Test.startTest();
            OpportunityFSFSplitServices.upsertSplits(newRecords, oldMap);
        Test.stopTest();
    }
}