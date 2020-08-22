@isTest
private class BatchCreateDealProductsTest {

	private static testMethod void testBatch() {
	             Product2 newProd = new Product2(Name = 'Forecast Lock');
        insert newProd;
        PriceBookEntry pbe = new PriceBookEntry(Product2Id = newProd.Id, PriceBook2Id = Test.getStandardPricebookId(), UnitPrice = 1.0);
        insert pbe;
        Account testAcc = new Account(Name = 'testAcc');
        insert testAcc;
        Opportunity testOpp = new Opportunity(Name = 'testOpp', AccountId = testAcc.Id, StageName ='Incubate', CloseDate = Date.today(), FY_16_Primary_Product__c = 'Programmable Messaging', Contract_Terms_Months__c = 1, Amount = 1000, Launch_Date__c = Date.today());
        insert testOpp;
        Forecast_Schedule__c schedule = new Forecast_Schedule__c(Opportunity__c = testOpp.Id, Forecast_Amount__c = 1000, Start_Date__c = Date.today());
        insert schedule;
        List<Deal__c> deals = [SELECT Id FROM Deal__c];
        delete deals;
        List<Opportunity_Product__c> opps = [SELECT Id FROM Opportunity_Product__c];
        delete opps;
        
        Test.startTest();
            Database.executeBatch(new BatchCreateDealProducts());
        Test.stopTest();
        
	}

}