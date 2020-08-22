@isTest
private class AgreementDocuSignerTriggerHandlerTest {

	private static testMethod void testAfterInsert() {
	    insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement', Commit_Frequency__c = 'Monthly', Term_Range__c = '12', Total_Committed_Revenue_Input__c = 1200);
        Agreement_DocuSigner__c setting = new Agreement_DocuSigner__c(First_Name__c = 'Test', Name = 'Tester', Last_Name__c = 'Testerson', Is_Required__c = true, Email__c = 'test@testerson.com.123', Signing_Order__c = 1, Type__c = 'Signer');
        insert setting;
        
        Test.startTest();
        insert agreement;
        agreement.Signatory_s_Name__c = 'test all 1';
        agreement.Signatorys_Email__c = 'test@test.com';
        update agreement;
        agreement.Signatory_s_Name__c = 'test';
        agreement.Signatorys_Email__c = 'test@test.com';
        update agreement;
        Test.stopTest();
	}
	
	private static testMethod void testBatch(){
	     insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
	    Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement', Commit_Frequency__c = 'Monthly', Term_Range__c = '12', Total_Committed_Revenue_Input__c = 1200);
        Agreement_DocuSigner__c setting = new Agreement_DocuSigner__c(First_Name__c = 'Test', Name = 'Tester', Last_Name__c = 'Testerson', Is_Required__c = true, Email__c = 'test@testerson.com.123', Signing_Order__c = 1, Type__c = 'Signer');
        insert setting;
        insert agreement;
        
        delete [SELECT Id FROM Apttus_DocuApi__DocuSignDefaultRecipient2__c];
        Test.startTest();
            //Database.executeBatch(new BatchGenerateDocusignSigner());
        Test.stopTest();
	} 
    
    private static testMethod void test() {
        insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
        Account acc = APTS_CPQTestUtility.createAccount('Test Account','Prospect');
        insert acc;
        
        Contact con = APTS_CPQTestUtility.createContact('Test Contact', acc.Id);
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Incubate');
        insert opp;
        
        Apttus_Config2__ClassificationName__c objMainCat = new Apttus_Config2__ClassificationName__c ();
        objMainCat.Apttus_Config2__Active__c = true;
        objMainCat.Apttus_Config2__Type__c ='Option Group';
        objMainCat.Apttus_Config2__HierarchyLabel__c ='SendGrid';
        insert objMainCat;
        
        Apttus_Config2__ClassificationHierarchy__c objCat = new Apttus_Config2__ClassificationHierarchy__c();
        objCat.Apttus_Config2__Label__c ='SendGrid';
        objCat.Apttus_Config2__HierarchyId__c = objMainCat.Id;
        insert objCat;
        
        Apttus_Config2__ProductOptionGroup__c objProdOption = new Apttus_Config2__ProductOptionGroup__c();
        objProdOption.Apttus_Config2__OptionGroupId__c = objCat.Id;
        objProdOption.Apttus_Config2__Sequence__c = 1;
        insert objProdOption;
        
        Apttus_Config2__ProductOptionComponent__c  objProdOption1 = new Apttus_Config2__ProductOptionComponent__c ();
        objProdOption1.Apttus_Config2__ProductOptionGroupId__c  = objProdOption.Id;
        objProdOption1.Apttus_Config2__Sequence__c = 1;
        insert objProdOption1;
        
        Apttus_Config2__PriceList__c priceList = APTS_CPQTestUtility.createPriceList('Test PriceList', true);
        insert priceList;
        
        Product2 product = APTS_CPQTestUtility.createProduct('Test Product', 'A111111', 'SendGrid', 'SendGrid', true, true, true, true);
        //product.Bucket_Product__c = true;
        product.BI_SID__c = 'Test1';
        insert product;

		Product2 product1 = APTS_CPQTestUtility.createProduct('Test Product', 'A111111', 'Test Family', 'Test', true, true, true, true);
        //product.Bucket_Product__c = true;
        product1.BI_SID__c = 'Test1';
        insert product1;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        APTS_CPQTestUtility.createLineItem(cartId, product1.Id, 1);
        
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = new Apttus_Proposal__Proposal_Line_Item__c(Apttus_Proposal__Proposal__c = proposal.Id, Apttus_Proposal__Description__c = 'Flex Test', Apttus_Proposal__Product__c = product.Id,
                                                                                                            Apttus_QPConfig__ProductOptionId__c=objProdOption1.id, Apttus_QPConfig__ClassificationHierarchy__c='SendGrid');
        insert proposalLineItem;
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 = new Apttus_Proposal__Proposal_Line_Item__c(Apttus_Proposal__Proposal__c = proposal.Id, Apttus_Proposal__Description__c = 'Flex Test', Apttus_Proposal__Product__c = product1.Id);
        insert proposalLineItem1;
        
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement',Apttus__Account__c=acc.Id ,Related_Opportunity_APTS__c=opp.Id, Commit_Frequency__c = 'Monthly', Term_Range__c = '12', Total_Committed_Revenue_Input__c = 1200,Apttus_QPComply__RelatedProposalId__c=proposal.Id);
        Agreement_DocuSigner__c setting = new Agreement_DocuSigner__c(First_Name__c = 'Test', Name = 'Tester', Last_Name__c = 'Testerson', Is_Required__c = true, Email__c = 'test@testerson.com.123', Signing_Order__c = 1, Type__c = 'Signer');
        insert setting;
        
        Agreement_DocuSigner__c setting1 = new Agreement_DocuSigner__c(First_Name__c = 'Test', Name = 'Tester1', Last_Name__c = 'Testerson', Is_Required__c = true, Email__c = 'test@testerson.com.1223', Signing_Order__c = 2, Type__c = 'Signer');
        insert setting1;
        
        Agreement_DocuSigner__c setting2 = new Agreement_DocuSigner__c(First_Name__c = 'Test', Name = 'Tester2', Last_Name__c = 'Testerson', Is_Required__c = true, Email__c = 'test@testerson.com.1233', Signing_Order__c = 3, Type__c = 'Signer',SendGrid_Only__c=true);
        insert setting2;
        
        Test.startTest();
        insert agreement;
        agreement.Signatory_s_Name__c = 'test all 1';
        agreement.Signatorys_Email__c = 'test@test.com';
        update agreement;
        agreement.Signatory_s_Name__c = 'test';
        agreement.Signatorys_Email__c = 'test@test.com';
        update agreement;
        Test.stopTest();
    }

}