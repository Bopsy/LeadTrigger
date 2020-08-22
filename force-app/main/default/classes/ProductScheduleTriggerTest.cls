@isTest
private class ProductScheduleTriggerTest {

	private static testMethod void testTrigger() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        
        Product2 newProd = new Product2(Name = 'Forecast Lock');
        insert newProd;

        PriceBookEntry pbe = new PriceBookEntry(Product2Id = newProd.Id, PriceBook2Id = Test.getStandardPricebookId(), UnitPrice = 1.0);
        insert pbe;
        
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', StageName = 'Incubate', Amount = 1000, CloseDate = Date.today(), Launch_Date__c = Date.today());
        insert testOpp;
        Forecast_Schedule__c testFS1 = new Forecast_Schedule__c(Forecast_Amount__c = 100, Start_Date__c = Date.today(), Opportunity__c = testOpp.Id);
        Forecast_Schedule__c testFS2 = new Forecast_Schedule__c(Forecast_Amount__c = 100, Start_Date__c = Date.today().addMonths(1), Opportunity__c = testOpp.Id);
        insert new List<Forecast_Schedule__c>{testFS1, testFS2};
        
        Opportunity_Product__c oppProd = new Opportunity_Product__c(Opportunity__c = testOpp.Id, Name = 'Flex', Product_Name__c = 'Flex', Amount__c = 200);
        insert oppProd;
        
        Product_Schedule__c testProdShceudle1 = new Product_Schedule__c(Forecast_Amount__c = 100, Opportunity_Product__c = oppProd.Id, Forecast_Schedule__c = testFS1.Id);
        Product_Schedule__c testProdShceudle2 = new Product_Schedule__c(Forecast_Amount__c = 100, Opportunity_Product__c = oppProd.Id, Forecast_Schedule__c = testFS2.Id);
        
        
        Test.startTest();
            insert new List<Product_Schedule__c>{testProdShceudle1, testProdShceudle2};
            testFS1.Start_Date__c = Date.today().addMonths(2);
            testFS2.Start_Date__c = Date.today().addMonths(3);
            update new List<Forecast_Schedule__c>{testFS1, testFS2};
        Test.stopTest();
	}

}