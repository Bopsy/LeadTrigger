@isTest
private class NewForecastSchedulerControllerTest {

	static testMethod void testController() {
        Opportunity opp = new Opportunity(Name='Test Opp', StageName = 'Pipeline', CloseDate = Date.today());
        insert opp;
        Product2 prod = new Product2(Name = 'Forecast Lock');
        insert prod;
        PriceBookEntry pbe = new PriceBookEntry(Product2Id = prod.Id, UnitPrice = 1.0, Pricebook2Id = Test.getStandardPricebookId());
        insert pbe;
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        
        Test.startTest();
            NewForecastSchedulerController ctrl = new NewForecastSchedulerController(sc);
            Forecast_Schedule__c fs1 = new Forecast_Schedule__c (Opportunity__c = opp.Id, Forecast_Amount__c = 100, Start_Date__c = Date.today());
            List<Forecast_Schedule__c> fss = new List<Forecast_Schedule__c>{fs1};
            NewForecastSchedulerController.saveForecasts(JSON.serialize(fss), opp.Id);
            insert fs1;
            Forecast_Schedule__c fs2 = new Forecast_Schedule__c (Opportunity__c = opp.Id, Forecast_Amount__c = 200, Start_Date__c = Date.today().addMonths(1));
            fss.add(fs2);
            NewForecastSchedulerController.saveForecasts(JSON.serialize(fss), opp.Id);
            fss = new List<Forecast_Schedule__c>();
            PassToPartnerForecastController.saveForecasts(JSON.serialize(fss), opp.Id);
        Test.stopTest();
	}

}