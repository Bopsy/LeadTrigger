@isTest
private class QuotePricingControllerTest {

	private static testMethod void test() {
        Account acc = APTS_CPQTestUtility.createAccount('Test Account','Prospect');
        insert acc;
        
        Contact con = APTS_CPQTestUtility.createContact('Test Contact', acc.Id);
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Prospecting');
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APTS_CPQTestUtility.createPriceList('Test PriceList', true);
        insert priceList;
        
        Product2 product = APTS_CPQTestUtility.createProduct('Test Product', 'A111111', 'Test Family', 'Bundle', true, true, true, true);
        product.Bucket_Product__c = true;
        product.BI_SID__c = 'Test1';
        insert product;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
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
        
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = new Apttus_Proposal__Proposal_Line_Item__c(Apttus_Proposal__Proposal__c = proposal.Id, Apttus_Proposal__Description__c = 'Flex Test', Apttus_Proposal__Product__c = product.Id);
        insert proposalLineItem;
        
        Apttus_QPConfig__ProposalUsagePriceTier__c usageTier = new Apttus_QPConfig__ProposalUsagePriceTier__c(Apttus_QPConfig__LineItemId__c = proposalLineItem.Id, Apttus_QPConfig__Sequence__c = 1);
        insert usageTier;
        
        
        
        Test.startTest();
            Test.setCurrentPageReference(new PageReference('Page.myPage'));
            System.currentPageReference().getParameters().put('quoteId', proposal.Id);
            System.currentPageReference().getParameters().put('agreementId', agreement.Id);
            QuotePricingController ctrl = new QuotePricingController();
            ctrl.updatePricing();
            ctrl.cancel();
        Test.stopTest();
	}

}