/**********************************************************/
// Created by: Gram Bischof ^Ash
//
// Last Modified by: Gram Bischof {1/21/2020}
//
// Description:
// This test class for ProductScheduleForecast which shows charts based on twilio product.
// 
/**********************************************************/

@isTest
public with sharing class ProductScheduleForecastControllerTest {
    
    @testSetup 
    static void setup() {
        
        Id testEnterpriseAccId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Enterprise Account').getRecordTypeId();
        Id testdirectSalesOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Direct Sales').getRecordTypeId();
        
        Account testAcc = new Account();
        testAcc.Name = 'Enterprise Customer Company';
        testAcc.RecordTypeId = testEnterpriseAccId;
        insert testAcc;
        
        Opportunity testOpp = new Opportunity();
        testOpp.AccountId = testAcc.Id;
        testOpp.RecordTypeId = testdirectSalesOppId;
        testOpp.Name = 'Twilio Enterprise Deal';
        testOpp.StageName = 'Closed Won';
        testOpp.CloseDate = Date.Today();
        testOpp.Launch_Date__c = Date.Today()-100;
        insert testOpp;
        
        List<Opportunity_Product__c> testTwilioProductList = new List<Opportunity_Product__c>();
        Opportunity_Product__c testTwilioProduct = new Opportunity_Product__c();
        testTwilioProduct.Name = 'Enterprise Twilio Product';
        testTwilioProduct.Opportunity__c = testOpp.Id;
        testTwilioProductList.add(testTwilioProduct);
        
        Opportunity_Product__c testTwilioProduct1 = new Opportunity_Product__c();
        testTwilioProduct1.Name = 'Total';
        testTwilioProduct1.Opportunity__c = testOpp.Id;
        testTwilioProductList.add(testTwilioProduct1);
        
        Opportunity_Product__c testTwilioProduct2 = new Opportunity_Product__c();
        testTwilioProduct2.Name = 'Enterprise Twilio Product';
        testTwilioProduct2.Opportunity__c = testOpp.Id;
        testTwilioProductList.add(testTwilioProduct2);
        insert testTwilioProductList;
        
        Forecast_Schedule__c  testForecastSch = new Forecast_Schedule__c();
        testForecastSch.Opportunity__c = testOpp.Id;
        insert testForecastSch;
        
        List<Product_Schedule__c> testProductSchList = new List<Product_Schedule__c>();
        Product_Schedule__c testProductSch = new Product_Schedule__c();
        testProductSch.Forecast_Schedule__c = testForecastSch.Id;
        testProductSch.Forecast_Amount__c = 10000;
        testProductSch.Opportunity_Product__c = testTwilioProduct.Id;
        testProductSch.Start_Date__c  = Date.today();
        testProductSch.End_Date__c  = Date.today()+2;
        testProductSchList.add(testProductSch);
        
        Product_Schedule__c testProductSch1 = new Product_Schedule__c();
        testProductSch1.Forecast_Schedule__c = testForecastSch.Id;
        testProductSch1.Forecast_Amount__c = 20000;
        testProductSch1.Opportunity_Product__c = testTwilioProduct1.Id;
        testProductSch1.Start_Date__c  = Date.today();
        testProductSch1.End_Date__c  = Date.today()+3;
        testProductSchList.add(testProductSch1);
        
        Product_Schedule__c testProductSch2 = new Product_Schedule__c();
        testProductSch2.Forecast_Schedule__c = testForecastSch.Id;
        testProductSch2.Forecast_Amount__c = 25000;
        testProductSch2.Opportunity_Product__c = testTwilioProduct.Id;
        testProductSch2.Start_Date__c  = Date.today();
        testProductSch2.End_Date__c  = Date.today()+4;
        testProductSchList.add(testProductSch2);
        insert testProductSchList;
    }
    
     @isTest
    public Static void getProductDataTest() {
        
        Opportunity testOpp = [SELECT Id FROM Opportunity];
        
        //Execution
        test.startTest();
        List<ProductScheduleForecastController.ProductOption> testProductList = ProductScheduleForecastController.getProductData(testOpp.Id);
        test.stopTest();
        
        //Assertion
        System.assertEquals(3, testProductList.size());
    }
    
    @isTest
    public Static void getForecastDataTest() {
        
        Opportunity testOpp = [SELECT Id FROM Opportunity];
        List<Opportunity_Product__c> testTwilioProduct = [SELECT Id, Name FROM Opportunity_Product__c WHERE Name =: 'Enterprise Twilio Product'];
        
        //Execution
        test.startTest();
        ProductScheduleForecastController.getProductData(testOpp.Id);
        List<ProductScheduleForecastController.Series> testReturnSeries = ProductScheduleForecastController.getForecastData(testOpp.Id, new List<String>{testTwilioProduct[0].Name,testTwilioProduct[1].Name});
        test.stopTest();
        
        //Assertion
        System.assertEquals(2, testReturnSeries.size());
    }
    
    @isTest
    public Static void getForecastDataTest2() {
        
        Opportunity testOpp = [SELECT Id FROM Opportunity];
        List<Opportunity_Product__c> testTwilioProduct = [SELECT Id, Name FROM Opportunity_Product__c];
        
        //Execution
        test.startTest();
        List<ProductScheduleForecastController.Series> testReturnSeries = ProductScheduleForecastController.getForecastData(testOpp.Id, new List<String>{testTwilioProduct[0].Name,testTwilioProduct[1].Name,testTwilioProduct[2].Name});
        test.stopTest();
        
        //Assertion
        System.assertEquals(2, testReturnSeries.size());
    }
}