/*************************************************************
@Name: APTS_DealGuidanceCustomControllerTest
@Author: Nikunj Vedia
@Description: This is the test class for APTS_DealGuidanceCustomScreenController
******************************************************************/
@isTest
public class APTS_DealGuidanceCustomControllerTest {

    @isTest
    public static void testController(){
        Account acc = APTS_CPQTestUtility.createAccount('Test Account','Prospect');
        insert acc;
        
        Contact con = APTS_CPQTestUtility.createContact('Test Contact', acc.Id);
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Prospecting');
        opp.ForecastCategoryName='Commit';
        opp.StageName = 'Incubate';
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APTS_CPQTestUtility.createPriceList('Test PriceList', true);
        insert priceList;
        
        Product2 product = APTS_CPQTestUtility.createProduct('Test Product', 'A111111', 'Test Family', 'Bundle', true, true, true, true);
        product.Capable_of_Sub_Minute_Billing__c = true;
        insert product;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        proposal.Total_Committed_Revenue__c=100000.00;
        proposal.Commit_Frequency__c='Monthly';
        proposal.Term_Range__c='12';
        insert proposal;
        
        Apttus_DealMgr__DealGuidanceRule__c testRule = new Apttus_DealMgr__DealGuidanceRule__c(Apttus_DealMgr__ProductScope__c = product.Id, Apttus_DealMgr__Sequence__c = 1);
        insert testRule;
        
        Apttus_DealMgr__DealGuidanceRuleEntry__c testEntry = new Apttus_DealMgr__DealGuidanceRuleEntry__c(Apttus_DealMgr__Sequence__c = 1, Apttus_DealMgr__GuidanceRuleId__c = testRule.Id, Apttus_DealMgr__Band1Value__c = '0', Apttus_DealMgr__Dimension1Value__c = '0', Apttus_DealMgr__Dimension2Value__c = '0.009', Apttus_DealMgr__Dimension3Value__c = '0.012',Apttus_DealMgr__Band3Value__c='0.12',Apttus_DealMgr__Band2Value__c='0.12');
        insert testEntry;
        
        Apttus_DealMgr__DealGuidanceRuleEntry__c testEntry2 = new Apttus_DealMgr__DealGuidanceRuleEntry__c(Apttus_DealMgr__Sequence__c = 2, Apttus_DealMgr__GuidanceRuleId__c = testRule.Id, Apttus_DealMgr__Band1Value__c = '0', Apttus_DealMgr__Dimension1Value__c = '59', Apttus_DealMgr__Dimension2Value__c = '0.019', Apttus_DealMgr__Dimension3Value__c = '0.022',Apttus_DealMgr__Band3Value__c='0.32',Apttus_DealMgr__Band2Value__c='0.42');
        insert testEntry2;
        
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        
        list<Apttus_Config2__LineItem__c> listLineItem = [SELECT Id FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c = :cartId];
        
        Apttus_Config2__LineItem__c lineItemSO = listLineItem[0];
        
        lineItemSO.Apttus_Config2__PricingGuidance__c = '{"HidePrice" : false,"HidePercentile" : false,"Entries" : [ {"Sequence" : 1,"Rating" : "Green","RangeName" : "Start","PriceTo" : 135.00,"PriceFrom" : 150.00000,"PercentileTo" : 10,"PercentileFrom" : 0,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#387C35"}, {"Sequence" : 2,"Rating" : "Yellow","RangeName" : "Target","PriceTo" : 120.00,"PriceFrom" : 135.00,"PercentileTo" : 20,"PercentileFrom" : 10,"MeasureType" : "LowHigh","IsItemRating" : true,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps": [ ],"ColorCode" : "#FFE512"}, {"Sequence" : 3,"Rating" : "Orange","RangeName" : "Walkaway","PriceTo" : 75.00,"PriceFrom" : 120.00,"PercentileTo" : 50,"PercentileFrom" : 20,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#E36F1E"}, {"Sequence" : 4,"Rating" : "Red","RangeName" : "Approval Required","PriceTo" : 0.00,"PriceFrom" : 75.00,"PercentileTo" : 100,"PercentileFrom" : 50,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#B2102C"} ],"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ]}';
        lineItemSO.Billing_Minute__c = 0.02;
        lineItemSO.Apttus_Config2__OptionId__c = product.Id;
        update lineItemSO;
        
        ApexPages.currentPage().getParameters().put('lineitemid',lineItemSO.id);
        APTS_DealGuidanceCustomScreenController ctrl = new APTS_DealGuidanceCustomScreenController();
    }
}