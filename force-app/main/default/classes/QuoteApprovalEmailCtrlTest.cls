@isTest
private class QuoteApprovalEmailCtrlTest {

	private static testMethod void test() {
        Account acc = APTS_CPQTestUtility.createAccount('Test Account','Prospect');
        insert acc;
        
        Contact con = APTS_CPQTestUtility.createContact('Test Contact', acc.Id);
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Prospecting');
        insert opp;
        
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
        
        Test.startTest();
            QuoteApprovalEmailCtrl ctrl = new QuoteApprovalEmailCtrl();
            ctrl.configId = cartId;
            Apttus_Config2__ProductConfiguration__c config = ctrl.config;
            List<Apttus_Config2__LineItem__c> flatDiscountItems = ctrl.flatDiscountItems;
            List<Apttus_Config2__LineItem__c> tieredDiscountItems = ctrl.tieredDiscountItems;
            List<Apttus_Config2__LineItem__c> recurringDiscountItems = ctrl.recurringDiscountItems;
            List<Apttus_Config2__LineItem__c> flexDiscountItems = ctrl.flexDiscountItems;
            List<Apttus_Config2__LineItem__c> bucketDiscountItems = ctrl.bucketDiscountItems;
        Test.stopTest();
	}

}