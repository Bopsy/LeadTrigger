public without sharing class AssetBasedQuotingServices {
    @future
    public static void createAssetBasedLineItems(Set<Id> oppSkuIds){
        List<Opp_SID_SKU__c> oppSkus = [SELECT Opportunity__r.AccountId, Account_SID__r.Account_SID__c FROM Opp_SID_SKU__c WHERE Id =: oppSkuIds];
        Map<String, String> OppSIDSKUtoAccountSIDMap = new Map<String, String>();
        Map<String, String> OppSIDSKUtoAccountMap = new Map<String, String>();
        for(Opp_SID_SKU__c sku: oppSkus){
            OppSIDSKUtoAccountSIDMap.put(sku.Id, sku.Account_SID__r.Account_SID__c);
            OppSIDSKUtoAccountMap.put(sku.Id, sku.Opportunity__r.AccountId);
        }

        Map<String, List<Asset_Based_Line_Item__x>> accountSidAssets = new Map<String, List<Asset_Based_Line_Item__x>>();
        Set<String> bisids = new Set<String>();
        
       if(!Test.isRunningTest()){
           for(Asset_Based_Line_Item__x asset:         
           [SELECT bi_sid__c, account_sid__c, unit_price__c FROM Asset_Based_Line_Item__x WHERE account_sid__c =: OppSIDSKUtoAccountSIDMap.values()]){
               List<Asset_Based_Line_Item__x> assets = accountSidAssets.get(asset.account_sid__c);
               if(assets == null) assets = new List<Asset_Based_Line_Item__x>();
               assets.add(asset);
               accountSidAssets.put(asset.account_sid__c, assets);
               bisids.add(asset.bi_sid__c);
           }
       }
       else if(!oppSkus.isEmpty()){
           for(Asset_Based_Line_Item__x asset:         
           new List<Asset_Based_Line_Item__x>{new Asset_Based_Line_Item__x(account_sid__c = oppSkus[0].Account_SID__r.Account_SID__c, bi_sid__c = 'BI123', unit_price__c = 0.0060)}){
               List<Asset_Based_Line_Item__x> assets = accountSidAssets.get(asset.account_sid__c);
               if(assets == null) assets = new List<Asset_Based_Line_Item__x>();
               assets.add(asset);
               accountSidAssets.put(asset.account_sid__c, assets);
               bisids.add(asset.bi_sid__c);
           }
       }
       
       Map<String, List<Consumption_Usage__x>> accountSidUsages = new Map<String, List<Consumption_Usage__x>>();
       if(!Test.isRunningTest()){
           for(Consumption_Usage__x usage: [SELECT bi_sid__c, account_sid__c, total_price__c, quantity__c FROM Consumption_Usage__x WHERE account_sid__c =:OppSIDSKUtoAccountSIDMap.values()]){
               List<Consumption_Usage__x> usages = accountSidUsages.get(usage.account_sid__c);
               if(usages == null) usages = new List<Consumption_Usage__x>();
               usages.add(usage);
               accountSidUsages.put(usage.account_sid__c, usages);
               bisids.add(usage.bi_sid__c);
           }
       }
       else if(!oppSkus.isEmpty()){
           for(Consumption_Usage__x usage: 
               new List<Consumption_Usage__x>{new Consumption_Usage__x(account_sid__c = oppSkus[0].Account_SID__r.Account_SID__c, bi_sid__c = 'BI1234', total_price__c = 6, quantity__c = 1000)}){
               List<Consumption_Usage__x> usages = accountSidUsages.get(usage.account_sid__c);
               if(usages == null) usages = new List<Consumption_Usage__x>();
               usages.add(usage);
               accountSidUsages.put(usage.account_sid__c, usages);
               bisids.add(usage.bi_sid__c);
           }
       }
       
       Map<String, String> bundleMap = new Map<String, String>();
       Set<String> bundleIds = new Set<String>();
       Map<String, String> bisidMap = new Map<String, String>();
       
       for(Apttus_Config2__ProductOptionComponent__c junction: [SELECT Apttus_Config2__ComponentProductId__r.BI_SID__c, Apttus_Config2__ParentProductId__r.BI_SID__c 
                                                                FROM Apttus_Config2__ProductOptionComponent__c 
                                                                WHERE Apttus_Config2__ComponentProductId__r.BI_SID__c in: bisids 
                                                                AND Apttus_Config2__ParentProductId__c != null
                                                                ORDER BY CreatedDate DESC]){
           bundleMap.put(junction.Apttus_Config2__ComponentProductId__r.BI_SID__c, junction.Apttus_Config2__ParentProductId__c);
           bundleIds.add(junction.Apttus_Config2__ParentProductId__c);
       }
       
       Map<String, Decimal> listPrice = new Map<String, Decimal>();
       Map<String, String> biName = new Map<String, String>();
       Map<String, String> biPriceId = new Map<String, String>();
       for(Apttus_Config2__PriceListItem__c price: [SELECT BI_SID__c, Apttus_Config2__ProductId__c, Apttus_Config2__ListPrice__c, Apttus_Config2__ProductId__r.Name FROM Apttus_Config2__PriceListItem__c WHERE BI_SID__c =: bisids AND Apttus_Config2__PriceType__c != 'Usage'] ){
           if(price.BI_SID__c != null){
              listPrice.put(price.BI_SID__c, price.Apttus_Config2__ListPrice__c);
              biName.put(price.BI_SID__c, price.Apttus_Config2__ProductId__r.Name.left(80));
              biPriceId.put(price.BI_SID__c, price.Id);
           }
           else{
              listPrice.put(price.Apttus_Config2__ProductId__c, price.Apttus_Config2__ListPrice__c);
              biName.put(price.Apttus_Config2__ProductId__c, price.Apttus_Config2__ProductId__r.Name.left(80));
              biPriceId.put(price.Apttus_Config2__ProductId__c, price.Id);
           }
       }
       Map<String, Apttus_Config2__AssetLineItem__c> bundleLineItems = new Map<String, Apttus_Config2__AssetLineItem__c>();
       Map<String, Apttus_Config2__AssetLineItem__c> bundleMaps = new Map<String, Apttus_Config2__AssetLineItem__c>();
       Id priceListId = 'aBE1W00000006JJWAY';
       
       Map<String, Apttus_Config2__AssetLineItem__c> assetLineItems = new Map<String, Apttus_Config2__AssetLineItem__c>();
       Map<String, Apttus_Config2__AssetLineItem__c> biItems = new Map<String, Apttus_Config2__AssetLineItem__c>();
       for(Opp_SID_SKU__c oppSku: oppSkus){
           List<Asset_Based_Line_Item__x> assets = accountSidAssets.get(oppSku.Account_SID__r.Account_SID__c);
           List<Consumption_Usage__x> usages = accountSidUsages.get(oppSku.Account_SID__r.Account_SID__c);
           Integer count = 1;
           if(assets != null){
               for(Asset_Based_Line_Item__x asset: assets){
                   Apttus_Config2__AssetLineItem__c newLineItem = new Apttus_Config2__AssetLineItem__c();
                   newLineItem.Type__c = 'Asset';
                   Product2 newProduct = new Product2(BI_SID__c = asset.bi_sid__c);
                   newLineItem.Apttus_Config2__ProductId__r = newProduct;
                   newLineItem.Apttus_Config2__PriceListId__c = priceListId;
                   newLineItem.Apttus_Config2__PriceListItemId__c = biPriceId.get(asset.bi_sid__c);
                   newLineItem.Apttus_Config2__ChargeType__c = 'Subscription Fee';
                   newLineItem.Apttus_Config2__NetUnitPrice__c = asset.unit_price__c;
                   newLineItem.Apttus_Config2__AccountId__c = oppSku.Opportunity__r.AccountId;
                   newLineItem.Name = biName.get(asset.bi_sid__c);
                   newLineItem.Apttus_Config2__ListPrice__c = listPrice.get(asset.bi_sid__c);
                   newLineItem.Account_SID__c = asset.account_sid__c;
                   newLineItem.Apttus_Config2__AssetStatus__c = 'Activated';
                   newLineItem.Apttus_Config2__RenewalAdjustmentAmount__c = asset.unit_price__c;
                   newLineItem.Apttus_Config2__RenewalAdjustmentType__c = 'Base Price Override';
                   newLineItem.Apttus_Config2_AdjustmentAmount_c__c = newLineItem.Apttus_Config2__RenewalAdjustmentAmount__c;
                   newLineItem.Apttus_Config2_AdjustmentType_c__c = newLineItem.Apttus_Config2__RenewalAdjustmentType__c;
                   newLineItem.Apttus_Config2__IsPrimaryLine__c = true;
                   newLineItem.Apttus_Config2__ItemSequence__c = 1;
                   newLineItem.Apttus_Config2__Quantity__c = 1;
                   newLineItem.Apttus_Config2__ChargeType__c = 'Standard Price';
                   newLineItem.Apttus_Config2__SellingTerm__c = 1;
                   newLineItem.Apttus_Config2__SellingFrequency__c = 'One Time';
                   newLineItem.Apttus_Config2__LineType__c = 'Product/Service';
                   newLineItem.Apttus_Config2__PrimaryLineNumber__c = count;
                   newLineItem.Apttus_Config2__LineNumber__c = count;
                   newLineItem.Unique_Key__c = asset.bi_sid__c + '-' + asset.account_sid__c + '-' + oppSku.Opportunity__r.AccountId + '-' + 'Asset';
                   biItems.put(asset.bi_sid__c + '-' + asset.account_sid__c + '-' + oppSku.Opportunity__r.AccountId, newLineItem);
                   assetLineItems.put(newLineItem.Unique_Key__c, newLineItem);
                   count++;
               }
           }
           if(usages != null){
               for(Consumption_Usage__x usage: usages){
                   if(biItems.get(usage.bi_sid__c + '-' + usage.account_sid__c + '-' + oppSku.Opportunity__r.AccountId) != null){
                       Apttus_Config2__AssetLineItem__c newLineItem = biItems.get(usage.bi_sid__c + '-' + usage.account_sid__c + '-' + oppSku.Opportunity__r.AccountId);
                       newLineItem.Average_Monthly_Spend__c = usage.total_price__c;
                       newLineItem.Average_Usage_Last_3_Months__c = usage.quantity__c;
                       newLineItem.Usage_Period__c = Date.today().addMonths(-3).toStartOfMonth().format() + ' - ' + Date.today().toStartOfMonth().addDays(-1).format();
                   }
                   else{
                       Apttus_Config2__AssetLineItem__c newLineItem = new Apttus_Config2__AssetLineItem__c();
                       newLineItem.Type__c = 'Consumption';
                       newLineItem.Apttus_Config2__PriceListId__c = priceListId;
                       newLineItem.Apttus_Config2__PriceListItemId__c = biPriceId.get(usage.bi_sid__c);
                       newLineItem.Apttus_Config2__RenewalAdjustmentType__c = 'Base Price Override';
                       Product2 newProduct = new Product2(BI_SID__c = usage.bi_sid__c);
                       newLineItem.Apttus_Config2__ProductId__r = newProduct;
                       newLineItem.Apttus_Config2__ChargeType__c = 'Subscription Fee';
                       newLineItem.Average_Monthly_Spend__c = usage.total_price__c;
                       newLineItem.Apttus_Config2__NetUnitPrice__c = (usage.total_price__c / usage.quantity__c).setScale(5, System.RoundingMode.HALF_UP);
                       newLineItem.Apttus_Config2__RenewalAdjustmentAmount__c =  newLineItem.Apttus_Config2__NetUnitPrice__c;
                       newLineItem.Apttus_Config2_AdjustmentAmount_c__c = newLineItem.Apttus_Config2__RenewalAdjustmentAmount__c;
                       newLineItem.Apttus_Config2_AdjustmentType_c__c = newLineItem.Apttus_Config2__RenewalAdjustmentType__c;
                       newLineItem.Apttus_Config2__AccountId__c = oppSku.Opportunity__r.AccountId;
                       newLineItem.Name = biName.get(usage.bi_sid__c);
                       newLineItem.Apttus_Config2__ListPrice__c = listPrice.get(usage.bi_sid__c);
                       newLineItem.Account_SID__c = usage.account_sid__c;
                       newLineItem.Apttus_Config2__AssetStatus__c = 'Activated';
                       newLineItem.Apttus_Config2__IsPrimaryLine__c = true;
                       newLineItem.Apttus_Config2__Quantity__c = 1;
                       newLineItem.Apttus_Config2__ItemSequence__c = 1;
                       newLineItem.Average_Usage_Last_3_Months__c = usage.quantity__c;
                       newLineItem.Usage_Period__c = Date.today().addMonths(-3).toStartOfMonth().format() + ' - ' + Date.today().toStartOfMonth().addDays(-1).format();
                       newLineItem.Apttus_Config2__LineType__c = 'Product/Service';
                       newLineItem.Apttus_Config2__ChargeType__c = 'Standard Price';
                       newLineItem.Apttus_Config2__SellingTerm__c = 1;
                       newLineItem.Apttus_Config2__SellingFrequency__c = 'One Time';
                       newLineItem.Apttus_Config2__PrimaryLineNumber__c = count;
                       newLineItem.Apttus_Config2__LineNumber__c = count;
                       newLineItem.Unique_Key__c = usage.bi_sid__c + '-' + usage.account_sid__c + '-' + oppSku.Opportunity__r.AccountId + '-' + 'Consumption';
                       if(newLineItem.Apttus_Config2__ListPrice__c > newLineItem.Apttus_Config2__NetUnitPrice__c){
                           newLineItem.Type__c = 'Asset';
                           newLineItem.Unique_Key__c = usage.bi_sid__c + '-' + usage.account_sid__c + '-' + oppSku.Opportunity__r.AccountId + '-' + 'Asset';
                       }
                       assetLineItems.put(newLineItem.Unique_Key__c, newLineItem);
                       count++;
                   }
               }
           }
       }
       
       /*for(Apttus_Config2__AssetLineItem__c lineItem: assetLineItems.values()){
           String lineItemBisid = lineItem.Unique_Key__c.split('-')[0];
           if(bundleMap.containsKey(lineItemBisid)){
               String prodId = bundleMap.get(lineItemBisid);
               String accountsid = lineItem.Unique_Key__c.split('-')[1];
               string accountid = lineItem.Unique_Key__c.split('-')[2];
               String uniqueKey = prodId + '-' +  accountsid + '-' + accountid + '-' + 'Bundle';
               if(!bundleLineItems.containsKey(uniqueKey)){
                   Apttus_Config2__AssetLineItem__c newLineItem = new Apttus_Config2__AssetLineItem__c();
                   newLineItem.Type__c = 'Bundle';
                   newLineItem.Apttus_Config2__ItemSequence__c = 1;
                   newLineItem.Apttus_Config2__ProductId__c = prodId;
                   newLineItem.Apttus_Config2__ChargeType__c = 'Subscription Fee';
                   newLineItem.Apttus_Config2__AccountId__c = accountId;
                   newLineItem.Name = biName.get(prodId);
                   newLineItem.Apttus_Config2__ListPrice__c = 0;
                   newLineItem.Apttus_Config2__NetUnitPrice__c = 0;
                   newLineItem.Account_SID__c = accountsid;
                   newLineItem.Apttus_Config2__AssetStatus__c = 'Activated';
                   newLineItem.Apttus_Config2__IsPrimaryLine__c = true;
                   newLineItem.Apttus_Config2__Quantity__c = 1;
                   newLineItem.Apttus_Config2__HasOptions__c = true;
                   //newLineItem.Usage_Period__c = Date.today().addMonths(-3).toStartOfMonth().format() + ' - ' + Date.today().toStartOfMonth().addDays(-1).format();
                   newLineItem.Apttus_Config2__LineType__c = 'Product/Service';
                   newLineItem.Apttus_Config2__ChargeType__c = 'Standard Price';
                   newLineItem.Apttus_Config2__SellingTerm__c = 1;
                   newLineItem.Apttus_Config2__SellingFrequency__c = 'One Time';
                   newLineItem.Unique_Key__c = uniqueKey;
                   newLineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
                   newLineItem.Apttus_Config2__LineNumber__c = 1;
                   
                   bundleLineItems.put(uniqueKey, newLineItem);
                   
                   lineItem.Apttus_Config2__OptionId__r = lineItem.Apttus_Config2__ProductId__r;
                   lineItem.Apttus_Config2__ProductId__r = null;
                   lineItem.Apttus_Config2__ProductId__c = prodId;
                   
                   bundleMaps.put(lineItem.Unique_Key__c, newLineItem);
               }
               else{
                   lineItem.Apttus_Config2__OptionId__r = lineItem.Apttus_Config2__ProductId__r;
                   lineItem.Apttus_Config2__ProductId__r = null;
                   lineItem.Apttus_Config2__ProductId__c = prodId;
                   bundleMaps.put(lineItem.Unique_Key__c, bundleLineItems.get(uniqueKey));
               }
           }
       }
       
       upsert bundleLineItems.values() Unique_Key__c;
       
       for(String uniqueKey: bundleMaps.keySet()){
           Apttus_Config2__AssetLineItem__c lineItem = assetLineItems.get(uniqueKey);
           Apttus_Config2__AssetLineItem__c bundleLineItem = bundleMaps.get(uniqueKey);
           lineItem.Apttus_Config2__BundleAssetId__c = bundleLineItem.Id;
           lineItem.Apttus_Config2__ParentAssetId__c = bundleLineItem.Id;
           lineItem.Apttus_Config2__LineType__c = 'Option';
       }*/
       
       List<String> names = new List<String>();
       Set<String> ids = new Set<String>();
       Map<String, Apttus_Config2__AssetLineItem__c> sortMap = new Map<String, Apttus_Config2__AssetLineItem__c>();
       List<Apttus_Config2__AssetLineItem__c> sortedLineItems = new List<Apttus_Config2__AssetLineItem__c>();
       
       for(Apttus_Config2__AssetLineItem__c lineItem: assetLineItems.values()){
           if(!ids.contains(lineItem.Unique_Key__c) && lineItem.Name != null && !lineItem.Name.contains('Carrier Fee')){
              names.add(lineItem.Name + lineItem.Unique_Key__c);
              sortMap.put(lineItem.Name + lineItem.Unique_Key__c, lineItem);
              ids.add(lineItem.Unique_Key__c);
           }
       }
       
       names.sort();
       
       for(String lineItemName: names){
           sortedLineItems.add(sortMap.get(lineItemName));
       }
       
       //system.assert(false, sortedLineItems[0]);
       upsert sortedLineItems Unique_Key__c;
    }

}