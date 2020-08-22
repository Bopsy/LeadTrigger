/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ProductUsageServiceTest {

    static Opportunity oppForProgrammableMessaging;
    static Opportunity oppForSupport;
    static Account acc;

    static Product_Schedule__c productSchedulesForSupport;
    static Twilio_Usage__c usageWithoutProdSchedForSupport1;
    static Twilio_Usage__c usageWithProdSchedForSupport1;

    static Product_Schedule__c productSchedulesForProgrammableMessaging;
    static Twilio_Usage__c usageWithProdSchedForProgrammableMessaging1;
    static Twilio_Usage__c usageWithProdSchedForProgrammableMessaging2;

    static testMethod void NoProductSchedules() {
        setupTestRecords();

        Test.startTest();
        
        List<Product_Usage_By_Month__c> results = ProductUsageService.createProductUsageByMonthRecords(new List<Product_Schedule__c>());

        Test.stopTest();

        System.assert(results.isEmpty());
    }
    
    static testMethod void testBatch(){
        
        setupTestRecords();
        
        Test.startTest();
            Database.executeBatch(new BatchLinkTwilioUsageToProductSchedule());
        Test.stopTest();
    }


    static testMethod void testScheduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        setupTestRecords();
        
        Test.startTest();
            String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchLinkTwilioUsageToProductSchedule());
        Test.stopTest();
    }
	// Product Schedules for Support is setup to have 2 Twilio Usage records
	// where 1 matches the month and 1 does not.
    static testMethod void MatchingProductSchedulesForSupport() {
        setupTestRecords();

        Test.startTest();
        
        System.debug('ProductUsageServiceTest.MatchingProductSchedulesForSupport - Product Schedule: ' + productSchedulesForProgrammableMessaging);
        List<Product_Usage_By_Month__c> results = ProductUsageService.createProductUsageByMonthRecords(new List<Product_Schedule__c> { productSchedulesForSupport });
		System.debug('ProductUsageServiceTest.MatchingProductSchedulesForSupport - Results: ' + results);
        
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'There should be only 1 Product_Usage_By_Month__c record created for the Product Schedule for Support.');
        System.assertEquals(productSchedulesForSupport.Id, results[0].Product_Schedule__c);
        System.assertEquals(usageWithProdSchedForSupport1.Id, results[0].Twilio_Usage__c);
    }

    static testMethod void SummarizeProductUsage() {
        setupTestRecords();

		List<Product_Schedule__c> productSchedules = new List<Product_Schedule__c> {productSchedulesForProgrammableMessaging, productSchedulesForSupport};
        System.debug('ProductUsageServiceTest.SummarizeProductUsage - Product Schedule: ' + productSchedules);

        Test.startTest();
        
        List<Product_Usage_By_Month__c> productUsageByMonth = ProductUsageService.createProductUsageByMonthRecords(productSchedules);
        System.debug('ProductUsageServiceTest.SummarizeProductUsage - Product Usage By Month: ' + productUsageByMonth);
        Map<Id,Product_Schedule__c> results = ProductUsageService.summarizeProductUsages(productUsageByMonth);
		System.debug('ProductUsageServiceTest.SummarizeProductUsage - Results: ' + results);
        Test.stopTest();
		        
        System.assertEquals(2, results.size());
        System.assertEquals(2.0, results.get(productSchedulesForSupport.Id).Actual_Usage__c);
        System.assertEquals(7.0, results.get(productSchedulesForProgrammableMessaging.Id).Actual_Usage__c);
    }

    static testMethod void SummarizeProductUsageTwilioUsageAdded() {
        setupTestRecords();

		List<Product_Schedule__c> productSchedules = new List<Product_Schedule__c> {productSchedulesForProgrammableMessaging, productSchedulesForSupport};
        System.debug('ProductUsageServiceTest.SummarizeProductUsageTwilioUsageAdded - Product Schedule: ' + productSchedules);
        
        Test.startTest();
        
        List<Product_Usage_By_Month__c> productUsageByMonth = ProductUsageService.createProductUsageByMonthRecords(productSchedules);

		// Delete a usage record and summarize the product usages
		delete usageWithProdSchedForProgrammableMessaging2;
        System.debug('ProductUsageServiceTest.SummarizeProductUsageTwilioUsageAdded - Product Usage By Month (before): ' + productUsageByMonth);
        Map<Id,Product_Schedule__c> results = ProductUsageService.summarizeProductUsages(productUsageByMonth);

		// Restore the usage record and summarize the product usages
		undelete usageWithProdSchedForProgrammableMessaging2;
        System.debug('ProductUsageServiceTest.SummarizeProductUsageTwilioUsageAdded - Product Usage By Month (after): ' + productUsageByMonth);
        results = ProductUsageService.summarizeProductUsages(productUsageByMonth);
		System.debug('ProductUsageServiceTest.SummarizeProductUsageTwilioUsageAdded - Results: ' + results);

        Test.stopTest();
		        
        System.assertEquals(2, results.size());
        System.assertEquals(2.0, results.get(productSchedulesForSupport.Id).Actual_Usage__c);
        System.assertEquals(7.0, results.get(productSchedulesForProgrammableMessaging.Id).Actual_Usage__c);
    }

    static testMethod void SummarizeProductUsageTwilioUsageDeleted() {
        setupTestRecords();

		List<Product_Schedule__c> productSchedules = new List<Product_Schedule__c> {productSchedulesForProgrammableMessaging, productSchedulesForSupport};
        System.debug('ProductUsageServiceTest.SummarizeProductUsageTwilioUsageDeleted - Product Schedule: ' + productSchedules);
        
        Test.startTest();
        List<Product_Usage_By_Month__c> productUsageByMonth = ProductUsageService.createProductUsageByMonthRecords(productSchedules);

        System.debug('ProductUsageServiceTest.SummarizeProductUsageTwilioUsageDeleted - Product Usage By Month (before): ' + productUsageByMonth);
        Map<Id,Product_Schedule__c> results = ProductUsageService.summarizeProductUsages(productUsageByMonth);

		// Delete a usage record and summarize the product usages
		delete usageWithProdSchedForProgrammableMessaging2;
        System.debug('ProductUsageServiceTest.SummarizeProductUsageTwilioUsageDeleted - Product Usage By Month (after): ' + productUsageByMonth);
        results = ProductUsageService.summarizeProductUsages(productUsageByMonth);
		System.debug('ProductUsageServiceTest.SummarizeProductUsageTwilioUsageDeleted - Results: ' + results);

        Test.stopTest();
		        
        System.assertEquals(2, results.size());
        System.assertEquals(2.0, results.get(productSchedulesForSupport.Id).Actual_Usage__c);
        System.assertEquals(3.0, results.get(productSchedulesForProgrammableMessaging.Id).Actual_Usage__c);
    }

    static testMethod void SummarizeProductUsageByUsageAPIField() {
        setupTestRecords();

		AccountSID_to_SKU_Mappings__c setting = AccountSID_to_SKU_Mappings__c.getInstance('Support');
		delete setting;

		List<Product_Schedule__c> productSchedules = new List<Product_Schedule__c> {productSchedulesForProgrammableMessaging, productSchedulesForSupport};
        System.debug('ProductUsageServiceTest.SummarizeProductUsageByUsageAPIField - Product Schedule: ' + productSchedules);

        Test.startTest();
        
        List<Product_Usage_By_Month__c> productUsageByMonth = ProductUsageService.createProductUsageByMonthRecords(productSchedules);
		for (Product_Usage_By_Month__c u : productUsageByMonth) {
			if (u.Product_Schedule__c == productSchedulesForSupport.Id) {
				u.Usage_API_Field__c = 'Amortized_Usage_Support__c';
				update u;
			}
		}
        
        System.debug('ProductUsageServiceTest.SummarizeProductUsageByUsageAPIField - Product Usage By Month: ' + productUsageByMonth);
        Map<Id,Product_Schedule__c> results = ProductUsageService.summarizeProductUsages(productUsageByMonth);
		System.debug('ProductUsageServiceTest.SummarizeProductUsageByUsageAPIField - Results: ' + results);
        Test.stopTest();
		        
        System.assertEquals(2, results.size());
        System.assertEquals(2.0, results.get(productSchedulesForSupport.Id).Actual_Usage__c);
        System.assertEquals(7.0, results.get(productSchedulesForProgrammableMessaging.Id).Actual_Usage__c);
    }

    static testMethod void RollupActualUsages() {
        setupTestRecords();

		List<Product_Schedule__c> productSchedules = new List<Product_Schedule__c> {productSchedulesForProgrammableMessaging, productSchedulesForSupport};
        System.debug('ProductUsageServiceTest.RollupActualUsages - Product Schedule: ' + productSchedules);
        

        Test.startTest();
        
        List<Product_Usage_By_Month__c> productUsageByMonth = ProductUsageService.createProductUsageByMonthRecords(productSchedules);
        productUsageByMonth[0].Actual_Usage__c = 1.0;
        productUsageByMonth[1].Actual_Usage__c = 2.0;
        update productUsageByMonth;
        
        System.debug('ProductUsageServiceTest.RollupActualUsages - Product Usage By Month (before): ' + productUsageByMonth);
        Map<Id,Product_Schedule__c> results = ProductUsageService.rollupActualUsages(productUsageByMonth);

		System.debug('ProductUsageServiceTest.RollupActualUsages - Results: ' + results);

        Test.stopTest();
		        
        System.assertEquals(2, results.size());
        //System.assertEquals(1.0, results.get(productUsageByMonth[0].Product_Schedule__c).Actual_Usage__c);
        //System.assertEquals(2.0, results.get(productUsageByMonth[1].Product_Schedule__c).Actual_Usage__c);
    }

    static void setupTestRecords() {
        ProductScheduleServices.bypassTrigger = true;
        WholesaleUsageServices.bypassTrigger = true;
        Datetime now = Datetime.now();
        Integer year = now.year();
        Integer month = now.month(); 
        String current_months_year = String.valueOf(year);
        String current_months_month = now.format('MMMMM');

        List<AccountSID_to_SKU_Mappings__c> settings = new List<AccountSID_to_SKU_Mappings__c>();
        settings.add(new AccountSID_to_SKU_Mappings__c(
            Name = 'Support',
            Year__c = 2018,
            Product_Name__c = 'Support',
            Account_SID_API_Name__c = 'Support_MRR__c',
            Opp_SKU_Field__c = 'Support_MRR__c',
            Usage_Field__c = 'Amortized_Usage_Support__c'
        ));
        settings.add(new AccountSID_to_SKU_Mappings__c(
            Name = 'Programmable Messaging',
            Year__c = 2018,
            Product_Name__c = 'Programmable Messaging',
            Account_SID_API_Name__c = 'Programmable_Messaging_MRR__c',
            Opp_SKU_Field__c = 'Programmable_Messaging_MRR__c',
            Usage_Field__c = 'Amortized_Usage_Messaging__c'
        ));
        insert settings;

        AccountSID_to_SKU_Config__c config = new AccountSID_to_SKU_Config__c(MRR_Exception__c = 100);
        insert config;

        Decimal mrrEx = config.MRR_Exception__c;
        Decimal mrr = mrrEx - 1;
    
        acc = new Account(Name = 'TestAccount', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert acc;

        Product2 newProd = new Product2(Name = 'Forecast Lock');
        insert newProd;

        PriceBookEntry pbe = new PriceBookEntry(Product2Id = newProd.Id, PriceBook2Id = Test.getStandardPricebookId(), UnitPrice = 1.0);
        insert pbe;

        Deal__c deal = new Deal__c(Name = 'TestDeal', Account__c = acc.Id);
        insert deal;

        Account_SID__c sidForSupport = new Account_SID__c(
                        Name = 'Support Account SID',
                        Account_SID__c = 'SUPPORTACCOUNTSID',
                        Account__c = acc.Id,
                        Support_MRR__c = mrr
                );
        Account_SID__c sidForProgrammableMessaging = new Account_SID__c(
                        Name = 'Programmable Messaging Account SID',
                        Account_SID__c = 'MESSAGINGACCOUNTSID',
                        Account__c = acc.Id,
                        Programmable_Messaging_MRR__c = mrr
                );
        insert new List<Account_SID__c> { sidForSupport, sidForProgrammableMessaging };
        
        
        Opportunity oppForSupport = new Opportunity(
            Name = 'TestOpp',
            Deal__c = deal.Id,
            AccountId = acc.Id,
            FY_16_Primary_Product__c = 'Support',
            Launch_Date__c = Date.today(),
            CloseDate = Date.today(),
            Contract_Terms_Months__c = 12,
            Amount = mrr*12,
            StageName = 'Go / No Go',
            Product__c = 'Client',
            Primary_Competitor__c = 'Support',
            New_Business_Account_SID__c = '77777776666555444'
        );
        Opportunity oppForProgrammableMessaging = new Opportunity(
            Name = 'TestOpp',
            Deal__c = deal.Id,
            AccountId = acc.Id,
            FY_16_Primary_Product__c = 'Programmable Messaging',
            Launch_Date__c = Date.today(),
            CloseDate = Date.today(),
            Contract_Terms_Months__c = 12,
            Amount = mrr*12,
            StageName = 'Go / No Go',
            Product__c = 'Client',
            Primary_Competitor__c = 'Support',
            New_Business_Account_SID__c = '77777776666555444'
        );
        insert new List<Opportunity> { oppForSupport, oppForProgrammableMessaging };

        Forecast_Schedule__c fsForSupport = new Forecast_Schedule__c (
            Opportunity__c = oppForSupport.Id,
            Forecast_Amount__c = mrr*12,
            Start_Date__c = Date.today()
        );
        Forecast_Schedule__c fsForProgrammableMessaging = new Forecast_Schedule__c (
            Opportunity__c = oppForProgrammableMessaging.Id,
            Forecast_Amount__c = mrr*12,
            Start_Date__c = Date.today()
        );
        insert new List<Forecast_Schedule__c> { fsForSupport, fsForProgrammableMessaging };

        Opportunity_Product__c oppProductForSupport = new Opportunity_Product__c(
            Name = 'Test oppForSupport Product',
            Amount__c = mrr*12,
            Opportunity__c = oppForSupport.Id,
            Primary_Product__c = true,
            Product_Name__c = 'Support',
            Launch_Date__c = Date.today(),
            Contract_Terms_Months__c = 12
        );
        Opportunity_Product__c oppProductForProgrammableMessaging = new Opportunity_Product__c(
            Name = 'Test oppForProgrammableMessaging Product',
            Amount__c = mrr*12,
            Opportunity__c = oppForProgrammableMessaging.Id,
            Primary_Product__c = true,
            Product_Name__c = 'Programmable Messaging',
            Launch_Date__c = Date.today(),
            Contract_Terms_Months__c = 12
        );
        insert new List<Opportunity_Product__c> { oppProductForSupport, oppProductForProgrammableMessaging };

        productSchedulesForSupport = new Product_Schedule__c(
            Forecast_Amount__c = 100,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().toStartOfMonth().addMonths(1).addDays(-1),
            Opportunity_Product__c = oppProductForSupport.Id,
            Forecast_Schedule__c = fsForSupport.Id
        );
        productSchedulesForProgrammableMessaging = new Product_Schedule__c(
            Forecast_Amount__c = 100,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().toStartOfMonth().addMonths(1).addDays(-1),
            Opportunity_Product__c = oppProductForProgrammableMessaging.Id,
            Forecast_Schedule__c = fsForProgrammableMessaging.Id
        );
        insert new List<Product_Schedule__c> { productSchedulesForSupport, productSchedulesForProgrammableMessaging };
        
        Opp_SID_SKU__c skuForSupport = new Opp_SID_SKU__c(Opportunity__c = oppForSupport.Id, Account_SID__c = sidForSupport.Id);
        Opp_SID_SKU__c skuForProgrammableMessaging = new Opp_SID_SKU__c(Opportunity__c = oppForProgrammableMessaging.Id, Account_SID__c = sidForProgrammableMessaging.Id);
        insert new List<Opp_SID_SKU__c> { skuForSupport, skuForProgrammableMessaging };

        usageWithoutProdSchedForSupport1 = new Twilio_Usage__c(
            Related_Account_SID__c = sidForSupport.Id,
            AccountSid__c = sidForSupport.Account_SID__c,
            Product__c = 'Support',
            Month__c = month,
            Year__c = year+1,
            Total__c = 1.00,
            Volume__c = 1,
            Currency__c = 'USD',
            Amortized_Usage_Support__c = 1.0
        );
        usageWithProdSchedForSupport1 = new Twilio_Usage__c(
            Related_Account_SID__c = sidForSupport.Id,
            AccountSid__c = sidForSupport.Account_SID__c,
            Product__c = 'Support',
            Month__c = month,
            Year__c = year,
            Total__c = 2.00,
            Volume__c = 2,
            Currency__c = 'USD',
            Amortized_Usage_Support__c = 2.0
        );
        usageWithProdSchedForProgrammableMessaging1 = new Twilio_Usage__c(
            Related_Account_SID__c = sidForProgrammableMessaging.Id,
            AccountSid__c = sidForProgrammableMessaging.Account_SID__c,
            Product__c = 'Programmable Messaging',
            Month__c = month,
            Year__c = year,
            Total__c = 3.00,
            Volume__c = 2,
            Currency__c = 'USD',
            Amortized_Usage_Messaging__c = 3.0
        );
        usageWithProdSchedForProgrammableMessaging2 = new Twilio_Usage__c(
            Related_Account_SID__c = sidForProgrammableMessaging.Id,
            AccountSid__c = sidForProgrammableMessaging.Account_SID__c,
            Product__c = 'Programmable Messaging',
            Month__c = month,
            Year__c = year,
            Total__c = 4.00,
            Volume__c = 2,
            Currency__c = 'USD',
            Amortized_Usage_Messaging__c = 4.0
        );
        insert new List<Twilio_Usage__c> {
			usageWithoutProdSchedForSupport1,
			usageWithProdSchedForSupport1,
        	usageWithProdSchedForProgrammableMessaging1,
			usageWithProdSchedForProgrammableMessaging2
		};
    }
}