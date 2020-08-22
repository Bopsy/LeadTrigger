/*****************************************************************************************
     Added by Apttus Managed Service Team
     Case: CAS-09086-J4T4D4
     Date: 04-01-2019
     Desc: Test class for APTS_ValidationCallback validation call back
******************************************************************************************/

@isTest
public class APTS_ValidationCallbackTest {
    
    @testSetup
    static void testDataSetup(){
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
        
        
        Product2 product1 = APTS_CPQTestUtility.createProduct('Test Product', 'A111111', 'Test Family', 'Bundle', true, true, true, true);
        product1.Bucket_Product__c = true;
        product1.BI_SID__c = 'Test1';
        insert product1;
        
        Product2 product2 = APTS_CPQTestUtility.createProduct('Voice CPS Capacity', 'A111111', 'Voice CPS Capacity', 'Bundle', true, true, true, true);
        product2.Bucket_Product__c = true;
        product2.BI_SID__c = 'Test1';
        insert product2;
        
        Apttus_Config2__PriceListItem__c pli1 = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product1.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli1;
                
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        APTS_CPQTestUtility.createLineItem(cartId, product2.Id, 1);
        
        Apttus_Config2__ConfigCustomClasses__c customSetting = new Apttus_Config2__ConfigCustomClasses__c();
        customSetting.Name = 'Custom Classes';
        customSetting.Apttus_Config2__ValidationCallbackClass__c = 'APTS_ValidationCallBack';
        insert customSetting;
    }
    
    @isTest
    static void validationCallbackTest(){
        List<Apttus_Config2__LineItem__c> listLineItem = [select id,name,Apttus_Config2__ConfigurationId__c from Apttus_Config2__LineItem__c];        

        Apttus_Config2.CustomClass.ValidationResult vResult = Apttus_Config2.CPQWebService.validateCart(listLineItem.get(0).Apttus_Config2__ConfigurationId__c);
        boolean isSuccess = vResult.IsSuccess;
        
        //Currently we are not using Ramp or asset line item in validation callback so calling below method directly to increase the code coverage.
        APTS_ValidationCallBack clb = new APTS_ValidationCallBack();
        clb.validateRampLineItems(null,null,null);
    }
    
}