@isTest
private class PhantomForecastServicesTest {

	private static testMethod void test() {
        Account testAcct = new Account( Name = 'TestAcct' );
		insert testAcct;
		
		Product2 newProd = new Product2(Name = 'Forecast Lock');
        insert newProd;

        PriceBookEntry pbe = new PriceBookEntry(Product2Id = newProd.Id, PriceBook2Id = Test.getStandardPricebookId(), UnitPrice = 1.0);
        insert pbe;
		
		Opportunity testOpp = new Opportunity(
			Name = 'TestOpp',
			AccountId = testAcct.Id,
			CloseDate = Date.today(),
			StageName = 'Incubate',
			FY_16_Primary_Product__c = 'Programmable Messaging',
		    Amount = 1200,
		    Contract_Terms_Months__c = 12,
		    Launch_Date__c = Date.today()
		);
		
		insert testOpp;
		testOpp = [SELECT Contract_Terms_Months__c, Launch_Date__c, Number_of_Schedules__c FROM Opportunity WHERE Id =: testOpp.Id LIMIT 1];
		
		Test.startTest();
		    PhantomForecastServices.createPhantomForecasts(new List<Opportunity>{testOpp});
		    testOpp.StageName = 'Closed Won';
		    update testOpp;
		    delete [SELECT Id FROM Forecast_Schedule__c WHERE Opportunity__c =: testOpp.Id];
		    Database.executeBatch(new BatchGeneratePhantomForecast());
		Test.stopTest();
	}

}