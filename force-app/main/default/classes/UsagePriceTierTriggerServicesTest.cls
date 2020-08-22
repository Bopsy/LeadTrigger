/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  UsagePriceTierTriggerServicesTest
*
* @description 	  Test class for UsagePriceTierTrigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2019-04-30
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class UsagePriceTierTriggerServicesTest {
    private static testMethod void test() {
        Account acc = APTS_CPQTestUtility.createAccount('Test Account','Prospect');
        insert acc;
        
        Contact con = APTS_CPQTestUtility.createContact('Test Contact', acc.Id);
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Incubate');
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APTS_CPQTestUtility.createPriceList('Test PriceList', true);
        insert priceList;
        
        Product2 product = APTS_CPQTestUtility.createProduct('Test Product', 'A111111', 'Test Family', 'Bundle', true, true, true, true);
        product.Bucket_Product__c = true;
        product.BI_SID__c = 'Test1';
        insert product;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
        Apttus_Config2__PriceMatrix__c priceMatrix = new Apttus_Config2__PriceMatrix__c(Apttus_Config2__PriceListItemId__c = pli.Id, Apttus_Config2__Sequence__c = 1);
        insert priceMatrix;
        
        Apttus_Config2__PriceMatrixEntry__c pme = new Apttus_Config2__PriceMatrixEntry__c(Apttus_Config2__Sequence__c = 1, Apttus_Config2__PriceMatrixId__c = priceMatrix.Id, Apttus_Config2__TierStartValue__c = 1, Apttus_Config2__TierEndValue__c = 2, Apttus_Config2__UsageRate__c = 5);
        insert pme;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        
        Billable_Item__c bi = new Billable_Item__c(Name = 'Test Prod', BI_SID__c = 'Test1');
        insert bi;
        
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Related_Opportunity_APTS__c = opp.Id, Apttus__Account__c = acc.Id, Apttus_QPComply__RelatedProposalId__c = proposal.Id);
        insert agreement;
        
        ALI_to_Single_BI_Mapping__c mapping = new ALI_to_Single_BI_Mapping__c(Name = 'Agreement', ALI_Field__c = 'Apttus__AgreementId__c', Single_BI_Field__c = 'Agreement__c');
        insert mapping;
        
        Usage_Price_Tier_to_Single_BI_Tier__c tierMapping = new Usage_Price_Tier_to_Single_BI_Tier__c(Name = 'Tier Row', Single_BI_Tier_Field__c = 'Tier_Row__c', Usage_Price_Tier_Field__c = 'Apttus_CMConfig__Sequence__c');
        insert tierMapping;
        
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id,Billing_Increment__c FROM Apttus_Config2__LineItem__c];
        
        Test.startTest();
        Apttus_Config2__UsagePriceTier__c usageTier = new Apttus_Config2__UsagePriceTier__c(Apttus_Config2__TierStartValue__c = 1, Apttus_Config2__TierEndValue__c = 2, Apttus_Config2__PriceMatrixId__c = priceMatrix.Id, Apttus_Config2__LineItemId__c = lineItems[0].Id, Apttus_Config2__Sequence__c = 1);
        insert usageTier;
        usageTier.Apttus_Config2__UsageRate__c = 100;
        update usageTier;
        Test.stopTest();
    }
    
}