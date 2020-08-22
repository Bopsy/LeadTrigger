@isTest
private class ProductUsageLookupServiceTest {
    static Opportunity oppForProgrammableMessaging;
    static Opportunity oppForSupport;
    static Account acc;

    static Product_Schedule__c productSchedulesForSupport;
    static Twilio_Usage__c usageWithoutProdSchedForSupport1;
    static Twilio_Usage__c usageWithProdSchedForSupport1;

    static Product_Schedule__c productSchedulesForProgrammableMessaging;
    static Twilio_Usage__c usageWithProdSchedForProgrammableMessaging1;
    static Twilio_Usage__c usageWithProdSchedForProgrammableMessaging2;

	private static testMethod void testTrigger() {
	    
        OpportunitySKUHandler.bypassTrigger = true;
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
            FY_16_Primary_Product__c = 'Programmable Messaging',
            Launch_Date__c = Date.today(),
            CloseDate = Date.today(),
            Contract_Terms_Months__c = 12,
            Amount = mrr*12,
            StageName = 'Closed Won',
            Opportunity_Gate_Override_Picklist__c = 'True',
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
        Forecast_Schedule__c fsForSupport2 = new Forecast_Schedule__c (
            Opportunity__c = oppForSupport.Id,
            Forecast_Amount__c = mrr*12,
            Start_Date__c = Date.today().addMonths(1)
        );
        
        Forecast_Schedule__c fsForProgrammableMessaging = new Forecast_Schedule__c (
            Opportunity__c = oppForProgrammableMessaging.Id,
            Forecast_Amount__c = mrr*12,
            Start_Date__c = Date.today().addMonths(1)
        );
        
        Forecast_Schedule__c fsForProgrammableMessaging2 = new Forecast_Schedule__c (
            Opportunity__c = oppForProgrammableMessaging.Id,
            Forecast_Amount__c = mrr*12,
            Start_Date__c = Date.today().addMonths(2)
        );
        Test.startTest();
        insert new List<Forecast_Schedule__c> { fsForSupport, fsForSupport2, fsForProgrammableMessaging, fsForProgrammableMessaging2 };
        
        Opportunity_Product__c oppProductForSupport = new Opportunity_Product__c(
            Name = 'Test oppForSupport Product',
            Amount__c = mrr*12,
            Opportunity__c = oppForSupport.Id,
            Primary_Product__c = true,
            Product_Name__c = 'Programmable Messaging',
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
        Product_Schedule__c productSchedulesForSupport2 = new Product_Schedule__c(
            Forecast_Amount__c = 100,
            Start_Date__c = Date.today().addMonths(1),
            End_Date__c = Date.today().toStartOfMonth().addMonths(2).addDays(-1),
            Opportunity_Product__c = oppProductForSupport.Id,
            Forecast_Schedule__c = fsForSupport2.Id
        );
        
        productSchedulesForProgrammableMessaging = new Product_Schedule__c(
            Forecast_Amount__c = 100,
            Start_Date__c = Date.today().addMonths(1),
            End_Date__c = Date.today().toStartOfMonth().addMonths(2).addDays(-1),
            Opportunity_Product__c = oppProductForProgrammableMessaging.Id,
            Forecast_Schedule__c = fsForProgrammableMessaging.Id
        );
        
        Product_Schedule__c productSchedulesForProgrammableMessaging2 = new Product_Schedule__c(
            Forecast_Amount__c = 100,
            Start_Date__c = Date.today().addMonths(2),
            End_Date__c = Date.today().toStartOfMonth().addMonths(3).addDays(-1),
            Opportunity_Product__c = oppProductForProgrammableMessaging.Id,
            Forecast_Schedule__c = fsForProgrammableMessaging2.Id
        );
        insert new List<Product_Schedule__c> { productSchedulesForSupport, productSchedulesForSupport2, productSchedulesForProgrammableMessaging, productSchedulesForProgrammableMessaging2 };
        
        Opp_SID_SKU__c skuForSupport = new Opp_SID_SKU__c(Opportunity__c = oppForSupport.Id, Account_SID__c = sidForProgrammableMessaging.Id);
        Opp_SID_SKU__c skuForProgrammableMessaging = new Opp_SID_SKU__c(Opportunity__c = oppForProgrammableMessaging.Id, Account_SID__c = sidForProgrammableMessaging.Id);
        insert new List<Opp_SID_SKU__c> { skuForSupport, skuForProgrammableMessaging};

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
            Month__c = Date.today().addMonths(1).month(),
            Year__c = year,
            Total__c = 4.00,
            Volume__c = 2,
            Currency__c = 'USD',
            Amortized_Usage_Messaging__c = 4.0
        );
        Twilio_Usage__c usageWithProdSchedForProgrammableMessaging3 = new Twilio_Usage__c(
            Related_Account_SID__c = sidForProgrammableMessaging.Id,
            AccountSid__c = sidForProgrammableMessaging.Account_SID__c,
            Product__c = 'Programmable Messaging',
            Month__c = Date.today().addMonths(2).month(),
            Year__c = year,
            Total__c = 5.00,
            Volume__c = 2,
            Currency__c = 'USD',
            Amortized_Usage_Messaging__c = 5.0
        );
        insert new List<Twilio_Usage__c> {
			usageWithoutProdSchedForSupport1,
			usageWithProdSchedForSupport1,
        	usageWithProdSchedForProgrammableMessaging1,
			usageWithProdSchedForProgrammableMessaging2,
			usageWithProdSchedForProgrammableMessaging3
		};
		
		
		    List<Product_Schedule__c> productSchedules = new List<Product_Schedule__c> {productSchedulesForProgrammableMessaging, productSchedulesForProgrammableMessaging2, productSchedulesForSupport, productSchedulesForSupport2};
		    List<Product_Usage_By_Month__c> results = ProductUsageService.createProductUsageByMonthRecords(productSchedules);
		    update results;
		Test.stopTest();
		
        List<Product_Usage_By_Month__c> resultQuery = [
            SELECT Last_Month_Usage__c, Product_Schedule__c, Twilio_Usage__c, Month_Number__c, Twilio_Usage__r.Related_Account_SID__c,
                Product_Schedule__r.Opportunity_Product__c, Account_SID_SKU__c, Blocked_Usage__c 
            FROM Product_Usage_By_Month__c];
        System.debug('resultQuery: '+JSON.serialize(resultQuery));
        System.debug('results: '+ JSON.serialize(results));
	}

}