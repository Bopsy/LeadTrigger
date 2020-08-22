/***************************************************
                Added by Apttus Support
                Case: CAS-09701-F2Y8Y7
                Date: 15-03-2019
                Desc: Test class for ConfigurationTrigger and it's handler
****************************************************/
@isTest
private class APTS_ConfigurationTriggerTest {

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
        
        list<Apttus_Config2__LineItem__c> liList = [select id,Apttus_Config2__Guidance__c from Apttus_Config2__LineItem__c];
        
        for(Apttus_Config2__LineItem__c li : liList)
            li.Apttus_Config2__Guidance__c = 'Red';
            
        update liList;
        
        Apttus_Config2__ProductConfiguration__c configRec = [select id,name,Apttus_CQApprov__Approval_Status__c from Apttus_Config2__ProductConfiguration__c  where id=:cartId];
        configRec.Apttus_CQApprov__Approval_Status__c = 'Approved';
        configRec.Total_Hours_to_Approve_Request__c=10;
        update configRec;
        
        delete configRec;
    }
}