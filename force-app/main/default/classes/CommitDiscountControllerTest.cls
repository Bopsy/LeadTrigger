@isTest
private class CommitDiscountControllerTest {
    static testMethod void testConstructor(){
        CPQ_discount_and_field_mapping__c  setting = new CPQ_discount_and_field_mapping__c ();
        setting.Name = '100k';
        setting.Commit_Level_Discount__c  = '100000.00';
        setting.Flat_Field_API_Name__c  = 'X100000_Discount_Price__c';
        setting.Percent_Field_API_Name__c  = 'X100000_Percent_of_Spend_Price__c';
        insert setting;
        
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
        insert product;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product.Id, 100, 'Test', 'Test','Test', 'Test',true);
        pli.X100000_Discount_Price__c = 20;
        pli.X100000_Percent_of_Spend_Price__c =30;
        insert pli;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id,Billing_Increment__c FROM Apttus_Config2__LineItem__c];
        lineItems[0].Apttus_Config2__PriceListItemId__c =pli.id;
        update lineItems;
        
        Test.setCurrentPageReference(new PageReference('Page.myPage'));
        System.currentPageReference().getParameters().put('id', cartId);
        
        Test.startTest();
        CommitDiscountController ctrl = new CommitDiscountController();
        ctrl.priceValue = 100000.00;
        ctrl.reprice();
        ctrl.cancel();
        ctrl.savePage();
        ctrl.priceValue = 5000.00;
        ctrl.reprice();
        Test.stopTest();
    }
}