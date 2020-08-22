/* * * * * * * * * * * * *
 *  Class Name:   OrderToCashControllerTest
 *  Purpose:      This is test class for the OrderToCashController controller.
 *  Author:       Purushottam Bhaigade
 *  Company:      GoNimbly
 *  Created Date: 25-May-2016
 *
 * * * * * * * * * * * * */
@isTest
private class OrderToCashControllerTest{

    private static Apttus__APTS_Agreement__c  apttusAgreementObj = new Apttus__APTS_Agreement__c();
    private static Account  accountObj = new Account();
    private static List<Account_SID__c> accountSIDs = new List<Account_SID__c>();
    private static Integer numOfRec = 10;
    private static List<Billable_Item__c> billableItemList = new List<Billable_Item__c>();
    private static List<String> productFamilyList = new List<String>{'Billing', 'Data & Other', 'Messaging', 'Numbers', 'Numbers Setup', 'Voice & Video'};

    /* * * * * * * * * * * * *
    *  Method Name:  setup
    *  Purpose:      This method is used to create the test data.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 25-May-2016
    * * * * * * * * * * * * */
    static  void setup() {

        try{
            accountObj.Name='TestAccount';
            accountObj.Channel_Account_Status__c='Healthy';
            insert accountObj;

            for ( Integer i = 0; i < numOfRec; i++ )
                accountSIDs.add( createSID( 'sidName'+i, 'testSidEmail'+i+'@testSID.com', accountObj.Id , 'accountSID'+i) );

            insert accountSIDs;

            apttusAgreementObj.Name='TestApptusAgreement';
            apttusAgreementObj.Company_Description__c='TestDescription';
            apttusAgreementObj.Apttus__Account__c=accountObj.Id;
            apttusAgreementObj.Use_Case_Internal_External__c='Other';
            apttusAgreementObj.Product__c='SMS';
            apttusAgreementObj.Directional_Messaging__c='Inbound Only';
            apttusAgreementObj.Twilio_Paper__c='Yes';
            apttusAgreementObj.Use_Case_Description__c='Test use case description';
            apttusAgreementObj.Apttus__Term_Months__c=8;
            apttusAgreementObj.Apttus__Status_Category__c='Initiate';
            apttusAgreementObj.Account_SIDs__c='';
            insert apttusAgreementObj;
        }catch(DmlException ex){
          throw ex;
        }
    }

    static Account_SID__c createSID( String name, String email, Id acctId , String accountSID) {

        return new Account_SID__c( Name = name, OwnerUser_Email_Address__c = email, Account__c = acctId, Account_SID__c = accountSID );
    }

    static void createBillableItem(){

        for(Integer i = 0; i < numOfRec; i++){
            Billable_Item__c billableItem= new Billable_Item__c();
            billableItem.Billing_Type__c     = 'Immediate';
            billableItem.BI_SID__c = 'BId'+i;
            billableItem.Name = 'INDIA Local Incoming SMS';
            billableItem.Price__c = 0.01;

            // Use of Modulo ensures that numOfRec and length of productFamilyList
            // can be any size but will not break
            billableItem.Product_Family__c = productFamilyList[ math.mod( i, productFamilyList.size() ) ];

            billableItem.Product_Group__c = 'Messages Int';
            billableItem.Product__c = 'SMS International Inbound';
            billableItem.Region__c = 'APAC';
            billableItem.Status__c = 'ACTIVE';
            billableItem.Territory__c= 'India';
            billableItemList.add(billableItem);
        }
        insert billableItemList;
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testGetOrderDetails_PositiveTestMethod
    *  Purpose:      This is positive test for getOrderDetails.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 25-May-2016
    * * * * * * * * * * * * */
    static testMethod void testGetOrderDetails_PositiveTestMethod() {
        setup();
        Apexpages.StandardController stdController = new Apexpages.StandardController(new Apttus__APTS_Agreement__c());
        OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);
        OrderToCashController.getOrderDetails(apttusAgreementObj.Id);
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testGetOrderDetails_NegativeTestMethod
    *  Purpose:      This is negative test for getOrderDetails.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 25-May-2016
    * * * * * * * * * * * * */
    static testMethod void testGetOrderDetails_NegativeTestMethod() {
        setup();
        Apexpages.StandardController stdController = new Apexpages.StandardController(new Apttus__APTS_Agreement__c());
        OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);
        String id='0011900000N0Tcd';
        Map<String, Object> orderDetailObj=OrderToCashController.getOrderDetails(Id);
        system.assertEquals(null, orderDetailObj.get('accountSIDs'));
    }



    /* * * * * * * * * * * * *
    *  Method Name:  testGetAccountSIDs_byName
    *  Purpose:      Finds Account SIDs by Name
    *  Author:       Will Saunders
    *  Company:      GoNimbly
    *  Created Date: 27-May-2016
    * * * * * * * * * * * * */
    static testMethod void testGetAccountSIDs_byName() {

        setup();
        Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
        OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

        Test.startTest();

            Map<String, Object> acctSIDResults = OrderToCashController.getAccountSIDs( apttusAgreementObj.Id, 'sidName' );

        Test.stopTest();

        List<Account_SID__c> resultAcctSIDs = (List<Account_SID__c>) acctSIDResults.get( 'accountSIDs' );
        system.assertEquals( 10, resultAcctSIDs.size() );
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testGetAccountSIDs_byName
    *  Purpose:      Test getAccountSIDs with Blank search query
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 31-May-2016
    * * * * * * * * * * * * */
    static testMethod void testGetAccountSIDs_byEmptySearchString() {

        setup();
        Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
        OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

        Test.startTest();

            Map<String, Object> acctSIDResults = OrderToCashController.getAccountSIDs( apttusAgreementObj.Id, '' );

        Test.stopTest();

        String actualResult = String.valueOf(acctSIDResults.get( OrderToCashController.ERRORS ));
        system.assertEquals( OrderToCashController.EMPTY_SEARCHQUERY, actualResult );
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testAddSIDToOrder
    *  Purpose:      This is positive test for addSIDToOrder method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 30-May-2016
    * * * * * * * * * * * * */
    static testMethod void testAddSIDToOrder() {
           setup();
           Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
           OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

           Test.startTest();

              for(Integer i=0; i < numOfRec; i++){
                  Account_SID__c accountSID = accountSIDs.get(i);
                  OrderToCashController.addSIDToOrder(apttusAgreementObj.Id,accountSID.Id);
              }

           Test.stopTest();

           Apttus__APTS_Agreement__c agreement = [select Account_SIDs__c  from Apttus__APTS_Agreement__c where Id =:apttusAgreementObj.Id];
           String agreementSIDs = agreement.Account_SIDs__c;
           System.assert(String.isNotBlank(agreementSIDs));
           List<String> accountSIDList = agreementSIDs.split(',');
           for(Integer i=0; i < numOfRec; i++){
              Account_SID__c accountSID = accountSIDs.get(i);
              System.assertEquals(accountSID.Account_SID__c, accountSIDList.get(i));
           }
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testRemoveSIDToOrder
    *  Purpose:      This is positive test for removeSIDToOrder method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 30-May-2016
    * * * * * * * * * * * * */
    static testMethod void testRemoveSIDToOrder() {
           setup();
           Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
           OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);
           Account_SID__c accountSID1 = accountSIDs.get(0);
           Account_SID__c accountSID2 = accountSIDs.get(1);
           OrderToCashController.addSIDToOrder(apttusAgreementObj.Id,accountSID1.Id);
           OrderToCashController.addSIDToOrder(apttusAgreementObj.Id,accountSID2.Id);

           Test.startTest();

              OrderToCashController.removeSIDFromOrder(apttusAgreementObj.Id, accountSID2.Account_SID__c);

           Test.stopTest();

           Apttus__APTS_Agreement__c agreement = [select Account_SIDs__c  from Apttus__APTS_Agreement__c where Id =:apttusAgreementObj.Id];
           String agreementSIDs = agreement.Account_SIDs__c;
           System.assert(String.isNotBlank(agreementSIDs));
           System.assertEquals(accountSID1.Account_SID__c,agreementSIDs);
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testRemoveSIDToOrder_NegativeTest
    *  Purpose:      This is negative test for removeSIDToOrder method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 30-May-2016
    * * * * * * * * * * * * */
    static testMethod void testRemoveSIDToOrder_NegativeTest() {
           setup();
           Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
           OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);
           Account_SID__c accountSID = accountSIDs.get(0);
           OrderToCashController.addSIDToOrder(apttusAgreementObj.Id,accountSID.Id);

           Test.startTest();

              OrderToCashController.removeSIDFromOrder(apttusAgreementObj.Id, '');

           Test.stopTest();

           Apttus__APTS_Agreement__c agreement = [select Account_SIDs__c  from Apttus__APTS_Agreement__c where Id =:apttusAgreementObj.Id];
           System.assertEquals(accountSID.Account_SID__c,agreement.Account_SIDs__c);
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testGetAllProductFamilies
    *  Purpose:      This is positive test for getAllProductFamilies method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 31-May-2016
    * * * * * * * * * * * * */
    static testMethod void testGetAllProductFamilies() {

         createBillableItem();
         Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
         OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

         Test.startTest();

            Map<String, Object> productFamilyMap = OrderToCashController.getAllProductFamilies();

         Test.stopTest();

         List<String> billItemList = (List<String>)productFamilyMap.get(OrderToCashController.PRODUCT_FAMILY_LIST);
         System.assertEquals(productFamilyList.size(), billItemList.size());
         System.assertEquals('', productFamilyMap.get(OrderToCashController.ERRORS));

         Set<String> pfFamResultSet = new Set<String>( billItemList );
         for ( Integer pfCount = 0; pfCount < productFamilyList.size(); pfCount++ ) {

             System.assert( pfFamResultSet.contains( productFamilyList[ pfCount ] ) );
         }
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testAddBillableItemToOrder
    *  Purpose:      This is positive test for addBillableItemToOrder method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 1-Jun-2016
    * * * * * * * * * * * * */
    static testMethod void testAddBillableItemToOrder() {

         setup();
         createBillableItem();
         Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
         OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

         Test.startTest();

            Map<String, Object> billableItemMap = OrderToCashController.addBillableItemToOrder(apttusAgreementObj.Id, billableItemList[0].Id);

         Test.stopTest();
         Single_BI_Discount__c singleBIdiscountObj = (Single_BI_Discount__c) billableItemMap.get(OrderToCashController.BILLABLE_ITEM);
         System.assertEquals(apttusAgreementObj.Id, singleBIdiscountObj.Agreement__c);
         System.assertEquals(billableItemList[0].Id, singleBIdiscountObj.Billable_Item__c);
         System.assertEquals('', billableItemMap.get(OrderToCashController.ERRORS));
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testaddTierToBillableItem
    *  Purpose:      This is test method for addTierToBillableItem method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 02-June-2016
    * * * * * * * * * * * * */
    static testMethod void testAddTierToBillableItem() {
         setup();
         Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
         OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

         Test.startTest();
            Single_BI_Discount__c singleBIdiscountObjParent = new Single_BI_Discount__c();
            singleBIdiscountObjParent.Name = 'TestSingleBIDiscount';
            singleBIdiscountObjParent.Min_Quantity__c = 20;
            singleBIdiscountObjParent.Round_Quantity__c = 20;
            singleBIdiscountObjParent.Agreement__c = apttusAgreementObj.Id;
            insert singleBIdiscountObjParent;

            Single_BI_Discount__c singleBIdiscountObj = new Single_BI_Discount__c();
            singleBIdiscountObj.Name = 'TestSingleBIDiscount';
            singleBIdiscountObj.Agreement__c = apttusAgreementObj.Id;
            singleBIdiscountObj.Tier_Parent__c = singleBIdiscountObjParent.Id;

            Map<String, Object> mapToReturn = OrderToCashController.addTierToBillableItem(singleBIdiscountObj);
         Test.stopTest();
         Single_BI_Discount__c singleBIdiscountObjForBillableItem = (Single_BI_Discount__c) mapToReturn.get(OrderToCashController.TIER);

         System.assertEquals(singleBIdiscountObjParent.Min_Quantity__c, singleBIdiscountObjForBillableItem.Min_Quantity__c);
         System.assertEquals(singleBIdiscountObjParent.Round_Quantity__c, singleBIdiscountObjForBillableItem.Round_Quantity__c);

    }

    /* * * * * * * * * * * * *
    *  Method Name:  testAddTierToBillableItemNegative
    *  Purpose:      This is test method for addTierToBillableItem method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 02-June-2016
    * * * * * * * * * * * * */
    static testMethod void testAddTierToBillableItemNegative() {

         Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
         OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

         Test.startTest();
            Single_BI_Discount__c singleBIdiscountObj = null;
            Map<String, Object> mapToReturn = OrderToCashController.addTierToBillableItem(singleBIdiscountObj);
         Test.stopTest();
         String error = (String) mapToReturn.get(OrderToCashController.ERRORS);
         System.assertEquals(OrderToCashController.EMPTY_TIER, error);
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testupdateOrderBillableItem
    *  Purpose:      This is test method for updateOrderBillableItem method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 02-June-2016
    * * * * * * * * * * * * */
    static testMethod void testupdateOrderBillableItem() {
         setup();
         Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
         OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

         Test.startTest();
            Single_BI_Discount__c singleBIdiscountObj = new Single_BI_Discount__c();
            singleBIdiscountObj.Name = 'TestSingleBIDiscount';
            singleBIdiscountObj.Agreement__c = apttusAgreementObj.Id;
            insert singleBIdiscountObj;

            singleBIdiscountObj.Flat_Price__c = 0.12;

            OrderToCashController.updateOrderBillableItem(singleBIdiscountObj);
         Test.stopTest();
         Single_BI_Discount__c singleBIdiscountObjForBillableItem = [select Flat_Price__c from Single_BI_Discount__c where Id =:singleBIdiscountObj.Id];
         System.assertEquals(singleBIdiscountObj.Flat_Price__c, singleBIdiscountObjForBillableItem.Flat_Price__c);
    }


    /* * * * * * * * * * * * *
    *  Method Name:  testupdateBillableItemTier
    *  Purpose:      This is test method for updateBillableItemTier method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 02-June-2016
    * * * * * * * * * * * * */
    static testMethod void testupdateBillableItemTier() {
        setup();    
         Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
         OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

         Test.startTest();
            Single_BI_Discount__c singleBIdiscountObj = new Single_BI_Discount__c();
            singleBIdiscountObj.Name = 'TestSingleBIDiscount';
            singleBIdiscountObj.Agreement__c = apttusAgreementObj.Id;
            insert singleBIdiscountObj;

            singleBIdiscountObj.Flat_Price__c = 0.10;

            OrderToCashController.updateBillableItemTier(singleBIdiscountObj);
         Test.stopTest();
         Single_BI_Discount__c singleBIdiscountObjForTier = [select Flat_Price__c from Single_BI_Discount__c where Id =:singleBIdiscountObj.Id];
         System.assertEquals(singleBIdiscountObj.Flat_Price__c, singleBIdiscountObjForTier.Flat_Price__c);
    }


    /* * * * * * * * * * * * *
    *  Method Name:  testdeleteBillableItemFromOrder
    *  Purpose:      This is test method for deleteBillableItemFromOrder method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 02-June-2016
    * * * * * * * * * * * * */
    static testMethod void testdeleteBillableItemFromOrder() {
         setup();
         Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
         OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

         Test.startTest();

            Single_BI_Discount__c singleBIdiscountObj1 = new Single_BI_Discount__c();
            singleBIdiscountObj1.Name = 'TestSingleBIDiscount1';
            singleBIdiscountObj1.Agreement__c = apttusAgreementObj.Id;
            insert singleBIdiscountObj1;

            Single_BI_Discount__c singleBIdiscountObj2 = new Single_BI_Discount__c();
            singleBIdiscountObj2.Name = 'TestSingleBIDiscount2';
            singleBIdiscountObj2.Agreement__c = apttusAgreementObj.Id;
            singleBIdiscountObj2.Tier_Parent__c = singleBIdiscountObj1.Id;
            insert singleBIdiscountObj2;

            List<Id> singleBIDiscountIDList = new List<Id>();
            singleBIDiscountIDList.add(singleBIdiscountObj1.Id);
            singleBIDiscountIDList.add(singleBIdiscountObj2.Id);

            OrderToCashController.deleteBillableItemFromOrder(apttusAgreementObj.Id,singleBIDiscountIDList);

         Test.stopTest();
//         List<Single_BI_Discount__c> deletedSingleBIObjList = [SELECT Id, IsDeleted from Single_BI_Discount__c where Agreement__c =:apttusAgreementObj.Id AND Id IN :singleBIDiscountIDList  ALL ROWS];
         List<Billable_Item__c> deletedSingleBIObjList = [select Id from Billable_Item__c where Id IN (SELECT Billable_Item__c from Single_BI_Discount__c WHERE Id IN :singleBIDiscountIdList) ALL ROWS];

         for(Billable_Item__c billableItemRecord : deletedSingleBIObjList)
         {
           System.assert(billableItemRecord.IsDeleted);
         }

    }

    /* * * * * * * * * * * * *
    *  Method Name:  testdeleteTierFromOrder
    *  Purpose:      This is test method for deleteTierFromOrder method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 02-June-2016
    * * * * * * * * * * * * */
    static testMethod void testdeleteTierFromOrder() {
         setup();
         Apexpages.StandardController stdController = new Apexpages.StandardController( apttusAgreementObj );
         OrderToCashController orderToCashControllerObj = new OrderToCashController(stdController);

         Test.startTest();

            Single_BI_Discount__c singleBIdiscountObj1 = new Single_BI_Discount__c();
            singleBIdiscountObj1.Name = 'TestSingleBIDiscount1';
            singleBIdiscountObj1.Agreement__c = apttusAgreementObj.Id;
            insert singleBIdiscountObj1;

            Single_BI_Discount__c singleBIdiscountObj2 = new Single_BI_Discount__c();
            singleBIdiscountObj2.Name = 'TestSingleBIDiscount1';
            singleBIdiscountObj2.Agreement__c = apttusAgreementObj.Id;
            insert singleBIdiscountObj2;

            List<Id> singleBIDiscountIdList = new List<Id>();
            singleBIDiscountIdList.add(singleBIdiscountObj1.Id);
            singleBIDiscountIdList.add(singleBIdiscountObj2.Id);

            OrderToCashController.deleteTierFromOrder(apttusAgreementObj.Id,singleBIDiscountIdList);

         Test.stopTest();

         List<Single_BI_Discount__c> deletedSingleBIObjList = [SELECT IsDeleted,Id FROM Single_BI_Discount__c WHERE Id IN :singleBIDiscountIdList  ALL ROWS ];
         for(Single_BI_Discount__c singleBIDiscountRec : deletedSingleBIObjList)
         {
           System.assert(singleBIDiscountRec.IsDeleted);
         }
    }



    /* * * * * * * * * * * * *
    *  Method Name:  testsearchSKUGroupByNamePositive
    *  Purpose:      This is test method for searchSKUGroupByName method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 06-June-2016
    * * * * * * * * * * * * */
    static testMethod void testsearchSKUGroupByNamePositive()
    {
         List<SKU_Group__c> skuGroupList = new List<SKU_Group__c>();
         List<SKU_Group__c> skuGroupListFromMap = new List<SKU_Group__c>();
         Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();

         Map<String,String> searchParam = new Map<String,String>();
         searchParam.put('name','Test');

         SKU_Group__c skuGroupObj1 = new SKU_Group__c(Name='TestSkuGroup1', Status__c='STATUS_ACTIVE');
         SKU_Group__c skuGroupObj2 = new SKU_Group__c(Name='TestSkuGroup2', Status__c='STATUS_ACTIVE');
         skuGroupList.add(skuGroupObj1);
         skuGroupList.add(skuGroupObj2);

         Test.startTest();
            insert skuGroupList;

            mapReturnedFromMethod =  OrderToCashController.searchSKUGroupByName(searchParam);
            skuGroupListFromMap = (List<SKU_Group__c>)mapReturnedFromMethod.get(OrderToCashController.SKU_GROUP_LIST);
         Test.stopTest();

         System.assertEquals(skuGroupListFromMap.size(),skuGroupList.size());
         for(integer i = 0; i < skuGroupList.size(); i++)
         {
            SKU_Group__c skuGroupRec =  skuGroupList.get(i);
            System.assertEquals(skuGroupRec.Id,skuGroupList[i].Id);
            System.assertEquals(skuGroupRec.Name,skuGroupList[i].Name);
         }
    }


    /* * * * * * * * * * * * *
    *  Method Name:  testSearchSKUGroupByNameNegative_WithWrongSearchQuery
    *  Purpose:      This is test method for searchSKUGroupByName method by sending wrong search param.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 10-June-2016
    * * * * * * * * * * * * */
    static testMethod void testSearchSKUGroupByNameNegative_WithWrongSearchQuery()
    {
         Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();
         String errorMessage='';
         Map<String,String> searchParam = new Map<String,String>();
         searchParam.put('name','puru');

         Test.startTest();
            mapReturnedFromMethod =  OrderToCashController.searchSKUGroupByName(searchParam);
            errorMessage = String.valueOf(mapReturnedFromMethod.get(OrderToCashController.ERRORS));
            List<SKU_Group__c> skuGroupList = (List<SKU_Group__c>) mapReturnedFromMethod.get(OrderToCashController.SKU_GROUP_LIST);
         Test.stopTest();
         System.assertEquals(errorMessage,'');
         System.assertEquals(0,skuGroupList.size());
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testAddSKUGroupToOrderPositive
    *  Purpose:      This is test method for addSKUGroupToOrder method. by sendint search param blank
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 06-June-2016
    * * * * * * * * * * * * */
    static testMethod void testAddSKUGroupToOrderPositive()
    {
        setup();
        Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();
        Order_Form_SKU_Group_Discount__c orderFromSKUGrpDiscount = new Order_Form_SKU_Group_Discount__c();
        Order_Form_SKU_Group_Discount__c orderFromSKUGrpDiscountFromMap = new Order_Form_SKU_Group_Discount__c();

        SKU_Group__c skuGroupObj = new SKU_Group__c(Name='TestSKUGroup');
        insert skuGroupObj; // insert SKU_Group__c record

         Test.startTest();
            //get the Order_Form_SKU_Group_Discount__c created from the controller
            mapReturnedFromMethod =  OrderToCashController.addSKUGroupToOrder(apttusAgreementObj.Id,skuGroupObj.Id);
            orderFromSKUGrpDiscountFromMap = (Order_Form_SKU_Group_Discount__c)mapReturnedFromMethod.get(OrderToCashController.ORDER_FORM_SKU_GROUP_DISCOUNT);
        Test.stopTest();

        System.assertEquals(apttusAgreementObj.Id,orderFromSKUGrpDiscountFromMap.agreement__c);
        System.assertEquals(skuGroupObj.Id,orderFromSKUGrpDiscountFromMap.SKU_Group__c);
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testUpdateSKUGroupFromOrder
    *  Purpose:      This is test method for addSKUGroupToOrder method. by sendint search param blank
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 06-June-2016
    * * * * * * * * * * * * */
    static testMethod void testUpdateSKUGroupFromOrder()
    {
        setup();
        Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();
        SKU_Group__c skuGroupObj = new SKU_Group__c(Name='TestSKUGroup');
        insert skuGroupObj; // insert SKU_Group__c record
        String nameToUpdate = 'Updated Name';
        Order_Form_SKU_Group_Discount__c orderFromSKUGrpDiscount = new Order_Form_SKU_Group_Discount__c();
        orderFromSKUGrpDiscount.agreement__c = apttusAgreementObj.Id;
        orderFromSKUGrpDiscount.SKU_Group__c = skuGroupObj.Id;
        orderFromSKUGrpDiscount.name = 'test Discount';
        insert orderFromSKUGrpDiscount;
         Test.startTest();
            orderFromSKUGrpDiscount.Name = nameToUpdate;
            OrderToCashController.updateSKUGroupFromOrder(orderFromSKUGrpDiscount);
        Test.stopTest();

        Order_Form_SKU_Group_Discount__c updatedOrderFromSKUGrpDiscount = [select Name from Order_Form_SKU_Group_Discount__c where Id = :orderFromSKUGrpDiscount.Id];
        System.assertEquals(nameToUpdate,updatedOrderFromSKUGrpDiscount.Name);
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testDeleteSKUGroupFromOrder
    *  Purpose:      This is test method for addSKUGroupToOrder method. by sendint search param blank
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 06-June-2016
    * * * * * * * * * * * * */
    static testMethod void testDeleteSKUGroupFromOrder()
    {
        setup();
        Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();
        SKU_Group__c skuGroupObj = new SKU_Group__c(Name='TestSKUGroup');
        insert skuGroupObj; // insert SKU_Group__c record

        Order_Form_SKU_Group_Discount__c orderFromSKUGrpDiscount1 = new Order_Form_SKU_Group_Discount__c();
        orderFromSKUGrpDiscount1.agreement__c = apttusAgreementObj.Id;
        orderFromSKUGrpDiscount1.SKU_Group__c = skuGroupObj.Id;
        insert orderFromSKUGrpDiscount1;

        Order_Form_SKU_Group_Discount__c orderFromSKUGrpDiscount2 = new Order_Form_SKU_Group_Discount__c();
        orderFromSKUGrpDiscount2.agreement__c = apttusAgreementObj.Id;
        orderFromSKUGrpDiscount2.SKU_Group__c = skuGroupObj.Id;
        insert orderFromSKUGrpDiscount2;

        List<Id> orderFromSKUGrpDiscountIdList = new List<Id>();
        orderFromSKUGrpDiscountIdList.add(orderFromSKUGrpDiscount1.Id);
        orderFromSKUGrpDiscountIdList.add(orderFromSKUGrpDiscount2.Id);

        Test.startTest();
            OrderToCashController.deleteSKUGroupFromOrder(apttusAgreementObj.Id, orderFromSKUGrpDiscountIdList);
        Test.stopTest();

        List<Order_Form_SKU_Group_Discount__c> deletedOrderFromSKUGrpDiscount = [select IsDeleted from Order_Form_SKU_Group_Discount__c where Id IN :orderFromSKUGrpDiscountIdList ALL ROWS];
        for(Order_Form_SKU_Group_Discount__c deletedOrderRecord : deletedOrderFromSKUGrpDiscount)
        {
          System.assert(deletedOrderRecord.IsDeleted);
        }
    }


    /* * * * * * * * * * * * *
    *  Method Name:  testSearchBillableItem
    *  Purpose:      This is test method for searchSKUGroupByName method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 07-June-2016
    * * * * * * * * * * * * */
    static testMethod void testSearchBillableItemPositive()
    {
         setup();

         List<Billable_Item__c> billableItemToInsertList = new List<Billable_Item__c>();
         List<Billable_Item__c> billableItemSearchedList = new List<Billable_Item__c>();
         List<Billable_Item__c> billableItemListFromMap = new List<Billable_Item__c>();
         Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();
         Map<String, String> searchParams  = new Map<String,String>();
         //add parameters to the map that will be used in search
         searchParams.put('agreementId',apttusAgreementObj.Id);
         searchParams.put('name','billable');
         searchParams.put('Product_Group__c','Messages Int');
         searchParams.put('Product__c','SMS International Outbound');
         searchParams.put('Region__c','APAC');
         searchParams.put('Territory__c','Afghanistan');
         searchParams.put('Product_Family__c','Messages');

         Billable_Item__c billableItemObj1 = new Billable_Item__c(Name='billableItem1',Product_Group__c='Messages Int',Territory__c='Afghanistan',Product__c='SMS International Outbound',Region__c='APAC', Status__c = 'ACTIVE');
         Billable_Item__c billableItemObj2 = new Billable_Item__c(Name='billableItem2',Product_Group__c='Messages Int',Territory__c='Afghanistan',Product__c='SMS International Outbound',Region__c='APAC', Status__c = 'ACTIVE');
         Billable_Item__c billableItemObj3 = new Billable_Item__c(Name='billableItem3',Product_Group__c='Messages Int',Territory__c='Afghanistan',Product__c='SMS International Outbound',Region__c='APAC', Status__c = 'ACTIVE');

         billableItemToInsertList.add(billableItemObj1);
         billableItemToInsertList.add(billableItemObj2);
         billableItemToInsertList.add(billableItemObj3);
         insert billableItemToInsertList;

         Single_BI_Discount__c singleBIdiscountObj = new Single_BI_Discount__c(Name='TestSingleBIRecord',Billable_Item__c=billableItemToInsertList[0].Id,Agreement__c=apttusAgreementObj.Id);
         insert   singleBIdiscountObj;

         String productFamily = searchParams.get('Product_Family__c');
         productFamily = productFamily.replace( '&amp;', '&' );

         List<Single_BI_Discount__c> existingDiscount = [ SELECT Id, Billable_Item__c FROM Single_BI_Discount__c WHERE Agreement__c = :searchParams.get('agreementId') AND Billable_Item__c != null ];
         List<Id> existingBillableItemIdList = new List<Id>();
         for(Single_BI_Discount__c singleBiDisc :existingDiscount){
           existingBillableItemIdList.add(singleBiDisc.Billable_Item__c);
         }

         Map<String, Boolean> fieldNameAndAvailabilityMap = new Map<String, Boolean>();
         Map<String, Schema.SObjectField> fieldNameDescribeMap = Schema.getGlobalDescribe().get('Billable_Item__c').getDescribe().fields.getMap();

         for(String fieldName :searchParams.keySet()){
           if(fieldName.equals('agreementId')){
             continue;
           }
           if(fieldNameDescribeMap.get(fieldName.toLowerCase()) != NULL){
             fieldNameAndAvailabilityMap.put(fieldName, true);
           }
         }

         String whereClause = '';
         for(String fieldName :fieldNameAndAvailabilityMap.keySet()){

           if(String.isNotBlank(searchParams.get(fieldName))){
             String value = searchParams.get(fieldName);
             String condition = ' = ';
             if(fieldName.equals('name')){
               value = '%'+value+'%';
               condition = ' like ';
             }
             whereClause += ' OR '+ fieldName + condition +'\''+value+'\'';
           }
         }

         whereClause = whereClause.trim();
         if(whereClause.startsWith('OR')){
           whereClause = whereClause.subString(2,whereClause.length());
           whereClause = whereClause.trim();
         }


         Test.startTest();

           String query = 'select Id, Name from Billable_Item__c where Status__c = \'ACTIVE\' AND ('+whereClause+')';
           if(String.isNotBlank(productFamily)){
             query += ' AND Product_Family__c =:productFamily';
           }
           query += ' AND Id NOT IN :existingBillableItemIdList';

           query = query.replace( '&amp;', '&' );


            billableItemSearchedList = Database.query(query);

            mapReturnedFromMethod =  OrderToCashController.searchBillableItems(searchParams);
            billableItemListFromMap = (List<Billable_Item__c>)mapReturnedFromMethod.get(OrderToCashController.BILLABLE_ITEM_LIST);


         Test.stopTest();

         System.assertEquals(billableItemSearchedList.size(),billableItemListFromMap.size());
         for(integer i = 0; i < billableItemListFromMap.size(); i++)
         {
            Billable_Item__c billableItemRec =  billableItemListFromMap.get(i);
            System.assertEquals(billableItemRec.Id,billableItemSearchedList[i].Id);
            System.assertEquals(billableItemRec.Name,billableItemSearchedList[i].Name);
         }

    }


    /* * * * * * * * * * * * *
    *  Method Name:  testSearchBillableItemsNegative
    *  Purpose:      This is test method for searchBillableItems method. by sending search param blank
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 06-June-2016
    * * * * * * * * * * * * */
    static testMethod void testSearchBillableItemsNegative1()
    {
         Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();
         String searchParam='',errorMessage='';
         Map<String, String> searchParams  = new Map<String,String>();
         //add parameters to the map that will be used in search
         searchParams.put('agreementId',apttusAgreementObj.Id);


         Test.startTest();
          // called method to check for null agreement ID
         mapReturnedFromMethod =  OrderToCashController.searchBillableItems(searchParams);
          errorMessage = String.valueOf(mapReturnedFromMethod.get(OrderToCashController.ERRORS));
         Test.stopTest();

         System.assertEquals(errorMessage,OrderToCashController.NO_AGREEMENTRECORD);
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testsendOrderToDealDesk
    *  Purpose:      This is test method for sendOrderToDealDesk method. by sending search param Agreement Id
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 23-June-2016
    * * * * * * * * * * * * */
    static testMethod void testsendOrderToDealDesk()
    {
         setup();
         Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();
         String url='';

         Test.startTest();
           mapReturnedFromMethod =  OrderToCashController.sendOrderToDealDesk(apttusAgreementObj.Id);
           url = String.valueOf(mapReturnedFromMethod.get(OrderToCashController.BASEURL));
         Test.stopTest();

    }

    /* * * * * * * * * * * * *
    *  Method Name:  testgetBillableItemFilterCriteria
    *  Purpose:      This is test method for getBillableItemFilterCriteria method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 23-June-2016
    * * * * * * * * * * * * */
    static testMethod void testGetBillableItemFilterCriteria()
    {
         setup();
         Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();
         String productFamily='Billing';

         product_family_mapping__c productFamilyMapping = new product_family_mapping__c();
         productFamilyMapping.Name  = 'PM0001';
         productFamilyMapping.Product__c = 'Sales Tax';
         productFamilyMapping.Product_Family__c = productFamily;
         productFamilyMapping.Product_Group__c = 'Billing';
         insert productFamilyMapping;
         Map<String, List<Schema.PicklistEntry>> fieldNameAndPickListMap = null;
         List<String> fieldList = new List<String>{'Region__c','Territory__c'};
         Test.startTest();
           mapReturnedFromMethod =  OrderToCashController.getBillableItemFilterCriteria(productFamily);
           fieldNameAndPickListMap = getPickListValues('Billable_Item__c', fieldList);
         Test.stopTest();
         System.assertEquals(productFamilyMapping.Product__c,((List<String>)mapReturnedFromMethod.get(OrderToCashController.PRODUCT_LIST)).get(0));
         System.assertEquals(productFamilyMapping.Product_Group__c,((List<String>)mapReturnedFromMethod.get(OrderToCashController.PRODUCT_GROUP_LIST)).get(0));

         List<String> regionList = (List<String>)mapReturnedFromMethod.get(OrderToCashController.REGION_LIST);
         List<String> territoryList = (List<String>)mapReturnedFromMethod.get(OrderToCashController.TERRITORY_LIST);
         System.assertEquals(fieldNameAndPickListMap.get(fieldList.get(0)).size(),regionList.size());
         System.assertEquals(fieldNameAndPickListMap.get(fieldList.get(1)).size(),territoryList.size());

         List<Schema.PicklistEntry> pickListObjList = fieldNameAndPickListMap.get(fieldList.get(0));
         for(integer i=0; i<fieldNameAndPickListMap.get(fieldList.get(0)).size();i++){
           System.assertEquals(pickListObjList.get(i).getValue(),regionList.get(i));
         }
         List<Schema.PicklistEntry> pickListObjListForTerritory = fieldNameAndPickListMap.get(fieldList.get(1));
         for(integer i=0; i<fieldNameAndPickListMap.get(fieldList.get(1)).size();i++){
           System.assertEquals(pickListObjListForTerritory.get(i).getValue(),territoryList.get(i));
         }
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testGetSKUGroupFilterCriteria
    *  Purpose:      This is test method for getSKUGroupFilterCriteria method.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 23-June-2016
    * * * * * * * * * * * * */
    static testMethod void testGetSKUGroupFilterCriteria()
    {
         setup();
         Map<String, Object> mapReturnedFromMethod = new Map<String, Object>();

         Map<String, List<Schema.PicklistEntry>> fieldNameAndPickListMap = null;
         List<String> fieldList = new List<String>{'Territory__c','Product__c'};
         Test.startTest();
           mapReturnedFromMethod =  OrderToCashController.getSKUGroupFilterCriteria();
           fieldNameAndPickListMap = getPickListValues('SKU_Group__c', fieldList);
         Test.stopTest();

         List<String> territoryList = (List<String>)mapReturnedFromMethod.get(OrderToCashController.GEOGRAPHY_LIST);
         List<String> productComponentList = (List<String>)mapReturnedFromMethod.get(OrderToCashController.PRODUCT_COMPONENT_LIST);
         System.assertEquals(fieldNameAndPickListMap.get(fieldList.get(0)).size(),territoryList.size());
         System.assertEquals(fieldNameAndPickListMap.get(fieldList.get(1)).size(),productComponentList.size());

         List<Schema.PicklistEntry> pickListObjList = fieldNameAndPickListMap.get(fieldList.get(0));
         for(integer i=0; i<fieldNameAndPickListMap.get(fieldList.get(0)).size();i++){
           System.assertEquals(pickListObjList.get(i).getValue(),territoryList.get(i));
         }
         List<Schema.PicklistEntry> pickListObjListForProductComp = fieldNameAndPickListMap.get(fieldList.get(1));
         for(integer i=0; i<fieldNameAndPickListMap.get(fieldList.get(1)).size();i++){
           System.assertEquals(pickListObjListForProductComp.get(i).getValue(),productComponentList.get(i));
         }
    }

    /* * * * * * * * * * * * *
     *  Method Name:  getPickListValues
     *  Purpose:      This method search billable items.
     *  Param:        String, List<String>
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 23-June-2016
     *
     * * * * * * * * * * * * */
    private static Map<String, List<Schema.PicklistEntry>> getPickListValues(String objectName, List<String> fieldNameList) {

        Map<String, List<Schema.PicklistEntry>> fieldNameAndPickListMap = new Map<String, List<Schema.PicklistEntry>>();
        Map<String, Schema.SObjectType> objectDescribeMap = Schema.getGlobalDescribe();

        if(objectDescribeMap == null){
            throw new OrderToCashController.ApplicationException(OrderToCashController.EMPTY_GLOBAL_DESCRIBE);
        }
        Schema.SObjectType sobjectType = objectDescribeMap.get(objectName);
        if(sobjectType == null){
            throw new OrderToCashController.ApplicationException(OrderToCashController.NO_SCHEMA_FOR_OBJECT);
        }
        Schema.DescribeSObjectResult sobjectDescribeResult = sobjectType.getDescribe();
        if(sobjectDescribeResult == null){
            throw new OrderToCashController.ApplicationException(OrderToCashController.EMPTY_OBJECT_DESCRIBE);
        }
        Map<String, Schema.SObjectField> fieldNameDescribeMap = sobjectDescribeResult.fields.getMap();
        if(fieldNameDescribeMap == null){
            throw new OrderToCashController.ApplicationException(OrderToCashController.NO_SCHEMA_FOR_FIELDS);
        }

        Schema.DescribeFieldResult fieldDescribeResult ;
        sObjectField sObjField;
        for(string fieldName :fieldNameList){

            if(fieldNameDescribeMap.get(fieldName.toLowerCase()) == null){
              continue;
            }
            sObjField = fieldNameDescribeMap.get(fieldName);
            fieldDescribeResult = sObjField.getDescribe();
            if(fieldDescribeResult == null){
                throw new OrderToCashController.ApplicationException(OrderToCashController.EMPTY_FIELD_DESCRIBE);
            }
            if(fieldDescribeResult.getType() == Schema.DisplayType.PICKLIST){
                List<Schema.PicklistEntry> pickListEntry = fieldDescribeResult.getPicklistValues();
                fieldNameAndPickListMap.put(fieldName, pickListEntry);
            }
        }
        return fieldNameAndPickListMap;
    }
}