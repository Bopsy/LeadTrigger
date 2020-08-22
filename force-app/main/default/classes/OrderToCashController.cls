/* * * * * * * * * * * * *
 *  Class Name:   OrderToCashController
 *  Purpose:      This is javascript remoting controller for OrderToCashForm VF page.
 *  Author:       Purushottam Bhaigade
 *  Company:      GoNimbly
 *  Created Date: 23-May-2016
 *
 * * * * * * * * * * * * */

public with sharing class OrderToCashController
{

    public static String EMPTY_SEARCHQUERY = 'Please enter search query.';
    public static String NO_AGREEMENTRECORD = 'Please select Agreement Id.';
    public static String EMPTY_TIER = 'Tier is empty or null.';
    public static String EMPTY_TIER_PARENT = 'Parent is missing for Tier.';
    public static String EMPTY_GLOBAL_DESCRIBE = 'Global Describe call is not allowd or it\'s returning empty, Please contact admin';
    public static String NO_SCHEMA_FOR_OBJECT = 'Invalid object, Please contact admin';
    public static String EMPTY_OBJECT_DESCRIBE = 'Object Describe call is not allowd or it\'s returning empty, Please contact admin';
    public static String NO_SCHEMA_FOR_FIELDS = 'Invalid field, Please contact admin';
    public static String EMPTY_FIELD_DESCRIBE = 'Field Describe call is not allowd or it\'s returning empty, Please contact admin';
    public static String INVALID_PRODUCTFAMILY_PARAM = 'Please provide proper Product Family value.';

    //Map keys
    public static String ERRORS = 'errors';
    public static String AGREEMENT_RECORD = 'agreementRecord';
    public static String SINGLE_BI_DISCOUNTS_LIST = 'singleBIDiscountsList';
    public static String SKU_GROUP_DISCOUNTS_LIST = 'skuGroupDiscountsList';
    public static String ACCOUNT_SIDS = 'accountSIDs';
    public static String PRODUCT_FAMILY_LIST = 'productFamilyList';
    public static String BILLABLE_ITEM = 'billableItem';
    public static String TIER = 'tier';
    public static String SKU_GROUP_LIST = 'skuGroupList';
    public static String GEOGRAPHY_LIST = 'geographyList';
    public static String PRODUCT_COMPONENT_LIST = 'productComponentList';
    public static String ORDER_FORM_SKU_GROUP_DISCOUNT = 'orderFormSKUGroupDiscount';
    public static String BILLABLE_ITEM_LIST = 'billableItemList';
    public static String PRODUCT_GROUP_LIST = 'productGroupList';
    public static String PRODUCT_LIST = 'productList';
    public static String REGION_LIST = 'regionList';
    public static String TERRITORY_LIST = 'territoryList';
    public static String BASEURL = 'baseurl';



    public OrderToCashController( ApexPages.StandardController stdCont ) { }
    public OrderToCashController( ) { }

    /* * * * * * * * * * * * *
     *  Method Name:  getOrderDetails
     *  Purpose:      This method returns order details related to agreement id.
     *  Param:        Id
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 24-May-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> getOrderDetails(Id agreementId)
    {
          Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.AGREEMENT_RECORD=>null,OrderToCashController.SINGLE_BI_DISCOUNTS_LIST=>null,OrderToCashController.SKU_GROUP_DISCOUNTS_LIST=>null,OrderToCashController.ERRORS=>''};
        Apttus__APTS_Agreement__c agreementRecord = null;

        try
        {
            String query= 'select Id, Name, Apttus__Account__c, Account_SIDs__c, Minimum_Commitment_Type__c, (select id, name, Agreement__c, Billable_Item__r.Product_Family__c, Billable_Item__r.Price__c,Billable_Item__r.Name, Billable_Item__r.Pricing_Type__c, Tier_Parent__c, Min_Quantity__c, Round_Quantity__c, Percent_Off__c, Flat_Price__c, Tier_Parent__r.name, Trigger__c from Single_BI_Discounts__r where Billable_Item__r.Product_Family__c != null ORDER BY CreatedDate ASC), (select Id, Name, agreement__c, Percent_Off__c, Min_Quantity__c, Round_Quantity__c,SKU_Group__r.Name from Order_Form_SKU_Group_Discounts__r where SKU_Group__c != null AND SKU_Group__r.Status__c = \'STATUS_ACTIVE\' ORDER BY CreatedDate ASC) FROM Apttus__APTS_Agreement__c where Id =:agreementId ORDER BY CreatedDate ASC';
            agreementRecord = Database.query(query);
        }catch(Exception e)
        {
            mapToReturn.put(OrderToCashController.ERRORS, e.getMessage());
            return mapToReturn;
        }

        mapToReturn.put(OrderToCashController.AGREEMENT_RECORD,agreementRecord);
        mapToReturn.put(OrderToCashController.SINGLE_BI_DISCOUNTS_LIST,agreementRecord.Single_BI_Discounts__r);
        mapToReturn.put(OrderToCashController.SKU_GROUP_DISCOUNTS_LIST,agreementRecord.Order_Form_SKU_Group_Discounts__r);
        mapToReturn.put(OrderToCashController.ERRORS,'');
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  isValidInputString
     *  Purpose:      This method validate input string.
     *  Param:        String
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 15-Jun-2016
     *
     * * * * * * * * * * * * */
    public static boolean isValidInputString(String inputString)
    {
        boolean isValid = false;
        if(String.isNotBlank(inputString))
        {
            isValid = true;
        }
        return isValid;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  getAccountSIDs
     *  Purpose:      This method returns accountSIDs on basis of agreement Id and searchQuery.
     *  Param:        Id, String
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 27-May-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> getAccountSIDs(Id agreementId, String searchQuery)
    {
        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.ACCOUNT_SIDS=>null,OrderToCashController.ERRORS=>''};
        if(!OrderToCashController.isValidInputString(searchQuery))
        {
            mapToReturn.put(OrderToCashController.ERRORS, OrderToCashController.EMPTY_SEARCHQUERY);
            return mapToReturn;
        }

        agreementId = String.escapeSingleQuotes(agreementId);
        searchQuery = String.escapeSingleQuotes(searchQuery);
        List<Account_SID__c> accountSIDList = new List<Account_SID__c>();
        String nameVar = '%'+searchQuery+'%';
        try
        {
            List<Apttus__APTS_Agreement__c> agreementList = [select Apttus__Account__c  from Apttus__APTS_Agreement__c where Id =:agreementId];
            List<Id> accIdList = new List<Id>();
            for(Apttus__APTS_Agreement__c aptsAgreement :agreementList){
                if(aptsAgreement.Apttus__Account__c != null){
                    accIdList.add(aptsAgreement.Apttus__Account__c);
                }
            }
            String query = 'select Account_SID__c from Account_SID__c where (Account__c in :accIdList) AND ((Name__c like :nameVar) OR (Name like :nameVar) OR (OwnerUser_Email_Address__c =:searchQuery))';
            accountSIDList = Database.query(query);
        }catch(DmlException de)
        {
            mapToReturn.put(OrderToCashController.ERRORS, de.getMessage());
        }
        mapToReturn.put(OrderToCashController.ACCOUNT_SIDS,accountSIDList);
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  addSIDToOrder
     *  Purpose:      This method add SIDs to Order
     *  Param:        Id, Id
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 27-May-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static void addSIDToOrder(Id agreementId, Id accountSIDId)
    {
        try
        {
            Account_SID__c accountSID = [select Account_SID__c from Account_SID__c where Id =:accountSIDId];
            Apttus__APTS_Agreement__c agreement = [select Account_SIDs__c  from Apttus__APTS_Agreement__c where Id =:agreementId];

            String agreementSIDs = agreement.Account_SIDs__c !=null ? agreement.Account_SIDs__c : '';
            if(!agreementSIDs.contains(accountSID.Account_SID__c)){
                agreementSIDs += ','+accountSID.Account_SID__c;
                agreementSIDs = agreementSIDs.trim();
                agreementSIDs = agreementSIDs.removeStart(',');
                agreement.Account_SIDs__c = agreementSIDs;
            }
            Database.update(agreement);
        }catch(Exception e)
        {
          throw e;
        }
    }

    /* * * * * * * * * * * * *
     *  Method Name:  removeSIDFromOrder
     *  Purpose:      This method removes SIDs from Order
     *  Param:        Id, String
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 27-May-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static void removeSIDFromOrder(Id agreementId, String sidString)
    {
        if(!OrderToCashController.isValidInputString(sidString))
        {
            return;
        }

        try
        {
            Apttus__APTS_Agreement__c agreement = [select Account_SIDs__c  from Apttus__APTS_Agreement__c where Id =:agreementId];
            boolean isRemoved = false;
            String agreementSIDs = agreement.Account_SIDs__c !=null ? agreement.Account_SIDs__c : '';
            sidString = sidString.endsWith(',') ? sidString : sidString+',';
            if(agreementSIDs.contains(sidString)){
                agreementSIDs = agreementSIDs.remove(sidString);
                agreementSIDs = agreementSIDs.trim();
                agreement.Account_SIDs__c = agreementSIDs;
                isRemoved = true;
            }
            //Remove single SID
            sidString = sidString.removeEnd(',');
            if(!isRemoved && agreementSIDs.contains(sidString)){
                agreementSIDs = agreementSIDs.remove(sidString);
                agreementSIDs = agreementSIDs.trim();
                agreement.Account_SIDs__c = agreementSIDs;
            }
            if(agreement.Account_SIDs__c.endsWith(',')){
                agreement.Account_SIDs__c = agreement.Account_SIDs__c.removeEnd(',');
            }
            Database.update(agreement);
        }catch(Exception e)
        {
          throw e;
        }
    }

    /* * * * * * * * * * * * *
     *  Method Name:  getAllProductFamilies
     *  Purpose:      This returns all product families.
     *  Param:        none
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 31-May-2016
     *
     * * * * * * * * * * * * */
     @RemoteAction
    public static Map<String, Object> getAllProductFamilies()
    {
        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.PRODUCT_FAMILY_LIST=>null,OrderToCashController.ERRORS=>''};
        List<AggregateResult> groupedResults = null;
        List<String> productFamilyList = new List<String>();
        try
        {
            String query = 'select Product_Family__c, count(Id) from Billable_Item__c where Product_Family__c != NULL AND Status__c = \'ACTIVE\'  Group By Product_Family__c';
            groupedResults = Database.query(query);
            for (AggregateResult ar : groupedResults)  {
                productFamilyList.add(String.valueOf(ar.get('Product_Family__c')));
            }
        }catch(Exception e)
        {
            mapToReturn.put(OrderToCashController.ERRORS, e.getMessage());
        }
        mapToReturn.put(OrderToCashController.PRODUCT_FAMILY_LIST, productFamilyList);
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  addBillableItemToOrder
     *  Purpose:      Insert a Single BI Discount record for the Agreement
     *  Param:        Id, Id
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 01-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> addBillableItemToOrder(Id agreementId, Id billableItemId)
    {
        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.BILLABLE_ITEM=>null,OrderToCashController.ERRORS=>''};

        try
        {
            Single_BI_Discount__c newSingleBIdiscountObj = new Single_BI_Discount__c();
            newSingleBIdiscountObj.Agreement__c = agreementId;
            newSingleBIdiscountObj.Billable_Item__c = billableItemId;

            Database.insert(newSingleBIdiscountObj);
            Id newDiscountId = newSingleBIdiscountObj.Id;
            String query = 'select id, name, Agreement__c, Agreement__r.Minimum_Commitment_Type__c, Billable_Item__r.Product_Family__c, Billable_Item__r.Price__c,Billable_Item__r.Name, Tier_Parent__c, Min_Quantity__c, Round_Quantity__c,Tier_Parent__r.name from Single_BI_Discount__c where Id = :newDiscountId';
            Single_BI_Discount__c singleBIdiscountObj = Database.query(query);
            mapToReturn.put(OrderToCashController.BILLABLE_ITEM,singleBIdiscountObj);
        }catch(Exception e)
        {
          mapToReturn.put(OrderToCashController.ERRORS, e.getMessage());
          throw e;
        }
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  addTierToBillableItem
     *  Purpose:      Insert a Single BI Discount (child) for the specified Single BI Discount
     *  Param:        Single_BI_Discount__c
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 02-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> addTierToBillableItem(Single_BI_Discount__c singleBIDiscountObj)
    {
        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.TIER=>null,OrderToCashController.ERRORS=>''};
        if( singleBIDiscountObj == null )
        {
            mapToReturn.put(OrderToCashController.ERRORS, OrderToCashController.EMPTY_TIER);
            return mapToReturn;
        }
        try
        {
            if(singleBIDiscountObj.Tier_Parent__c == null)
            {
                mapToReturn.put(OrderToCashController.ERRORS, OrderToCashController.EMPTY_TIER_PARENT);
                return mapToReturn;
            }
            Single_BI_Discount__c parentTier = [select Id, Min_Quantity__c, Round_Quantity__c, Billable_Item__r.Price__c from Single_BI_Discount__c where Id =:singleBIDiscountObj.Tier_Parent__c];
            singleBIDiscountObj.Min_Quantity__c = parentTier.Min_Quantity__c;
            singleBIDiscountObj.Round_Quantity__c = parentTier.Round_Quantity__c;
            Database.insert(singleBIDiscountObj);
            mapToReturn.put(OrderToCashController.TIER, singleBIDiscountObj);
        }catch(Exception e)
        {
          mapToReturn.put(OrderToCashController.ERRORS, e.getMessage());
          throw e;
        }
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  updateOrderBillableItem
     *  Purpose:      Update the record passed in as parameter of Single BI Discount
     *  Param:        Single_BI_Discount__c
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 02-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static void updateOrderBillableItem(Single_BI_Discount__c singleBIDiscountObj)
    {
        if( singleBIDiscountObj != null )
        {
            try
            {
               Database.update(singleBIDiscountObj);
            }catch(Exception e)
            {
              throw e;
            }
        }
    }

    /* * * * * * * * * * * * *
     *  Method Name:  updateBillableItemTier
     *  Purpose:      Update the record passed in as parameter of Single BI Discount of Tier
     *  Param:        Single_BI_Discount__c
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 02-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static void updateBillableItemTier(Single_BI_Discount__c singleBIDiscountObj)
    {
        if( singleBIDiscountObj != null )
        {
            try
            {
               Database.update(singleBIDiscountObj);
            }catch(Exception e)
            {
              throw e;
            }
        }
    }

    /* * * * * * * * * * * * *
     *  Method Name:  deleteBillableItemFromOrder
     *  Purpose:      verify first that the Discount that got passed in belongs to the Agreement. Then, delete all other Single BI Discount records that look up to the one passed in (via Tier_Parent__c), and then the record that got passed in
     *  Param:        Id, List<Id>
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 02-June-2016
     *
     * * * * * * * * * * * * */
     @RemoteAction
     public static void deleteBillableItemFromOrder( Id agreementId, List<Id> singleBIDiscountIdList )
     {
          List<Single_BI_Discount__c> singleBIDiscountToDeleteList = [SELECT Id from Single_BI_Discount__c WHERE Tier_Parent__c IN :singleBIDiscountIdList];
          try
          {
            if( singleBIDiscountToDeleteList != null  && singleBIDiscountToDeleteList.size() > 0 )
            {
               //Delete child of Billable Item
               Database.delete(singleBIDiscountToDeleteList);
            }
             //Delete parent of Billable Item
             deleteTierFromOrder(agreementId, singleBIDiscountIdList);
          }catch(Exception e)
          {
              throw e;
          }
     }

    /* * * * * * * * * * * * *
     *  Method Name:  deleteTierFromOrder
     *  Purpose:      verify that the Discount belongs to the Agreement before deleting it and then delete the related records
     *  Param:        Id, List<Id>
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 02-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static void deleteTierFromOrder( Id agreementId, List<Id> singleBIDiscountIdList )
    {
        List<Single_BI_Discount__c> singleBIDiscountToDeleteList = [SELECT Id from Single_BI_Discount__c WHERE Id IN :singleBIDiscountIdList AND
                                                                      Agreement__c =:agreementId
                                                                     ];
        if( singleBIDiscountToDeleteList != null  && singleBIDiscountToDeleteList.size() > 0 )
        {
           try
           {
              Database.delete(singleBIDiscountToDeleteList);
           }catch(Exception e)
           {
               throw e;
           }
        }
    }

    /* * * * * * * * * * * * *
     *  Method Name:  searchSKUGroupByName
     *  Purpose:      This method search SKU Group by name.
     *  Param:        String
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 03-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> searchSKUGroupByName(Map<String, String> searchParams)
    {

        /* {
            name:"",
            Geography__c:"",
            Product_Component__c:""
           }*/
        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.SKU_GROUP_LIST=>null,OrderToCashController.ERRORS=>''};

        List<SKU_Group__c> skuGroupList = null;
        Map<String, Boolean> fieldNameAndAvailabilityMap = new Map<String, Boolean>();
        Map<String, Schema.SObjectField> fieldNameDescribeMap = Schema.getGlobalDescribe().get('SKU_Group__c').getDescribe().fields.getMap();

        for(String fieldName :searchParams.keySet()){
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
            whereClause += ' AND '+ fieldName + condition +'\''+value+'\'';
          }
        }

        whereClause = whereClause.trim();

        if(whereClause.startsWith('OR')){
          whereClause = whereClause.subString(2,whereClause.length());
        } else if(whereClause.startsWith('AND')){
          whereClause = whereClause.subString(3,whereClause.length());
        }

        whereClause = whereClause.trim();

        try
        {
            String query = 'select Id, Name, Territory__c, Product__c,  (select Id, Percent_Off__c, agreement__c, Min_Quantity__c, Round_Quantity__c from Pricing_Model_SKU_Groups__r) from SKU_Group__c where Status__c = \'STATUS_ACTIVE\'';
            if(String.isNotBlank(whereClause)){
              query += ' AND '+whereClause;
            }
            skuGroupList = Database.query(query);

            Set<String> geographySet =  new Set<String>();
            Set<String> productComponentSet =  new Set<String>();
            for(SKU_Group__c skuGroup :skuGroupList){
                geographySet.add(skuGroup.Territory__c);
                productComponentSet.add(skuGroup.Product__c);
            }
            List<String> geographyList =  new List<String>(geographySet);
            List<String> productComponentList =  new List<String>(productComponentSet);
            geographyList.sort();
            productComponentList.sort();
            mapToReturn.put(OrderToCashController.SKU_GROUP_LIST, skuGroupList);
            mapToReturn.put(OrderToCashController.GEOGRAPHY_LIST,geographyList);
            mapToReturn.put(OrderToCashController.PRODUCT_COMPONENT_LIST,productComponentList);
        }catch(Exception e)
        {
          mapToReturn.put(OrderToCashController.ERRORS, e.getMessage());
          throw e;
        }
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  addSKUGroupToOrder
     *  Purpose:      This method Add SKU Group to Order.
     *  Param:        Id, Id
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 03-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> addSKUGroupToOrder(Id agreementId, Id skuGroupId)
    {
        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.ORDER_FORM_SKU_GROUP_DISCOUNT=>null,OrderToCashController.ERRORS=>''};

        Order_Form_SKU_Group_Discount__c orderFromSKUGrpDiscount = null;
        try
        {
            orderFromSKUGrpDiscount = new Order_Form_SKU_Group_Discount__c();
            orderFromSKUGrpDiscount.agreement__c = agreementId;
            orderFromSKUGrpDiscount.SKU_Group__c = skuGroupId;
            Database.insert(orderFromSKUGrpDiscount);

            orderFromSKUGrpDiscount = [select Id, Name, agreement__c, SKU_Group__c, Percent_Off__c, Min_Quantity__c, Round_Quantity__c,SKU_Group__r.Name from Order_Form_SKU_Group_Discount__c where Id =: orderFromSKUGrpDiscount.Id ];

        }catch(Exception e)
        {
          mapToReturn.put(OrderToCashController.ERRORS, e.getMessage());
          throw e;
        }
        mapToReturn.put(OrderToCashController.ORDER_FORM_SKU_GROUP_DISCOUNT, orderFromSKUGrpDiscount);
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  updateSKUGroupFromOrder
     *  Purpose:      This method Update SKU Group from Order.
     *  Param:        Order_Form_SKU_Group_Discount__c
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 03-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static void updateSKUGroupFromOrder(Order_Form_SKU_Group_Discount__c orderFromSKUGrpDiscount)
    {
        try
        {
            if(orderFromSKUGrpDiscount != null){
                Database.update(orderFromSKUGrpDiscount);
            }
        }catch(Exception e)
        {
          throw e;
        }
    }

    /* * * * * * * * * * * * *
     *  Method Name:  deleteSKUGroupFromOrder
     *  Purpose:      This method delete SKU Group from Order.
     *  Param:        Id, List<Id>
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 03-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static void deleteSKUGroupFromOrder(Id agreementId, List<Id> orderFormSKUGroupDiscountIdList)
    {

        List<Order_Form_SKU_Group_Discount__c> orderFromSKUGrpDiscountList = null;
        try
        {
            String query = 'select Id from Order_Form_SKU_Group_Discount__c where Id IN :orderFormSKUGroupDiscountIdList AND agreement__c =:agreementId';
            orderFromSKUGrpDiscountList = Database.query(query);
            Database.delete(orderFromSKUGrpDiscountList);
        }catch(Exception e)
        {
          throw e;
        }
    }

    /* * * * * * * * * * * * *
     *  Method Name:  searchBillableItems
     *  Purpose:      This method search billable items.
     *  Param:        String, String
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 06-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> searchBillableItems(Map<String, String> searchParams)
    {
      /* {
          agreementId:"",
          name:"",
          Product_Group__c:"",
          Product__c:"",
          Region__c:"",
          Territory__c:""
        }*/
        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.BILLABLE_ITEM_LIST=>null,'errors'=>''};
        if(searchParams.get('agreementId') == null || !OrderToCashController.isValidInputString(searchParams.get('agreementId')))
        {
            mapToReturn.put('errors', OrderToCashController.NO_AGREEMENTRECORD);
            return mapToReturn;
        }

        String productFamily = searchParams.get('Product_Family__c');
        productFamily = productFamily.replace( '&amp;', '&' );
        /*
         * Select Single_BI_Discount__c to exclude exsiting Discount.
         */
        List<Single_BI_Discount__c> existingDiscount = [ SELECT Id, Billable_Item__c FROM Single_BI_Discount__c WHERE Agreement__c = :searchParams.get('agreementId') AND Billable_Item__c != null];
        List<Id> existingBillableItemIdList = new List<Id>();

        for(Single_BI_Discount__c singleBiDisc :existingDiscount){
          existingBillableItemIdList.add(singleBiDisc.Billable_Item__c);
        }

        Map<String, Boolean> fieldNameAndAvailabilityMap = new Map<String, Boolean>();
        Map<String, Schema.SObjectField> fieldNameDescribeMap = Schema.getGlobalDescribe().get('Billable_Item__c').getDescribe().fields.getMap();

        for(String fieldName :searchParams.keySet()){

          if(fieldName.equals('agreementId') || fieldName.equals('Product_Family__c')){
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
            whereClause += ' AND '+ fieldName + condition +'\''+value+'\'';
          }
        }

        whereClause = whereClause.trim();

        if(whereClause.startsWith('OR')){
          whereClause = whereClause.subString(2,whereClause.length());
        } else if(whereClause.startsWith('AND')){
          whereClause = whereClause.subString(3,whereClause.length());
        }

        whereClause = whereClause.trim();

        List<Billable_Item__c> billableItemList = null;
        try
        {
            String query = 'select Id, Name, Product_Group__c, Product__c, Region__c, Territory__c from Billable_Item__c where Status__c = \'ACTIVE\' AND ';
            if(String.isNotBlank(whereClause)){
              query += '('+whereClause+') AND ';
            }
            if(OrderToCashController.isValidInputString(productFamily)){
              query += 'Product_Family__c =:productFamily AND ';
            }
            query += 'Id NOT IN :existingBillableItemIdList';
            query = query.replace( '&amp;', '&' );
            System.debug('query :'+query);
            billableItemList = Database.query(query);
            Set<String> productGroupSet =  new Set<String>();
            Set<String> productSet =  new Set<String>();
            Set<String> regionSet =  new Set<String>();
            Set<String> territorySet =  new Set<String>();
            for(Billable_Item__c billableItem :billableItemList){
                productGroupSet.add(billableItem.Product_Group__c);
                productSet.add(billableItem.Product__c);
                regionSet.add(billableItem.Region__c);
                territorySet.add(billableItem.Territory__c);
            }
            List<String> productGroupList =  new List<String>(productGroupSet);
            List<String> productList =  new List<String>(productSet);
            List<String> regionList =  new List<String>(regionSet);
            List<String> territoryList =  new List<String>(territorySet);
            productGroupList.sort();
            productList.sort();
            regionList.sort();
            territoryList.sort();
            mapToReturn.put(OrderToCashController.BILLABLE_ITEM_LIST,billableItemList);
            mapToReturn.put(OrderToCashController.PRODUCT_GROUP_LIST,productGroupList);
            mapToReturn.put(OrderToCashController.PRODUCT_LIST,productList);
            mapToReturn.put(OrderToCashController.REGION_LIST,regionList);
            mapToReturn.put(OrderToCashController.TERRITORY_LIST,territoryList);
        }catch(Exception e)
        {
          mapToReturn.put(OrderToCashController.ERRORS , e.getMessage());
          throw e;
        }
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  getBillableItemFilterCriteria
     *  Purpose:      This method search billable items.
     *  Param:        none
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 16-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> getBillableItemFilterCriteria(String productFamilyName)
    {
        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.PRODUCT_GROUP_LIST=>null,OrderToCashController.PRODUCT_LIST=>null,OrderToCashController.REGION_LIST=>null,OrderToCashController.TERRITORY_LIST =>null,OrderToCashController.ERRORS =>''};

        List<String> fieldList = new List<String>{'Region__c','Territory__c'};
        Map<String, List<Schema.PicklistEntry>> fieldNameAndPickListMap = null;
        Map<String,List<String>> productFamilyAndProductDetailsMap = null;
        try{
            productFamilyAndProductDetailsMap = OrderToCashController.getProductFamilityMapping(productFamilyName);
            fieldNameAndPickListMap = OrderToCashController.getPickListValues('Billable_Item__c', fieldList);
        }catch(Exception e){
            mapToReturn.put(OrderToCashController.ERRORS, e.getMessage());
        }

        if(productFamilyAndProductDetailsMap != null){
            mapToReturn.put(OrderToCashController.PRODUCT_GROUP_LIST, productFamilyAndProductDetailsMap.get(PRODUCT_GROUP_LIST));
            mapToReturn.put(OrderToCashController.PRODUCT_LIST, productFamilyAndProductDetailsMap.get(PRODUCT_LIST));
        }
        for(String fieldName :fieldNameAndPickListMap.keySet()){

            List<String> pickListValueList = new List<String>();
            for(Schema.PicklistEntry pickListEntryObj :fieldNameAndPickListMap.get(fieldName)){
                pickListValueList.add(pickListEntryObj.getValue());
            }
            if(fieldName.equalsIgnoreCase('Region__c')){
                mapToReturn.put(OrderToCashController.REGION_LIST, pickListValueList);
            }
            if(fieldName.equalsIgnoreCase('Territory__c')){
                mapToReturn.put(OrderToCashController.TERRITORY_LIST, pickListValueList);
            }
        }
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  getSKUGroupFilterCriteria
     *  Purpose:      This method search billable items.
     *  Param:        none
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 16-June-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> getSKUGroupFilterCriteria()
    {
        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.GEOGRAPHY_LIST=>null,OrderToCashController.PRODUCT_COMPONENT_LIST=>null,OrderToCashController.ERRORS=>''};
        List<String> fieldList = new List<String>{'Territory__c','Product__c'};
        Map<String, List<Schema.PicklistEntry>> fieldNameAndPickListMap = null;

        try{
            fieldNameAndPickListMap = OrderToCashController.getPickListValues('SKU_Group__c', fieldList);
        }catch(Exception e){
            mapToReturn.put(OrderToCashController.ERRORS, e.getMessage());
        }
        if(fieldNameAndPickListMap == null){
            return mapToReturn;
        }

        for(String fieldName :fieldNameAndPickListMap.keySet()){

            List<String> pickListValueList = new List<String>();
            for(Schema.PicklistEntry pickListEntryObj :fieldNameAndPickListMap.get(fieldName)){
                pickListValueList.add(pickListEntryObj.getValue());
            }
            if(fieldName.equalsIgnoreCase('Territory__c')){
                mapToReturn.put(OrderToCashController.GEOGRAPHY_LIST, pickListValueList);
            }
            if(fieldName.equalsIgnoreCase('Product__c')){
                mapToReturn.put(OrderToCashController.PRODUCT_COMPONENT_LIST, pickListValueList);
            }
        }
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  getPickListValues
     *  Purpose:      This method search billable items.
     *  Param:        String, List<String>
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 16-June-2016
     *
     * * * * * * * * * * * * */
    private static Map<String, List<Schema.PicklistEntry>> getPickListValues(String objectName, List<String> fieldNameList) {

        Map<String, List<Schema.PicklistEntry>> fieldNameAndPickListMap = new Map<String, List<Schema.PicklistEntry>>();
        Map<String, Schema.SObjectType> objectDescribeMap = Schema.getGlobalDescribe();

        if(objectDescribeMap == null){
            throw new ApplicationException(OrderToCashController.EMPTY_GLOBAL_DESCRIBE);
        }
        Schema.SObjectType sobjectType = objectDescribeMap.get(objectName);
        if(sobjectType == null){
            throw new ApplicationException(OrderToCashController.NO_SCHEMA_FOR_OBJECT);
        }
        Schema.DescribeSObjectResult sobjectDescribeResult = sobjectType.getDescribe();
        if(sobjectDescribeResult == null){
            throw new ApplicationException(OrderToCashController.EMPTY_OBJECT_DESCRIBE);
        }
        Map<String, Schema.SObjectField> fieldNameDescribeMap = sobjectDescribeResult.fields.getMap();
        if(fieldNameDescribeMap == null){
            throw new ApplicationException(OrderToCashController.NO_SCHEMA_FOR_FIELDS);
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
                throw new ApplicationException(OrderToCashController.EMPTY_FIELD_DESCRIBE);
            }
            if(fieldDescribeResult.getType() == Schema.DisplayType.PICKLIST){
                List<Schema.PicklistEntry> pickListEntry = fieldDescribeResult.getPicklistValues();
                fieldNameAndPickListMap.put(fieldName, pickListEntry);
            }
        }
        return fieldNameAndPickListMap;
    }

    @RemoteAction
    public static Map<String, Object> sendOrderToDealDesk(Id agreementId){

        Map<String, Object> mapToReturn = new Map<String, Object>{OrderToCashController.BASEURL=>null,OrderToCashController.ERRORS=>''};
        String salesforceBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        salesforceBaseURL += '/'+ agreementId;
        mapToReturn.put(OrderToCashController.BASEURL, salesforceBaseURL);
        return mapToReturn;
    }


    /* * * * * * * * * * * * *
     *  Method Name:  getProductFamilityMapping
     *  Purpose:      This method is used to return the map of product and product group which mathces the product family
     *  Param:        String
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 22-June-2016
     *
     * * * * * * * * * * * * */
    private static Map<String,List<String>> getProductFamilityMapping(String productFamily){

        Set<String> productSet = new Set<String>();
        Set<String> productGroupSet = new Set<String>();
        Map<String,List<String>> productFamilyAndProductDetailsMap = new Map<String,List<String>>{OrderToCashController.PRODUCT_GROUP_LIST => null,OrderToCashController.PRODUCT_LIST => null};

        if( !isValidInputString(productFamily) )
        {
            return productFamilyAndProductDetailsMap;
        }

        //fetch all related product details
        List<product_family_mapping__c> productFamilyAndProductDetailsMappingList = product_family_mapping__c.getAll().values();
        if( productFamilyAndProductDetailsMappingList != null && productFamilyAndProductDetailsMappingList.size() > 0)
        {
            for(product_family_mapping__c productFamilyRec : productFamilyAndProductDetailsMappingList)
            {
                if(String.isNotBlank(productFamilyRec.Product_Family__c) && productFamily.equalsIgnoreCase(productFamilyRec.Product_Family__c))
                {
                    if(String.isNotBlank(productFamilyRec.Product__c))
                    {
                        productSet.add(productFamilyRec.Product__c);
                    }

                    if(String.isNotBlank(productFamilyRec.Product_Group__c))
                    {
                        productGroupSet.add(productFamilyRec.Product_Group__c);
                    }
                }
            }
            List<String> productGroupList = new List<String>(productGroupSet);
            List<String> productList = new List<String>(productSet);
            productGroupList.sort();
            productList.sort();
            productFamilyAndProductDetailsMap.put(OrderToCashController.PRODUCT_GROUP_LIST, productGroupList);
            productFamilyAndProductDetailsMap.put(OrderToCashController.PRODUCT_LIST, productList);
        }
        return productFamilyAndProductDetailsMap;
    }

    /* * * * * * * * * * * * *
     *  Class Name:   ApplicationException
     *  Purpose:      This is custom exception.
     *  Author:       Purushottam Bhaigade
     *  Company:      GoNimbly
     *  Created Date: 20-Jun-2016
     *
     * * * * * * * * * * * * */
    public class ApplicationException extends Exception{

    }
}