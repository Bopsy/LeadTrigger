/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name       Apts_ApprovalRequestTriggerHandlerTest
*
* @description     Test class for Apts_ApprovalRequestTriggerHandler class.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal   <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal   <arenjal@twilio.com>
* @version        1.0
* @created        2018-02-28
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class Apts_ApprovalRequestTriggerHandlerTest {

    private static testMethod void test() {
        Account acc = APTS_CPQTestUtility.createAccount('Test Account','Prospect');
        insert acc;
        
        Contact con = APTS_CPQTestUtility.createContact('Test Contact', acc.Id);
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Incubate');
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APTS_CPQTestUtility.createPriceList('Test PriceList', true);
        insert priceList;
        
        Product2 product = APTS_CPQTestUtility.createProduct('Test Product', 'A111111', 'Test Family', 'Test', true, true, true, true);
        product.BI_SID__c = 'Test1';
        insert product;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        
        Test.startTest();
        Apttus_Approval__Approval_Request__c  objApp = new Apttus_Approval__Approval_Request__c();
        objApp.Apttus_CQApprov__CartId__c= cartId;
        objApp.Apttus_Approval__DateAssigned__c = datetime.now();
        objApp.Apttus_Approval__DateApproved__c = datetime.now().adddays(1);
        insert objApp;
        objApp.Apttus_Approval__DateApproved__c = datetime.now().adddays(2);
        update objApp;
        Apttus_Config2__ProductConfiguration__c config= [Select Id, Total_Hours_to_Approve_Request__c from Apttus_Config2__ProductConfiguration__c limit 1];
        delete config;
        Test.stopTest();
    }
}