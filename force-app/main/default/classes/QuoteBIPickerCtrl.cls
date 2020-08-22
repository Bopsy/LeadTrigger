public with sharing class QuoteBIPickerCtrl {
    public class ErrorException extends Exception{}
    public class BillableItemWrapper{
        public string Name;
        public string Country;
        public String Region;
        public String productFamily;
        public string GroupName;
        public Decimal listPrice;
        public Decimal discount;
        public Decimal percent;
        public List<DiscountTiers> discountTiers;
        public Boolean pt;
        public String id;
        public Decimal qt;
        public Decimal duration;
        public Decimal increment;
        public Decimal t1p;
        public Decimal t2p;
        public Decimal t3p;
        public Boolean tp;
        public String gtmGroupId;
    }
    
    public class DiscountTiers{
        public Decimal floor;
        public Decimal ceiling;
        public Decimal flatPrice;
        public Decimal percent;
        public Boolean pt;
        
        public DiscountTiers(BI_Commit_Price__c price){
            this.floor = price.Min_Commit_Floor__c;
            this.ceiling = price.Min_Commit_Ceiling__c;
            this.flatPrice = price.Flat_Price__c;
            this.percent = price.Percent_Off__c;
            this.pt = price.Discount_Type__c == 'Percent';
        }
    }
    
    public class GroupItemWrapper{
        public string Name;
        public string productFamily;
        public String id;
    }
    
    public String getGroups(){
        List<GTM_Grouping__c> groups = [SELECT Name__c, Product_Family__c, SFDC_Product__c FROM GTM_Grouping__c WHERE Status__c = 'Active' ORDER BY Name__c];
        List<GroupItemWrapper> wrappers = new List<GroupItemWrapper>();
        for(GTM_Grouping__c aGroup: groups){
            GroupItemWrapper newWrapper = new GroupItemWrapper();
            newWrapper.Name = aGroup.Name__c;
            newWrapper.productFamily = aGroup.SFDC_Product__c;
            newWrapper.Id = aGroup.Id;
            wrappers.add(newWrapper);
        }
        return JSON.serialize(wrappers);
    }
    public Quote aQuote {get; set;}
    public List<Quote_BI__c> existingDiscounts {get; set;}
    public Map<Id, List<BI_Commit_Price__c>> discountPrices {get; set;}
    
    public List<String> commitFrequencies {get; set;}
    public List<String> paymentMethods {get; set;}
    public List<String> paymentFrequencies {get; set;}
    public List<String> termRanges {get; set;}
    
    public String paymentMethodsString {get; set;}
    public String paymentFrequenciesString {get; set;}
    public String termRangesString {get; set;}
    public String productString{get; set;}
    public final static String NEED_DD_APPROVAL = 'DD Approval';
    public final static String NEED_MANAGER_APPROVAL = 'Manager Approval';
    public final static String AUTO_APPROVAL = 'Auto Approval';
    
    public static Map<Id, String> checkApproval(List<Quote_BI__c> quoteBis){
        quoteBis = [SELECT Flat_Price__c, Volume__c, List_Price__c, Billable_Item__c, Quote__r.Total_Committed_Revenue__c, Quote__r.Term_Range__c FROM Quote_BI__c WHERE Id = :quoteBis];
        
        Map<Id, String> approvalMap = new Map<Id, String>();
        
        Set<Id> biIds = new Set<Id>();
        for(Quote_BI__c bi: quoteBis){
            biIds.add(bi.Billable_Item__c);
        }
        List<BI_Commit_Price__c> prices = [SELECT Billable_Item__c, Min_Commit_Floor__c, Min_Commit_Ceiling__c, Flat_Price__c, Percent_Off__c, Discount_Type__c FROM BI_Commit_Price__c WHERE Billable_Item__c = : biIds ORDER BY Min_Commit_Floor__c];
        
        Map<Id, List<DiscountTiers>> biDiscountTiers = new Map<Id, List<DiscountTiers>>();
        
        for(BI_Commit_Price__c price: prices){
            List<DiscountTiers> tiers = biDiscountTiers.get(price.Billable_Item__c);
            if(tiers == null)
                tiers = new List<DiscountTiers>();
            tiers.add(new DiscountTiers(price));
            biDiscountTiers.put(price.Billable_Item__c, tiers);
        }
        
        for(Quote_BI__c bi: quoteBis){
            Decimal commitNumber = bi.Quote__r.Total_Committed_Revenue__c / Decimal.valueOf(bi.Quote__r.Term_Range__c);
            List<DiscountTiers> tiers = biDiscountTiers.get(bi.Billable_Item__c);
            Boolean cannotFindTiers = true;
            if(tiers != null && !tiers.isEmpty()){
                for(Integer i = 0; i < tiers.size(); i++){
                    DiscountTiers tier = tiers[i];
                    if(commitNumber >= tier.floor && (tier.ceiling == null || commitNumber < tier.ceiling)){
                        if(bi.Flat_Price__c >= tier.flatPrice){
                            approvalMap.put(bi.Id, AUTO_APPROVAL);
                        }
                        else if(i != tiers.size() - 1){
                            DiscountTiers nextTier = tiers[i+1];
                            if(bi.Flat_Price__c >= nextTier.flatPrice){
                                approvalMap.put(bi.Id, NEED_MANAGER_APPROVAL);
                            }
                            else{
                                approvalMap.put(bi.Id, NEED_DD_APPROVAL);
                            }
                        }
                        else{
                           approvalMap.put(bi.Id, NEED_DD_APPROVAL);
                        }
                        cannotFindTiers = false;
                        break;
                    }
                }
            }
            if(cannotFindTiers){
                if(bi.Flat_Price__c < bi.List_Price__c){
                    approvalMap.put(bi.Id, NEED_DD_APPROVAL);
                }
                else{
                    approvalMap.put(bi.Id, AUTO_APPROVAL);
                }
            }
        }
        
        return approvalMap;
    }
    
    public QuoteBIPickerCtrl(ApexPages.standardController stdCtrl){
        aQuote = [SELECT Id FROM Quote WHERE Id=:stdCtrl.getRecord().Id];
        Id oppId = [SELECT OpportunityId FROM Quote WHERE Id=:stdCtrl.getRecord().Id].OpportunityId;
        existingDiscounts = [SELECT Quote__c, Billable_Item__r.Always_Needs_Review__c,Billable_Item__r.Name, Billable_Item__r.Product_Family__c, Billable_Item__c, 
                                    Billable_Item__r.Territory__c, Billable_Item__r.Region__c, Billable_Item__r.Price__c, Billable_Item__r.SFDC_Product__c, List_Price__c, Volume__c,
                                    GTM_Group__r.Name, First_Tier_Price__c, Second_Tier_Price__c, Third_Tier_Price__c, Quote_GTM_Group__c,
                                    (SELECT Commit_Floor__c, Discount_Type__c, Flat_Price__c, Percent_Off__c FROM Quote_Commit_Prices__r ORDER BY Commit_Floor__c)
                                    FROM Quote_BI__c WHERE Quote__c =:aQuote.Id ORDER BY Billable_Item__r.SFDC_Product__c];
                                    
        Set<Id> biIds = new Set<Id>();
        List<Opportunity_Product__c> products = [SELECT Amount__c, Product_Name__c FROM Opportunity_Product__c WHERE Opportunity__c =: oppId];
        for(Quote_BI__c discount: existingDiscounts){
            biIds.add(discount.Billable_Item__c);
        }
        
        discountPrices = new Map<Id, List<BI_Commit_Price__c>>();
        
        for(BI_Commit_Price__c price: [SELECT Billable_Item__c, Discount_Type__c, Flat_Price__c, Min_Commit_Ceiling__c, Min_Commit_Floor__c, Percent_Off__c
                                       FROM BI_Commit_Price__c
                                       WHERE Billable_Item__c =: biIds ORDER BY Min_Commit_Floor__c]){
            List<BI_Commit_Price__c> prices = discountPrices.get(price.Billable_Item__c);
            if(prices == null) prices = new List<BI_Commit_Price__c>();
            prices.add(price);
            discountPrices.put(price.Billable_Item__c, prices);
        }
        
        commitFrequencies = new List<String>();
        paymentMethods = new List<String>();
        paymentFrequencies = new List<String>();
        termRanges = new List<String>();
        
        Map<String, List<String>> paymentMethodsMap = new Map<String, List<String>>();
        Map<String, List<String>> paymentFrequenciesMap = new Map<String, List<String>>();
        Map<String, List<String>> termRangesMap = new Map<String, List<String>>();
        
        for(BI_Picker_Dependent_List__c setting: BI_Picker_Dependent_List__c.getAll().values()){
            List<String> paymentMethodsList = setting.Payment_Type__c.split(';');
            List<String> paymentFrequenciesList = setting.Prepay_Frequency__c.split(';');
            List<String> rangeList = new List<String>();
            if(setting.Term_Range__c != null)
               rangeList = setting.Term_Range__c.split(';');
            paymentMethodsMap.put(setting.Commit_Frequency__c, paymentMethodsList);
            paymentFrequenciesMap.put(setting.Commit_Frequency__c, paymentFrequenciesList);
            termRangesMap.put(setting.Commit_Frequency__c, rangeList);
        }
        
        paymentMethodsString = JSON.serialize(paymentMethodsMap);
        paymentFrequenciesString = JSON.serialize(paymentFrequenciesMap);
        termRangesString = JSON.serialize(termRangesMap);
        productString = JSON.serialize(products);
    }
    
    @RemoteAction
    public static void saveData(String dataString, String quoteId, String aQuote, Boolean updateForecast){
        List<Quote_BI__c> oldDiscounts = [SELECT Billable_Item__c, Quote_GTM_Group__c FROM Quote_BI__c WHERE Quote__c =: quoteId];
        List<Quote_GTM_Group__c> oldGroups = [SELECT GTM_Group__c FROM Quote_GTM_Group__c WHERE Quote__c =: quoteId];
        List<Quote_BI__c> discounts = (List<Quote_BI__c>) JSON.deserialize(dataString, List<Quote_BI__c>.class);
        Quote updateQuote = (Quote) JSON.deserialize(aQuote, Quote.class);
        updateQuote.Id = quoteId;
        Savepoint sp = Database.setSavepoint();
        for(Integer i = oldDiscounts.size() - 1; i >= 0; i--){
            for(Quote_BI__c discount: discounts){
                if(discount.Billable_Item__c != null && discount.Billable_Item__c == oldDiscounts[i].Billable_Item__c){
                    discount.Id = oldDiscounts[i].Id;
                    oldDiscounts.remove(i);
                    break;
                }
            }
        }
        Set<Id> groupId = new Set<Id>();
        Map<String, Quote_GTM_Group__c> alreadyAddedId = new Map<String, Quote_GTM_Group__c>();
        for(Quote_BI__c discount: oldDiscounts){
            groupId.add(discount.Quote_GTM_Group__c);
        }
        
        for(Integer i = oldGroups.size() - 1; i >= 0; i--){
            if(!groupId.contains(oldGroups[i].Id)){
                alreadyAddedId.put(oldGroups[i].GTM_Group__c, oldGroups[i]);
                oldGroups.remove(i);
            }
        }
        
        Map<Id, Quote_GTM_Group__c> itemToGroup = new Map<Id, Quote_GTM_Group__c>();
        Integer newGroupCount = 1;
        for(Quote_BI__c discount: discounts){
            if(discount.Quote_GTM_Group__c == null){
                if(discount.GTM_Group__c != null){
                    if(!alreadyAddedId.containsKey(discount.GTM_Group__c)){
                        Quote_GTM_Group__c newGroup = new Quote_GTM_Group__c(GTM_Group__c = discount.GTM_Group__c, Quote__c = quoteId);
                        itemToGroup.put(discount.Billable_Item__c, newGroup);
                        alreadyAddedId.put(discount.GTM_Group__c, newGroup);
                    }
                    else{
                        itemToGroup.put(discount.Billable_Item__c, alreadyAddedId.get(discount.GTM_Group__c));
                    }
                }
                else{
                    Quote_GTM_Group__c newGroup = new Quote_GTM_Group__c(Quote__c = quoteId);
                    itemToGroup.put(discount.Billable_Item__c, newGroup);
                    alreadyAddedId.put(String.valueOf(newGroupCount), newGroup);
                    newGroupCount++;
                }
            }
        }
        try{
            delete oldDiscounts;
            delete oldGroups;
            upsert alreadyAddedId.values();
            for(Quote_BI__c discount: discounts){
                if(discount.Id == null){
                    discount.Quote_GTM_Group__c = itemToGroup.get(discount.Billable_Item__c).Id;
                }
            }
            upsert discounts;
            update updateQuote;
            if(!discounts.isEmpty()){
                QuoteService.upsertOpportunityProductsFromQuote(discounts, updateQuote.OpportunityId, updateForecast);
            }
        }
        catch(DMLException e){
            Database.rollback(sp);
            throw new ErrorException(e.getMessage());
        }
    }
    
    public String getExistingItems(){
        List<BillableItemWrapper> wrappers = new List<BillableItemWrapper>();
        for(Quote_BI__c discount: existingDiscounts){
           BillableItemWrapper newWrapper = new BillableItemWrapper(); 
           newWrapper.tp = discount.Billable_Item__r.Always_Needs_Review__c;
           newWrapper.Id = discount.Billable_Item__c;
           newWrapper.Name = discount.Billable_Item__r.Name;
           newWrapper.Country = discount.Billable_Item__r.Territory__c;
           newWrapper.Region = discount.Billable_Item__r.Region__c;
           newWrapper.productFamily = discount.Billable_Item__r.SFDC_Product__c;
           newWrapper.listPrice = discount.Billable_Item__r.Price__c;
           newWrapper.t1p = discount.First_Tier_Price__c;
           newWrapper.t2p = discount.Second_Tier_Price__c;
           newWrapper.t3p = discount.Third_Tier_Price__c;
           newWrapper.qt = discount.Volume__c;
           newWrapper.gtmGroupId = discount.Quote_GTM_Group__c;
           newWrapper.pt = false;//discount.Discount_Type__c == 'Percent';
           List<DiscountTiers> tiers = new List<DiscountTiers>();
           List<BI_Commit_Price__c> prices = discountPrices.get(discount.Billable_Item__c);
           if(prices != null && !prices.isEmpty()){
                for(BI_Commit_Price__c price: prices){
                    DiscountTiers newTier = new DiscountTiers(price);
                    tiers.add(newTier);
                }
           }
           /*List<Quote_Commit_Prices__r> exceptionPrices = discount.Approved_BI_Commit_Prices__r;
           if(exceptionPrices != null){
               for(Approved_BI_Commit_Price__c exceptionPrice: exceptionPrices){
                   Boolean pt = exceptionPrice.Discount_Type__c == 'Percent';
                   BI_Commit_Price__c exceptionCommitPrice = new BI_Commit_Price__c(Min_Commit_Floor__c = exceptionPrice.Commit_Min__c, Discount_Type__c = exceptionPrice.Discount_Type__c, Flat_Price__c = exceptionPrice.Flat_Price__c, Percent_Off__c = exceptionPrice.Percent_Off__c);
                   Boolean inserted = false;
                   Decimal exceptionPriceNumber = null;
                   Integer insertIndex = -1;
                   for(Integer i = 0; i < tiers.size(); i++){
                       DiscountTiers tier = tiers[i];
                       if(tier.pt == pt && !inserted){
                           if(tier.floor == exceptionPrice.Commit_Min__c){
                               tier.flatPrice = exceptionPrice.Flat_Price__c;
                               tier.percent = exceptionPrice.Percent_Off__c;
                               exceptionPriceNumber = pt ? exceptionPrice.Percent_Off__c : exceptionPrice.Flat_Price__c;
                               inserted = true;
                           }
                           else if(tier.floor < exceptionPrice.Commit_Min__c && tier.ceiling > exceptionPrice.Commit_Min__c){
                               exceptionCommitPrice.Min_Commit_Ceiling__c = tier.ceiling;
                               tier.ceiling = exceptionPrice.Commit_Min__c;
                               insertIndex = i+1;
                               exceptionPriceNumber = pt ? exceptionPrice.Percent_Off__c : exceptionPrice.Flat_Price__c;
                               inserted = true;
                           }
                           else if(tier.floor > exceptionPrice.Commit_Min__c && i == 0){
                               exceptionCommitPrice.Min_Commit_Ceiling__c = tier.floor;
                               insertIndex = 0;
                               exceptionPriceNumber = pt ? exceptionPrice.Percent_Off__c : exceptionPrice.Flat_Price__c;
                               if(tier.floor >= exceptionPrice.Commit_Min__c){
                                   if(pt && exceptionPriceNumber > tier.percent){
                                       tier.percent = exceptionPriceNumber;
                                   }
                                   else if(!pt && exceptionPriceNumber < tier.flatPrice){
                                       tier.flatPrice = exceptionPriceNumber;
                                   }
                               }
                               inserted = true;
                           }
                       }
                       else if(tier.pt == pt && inserted && exceptionPriceNumber != null){
                           if(tier.floor >= exceptionPrice.Commit_Min__c){
                               if(pt && exceptionPriceNumber > tier.percent){
                                   tier.percent = exceptionPriceNumber;
                               }
                               else if(!pt && exceptionPriceNumber < tier.flatPrice){
                                   tier.flatPrice = exceptionPriceNumber;
                               }
                           }
                       }
                   }
                   if(!inserted){
            
                       if(!tiers.isEmpty() && tiers[tiers.size() - 1].pt == pt && exceptionPrice.Commit_Min__c > tiers[tiers.size() - 1].floor){
                          tiers[tiers.size() - 1].ceiling = exceptionPrice.Commit_Min__c;
                       }
                       tiers.add(new DiscountTiers(exceptionCommitPrice));
                   }
                   else if(insertIndex != -1){
                       tiers.add(insertIndex, new DiscountTiers(exceptionCommitPrice));
                   }
               }
           }*/
           newWrapper.discountTiers = tiers;
           if(discount.GTM_Group__r.Name != null)
                newWrapper.groupName = discount.GTM_Group__r.Name;
           else
                newWrapper.groupName = 'NO GROUP';
           newWrapper.discount = 0;//discount.Flat_Price__c;
           newWrapper.percent = 0;//discount.Percent_Off__c;
           wrappers.add(newWrapper);
        }
        return JSON.serialize(wrappers);
    }
    
    public String getBillableItems(){
      
        List<Billable_Item__c> items = [SELECT Always_Needs_Review__c, Name, SFDC_Product__c, Product_Family__c, Territory__c, Discount_Type__c, Region__c, Product__c, Price__c, 
                                            (SELECT GTM_Group__r.Name__c FROM GTM_Group_Billable_Items__r),
                                            (SELECT Discount_Type__c, Flat_Price__c, Min_Commit_Ceiling__c, Min_Commit_Floor__c, Percent_Off__c FROM BI_Commit_Prices__r ORDER BY Min_Commit_Floor__c) 
                                        FROM Billable_Item__c 
                                        WHERE Product_Family__c != null 
                                        AND Status__c = 'ACTIVE' 
                                        ORDER BY Name];
        List<BillableItemWrapper> wrappers = new List<BillableItemWrapper>();
        
        for(Billable_Item__c item: items){
            BillableItemWrapper newWrapper = new BillableItemWrapper();
            newWrapper.Id = item.Id;
            newWrapper.Name = item.Name;
            newWrapper.Country = item.Territory__c;
            newWrapper.Region = item.Region__c;
            newWrapper.productFamily = item.SFDC_Product__c;
            newWrapper.tp = item.Always_Needs_Review__c;
            if(item.GTM_Group_Billable_Items__r != null && !item.GTM_Group_Billable_Items__r.isEmpty() && item.GTM_Group_Billable_Items__r[0].GTM_Group__r.Name__c != null){
                newWrapper.GroupName = item.GTM_Group_Billable_Items__r[0].GTM_Group__r.Name__c;
            }
            else{
                newWrapper.GroupName = 'NO GROUP';
            }
            List<DiscountTiers> tiers = new List<DiscountTiers>();
            if(item.BI_Commit_Prices__r != null && !item.BI_Commit_Prices__r.isEmpty()){
                for(BI_Commit_Price__c price: item.BI_Commit_Prices__r){
                    DiscountTiers newTier = new DiscountTiers(price);
                    tiers.add(newTier);
                }
            }
            newWrapper.discountTiers = tiers;
            newWrapper.listPrice = item.Price__c;
            newWrapper.pt = item.Discount_Type__c == 'Percent';
            //if(agreement.Average_Monthly_Committed_Revenue__c == null || agreement.Average_Monthly_Committed_Revenue__c < 1000){
            newWrapper.discount = item.Price__c;
            newWrapper.percent = 0;
            newWrapper.duration = 0;
            newWrapper.increment = 0;
            //}
            //else{
            //    for(Integer i = startIndex; i < discountFields.size(); i += 2){
            //        newWrapper.discount = (Decimal) item.get(discountFields[i]);
            //        newWrapper.percent = (Decimal) item.get(discountFields[i+1]);
            //        if(newWrapper.percent != null || newWrapper.discount != null) break;
            //    }
            //    if(newWrapper.discount == null && newWrapper.percent != null){
            //        newWrapper.discount = newWrapper.percent * item.Price__c / 100;
            //    }
            //if(item.Price__c == 0){
            //    newWrapper.percent = 0;
            //    newWrapper.discount = 0;
            // }
            // else if(newWrapper.discount != null && newWrapper.percent == null){
            //    newWrapper.percent = newWrapper.discount / item.Price__c * 100;
            // }
            // if(newWrapper.discount == null && newWrapper.percent == null){
            //    newWrapper.discount = item.Price__c;
            //    newWrapper.percent = 0;
            // }
            //}
            wrappers.add(newWrapper);
        }
        return JSON.serialize(wrappers);
    }
    
}