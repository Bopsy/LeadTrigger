/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name       ConfigurationTriggerHandlerTest
*
* @description     Test class for ConfigurationTriggerHandler class.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal   <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal   <arenjal@twilio.com>
* @version        1.0
* @created        2019-06-19
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class ConfigurationTriggerHandlerTest {

    private static testMethod void test() {
        insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
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
        
        Test.startTest();
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        Deal_Desk_Request__c objDesk = new Deal_Desk_Request__c(Quote_Proposal__c =proposal.id, Account_SID__c='test', Prepayment_Amount__c=100 );
        insert objDesk;
        
        Apttus_Approval__Approval_Request__c  objApp = new Apttus_Approval__Approval_Request__c();
        objApp.Apttus_CQApprov__CartId__c= cartId;
        objApp.Apttus_Approval__DateAssigned__c = datetime.now();
        objApp.Apttus_Approval__DateApproved__c = datetime.now().adddays(1);
        insert objApp;
        
        update new Apttus_Config2__ProductConfiguration__c(Id = cartId, Apttus_CQApprov__Approval_Status__c = 'Approved');
        Apttus_Config2__ProductConfiguration__c oldConf= new Apttus_Config2__ProductConfiguration__c(Id = cartId);
        Apttus_Config2__ProductConfiguration__c cloneConf= new Apttus_Config2__ProductConfiguration__c(Id = cartId);
        cloneConf= oldConf.clone(false,true);
        cloneConf.Apttus_CQApprov__Approval_Status__c = 'Approved';
        insert cloneConf;            
        Test.stopTest();
    }
}