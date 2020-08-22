/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  APTS_ProposalTriggerHandlerTest
*
* @description 	  Test class for APTS_ProposalTriggerHandler
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2018-02-26
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class APTS_ProposalTriggerHandlerTest {

    private static testMethod void test() {
        Account acc = APTS_CPQTestUtility.createAccount('Test Account','Prospect');
        insert acc;
        
        Contact con = APTS_CPQTestUtility.createContact('Test Contact', acc.Id);
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Prospecting');
        opp.ForecastCategoryName='Commit';
        opp.StageName = 'Incubate';
        insert opp;
        
        SendGrid_Price_Concession__c sg= new SendGrid_Price_Concession__c();
        sg.Opportunity__c = opp.id;
        insert sg;
        
        Apttus_Config2__PriceList__c priceList = APTS_CPQTestUtility.createPriceList('Test PriceList', true);
        insert priceList;
        
        Product2 product = APTS_CPQTestUtility.createProduct('Test Product', 'A111111', 'Test Family', 'Test', true, true, true, true);
        //product.Bucket_Product__c = true;
        product.BI_SID__c = 'Test1';
        insert product;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        
        Apttus_DealMgr__DealGuidanceRule__c testRule = new Apttus_DealMgr__DealGuidanceRule__c(Apttus_DealMgr__ProductScope__c = product.Id, Apttus_DealMgr__Sequence__c = 1);
        insert testRule;
        
        Apttus_DealMgr__DealGuidanceRuleEntry__c testEntry = new Apttus_DealMgr__DealGuidanceRuleEntry__c(Apttus_DealMgr__Sequence__c = 1, Apttus_DealMgr__GuidanceRuleId__c = testRule.Id, Apttus_DealMgr__Band1Value__c = '0', Apttus_DealMgr__Dimension1Value__c = '0.008', Apttus_DealMgr__Dimension2Value__c = '0.009', Apttus_DealMgr__Dimension3Value__c = '0.012');
        insert testEntry;
        
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id FROM Apttus_Config2__LineItem__c];
        Test.startTest();
        lineItems[0].Apttus_Config2__NetUnitPrice__c = 0.01;
        update lineItems;
        update new Apttus_Config2__ProductConfiguration__c(Id = cartId, Apttus_CQApprov__Approval_Status__c = 'Cancelled');
        update new Apttus_Proposal__Proposal__c(Id = proposal.Id, Total_Committed_Revenue__c  = 120000);
        Apttus_Proposal__Proposal__c proposal1 = [Select Id,Apttus_QPApprov__Approval_Status__c from Apttus_Proposal__Proposal__c where Id =: proposal.Id limit 1];
        system.assertEquals('Approval Required', proposal1.Apttus_QPApprov__Approval_Status__c);
        
        Opportunity opp1 = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Prospecting');
        opp1.ForecastCategoryName='Commit';
        opp1.StageName = 'Incubate';
        insert opp1;
        
        Apttus_Proposal__Proposal__c proposal2 = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp1.Id, 'Proposal', priceList.Id);
        proposal2.Apttus_QPApprov__Approval_Status__c= 'Approved';
        insert proposal2;
        
        SendGrid_Price_Concession__c sg1= new SendGrid_Price_Concession__c();
        sg1.Opportunity__c = opp1.id;
        insert sg1;
        SendGrid_Price_Concession__c sgnew1=[Select id,Quote_Proposal__c from SendGrid_Price_Concession__c where id=:sg1.id];
        system.assertEquals(proposal2.id, sgnew1.Quote_Proposal__c);
        
        delete proposal2;
        SendGrid_Price_Concession__c sgnew2=[Select id,Quote_Proposal__c from SendGrid_Price_Concession__c where id=:sg1.id];
        system.assertEquals(null, sgnew2.Quote_Proposal__c);
        
        Test.stopTest();
    }

}