@isTest
private class MRRCalculationServicesTest {
	static Opportunity testOpp;
	static List<Account> accList;
	static List<Account_SID__c> sidList;
	static List<Account_SID__c> sidListWithNPCDate50;
	static Opportunity oppWithSKU;
	static Opportunity oppExWithSKU;
	static Account_SID__c sidWithSKUA;
	static Account_SID__c sidWithSKUB;
	static List<Account_SID_SKU__c> skuList;
    
	static testMethod void testSKURecords() {
		AccountSID_to_SKU_Config__c config = new AccountSID_to_SKU_Config__c(MRR_Exception__c = 100);
		insert config;
		
		Decimal mrrEx = config.MRR_Exception__c;
		Decimal mrr = mrrEx - 1;
		
		List<AccountSID_to_SKU_Mappings__c> settings = new List<AccountSID_to_SKU_Mappings__c>();
		settings.add(new AccountSID_to_SKU_Mappings__c(Name = 'Programmable Messaging', Product_Name__c = 'Programmable Messaging', Account_SID_API_Name__c = 'Programmable_Messaging_MRR__c',Opp_SKU_Field__c='Programmable_Messaging_MRR__c'));
		settings.add(new AccountSID_to_SKU_Mappings__c(Name = 'Support', Product_Name__c = 'Support', Account_SID_API_Name__c = 'Support_MRR__c',Opp_SKU_Field__c='Support_MRR__c'));
		settings.add(new AccountSID_to_SKU_Mappings__c(Name = 'FY18 - Support', Year__c = 2018,Product_Name__c = 'Support', Account_SID_API_Name__c = 'Support_MRR__c',Opp_SKU_Field__c='Support_MRR__c'));

		insert settings;

        Account acc = new Account(Name = 'Test Acc', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert acc;

		sidWithSKUA = new Account_SID__c(
			Name = 'TESTACCOUNTSIDA',
			Account_SID__c = 'TESTACCOUNTSIDA',
			Account__c = acc.Id,
			Support_MRR__c = mrr,
			Programmable_Messaging_MRR__c = mrr
		);
		sidWithSKUB = new Account_SID__c(
			Name = 'TESTACCOUNTSIDB',
			Account_SID__c = 'TESTACCOUNTSIDB',
			Account__c = acc.Id,
			Support_MRR__c = mrr,
			Programmable_Messaging_MRR__c = mrr
		);
		insert new List<Account_SID__c> { sidWithSKUA, sidWithSKUB };
		System.debug('TESTACCOUNTSIDA: ' + sidWithSKUA);
		System.debug('TESTACCOUNTSIDB: ' + sidWithSKUB);

        oppWithSKU = new Opportunity(Name = 'Test Opp', StageName = 'Pipeline', CloseDate = Date.today());
        oppExWithSKU = new Opportunity(Name = 'Test Opp Exception', StageName = 'Pipeline', CloseDate = Date.today());
        insert new List<Opportunity>{ oppWithSKU, oppExWithSKU };

        Product2 prod = new Product2(Name = 'Forecast Lock');
        insert prod;

        PriceBookEntry pbe = new PriceBookEntry(Product2Id = prod.Id, UnitPrice = 1.0, Pricebook2Id = Test.getStandardPricebookId());
        insert pbe;
        
        Forecast_Schedule__c fs = new Forecast_Schedule__c (Opportunity__c = oppWithSKU.Id, Forecast_Amount__c = 100, Start_Date__c = Date.today());
        insert fs;

		Opportunity_Product__c op = new Opportunity_Product__c(
			Name = 'Test Opp Prod',
			Amount__c = 100,
			Opportunity__c = oppWithSKU.Id,
			Primary_Product__c = true,
			Product_Name__c = 'Support',
			Launch_Date__c = Date.today(),
			Contract_Terms_Months__c = 12
		);
		Opportunity_Product__c opEx = new Opportunity_Product__c(
			Name = 'Test Opp Prod Exception',
			Amount__c = 100,
			Opportunity__c = oppExWithSKU.Id,
			Primary_Product__c = true,
			Product_Name__c = 'Support',
			Launch_Date__c = Date.today(),
			Contract_Terms_Months__c = 12
		);
		insert new List<Opportunity_Product__c> { op, opEx };

        Opp_SID_SKU__c testSKU = new Opp_SID_SKU__c(Opportunity__c = oppWithSKU.Id, Account_SID__c = sidWithSKUA.Id);
        insert testSKU; 
        
		skuList = new List<Account_SID_SKU__c>();
		skuList.add(new Account_SID_SKU__c(
			Account_SID__c = sidWithSKUA.Id,
			Opportunity_Product__c = op.Id,
			MRR_Baseline_Override__c  = 80,
			Type__c = 'Exception',
            Opp_SID_SKU__c= testSKU.id
		));
		skuList.add(new Account_SID_SKU__c(
			Account_SID__c = sidWithSKUA.Id,
			Opportunity_Product__c = opEx.Id,
			MRR_Baseline_Override__c  = 100,
			Type__c = 'Exception',
            Opp_SID_SKU__c= testSKU.id
		));

        test.startTest();
		insert skuList;
        
        skuList = new List<Account_SID_SKU__c>();
        skuList =[Select Id,MRR_Baseline_Override__c from Account_SID_SKU__c];
        skuList[0].MRR_Baseline_Override__c =200;
        skuList[1].MRR_Baseline_Override__c =200;
        update skuList;
        delete skuList;
        test.stopTest();
	}
}