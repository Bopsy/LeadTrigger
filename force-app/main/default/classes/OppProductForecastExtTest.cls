/******************************************
//Last Modified by: Gram Bischof {01/14/2020}
//
//Description: This is the test class of OppProductForecastExt
//
*******************************************/
@isTest
private class OppProductForecastExtTest {

	private static testMethod void testConstructor() {
	    WholesaleUsageServices.bypassTrigger = false;
        Product2 newProd = new Product2(Name = 'Forecast Lock');
        insert newProd;
        PriceBookEntry pbe = new PriceBookEntry(Product2Id = newProd.Id, PriceBook2Id = Test.getStandardPricebookId(), UnitPrice = 1.0);
        insert pbe;
        
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Deal__c testDeal = new Deal__c(Name = 'Test Deal', Account__c = testAcc.Id);
        insert testDeal;
        Account_SID__c testSid = new Account_SID__c(Name = 'Test SID');
        insert testSid;
        
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', CloseDate = Date.today(), StageName = 'Incubate', /*Deal__c = testDeal.Id,*/ AccountId = testAcc.Id, FY_16_Primary_Product__c = 'Programmable Messaging', Amount = 1200, Launch_Date__c = Date.today(), Contract_Terms_Months__c = 12);
        insert testOpp;
        
        //trigger will create a primary opp product
        Opportunity_Product__c primaryProduct = new Opportunity_Product__c(Name = 'Programmable Messaging', Product_Name__c = 'Programmable Messaging', Amount__c = 1200, Opportunity__c = testOpp.Id);
        insert primaryProduct;
        Product_Schedule__c schedule = new Product_Schedule__c(New_Business_Forecast_Amount__c = 100, Start_Date__c = Date.today(), End_Date__c = Date.today().toStartOfMonth().addMonths(1).addDays(-1), Opportunity_Product__c = primaryProduct.Id);
        Twilio_Sub_Product__c subProduct = new Twilio_Sub_Product__c(Name = 'Davis Test', Twilio_Product__c = primaryProduct.Id);
        
        Opp_SID_SKU__c sku = new Opp_SID_SKU__c(Opportunity__c = testOpp.Id, Account_SID__c = testSid.Id, Authy_MRR__c = 10);
        insert sku;
        List<Account_SID_SKU__c> skuList = new List<Account_SID_SKU__c>();
		skuList.add(new Account_SID_SKU__c(
			Account_SID__c = testSid.Id,
			Opportunity_Product__c = primaryProduct.Id,
			MRR_Baseline_Override__c  = 80,
			Type__c = 'Exception',
            Opp_SID_SKU__c= sku.id,
            New_Business_Opportunity__c = testOpp.id
		));
		insert skuList;
        
        AccountSID_to_SKU_Mappings__c setting = new AccountSID_to_SKU_Mappings__c(Name = 'Authy 2018', Year__c = 2018, Product_Name__c = 'Test Authy', Account_SID_API_Name__c = 'Authy__c', Sub_Product__c = 'Authy1;Authy2', Opp_SKU_Field__c = 'Authy_MRR__c', Usage_Field__c = 'Amortized_Usage_FY_18_Authy__c');
        insert setting;
        
        AccountSID_to_SKU_Mappings__c setting1 = new AccountSID_to_SKU_Mappings__c(Name = 'Test', Product_Name__c = 'Flex', Usage_Field__c = 'Amortized_Usage_FY_18_Flex__c', Year__c = 2018, Opp_SKU_Field__c = 'Flex_MRR__c', Account_SID_API_Name__c = 'Average_FY_18_Flex_MRR__c',  SID_Last_Month_Usage_Field__c = 'Amort_Usage_FY_18_Flex_Last_Month__c');
        insert setting1;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        Test.startTest();
            OppProductForecastExt ctrlExt = new OppProductForecastExt(sc);
            OppProductForecastExt.getOpportunity(testOpp.Id);
            ctrlExt.toStartOfQuarter(Date.newInstance(2020,2,1));
            ctrlExt.getCalendarQuarterString(Date.newInstance(2020,2,1));
            ctrlExt.getProductList();
            ctrlExt.getProductSchedules();
            ctrlExt.getProductMap();
            ctrlExt.getSoftwareProductMap();
            ctrlExt.getSubProducts();
            ctrlExt.getMRRMap();
            ctrlExt.getUsageMap();
            ctrlExt.getSendGridSizeMap();
            ctrlExt.getXsellMap();
            OppProductForecastExt.addProduct(JSON.serialize(new Opportunity_Product__c(Name = 'Test', Amount__c = 100, Opportunity__c = testOpp.Id)), JSON.serialize(new List<String>{'Davis Test 2'}));
            OppProductForecastExt.saveForecasts(JSON.serialize(new List<Product_Schedule__c>{schedule}), JSON.serialize(new List<Opportunity_Product__c>{primaryProduct}), JSON.serialize(new List<Twilio_Sub_Product__c>{subProduct}) ,testOpp.Id);
        Test.stopTest();
	}

    private static testMethod void testConstructor1() {
	    WholesaleUsageServices.bypassTrigger = false;
        Product2 newProd = new Product2(Name = 'Forecast Lock');
        insert newProd;
        PriceBookEntry pbe = new PriceBookEntry(Product2Id = newProd.Id, PriceBook2Id = Test.getStandardPricebookId(), UnitPrice = 1.0);
        insert pbe;
        
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Deal__c testDeal = new Deal__c(Name = 'Test Deal', Account__c = testAcc.Id);
        insert testDeal;
        Account_SID__c testSid = new Account_SID__c(Name = 'Test SID');
        insert testSid;
        
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', CloseDate = Date.today(), StageName = 'Incubate', /*Deal__c = testDeal.Id,*/ AccountId = testAcc.Id, FY_16_Primary_Product__c = 'Programmable Messaging', Amount = 1200, Launch_Date__c = Date.today(), Contract_Terms_Months__c = 12);
        insert testOpp;
        
        //trigger will create a primary opp product
        Opportunity_Product__c primaryProduct = new Opportunity_Product__c(Name = 'Programmable Messaging', Product_Name__c = 'Programmable Messaging', Amount__c = 1200, Opportunity__c = testOpp.Id);
        insert primaryProduct;
        Product_Schedule__c schedule = new Product_Schedule__c(New_Business_Forecast_Amount__c = 100, Start_Date__c = Date.today(), End_Date__c = Date.today().toStartOfMonth().addMonths(1).addDays(-1), Opportunity_Product__c = primaryProduct.Id);
        Twilio_Sub_Product__c subProduct = new Twilio_Sub_Product__c(Name = 'Davis Test', Twilio_Product__c = primaryProduct.Id);
        
        Opp_SID_SKU__c sku = new Opp_SID_SKU__c(Opportunity__c = testOpp.Id, Account_SID__c = testSid.Id, Authy_MRR__c = 10);
        insert sku;

        AccountSID_to_SKU_Mappings__c setting2 = new AccountSID_to_SKU_Mappings__c(Name = 'SendGrid: Expert Services', Product_Name__c = 'SendGrid: Expert Services', Usage_Field__c = 'Amortized_Usage_FY_18_Other__c', Year__c = 2018, Opp_SKU_Field__c = 'Other_MRR__c', Account_SID_API_Name__c = 'Average_Other_MRR__c',  SID_Last_Month_Usage_Field__c = 'Amort_Usage_Other_Last_Month__c', sub_product__c= 'Expert Services - 5 hour Professional Service Extension;Expert Services - Email Bootcamp;Expert Services - Expert Consultation;Expert Services - Expert Optimization;Expert Services - Expert Analysis;Expert Services - Email Implementation;');
        insert setting2;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        Test.startTest();
            OppProductForecastExt ctrlExt = new OppProductForecastExt(sc);
            OppProductForecastExt.getOpportunity(testOpp.Id);
            ctrlExt.getProductList();
            ctrlExt.getProductSchedules();
            ctrlExt.getProductMap();
            ctrlExt.getSoftwareProductMap();
            ctrlExt.getSubProducts();
            ctrlExt.getMRRMap();
            ctrlExt.getUsageMap();
            ctrlExt.getSendGridSizeMap();
            ctrlExt.getXsellMap();
            OppProductForecastExt.addProduct(JSON.serialize(new Opportunity_Product__c(Name = 'Test', Amount__c = 100, Opportunity__c = testOpp.Id)), JSON.serialize(new List<String>{'Davis Test 2'}));
            OppProductForecastExt.saveForecasts(JSON.serialize(new List<Product_Schedule__c>{schedule}), JSON.serialize(new List<Opportunity_Product__c>{primaryProduct}), JSON.serialize(new List<Twilio_Sub_Product__c>{subProduct}) ,testOpp.Id);
        Test.stopTest();
	}
}