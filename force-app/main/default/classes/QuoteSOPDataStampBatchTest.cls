/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  QuoteSOPDataStampBatchTest
*
* @description 	  Test class for QuoteSOPDataStampBatch class, test include:
					1. batch excute test
					4. schedulaer test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui	 <ncui@twilio.com>
* @modifiedBy     Mia Cui    <ncui@twilio.com>
* @version        1.0
* @created        2020-02-26
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		
*
**/
@isTest
public class QuoteSOPDataStampBatchTest {
    static testmethod void positivetest(){
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
        
        Product2 product1 = APTS_CPQTestUtility.createProduct('Test Product1', 'A111111', 'Test Family', 'Test', true, true, true, true);
        //product.Bucket_Product__c = true;
        product1.BI_SID__c = 'Test1';
        product1.Capable_of_Sub_Minute_Billing__c = true;
        insert product1;
        
        Product2 product2 = APTS_CPQTestUtility.createProduct('Test Product2', 'A111111', 'Test Family', 'Test', true, true, true, true);
        //product.Bucket_Product__c = true;
        product2.BI_SID__c = 'Test1';
        product2.Capable_of_Sub_Minute_Billing__c = true;
        insert product2;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product1.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        String cartId1 = APTS_CPQTestUtility.createConfiguration(proposal.id);
        APTS_CPQTestUtility.createLineItem(cartId1, product1.Id, 1);
        update new Apttus_Config2__ProductConfiguration__c(Id = cartId1,Total_Hours_to_Approve_Request__c=3,
                                                           Apttus_Config2__FinalizedDate__c= datetime.newInstance(2020, 2, 25, 12, 30, 0));
        
        String cartId2 = APTS_CPQTestUtility.createConfiguration(proposal.id);
        APTS_CPQTestUtility.createLineItem(cartId2, product2.Id, 1);        
        update new Apttus_Config2__ProductConfiguration__c(Id = cartId2,Total_Hours_to_Approve_Request__c=300, Apttus_Config2__FinalizedDate__c= datetime.newInstance(2020, 1, 25, 12, 30, 0));
        
        Apttus_Proposal__Proposal__c proposalBefore = [Select id, First_LI_created_date__c,
                                            				  First_Configuration_Finalized_Date__c,First_Configuration_Approval_Time__c 
                                                       from Apttus_Proposal__Proposal__c where id =: proposal.Id];
        
        system.assert(proposalBefore.First_LI_created_date__c == NULL);
        System.assert(proposalBefore.First_Configuration_Finalized_Date__c == NULL);
        System.assert(proposalBefore.First_Configuration_Approval_Time__c == NULL);
        
        Test.startTest();
            QuoteSOPDataStampBatch obj = new QuoteSOPDataStampBatch();
            DataBase.executeBatch(obj,20);
        Test.stopTest();
        
        Apttus_Proposal__Proposal__c proposalAfter = [Select id, First_LI_created_date__c,
                                            				  First_Configuration_Finalized_Date__c,First_Configuration_Approval_Time__c 
                                                       from Apttus_Proposal__Proposal__c where id =: proposal.Id];
        
        system.assert(proposalAfter.First_LI_created_date__c != NULL);
        System.assert(proposalAfter.First_Configuration_Finalized_Date__c == datetime.newInstance(2020, 1, 25, 12, 30, 0));
        System.assert(proposalAfter.First_Configuration_Approval_Time__c == 300);
    }
    
    static testmethod void negativeTest(){
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
        
        Product2 product1 = APTS_CPQTestUtility.createProduct('Test Product1', 'A111111', 'Test Family', 'Test', true, true, true, true);
        //product.Bucket_Product__c = true;
        product1.BI_SID__c = 'Test1';
        product1.Capable_of_Sub_Minute_Billing__c = true;
        insert product1;
        
        Product2 product2 = APTS_CPQTestUtility.createProduct('Test Product2', 'A111111', 'Test Family', 'Test', true, true, true, true);
        //product.Bucket_Product__c = true;
        product2.BI_SID__c = 'Test1';
        product2.Capable_of_Sub_Minute_Billing__c = true;
        insert product2;
        
        Product2 product3 = APTS_CPQTestUtility.createProduct('Test Product2', 'A111111', 'Test Family', 'Test', true, true, true, true);
        //product.Bucket_Product__c = true;
        product3.BI_SID__c = 'Test1';
        product3.Capable_of_Sub_Minute_Billing__c = true;
        insert product3;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product1.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        Apttus_Proposal__Proposal__c proposalBefore = [Select id, First_LI_created_date__c,
                                            				  First_Configuration_Finalized_Date__c,First_Configuration_Approval_Time__c 
                                                       from Apttus_Proposal__Proposal__c where id =: proposal.Id];
        
        system.assert(proposalBefore.First_LI_created_date__c == NULL);
        System.assert(proposalBefore.First_Configuration_Finalized_Date__c == NULL);
        System.assert(proposalBefore.First_Configuration_Approval_Time__c == NULL);
        
        Test.startTest();
            QuoteSOPDataStampBatch obj = new QuoteSOPDataStampBatch();
            DataBase.executeBatch(obj);
        Test.stopTest();
        
        Apttus_Proposal__Proposal__c proposalAfter = [Select id, First_LI_created_date__c,
                                            				  First_Configuration_Finalized_Date__c,First_Configuration_Approval_Time__c 
                                                       from Apttus_Proposal__Proposal__c where id =: proposal.Id];
        
        system.assert(proposalAfter.First_LI_created_date__c == NULL);
        System.assert(proposalAfter.First_Configuration_Finalized_Date__c == NULL);
        System.assert(proposalAfter.First_Configuration_Approval_Time__c == NULL);
        
    }
    
    static testMethod void testScehduler(){
        String CRON_EXP = '0 0 * * * ?'; 
        //test schedule
        Test.startTest();
            String jobId2 = System.schedule('ScheduleApexClassTester',
                                            CRON_EXP,
                                            new QuoteSOPDataStampBatch());
        Test.stopTest();
         
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'QuoteSOPDataStampBatch') LIMIT 1].Status);
    }
    
    
    

}