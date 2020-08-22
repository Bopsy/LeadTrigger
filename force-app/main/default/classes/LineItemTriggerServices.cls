public without sharing class LineItemTriggerServices {
    
    public static Map<String, Apttus_DealMgr__DealGuidanceRuleEntry__c> productDealGuidanceMap{
        get{
            if(productDealGuidanceMap == null){
                productDealGuidanceMap = new Map<String, Apttus_DealMgr__DealGuidanceRuleEntry__c>();
                List<Apttus_DealMgr__DealGuidanceRule__c> rules = [SELECT Apttus_DealMgr__ProductScope__c, 
                                                                   (SELECT Apttus_DealMgr__Band1Value__c, Apttus_DealMgr__Band2Value__c, Apttus_DealMgr__Band3Value__c, Apttus_DealMgr__Dimension1Value__c,
                                                                    Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__Measure__c, Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__CustomMeasureSource__c, 
                                                                     Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__CustomMeasureBandDirection__c 
                                                                    FROM Apttus_DealMgr__GuidanceRuleEntries__r
                                                                    ORDER BY Apttus_DealMgr__Sequence__c)
                                                                   FROM Apttus_DealMgr__DealGuidanceRule__c
                                                                   ORDER BY Apttus_DealMgr__Sequence__c
                                                                  ];
                for(Apttus_DealMgr__DealGuidanceRule__c rule: rules){
                    List<String> productIds = rule.Apttus_DealMgr__ProductScope__c.split(';');
                    for(String productId: productIds){
                        if(productId != 'All' && !productDealGuidanceMap.containsKey(productId)){
                            for(Apttus_DealMgr__DealGuidanceRuleEntry__c entry: rule.Apttus_DealMgr__GuidanceRuleEntries__r){
                                String keyString = productId + '-' + entry.Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__Measure__c + '-' + entry.Apttus_DealMgr__Dimension1Value__c;
                                if(entry.Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__Measure__c=='Custom'){
                                    keyString = productId + '-' + entry.Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__CustomMeasureSource__c + '-' + entry.Apttus_DealMgr__Dimension1Value__c;
                                }
                                productDealGuidanceMap.put(keyString, entry);
                            }
                        }
                    }
                }
            }
            return productDealGuidanceMap;
        }
        set;
    }
    
    public static void workflowsIntoCode(List<Apttus_Config2__LineItem__c> lineItems){
        for(Apttus_Config2__LineItem__c lineItem: lineItems){
            //WF - Clear Sub Minute Billing Fields when Not Applicable
            if((lineItem.Billing_Minute__c!=null || lineItem.Billing_Increment__c!=null) && lineItem.Capable_of_Sub_Minute_Billing__c==false){
                lineItem.Billing_Minute__c=null;
                lineItem.Billing_Increment__c=null;
            }
            //WF - Push list percent of spend on support products. Created formula field Percent_of_spend_on_support_products__c which calculates the value 
            if(lineItem.Percent_of_Spend__c==null && lineItem.Apttus_Config2__ChargeType__c=='Subscription Fee'){
                lineItem.Percent_of_Spend__c = lineItem.Percent_of_spend_on_support_products__c;
            }
            //WF - Update Is Support Product
            if(lineItem.Apttus_Config2__ClassificationHierarchy__c!=null && lineItem.Apttus_Config2__ClassificationHierarchy__c.containsignorecase(system.label.Category_Hierarchy_Info) &&
               lineitem.Product_Name_OF_Generate__c!=null && lineitem.Product_Name_OF_Generate__c.containsignorecase('Support')){
                lineitem.IsSupportProduct__c = true;   
            }
            //WF - Stamp List Price at Line Item Creation. Created formula field List_Price_Stamp_Formula__c which calculates the value 
            if(lineItem.List_Price_Stamp_Formula__c!=null){
                lineItem.List_Price_Stamp__c = lineitem.List_Price_Stamp_Formula__c;
            }
            if(lineItem.Product_Family__c != null){
                lineItem.Is_SendGrid_Product__c = lineItem.Product_Family__c.equalsignorecase('Sendgrid');
            }
            else{
                lineItem.Is_SendGrid_Product__c = false;
            }
        }
    }
    
    public static void populateAttributeValue(List<Apttus_Config2__LineItem__c> lineItems){
        Map<Id, String> biSidMap = new Map<Id, String>();
        for(Apttus_Config2__LineItem__c item: lineItems){
            if(item.Apttus_Config2__AssetLineItemId__c != null){
                biSidMap.put(item.Id, item.BI_SID__c);
            }
        }
        if(biSidMap.isEmpty()) return;
        
        Map<String, Boolean> multipleEntries = new Map<String, Boolean>();
        for(Apttus_Config2__PriceListItem__c priceList: [SELECT BI_SID__c FROM Apttus_Config2__PriceListItem__c WHERE BI_SID__c =: biSidMap.values()]){
            if(multipleEntries.containsKey(priceList.BI_SID__c)){multipleEntries.put(priceList.BI_SID__c, true);}
            else{multipleEntries.put(priceList.BI_SID__c, false);}
        }
        List<Apttus_Config2__ProductAttributeValue__c> newPAVs = new List<Apttus_Config2__ProductAttributeValue__c>();
        for(Id lineItemId: biSidMap.keySet()){
            String biSid = biSidMap.get(lineItemId);
            if(multipleEntries.get(biSid) != null && multipleEntries.get(biSid)){
                newPAVs.add(new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c = lineItemId, Charge_Type__c = 'Standard'));
            }
        }
        insert newPAVs;
        List<Apttus_Config2__LineItem__c> updateLineItems = new List<Apttus_Config2__LineItem__c>();
        for(Apttus_Config2__ProductAttributeValue__c pav: newPAVs){updateLineItems.add(new Apttus_Config2__LineItem__c(Id = pav.Apttus_Config2__LineItemId__c,Apttus_Config2__AttributeValueId__c = pav.Id));}
        update updateLineItems.deepClone(true, true);
        
    }
     //Apttus deletes and inserts remaining line items, so handling on delete
    public static void afterDelete(List<Apttus_Config2__LineItem__c> lineItems){
        Set<Id> setConfigIds = new Set<Id>();
        Set<String> setProductNames = new Set<String>();
        for(Apttus_Config2__LineItem__c lineItem: lineItems){
            if(lineItem.Product_Family__c!=null && lineItem.Product_Family__c.equalsignorecase('Sendgrid') && lineItem.SG_Product_Type__c!=null && lineItem.SG_Product_Type__c.equalsignorecase('Email')){
                setConfigIds.add(lineItem.Apttus_Config2__ConfigurationId__c );
                setProductNames.add(lineItem.Product_Name_OF_Generate__c);
            }
        }
        if(setConfigIds!=null && setConfigIds.size()>0){
            calculateTotalSGDiscount(setConfigIds,setProductNames);
        }
    }
    
    //Apttus updates first line item, so handling on update
    public static void afterUpdate(List<Apttus_Config2__LineItem__c> lineItems, Map<Id,Apttus_Config2__LineItem__c> oldMap){
        Set<Id> setConfigIds = new Set<Id>();
        Set<String> setProductNames = new Set<String>();
        for(Apttus_Config2__LineItem__c lineItem: lineItems){
            Apttus_Config2__LineItem__c oldLineItem = oldMap.get(lineItem.Id);
            if(lineItem.Product_Family__c!=null && lineItem.Product_Family__c.equalsignorecase('Sendgrid') && lineItem.SG_Product_Type__c!=null && lineItem.SG_Product_Type__c.equalsignorecase('Email')){
                if(oldLineItem.Total_Discount__c!=lineItem.Total_Discount__c){
                    setConfigIds.add(lineItem.Apttus_Config2__ConfigurationId__c );
                    setProductNames.add(lineItem.Product_Name_OF_Generate__c);
                }
            }
        }
        if(setConfigIds!=null && setConfigIds.size()>0){
            calculateTotalSGDiscount(setConfigIds,setProductNames);
        }
    }
    
    public static void beforeInsert(List<Apttus_Config2__LineItem__c> lineItems){
        List<Apttus_Config2__LineItem__c> filteredItems = new List<Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__LineItem__c> flexItems = new List<Apttus_Config2__LineItem__c>();
        for(Apttus_Config2__LineItem__c lineItem: lineItems){
            if(lineItem.Is_Bundle_Product__c && lineItem.Apttus_Config2__AdjustmentType__c==null){
                lineItem.Bucket_Floor_Price__c = lineItem.Apttus_Config2__NetUnitPrice__c;
            }
            if(lineItem.Apttus_Config2__Description__c == 'Voice CPS Capacity'){
                lineItem.Apttus_Config2__Guidance__c = 'Green';
                lineItem.Apttus_Config2__PricingGuidance__c = '{"HidePrice" :false, "HidePercentile": false, "Entries" : [ {"Sequence" : 1,"Rating" : "Green","RangeName":"Approved","PriceTo" : 135.00,"PriceFrom" : 150.00000,"PercentileTo" : 10,"PercentileFrom" : 0,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#387C35"}, {"Sequence" : 2,"Rating" : "Yellow","RangeName" : "Manager","PriceTo" : 120.00,"PriceFrom" : 135.00,"PercentileTo" : 20,"PercentileFrom" : 10,"MeasureType" : "LowHigh","IsItemRating" : true,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps": [ ],"ColorCode" : "#FFE512"}, {"Sequence" : 3,"Rating" : "Orange","RangeName" : "2nd Tier Manager","PriceTo" : 75.00,"PriceFrom" : 120.00,"PercentileTo" : 50,"PercentileFrom" : 20,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#E36F1E"}, {"Sequence" : 4,"Rating" : "Red","RangeName" : "Deal Desk","PriceTo" : 0.00,"PriceFrom" : 75.00,"PercentileTo" : 100,"PercentileFrom" : 50,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#B2102C"} ],"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ]}';
                
            }
            else if((lineItem.Apttus_Config2__NetUnitPrice__c != null || lineItem.Percent_of_Spend__c != null) && !lineItem.Is_Bucket_Option__c && (!lineItem.Is_Bundle_Product__c || (lineItem.Is_Bundle_Product__c && lineItem.BI_SID__c!=null && lineItem.BI_SID__c.containsIgnoreCase('Bucket')))){
                filteredItems.add(lineItem);
            }
            if(lineItem.Apttus_Config2__OptionGroupLabel__c != null && lineItem.Apttus_Config2__OptionGroupLabel__c.containsignorecase('Flex') && lineItem.BI_SID__c != null){
                flexItems.add(lineItem);
                filteredItems.add(lineItem);
            }
        }
        if(flexItems.size()>0){
        	generateFlexMaxQuantity(flexItems);
        }
        if(filteredItems.size()>0){
        	generateDealGuidanceStatus(filteredItems, false);
        }
    }
    
    public static void beforeUpdate(List<Apttus_Config2__LineItem__c> lineItems, Map<Id,Apttus_Config2__LineItem__c> oldMap){
        List<Apttus_Config2__LineItem__c> filteredItems = new List<Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__LineItem__c> flexItems = new List<Apttus_Config2__LineItem__c>();
        
        Map<String,integer> colorMap = new Map<String,integer>();
        colorMap.put('Green',1);
        colorMap.put('Yellow',2);
        colorMap.put('Orange',3);
        colorMap.put('Red',4);
        
        for(Apttus_Config2__LineItem__c lineItem: lineItems){
            if(lineItem.Apttus_Config2__Description__c == 'Voice CPS Capacity'){
                lineItem.Apttus_Config2__Guidance__c = lineItem.Tier_Changed_Number__c == 1 ? 'Red' : 'Green';
                lineItem.Apttus_Config2__PricingGuidance__c = '{"HidePrice" :false, "HidePercentile": false, "Entries" : [ {"Sequence" : 1,"Rating" : "Green","RangeName":"Approved","PriceTo" : 135.00,"PriceFrom" : 150.00000,"PercentileTo" : 10,"PercentileFrom" : 0,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#387C35"}, {"Sequence" : 2,"Rating" : "Yellow","RangeName" : "Manager","PriceTo" : 120.00,"PriceFrom" : 135.00,"PercentileTo" : 20,"PercentileFrom" : 10,"MeasureType" : "LowHigh","IsItemRating" : true,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps": [ ],"ColorCode" : "#FFE512"}, {"Sequence" : 3,"Rating" : "Orange","RangeName" : "2nd Tier Manager","PriceTo" : 75.00,"PriceFrom" : 120.00,"PercentileTo" : 50,"PercentileFrom" : 20,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#E36F1E"}, {"Sequence" : 4,"Rating" : "Red","RangeName" : "Deal Desk","PriceTo" : 0.00,"PriceFrom" : 75.00,"PercentileTo" : 100,"PercentileFrom" : 50,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#B2102C"} ],"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ]}';
            }
            if(lineItem.Is_Bundle_Product__c && lineItem.Apttus_Config2__AdjustmentType__c==null){
                lineItem.Bucket_Floor_Price__c = lineItem.Apttus_Config2__NetUnitPrice__c;
            }
            Apttus_Config2__LineItem__c oldLineItem = oldMap.get(lineItem.Id);
            if(((oldLineItem.Apttus_Config2__NetUnitPrice__c != lineItem.Apttus_Config2__NetUnitPrice__c && lineItem.Apttus_Config2__NetUnitPrice__c != null) || 
                (oldLineItem.Percent_of_Spend__c != lineItem.Percent_of_Spend__c && lineItem.Percent_of_Spend__c != null) ||
                (oldLineItem.Total_SG_Email_Discount__c!= lineItem.Total_SG_Email_Discount__c && lineItem.Total_SG_Email_Discount__c!=null) ||
                (oldLineItem.Apttus_Config2__AdjustmentType__c != lineItem.Apttus_Config2__AdjustmentType__c)  ||
                (oldLineItem.Billing_Increment__c != lineItem.Billing_Increment__c) ||
                (oldLineItem.Billing_Minute__c != lineItem.Billing_Minute__c) || (oldLineItem.Apttus_Config2__Guidance__c!= lineItem.Apttus_Config2__Guidance__c) ||
                (oldLineItem.Deal_Guidance_Level_Formula__c != lineItem.Deal_Guidance_Level_Formula__c && lineItem.Deal_Guidance_Level_Formula__c != null)) && !lineItem.Is_Bucket_Option__c && lineItem.Apttus_Config2__Description__c != 'Voice CPS Capacity'){
                    filteredItems.add(lineItem);
                }
            if(lineItem.Is_Bundle_Product__c && !filteredItems.contains(lineItem)){
                filteredItems.add(lineItem);
            }
            if(lineItem.Apttus_Config2__OptionGroupLabel__c != null && lineItem.Apttus_Config2__OptionGroupLabel__c.containsIgnoreCase('Flex') && lineItem.BI_SID__c != null){
                flexItems.add(lineItem);
                filteredItems.add(lineItem);
            }
        }
        if(flexItems.size()>0){
        	generateFlexMaxQuantity(flexItems);
        }
        if(filteredItems.size()>0){
        	generateDealGuidanceStatus(filteredItems, false);
        }
        
        for(Apttus_Config2__LineItem__c lineItem: lineItems){
            
            /***************************************************
            Added by Apttus Support
            Case: CAS-09701-F2Y8Y7
            Date: 15-03-2019
            Desc: To stop approval process to be fired based on the condition on TCR/Net unit price/color
            ****************************************************/
            if(colorMap.containskey(lineitem.APTS_Approved_Guidance__c) && colorMap.containskey(lineitem.Apttus_Config2__Guidance__c) && colorMap.get(lineitem.Apttus_Config2__Guidance__c) > colorMap.get(lineitem.APTS_Approved_Guidance__c))
                lineitem.APTS_line_item_approval_required__c = true;
            else
                lineitem.APTS_line_item_approval_required__c = false;
            
            if(!lineitem.APTS_line_item_approval_required__c && lineitem.Apttus_Config2__NetUnitPrice__c < lineitem.APTS_Approved_Net_Unit_Price__c)
                lineitem.APTS_line_item_approval_required__c = true;
            
            
            //For new line item 
            if(lineitem.APTS_Approved_Guidance__c==null || lineitem.APTS_Approved_Guidance__c==''){
                if(lineitem.Apttus_Config2__Guidance__c!=null && colorMap.get(lineitem.Apttus_Config2__Guidance__c)>1)
                    lineitem.APTS_line_item_approval_required__c = true;
                else
                    lineitem.APTS_line_item_approval_required__c = false;
            }
        }
    }
    
    public static void generateFlexMaxQuantity(List<Apttus_Config2__LineItem__c> flexLineItems){
        Map<String, List<Apttus_Config2__LineItem__c>> itemMaps = new Map<String, List<Apttus_Config2__LineItem__c>>();
        
        for(Apttus_Config2__LineItem__c item: flexLineItems){
            List<Apttus_Config2__LineItem__c> items = itemMaps.get(item.BI_SID__c);
            if(items == null) items = new List<Apttus_Config2__LineItem__c>();
            items.add(item);
            itemMaps.put(item.BI_SID__c, items);
        }
        
        for(String itemStr: itemMaps.keySet()){
            List<Apttus_Config2__LineItem__c> items = itemMaps.get(itemStr);
            Decimal maxQuantity = -1;
            for(Apttus_Config2__LineItem__c item: items){
                if(item.Apttus_Config2__Quantity__c > maxQuantity) maxQuantity = item.Apttus_Config2__Quantity__c;
            }
            
            if(maxQuantity != -1){
                for(Apttus_Config2__LineItem__c item: items){
                    item.Max_Flex_Quantity__c = maxQuantity;
                }
            }
        }
    }
    
     public static void calculateTotalSGDiscount(Set<Id> setConfigIds,Set<String> setProductNames){
        List<Apttus_Config2__LineItem__c> lstSGEmailItems = [Select Id,Apttus_Config2__ConfigurationId__c,Product_Family__c,SG_Product_Type__c,Total_Discount__c,Total_SG_Email_Discount__c, 
                                                             Product_Name_OF_Generate__c, Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c , Initial_Term__c from
                                                             Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c IN:setConfigIds and Product_Name_OF_Generate__c IN:setProductNames and Product_Family__c='SendGrid' and SG_Product_Type__c='Email' order by Apttus_Config2__StartDate__c];
        
        Map<String,List<Apttus_Config2__LineItem__c>> mapOfProductNameLineItems = new Map<String,List<Apttus_Config2__LineItem__c>>();
        Map<String,Decimal> mapOfProductNameTotalDiscount = new Map<String,Decimal>();
        for(Apttus_Config2__LineItem__c objLineItem: lstSGEmailItems){
            if(!mapOfProductNameLineItems.containsKey(objLineItem.Apttus_Config2__ConfigurationId__c + objLineItem.Product_Name_OF_Generate__c)){
                mapOfProductNameLineItems.put(objLineItem.Apttus_Config2__ConfigurationId__c + objLineItem.Product_Name_OF_Generate__c,new List<Apttus_Config2__LineItem__c>{objLineItem});
            }else{
                mapOfProductNameLineItems.get(objLineItem.Apttus_Config2__ConfigurationId__c + objLineItem.Product_Name_OF_Generate__c).add(objLineItem);
            }
        }
        
        for(String objkey: mapOfProductNameLineItems.keyset()){
            Integer remainingMonths = Integer.valueof(mapOfProductNameLineItems.get(objKey).get(0).Initial_Term__c);
            Decimal totalSum =0;
            Integer count=0;
            for(Apttus_Config2__LineItem__c objLineItem: mapOfProductNameLineItems.get(objKey)){
                count++;
                if(count == mapOfProductNameLineItems.get(objKey).size()){
                    totalSum += objLineItem.Total_Discount__c == null ? 0 : (objLineItem.Total_Discount__c*remainingMonths);
                }else{
                    totalSum += objLineItem.Total_Discount__c == null ? 0: objLineItem.Total_Discount__c;
                    Date a = objLineItem.Apttus_Config2__StartDate__c;
                    Date b = objLineItem.Apttus_Config2__EndDate__c;
                    Integer monthDiff = a == null ? -1 : a.monthsBetween(b);
                    if (b.day() > a.day()) monthDiff++;
                    remainingMonths -= monthDiff;
                }
            }
            mapOfProductNameTotalDiscount.put(objkey,totalSum/Integer.valueof(mapOfProductNameLineItems.get(objKey).get(0).Initial_Term__c));
        }
        for(Apttus_Config2__LineItem__c objLineItem: lstSGEmailItems){
            system.debug('+++mapOfProductNameTotalDiscount '+mapOfProductNameTotalDiscount.get(objLineItem.Apttus_Config2__ConfigurationId__c + objLineItem.Product_Name_OF_Generate__c));
            if(mapOfProductNameTotalDiscount.get(objLineItem.Apttus_Config2__ConfigurationId__c + objLineItem.Product_Name_OF_Generate__c) >=0){
            	objLineItem.Total_SG_Email_Discount__c = mapOfProductNameTotalDiscount.get(objLineItem.Apttus_Config2__ConfigurationId__c + objLineItem.Product_Name_OF_Generate__c);
            }
        }
        if(lstSGEmailItems!=null){
        	update lstSGEmailItems;
        }
    }
    
    public static Map<String, Decimal> getRuleEntry(Set<Id> flexProductIds){
        Map<String, Decimal> mapProductIdWithRuleEntry = new Map<String, Decimal>();
        List<Apttus_DealMgr__DealGuidanceRule__c> rules = [SELECT Apttus_DealMgr__ProductScope__c, 
                                                           (SELECT Apttus_DealMgr__Sequence__c, Apttus_DealMgr__Dimension1Value__c 
                                                            FROM Apttus_DealMgr__GuidanceRuleEntries__r
                                                            ORDER BY Apttus_DealMgr__Sequence__c)
                                                           FROM Apttus_DealMgr__DealGuidanceRule__c where Apttus_DealMgr__ProductScope__c IN: flexProductIds
                                                           ORDER BY Apttus_DealMgr__Sequence__c
                                                          ];
        for(Apttus_DealMgr__DealGuidanceRule__c rule: rules){
            List<Id> productIds = rule.Apttus_DealMgr__ProductScope__c.split(';');
            for(Id productId: productIds){
                for(Apttus_DealMgr__DealGuidanceRuleEntry__c entry: rule.Apttus_DealMgr__GuidanceRuleEntries__r){
                    String keyString = productId +' - '+entry.Apttus_DealMgr__Sequence__c;
                    mapProductIdWithRuleEntry.put(keyString, Decimal.valueof(entry.Apttus_DealMgr__Dimension1Value__c));
                }
            }
        }
        return mapProductIdWithRuleEntry;
        
    }
    
    public static void generateDealGuidanceStatus(List<Apttus_Config2__LineItem__c> lineItems, Boolean dmlOperation){
        
        //Added by Amrutha - Subminute billing
        Set<Id> productIds = new Set<Id>();
        Map<Id,Product2> mapProduct;
        Set<Id> optionIds = new Set<Id>();
        //Added by Amrutha - flex discount
        Set<Id> flexProductIds = new Set<Id>();
        Map<String, Decimal> mapProductIdWithRuleEntry = new Map<String, Decimal>();
        for(Apttus_Config2__LineItem__c lineItem: lineItems){
            productIds.add(lineItem.Apttus_Config2__ProductId__c);
            optionIds.add(lineItem.Apttus_Config2__OptionId__c);
            if(lineItem.Apttus_Config2__OptionGroupLabel__c != null && lineItem.Apttus_Config2__OptionGroupLabel__c.containsignorecase('Flex') && lineItem.BI_SID__c != null){
                flexProductIds.add(lineItem.Apttus_Config2__OptionId__c == null ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c);
            }
        }
        mapProduct = new Map<Id,Product2>([Select Id, Capable_of_Sub_Minute_Billing__c, Always_Needs_Review__c  from Product2 where Id IN: productIds or Id IN: optionIds]);
        if(flexProductIds.size()>0 ){
            mapProductIdWithRuleEntry = getRuleEntry(flexProductIds);
        }
        
        for(Apttus_Config2__LineItem__c lineItem: lineItems){
            String fieldString = (lineItem.Is_Bundle_Product__c) ? String.valueOf(lineItem.Bucket_Floor_Price__c) : String.valueOf(lineItem.Deal_Guidance_Level_Formula__c);
            if(lineItem.Is_Bundle_Product__c && lineItem.Product_Family__c!=null && lineItem.Product_Family__c.equalsignorecase('Sendgrid') && lineItem.SG_Product_Type__c!=null && lineItem.SG_Product_Type__c.equalsignorecase('Marketing Campaigns')) fieldString = String.valueOf(lineItem.Bucket_Floor_Price__c);
            //Added by Amrutha - flex discount
            if(lineItem.Apttus_Config2__OptionGroupLabel__c != null && lineItem.Apttus_Config2__OptionGroupLabel__c.containsignorecase('Flex') && lineItem.BI_SID__c != null){
                Id productId = lineItem.Apttus_Config2__OptionId__c == null ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
                if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+1)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+1));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+2)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+1));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+3)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+2));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+4)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+3));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+5)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+4));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+6)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+5));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+7)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+6));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+8)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+7));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+9)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+8));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+10)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+9));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+11)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+10));
                else if(lineItem.Max_Flex_Quantity__c <= mapProductIdWithRuleEntry.get(productId +' - '+12)) fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+11));
                else fieldString = string.valueof(mapProductIdWithRuleEntry.get(productId +' - '+12));
            }
            String measureUnit= lineitem.Rule_Measure__c;
            String keyString = lineItem.Apttus_Config2__OptionId__c == null ? lineItem.Apttus_Config2__ProductId__c + '-' + measureUnit + '-' + fieldString : lineItem.Apttus_Config2__OptionId__c + '-' + measureUnit + '-' + fieldString;
            lineItem.Apttus_Config2__PricingGuidance__c = '{"HidePrice" :false, "HidePercentile": false, "Entries" : [ {"Sequence" : 1,"Rating" : "Green","RangeName":"Approved","PriceTo" : 135.00,"PriceFrom" : 150.00000,"PercentileTo" : 10,"PercentileFrom" : 0,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#387C35"}, {"Sequence" : 2,"Rating" : "Yellow","RangeName" : "Manager","PriceTo" : 120.00,"PriceFrom" : 135.00,"PercentileTo" : 20,"PercentileFrom" : 10,"MeasureType" : "LowHigh","IsItemRating" : true,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps": [ ],"ColorCode" : "#FFE512"}, {"Sequence" : 3,"Rating" : "Orange","RangeName" : "2nd Tier Manager","PriceTo" : 75.00,"PriceFrom" : 120.00,"PercentileTo" : 50,"PercentileFrom" : 20,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#E36F1E"}, {"Sequence" : 4,"Rating" : "Red","RangeName" : "Deal Desk","PriceTo" : 0.00,"PriceFrom" : 75.00,"PercentileTo" : 100,"PercentileFrom" : 50,"MeasureType" : "LowHigh","IsItemRating" : false,"HidePrice" : false,"HidePercentile" : false,"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ],"ColorCode" : "#B2102C"} ],"DimensionValues" : [ ],"DimensionLabels" : [ ],"CustomProps" : [ ]}';
            
            Apttus_DealMgr__DealGuidanceRuleEntry__c ruleEntry = productDealGuidanceMap.get(keyString);
            Decimal matrixField = 0;
            if(measureUnit=='Unit Price'){
            	matrixField = lineItem.Percent_of_Spend__c == null ? lineItem.Apttus_Config2__NetUnitPrice__c: lineItem.Percent_of_Spend__c;
            }else{
                matrixField = measureUnit!=null ? (Decimal)lineItem.get(measureUnit) : 0;
            }
            
            if(ruleEntry != null){
                lineItem.Apttus_Config2__Guidance__c = 'Green';
                if(ruleEntry.Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__CustomMeasureBandDirection__c==null || ruleEntry.Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__CustomMeasureBandDirection__c=='HighLow'){
                    if(matrixField < Decimal.valueOf(ruleEntry.Apttus_DealMgr__Band3Value__c)){
                        lineItem.Apttus_Config2__Guidance__c = 'Red';
                    }
                    else if(matrixField < Decimal.valueOf(ruleEntry.Apttus_DealMgr__Band2Value__c)){
                        lineItem.Apttus_Config2__Guidance__c = 'Orange';
                    }
                    else if(matrixField < Decimal.valueOf(ruleEntry.Apttus_DealMgr__Band1Value__c)){
                        lineItem.Apttus_Config2__Guidance__c = 'Yellow';
                    }
                }else if(ruleEntry.Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__CustomMeasureBandDirection__c=='LowHigh'){
                    if(matrixField > Decimal.valueOf(ruleEntry.Apttus_DealMgr__Band3Value__c)){
                        lineItem.Apttus_Config2__Guidance__c = 'Red';
                    }
                    else if(matrixField > Decimal.valueOf(ruleEntry.Apttus_DealMgr__Band2Value__c)){
                        lineItem.Apttus_Config2__Guidance__c = 'Orange';
                    }
                    else if(matrixField > Decimal.valueOf(ruleEntry.Apttus_DealMgr__Band1Value__c)){
                        lineItem.Apttus_Config2__Guidance__c = 'Yellow';
                    }
                }
            }
            if(lineItem.Apttus_Config2__AdjustmentType__c == '% Discount' && lineItem.Fixed_Discount_on_OF__c && lineItem.Apttus_Config2__Description__c != null && !lineItem.Apttus_Config2__Description__c.contains('ROW')){lineItem.Apttus_Config2__Guidance__c = 'Red';}
            if(lineItem.Apttus_Config2__Description__c!=null){
                if(lineItem.Apttus_Config2__ChargeType__c =='Standard Price' && lineItem.Apttus_Config2__Description__c.containsignorecase('Support')){lineItem.Apttus_Config2__Guidance__c = 'Red';}
            }
            //Added by Amrutha
            if(mapProduct.size()>0){
                if(mapProduct.get(lineItem.Apttus_Config2__ProductId__c)!=null){
                    if((mapProduct.get(lineItem.Apttus_Config2__ProductId__c).Capable_of_Sub_Minute_Billing__c==true)&&
                       (lineItem.Billing_Increment__c!=null || lineItem.Billing_Minute__c!=null)){
                           lineItem.Apttus_Config2__Guidance__c = 'Red';
                       }
                    if(mapProduct.get(lineItem.Apttus_Config2__ProductId__c).Always_Needs_Review__c ==true){
                        lineItem.Apttus_Config2__Guidance__c = 'Red';
                    }
                }if(mapProduct.get(lineItem.Apttus_Config2__OptionId__c)!=null){
                    if((mapProduct.get(lineItem.Apttus_Config2__OptionId__c).Capable_of_Sub_Minute_Billing__c==true)&&
                       (lineItem.Billing_Increment__c!=null || lineItem.Billing_Minute__c!=null)){
                           lineItem.Apttus_Config2__Guidance__c = 'Red';
                       }
                    if(mapProduct.get(lineItem.Apttus_Config2__OptionId__c).Always_Needs_Review__c ==true){
                        lineItem.Apttus_Config2__Guidance__c = 'Red';
                    }
                }
            }
        }
        if(dmlOperation) update lineItems;
    }
}