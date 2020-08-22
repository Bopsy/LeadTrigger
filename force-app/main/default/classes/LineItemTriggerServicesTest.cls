@isTest
private class LineItemTriggerServicesTest {

    private static testMethod void test() {
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
        
        Product2 product = APTS_CPQTestUtility.createProduct('Test Product', 'A111111', 'Test Family', 'Test', true, true, true, true);
        //product.Bucket_Product__c = true;
        product.BI_SID__c = 'Test1';
        product.Capable_of_Sub_Minute_Billing__c = true;
        insert product;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product.Id, 100, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        
        Apttus_Config2__ClassificationName__c objMainCat = new Apttus_Config2__ClassificationName__c ();
        objMainCat.Apttus_Config2__Active__c = true;
        objMainCat.Apttus_Config2__Type__c ='Option Group';
        objMainCat.Apttus_Config2__HierarchyLabel__c ='Named User Flex';
        insert objMainCat;
        
        Apttus_Config2__ClassificationHierarchy__c objCat = new Apttus_Config2__ClassificationHierarchy__c();
        objCat.Apttus_Config2__Label__c ='Named User Flex';
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
        
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        
        Apttus_DealMgr__DealGuidanceRule__c testRule = new Apttus_DealMgr__DealGuidanceRule__c(Apttus_DealMgr__ProductScope__c = product.Id, Apttus_DealMgr__Sequence__c = 1, Apttus_DealMgr__Measure__c='Unit Price');
        insert testRule;
        
        Apttus_DealMgr__DealGuidanceRuleEntry__c testEntry = new Apttus_DealMgr__DealGuidanceRuleEntry__c(Apttus_DealMgr__Sequence__c = 1, Apttus_DealMgr__GuidanceRuleId__c = testRule.Id, Apttus_DealMgr__Band1Value__c = '0', Apttus_DealMgr__Dimension1Value__c = '59', Apttus_DealMgr__Dimension2Value__c = '0.009', Apttus_DealMgr__Dimension3Value__c = '0.012',Apttus_DealMgr__Band3Value__c='0.12',Apttus_DealMgr__Band2Value__c='0.12');
        insert testEntry;
        
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id,Billing_Increment__c FROM Apttus_Config2__LineItem__c];
        Test.startTest();
        lineItems[0].Apttus_Config2__NetUnitPrice__c = 0.01;
        lineItems[0].Apttus_Config2__ProductOptionId__c=objProdOption1.id;
        lineItems[0].Billing_Increment__c = 0.01;
        lineItems[0].Billing_Minute__c = 0.01;
        update lineItems;
        product.Capable_of_Sub_Minute_Billing__c = false;
        product.Always_Needs_Review__c=true;
        update product;
        update new Apttus_Config2__ProductConfiguration__c(Id = cartId, Apttus_CQApprov__Approval_Status__c = 'Cancelled');
        lineItems[0].Apttus_Config2__Description__c = 'Voice CPS Capacity';
        lineItems[0].Billing_Increment__c = 0.01;
        lineItems[0].Billing_Minute__c = 0.01;
        lineItems[0].Apttus_Config2__OptionId__c = product.Id;
        update lineItems;
        
        Apttus_Config2__LineItem__c objLineItem = new Apttus_Config2__LineItem__c();
        objLineItem.Apttus_Config2__ConfigurationId__c = cartId;
        objLineItem.Apttus_Config2__ProductId__c = product.Id;
        objLineItem.Apttus_Config2__NetUnitPrice__c = 0.01;
        objLineItem.Apttus_Config2__ProductOptionId__c=objProdOption1.id;
        objLineItem.Apttus_Config2__Description__c = 'Voice CPS Capacity';
        objLineItem.Apttus_Config2__ItemSequence__c =12;
        objLineItem.Apttus_Config2__LineNumber__c =12;
        insert objLineItem;
        
        Test.stopTest();
    }

    private static testMethod void test1() {
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
        
        Product2 product = APTS_CPQTestUtility.createProduct('SendGrid', 'A111111', 'SendGrid', 'SendGrid', true, true, true, true);
        product.Bucket_Product__c = true;
        product.BI_SID__c = 'Test1';
        product.Capable_of_Sub_Minute_Billing__c = true;
        product.SG_Product_Type__c = 'Email';
        insert product;
        
        Apttus_Config2__PriceListItem__c pli = APTS_CPQTestUtility.createPriceListItem(priceList.Id, product.Id, 200, 'Test', 'Test','Test', 'Test',true);
        insert pli;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        proposal.Commit_Frequency__c ='Monthly';
        proposal.Term_Range__c = '12';
        insert proposal;
        
        String cartId = APTS_CPQTestUtility.createConfiguration(proposal.id);
        
        Apttus_Config2__ClassificationName__c objMainCat = new Apttus_Config2__ClassificationName__c ();
        objMainCat.Apttus_Config2__Active__c = true;
        objMainCat.Apttus_Config2__Type__c ='Option Group';
        objMainCat.Apttus_Config2__HierarchyLabel__c ='Support';
        insert objMainCat;
        
        Apttus_Config2__ClassificationHierarchy__c objCat = new Apttus_Config2__ClassificationHierarchy__c();
        objCat.Apttus_Config2__Label__c ='Support';
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
        
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        APTS_CPQTestUtility.createLineItem(cartId, product.Id, 1);
        Apttus_DealMgr__DealGuidanceRule__c testRule = new Apttus_DealMgr__DealGuidanceRule__c(Apttus_DealMgr__ProductScope__c = product.Id, Apttus_DealMgr__Sequence__c = 1, Apttus_DealMgr__Measure__c='Unit Price');
        insert testRule;
        
        Apttus_DealMgr__DealGuidanceRuleEntry__c testEntry = new Apttus_DealMgr__DealGuidanceRuleEntry__c(Apttus_DealMgr__Sequence__c = 1, Apttus_DealMgr__GuidanceRuleId__c = testRule.Id, Apttus_DealMgr__Band1Value__c = '0', Apttus_DealMgr__Dimension1Value__c = '59', Apttus_DealMgr__Dimension2Value__c = '0.009', Apttus_DealMgr__Dimension3Value__c = '0.012',Apttus_DealMgr__Band3Value__c='0.12',Apttus_DealMgr__Band2Value__c='0.12');
        insert testEntry;
        
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id,Billing_Increment__c FROM Apttus_Config2__LineItem__c];
        Test.startTest();
        lineItems[0].Apttus_Config2__NetUnitPrice__c = 100;
        lineItems[0].Apttus_Config2__PriceListItemId__c =pli.id;
        lineItems[0].Apttus_Config2__OptionId__c = product.Id;
        lineItems[0].Apttus_Config2__StartDate__c = Date.newInstance(2017,10,1);
        lineItems[0].Apttus_Config2__EndDate__c = Date.newInstance(2017,10,31);
        lineItems[1].Apttus_Config2__NetUnitPrice__c = 300;
        lineItems[1].Apttus_Config2__PriceListItemId__c =pli.id;
        lineItems[1].Apttus_Config2__OptionId__c = product.Id;
        lineItems[1].Apttus_Config2__StartDate__c = Date.newInstance(2017,11,1);
        lineItems[1].Apttus_Config2__EndDate__c = Date.newInstance(2017,11,30);
        update lineItems;
        delete lineItems;
        
        Test.stopTest();
    }
    
}