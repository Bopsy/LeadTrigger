public with sharing class NewBillableItemPickerCtrl {
    public class ErrorException extends Exception{}
    //public String biPart1 {get; set;}
    //public String biPart2 {get; set;}
    public class BillableItemWrapper{
        public string Name;
        public string Country;
        //public String Region;
        public String productFamily;
        public string GroupName;
        public String groupType;
        public Decimal listPrice;
        public Decimal discount;
        public Decimal percent;
        public List<diT> diT; //discountTiers
        public List<QuantityTiers> quantityTiers;
        public List<QuantityTiers> deT; //defaultTiers
        public Boolean percentDiscount;
        public String id;
        public Decimal du; //duration
        public Decimal inc; //increment
        public Boolean tierPricing;
        public Boolean mip; //mip
        public Boolean ta; //tierApproval
        public Boolean mc; //monthlyCharge
        public String rtn; //RecordType Name
        public Decimal minPrice;
        public Decimal poa; //Percent of Account
        public Date sd;//Start Date
        public Boolean rq; //requires quantity
        public Decimal q; //Quantity
        public Decimal mp; //Max Wireless Allowance Percent
    }
    
    public class QuantityTiers{
        public Decimal floor;
        public Decimal ceiling;
        public Decimal flatPrice;
        public Decimal listPrice;
        public Decimal q;
        public Decimal r;
        public Date sd;
        public Date ed;
        public Boolean needsApproval;
        public String Id;
        
        public QuantityTiers(Default_Pricing_Tier__c price){
            this.floor = price.Tier_Floor__c;
            this.ceiling = price.Tier_Ceiling__c;
            this.listPrice = price.Flat_Price__c;
            this.flatPrice = price.Flat_Price__c;
            this.needsApproval = false;
        }
        
        public QuantityTiers(Single_BI_Tier__c price){
            this.Id = price.Id;
            this.floor = price.Floor__c;
            this.ceiling = price.Ceiling__c;
            this.listPrice = price.List_Price__c;
            this.flatPrice = price.Flat_Price__c;
            this.q = price.Monthly_Units_Purchased__c;
            this.sd = price.Discount_Rate_Start_Date__c;
            this.ed = price.Discount_Rate_End_Date__c;
            this.needsApproval = price.Needs_Approval__c;
        }
        
        public QuantityTiers(Single_GTM_Group_Tier__c price){
            this.Id = price.Id;
            this.floor = price.Floor__c;
            this.ceiling = price.Ceiling__c;
            this.listPrice = price.List_Price__c;
            this.flatPrice = price.Flat_Price__c;
            this.needsApproval = price.Needs_Approval__c;
        }
    }
    public class diT{
        public Decimal floor;
        public Decimal ceiling;
        public Decimal flatPrice;
        public Decimal percent;
        public Boolean percentDiscount;
        
        public diT(BI_Commit_Price__c price){
            this.floor = price.Min_Commit_Floor__c;
            this.ceiling = price.Min_Commit_Ceiling__c;
            this.flatPrice = price.Flat_Price__c;
            this.percent = price.Percent_Off__c;
            this.percentDiscount = price.Discount_Type__c == 'Percent';
        }
    }
    
    public class GroupItemWrapper{
        public string Name;
        public string productFamily;
        public String id;
        public List<QuantityTiers> quantityTiers;
        public List<QuantityTiers> deT;
        public String singleId;
        public String type;
    }
    
    public String getGroups(){
        List<GTM_Grouping__c> groups = [SELECT GTM_Group_Type__c, Name__c, Product_Family__c, (SELECT Tier_Floor__c, Tier_Ceiling__c, Flat_Price__c FROM Default_Pricing_Tiers__r ORDER BY Tier_Floor__c) FROM GTM_Grouping__c WHERE Status__c = 'Active' ORDER BY Name__c];
        List<GroupItemWrapper> wrappers = new List<GroupItemWrapper>();
        List<Single_GTM_Group_Tier__c> groupTiers = [SELECT Needs_Approval__c, GTM_Group__c, Single_GTM_Group__c, Floor__c, Ceiling__c, Flat_Price__c, List_Price__c FROM Single_GTM_Group_Tier__c WHERE GTM_Group__c != null AND Single_GTM_Group__c =:existingGroups ORDER BY Single_GTM_Group__c];
        Map<Id, List<Single_GTM_Group_Tier__c>> exsitingGroupTiers = new Map<Id, List<Single_GTM_Group_Tier__c>>();
        for(Single_GTM_Group_Tier__c tier: groupTiers){
            List<Single_GTM_Group_Tier__c> newTiers = exsitingGroupTiers.get(tier.GTM_Group__c);
            if(newTiers == null) newTiers = new List<Single_GTM_Group_Tier__c>();
            newTiers.add(tier);
            exsitingGroupTiers.put(tier.GTM_Group__c, newTiers);
        }
        Map<Id, Single_GTM_Group__c> groupIdMap = new Map<Id, Single_GTM_Group__c>();
        for(Single_GTM_Group__c existingGroup: existingGroups){
            for(GTM_Grouping__c aGroup: groups){
                if(existingGroup.GTM_Group__c == aGroup.Id){
                    groupIdMap.put(existingGroup.GTM_Group__c, existingGroup);
                }
            }
        }
        for(GTM_Grouping__c aGroup: groups){
            GroupItemWrapper newWrapper = new GroupItemWrapper();
            newWrapper.Name = aGroup.Name__c;
            newWrapper.productFamily = aGroup.Product_Family__c;
            newWrapper.type = aGroup.GTM_Group_Type__c;
            newWrapper.Id = aGroup.Id;
            if(groupIdMap.get(aGroup.Id) != null) newWrapper.singleId = groupIdMap.get(aGroup.Id).Id;
            List<QuantityTiers> quantityTiers = new List<QuantityTiers>();
            if( exsitingGroupTiers.get(aGroup.Id) != null){
                for(Single_GTM_Group_Tier__c tier: exsitingGroupTiers.get(aGroup.Id)){
                    QuantityTiers newTier = new QuantityTiers(tier);
                    quantityTiers.add(newTier);
                }
            }
            newWrapper.quantityTiers = quantityTiers;
            List<QuantityTiers> deT = new List<QuantityTiers>();
            if(aGroup.Default_Pricing_Tiers__r != null && !aGroup.Default_Pricing_Tiers__r.isEmpty()){
                for(Default_Pricing_Tier__c tier: aGroup.Default_Pricing_Tiers__r){
                    QuantityTiers newTier = new QuantityTiers(tier);
                    deT.add(newTier);
                }
            }
            if( exsitingGroupTiers.get(aGroup.Id) != null){
                for(Single_GTM_Group_Tier__c tier: exsitingGroupTiers.get(aGroup.Id)){
                   deT.add(new QuantityTiers(tier));
                }
            }
            newWrapper.deT = deT;
            wrappers.add(newWrapper);
        }
        return JSON.serialize(wrappers);
    }
    public Apttus__APTS_Agreement__c agreement {get; set;}
    public List<Single_BI_Discount__c> existingDiscounts {get; set;}
    public List<Single_GTM_Group__c> existingGroups {get; set;}
    public Map<Id, List<BI_Commit_Price__c>> discountPrices {get; set;}
    
    public List<String> commitFrequencies {get; set;}
    public List<String> paymentMethods {get; set;}
    public List<String> paymentFrequencies {get; set;}
    public List<String> termRanges {get; set;}
    
    public String paymentMethodsString {get; set;}
    public String paymentFrequenciesString {get; set;}
    public String termRangesString {get; set;}
    public Id skuGroupRecordTypeId {get; set;}
    public Id wirelessGroupRecordTypeId {get; set;}
    
    
    public NewBillableItemPickerCtrl(ApexPages.standardController stdCtrl){
        agreement = [SELECT Average_Monthly_Committed_Revenue__c FROM Apttus__APTS_Agreement__c WHERE Id=:stdCtrl.getRecord().Id];
        existingDiscounts = [SELECT Billable_Item__r.Max_Wireless_Discount__c, Quantity__c, Billable_Item__r.Requires_Quantity__c, Billable_Item__r.Monthly_Recurring_Charge__c, Account_Spend_Percentage__c, Billable_Item__r.Minimum_Support_Spend__c, Billable_Item__r.Percent_of_Spend_Pricing__c, Billable_Item__r.RecordType.Name, Agreement__c, Billable_Item__r.Always_Needs_Review__c,Billable_Item__r.Name, Billable_Item__r.Product_Family__c, Billable_Item__c, 
                                    Billable_Item__r.Territory__c,Billable_Item__r.Carrier_Fees__c, /*Billable_Item__r.Region__c,*/ Billable_Item__r.Price__c, Discount_Type__c, Min_Quantity__c,
                                    Round_Quantity__c, Billable_Item__r.Capable_of_Sub_Minute_Billing__c, Tier_Approval__c,
                                    Flat_Price__c, Percent_Off__c, GTM_Group__r.Name, GTM_Group__r.GTM_Group_Type__c, Product_Activation_Start_Date__c,
                                    (SELECT Commit_Min__c, Discount_Type__c, Flat_Price__c, Percent_Off__c FROM Approved_BI_Commit_Prices__r ORDER BY Commit_Min__c),
                                    (SELECT List_Price__c, Floor__c, Ceiling__c, Flat_Price__c, Needs_Approval__c, Monthly_Units_Purchased__c,
                                            Discount_Rate_Start_Date__c, Discount_Rate_End_Date__c FROM Single_BI_Tiers__r ORDER BY Floor__c)
                                    FROM Single_BI_Discount__c WHERE Agreement__c =:agreement.Id ORDER BY Billable_Item__r.Product_Family__c];
                                    
        Set<Id> biIds = new Set<Id>();
        existingGroups = [SELECT Id, GTM_Group__c FROM Single_GTM_Group__c WHERE Agreement__c =: agreement.Id];
        
        for(Single_BI_Discount__c discount: existingDiscounts){
            biIds.add(discount.Billable_Item__c);
        }
        skuGroupRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Single_BI_Discount__c' AND Name = 'Single SKU Discount'].Id;
        wirelessGroupRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Single_BI_Discount__c' AND Name = 'Single Wireless SKU Discount' LIMIT 1].Id;
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
        //generateBillableItems();
    }
    
    @RemoteAction
    public static void saveData(String dataString, String tierString, String groupString, String groupTierString, String agreementId, String agreement){
        List<Single_BI_Discount__c> oldDiscounts = [SELECT Billable_Item__c FROM Single_BI_Discount__c WHERE Agreement__c =: agreementId];
        List<Single_BI_Discount__c> discounts = (List<Single_BI_Discount__c>) JSON.deserialize(dataString, List<Single_BI_Discount__c>.class);
        List<Single_BI_Tier__c> tiers = (List<Single_BI_Tier__c>) JSON.deserialize(tierString, List<Single_BI_Tier__c>.class);
        List<Single_GTM_Group__c> groups = (List<Single_GTM_Group__c>) JSON.deserialize(groupString, List<Single_GTM_Group__c>.class);
        List<Single_GTM_Group__c> oldGroups = [SELECT GTM_Group__c FROM Single_GTM_Group__c WHERE Agreement__c =: agreementId];
        List<Single_GTM_Group_Tier__c> groupTiers = (List<Single_GTM_Group_Tier__c>) JSON.deserialize(groupTierString, List<Single_GTM_Group_Tier__c>.class);
        List<Single_GTM_Group_Tier__c> existingGroupTiers = [SELECT Id FROM Single_GTM_Group_Tier__c WHERE Agreement__c=: agreementId];
        
        List<Single_BI_Tier__c> exsitingTiers = [SELECT Id FROM Single_BI_Tier__c WHERE Agreement__c =: agreementId];
        Apttus__APTS_Agreement__c updateAgreement = (Apttus__APTS_Agreement__c) JSON.deserialize(agreement, Apttus__APTS_Agreement__c.class);
        updateAgreement.Id = agreementId;
        Savepoint sp = Database.setSavepoint();
        for(Integer i = oldDiscounts.size() - 1; i >= 0; i--){
            for(Single_BI_Discount__c discount: discounts){
                if(discount.Billable_Item__c != null && discount.Billable_Item__c == oldDiscounts[i].Billable_Item__c){
                    discount.Id = oldDiscounts[i].Id;
                    oldDiscounts.remove(i);
                    break;
                }
            }
        }
        for(Integer i = oldGroups.size() - 1; i >= 0; i--){
            for(Single_GTM_Group__c aGroup: groups){
                if(aGroup.GTM_Group__c != null && aGroup.GTM_Group__c == oldGroups[i].GTM_Group__c){
                    aGroup.Id = oldGroups[i].Id;
                    oldGroups.remove(i);
                    break;
                }
            }
        }
        try{
            delete oldGroups;
            upsert groups;
            for(Single_GTM_Group__c aGroup: groups){
                for(Single_BI_Discount__c discount: discounts){
                    if(discount.GTM_Group__c == aGroup.GTM_Group__c){
                        discount.Single_GTM_Group__c = aGroup.Id;
                    }
                }
            }
            delete oldDiscounts;
            upsert discounts;
            List<Single_BI_Discount__c> carrierFeeDiscounts = [SELECT GTM_Group__c, Carrier_Fees_Apply__c FROM Single_BI_Discount__c WHERE Id =: discounts];
            List<Single_GTM_Group_Tier__c> upsertGroupTiers = new List<Single_GTM_Group_Tier__c>();
            Map<Id, Single_GTM_Group_Tier__c> existingGroupIds = new Map<Id, Single_GTM_Group_Tier__c>();
            for(Single_GTM_Group_Tier__c tier: existingGroupTiers){
                existingGroupIds.put(tier.Id, tier);
            }
            for(Single_GTM_Group__c aGroup: groups){
                Boolean applyCarrierFee = true;
                for(Single_BI_Discount__c discount: carrierFeeDiscounts){
                    if(discount.GTM_Group__c == aGroup.GTM_Group__c && !discount.Carrier_Fees_Apply__c){
                        applyCarrierFee = false;
                        break;
                    }
                }
                for(Single_GTM_Group_Tier__c tier: groupTiers){
                    if(tier.GTM_Group__c == aGroup.GTM_Group__c){
                        tier.Single_GTM_Group__c = aGroup.Id;
                        tier.Carrier_Fees_Apply__c = applyCarrierFee;
                        upsertGroupTiers.add(tier);
                    }
                    if(tier.Id != null && existingGroupIds.containsKey(tier.Id)){
                        existingGroupIds.remove(tier.Id);
                    }
                }
            }
            delete existingGroupIds.values();
            upsert upsertGroupTiers;
            List<Single_BI_Tier__c> upsertTiers = new List<Single_BI_Tier__c>();
            Map<Id, Single_BI_Tier__c> existingIds = new Map<Id, Single_BI_Tier__c>();
            for(Single_BI_Tier__c tier: exsitingTiers){
                existingIds.put(tier.Id, tier);
            }
            for(Single_BI_Discount__c discount: discounts){
                for(Single_BI_Tier__c tier: tiers){
                    if(tier.Billable_Item__c == discount.Billable_Item__c){
                        tier.Single_BI_Discount__c = discount.Id;
                        upsertTiers.add(tier);
                    }
                    if(tier.Id != null && existingIds.containsKey(tier.Id)){
                        existingIds.remove(tier.Id);
                    }
                }
            }
            delete existingIds.values();
            upsert upsertTiers;
            update updateAgreement;
        }
        catch(DMLException e){
            Database.rollback(sp);
            throw new ErrorException(e.getMessage());
        }
    }
    
    public String getExistingItems(){
        List<BillableItemWrapper> wrappers = new List<BillableItemWrapper>();
        for(Single_BI_Discount__c discount: existingDiscounts){
           BillableItemWrapper newWrapper = new BillableItemWrapper(); 
           newWrapper.tierPricing = discount.Billable_Item__r.Always_Needs_Review__c;
           newWrapper.mc = discount.Billable_Item__r.Monthly_Recurring_Charge__c;
           newWrapper.Id = discount.Billable_Item__c;
           newWrapper.Name = discount.Billable_Item__r.Name;
           newWrapper.Country = discount.Billable_Item__r.Territory__c;
           newWrapper.rq = discount.Billable_Item__r.Requires_Quantity__c;
           newWrapper.mp = discount.Billable_Item__r.Max_Wireless_Discount__c;
           //newWrapper.Region = discount.Billable_Item__r.Region__c;
           newWrapper.productFamily = discount.Billable_Item__r.Percent_of_Spend_Pricing__c ? 'Support 18' : discount.Billable_Item__r.Product_Family__c;
           newWrapper.listPrice = discount.Billable_Item__r.Carrier_Fees__c == null ? discount.Billable_Item__r.Price__c :discount.Billable_Item__r.Price__c - discount.Billable_Item__r.Carrier_Fees__c;
           newWrapper.percentDiscount = discount.Discount_Type__c == 'Percent' || discount.Billable_Item__r.RecordType.Name == 'SKU Group' || discount.Billable_Item__r.RecordType.Name == 'Wireless SKU Group';
           newWrapper.du = discount.Min_Quantity__c;
           newWrapper.inc = discount.Round_Quantity__c;
           newWrapper.mip = discount.Billable_Item__r.Capable_of_Sub_Minute_Billing__c;
           newWrapper.ta = discount.Tier_Approval__c;
           newWrapper.rtn = discount.Billable_Item__r.RecordType.Name;
           newWrapper.minPrice = discount.Billable_Item__r.Percent_of_Spend_Pricing__c ? discount.Billable_Item__r.Minimum_Support_Spend__c : null;
           newWrapper.poa = discount.Billable_Item__r.Percent_of_Spend_Pricing__c ? discount.Account_Spend_Percentage__c : null;
           newWrapper.sd = discount.Product_Activation_Start_Date__c;
           newWrapper.q = discount.Quantity__c;
           List<diT> tiers = new List<diT>();
           List<BI_Commit_Price__c> prices = discountPrices.get(discount.Billable_Item__c);
           if(prices != null && !prices.isEmpty()){
                for(BI_Commit_Price__c price: prices){
                    diT newTier = new diT(price);
                    tiers.add(newTier);
                }
           }
           List<Approved_BI_Commit_Price__c> exceptionPrices = discount.Approved_BI_Commit_Prices__r;
           if(exceptionPrices != null){
               for(Approved_BI_Commit_Price__c exceptionPrice: exceptionPrices){
                   Boolean percentDiscount = exceptionPrice.Discount_Type__c == 'Percent';
                   BI_Commit_Price__c exceptionCommitPrice = new BI_Commit_Price__c(Min_Commit_Floor__c = exceptionPrice.Commit_Min__c, Discount_Type__c = exceptionPrice.Discount_Type__c, Flat_Price__c = exceptionPrice.Flat_Price__c, Percent_Off__c = exceptionPrice.Percent_Off__c);
                   Boolean inserted = false;
                   Decimal exceptionPriceNumber = null;
                   Integer insertIndex = -1;
                   for(Integer i = 0; i < tiers.size(); i++){
                       diT tier = tiers[i];
                       if(tier.percentDiscount == percentDiscount && !inserted){
                           if(tier.floor == exceptionPrice.Commit_Min__c){
                               tier.flatPrice = exceptionPrice.Flat_Price__c;
                               tier.percent = exceptionPrice.Percent_Off__c;
                               exceptionPriceNumber = percentDiscount ? exceptionPrice.Percent_Off__c : exceptionPrice.Flat_Price__c;
                               inserted = true;
                           }
                           else if(tier.floor < exceptionPrice.Commit_Min__c && tier.ceiling > exceptionPrice.Commit_Min__c){
                               exceptionCommitPrice.Min_Commit_Ceiling__c = tier.ceiling;
                               tier.ceiling = exceptionPrice.Commit_Min__c;
                               insertIndex = i+1;
                               exceptionPriceNumber = percentDiscount ? exceptionPrice.Percent_Off__c : exceptionPrice.Flat_Price__c;
                               inserted = true;
                           }
                           else if(tier.floor > exceptionPrice.Commit_Min__c && i == 0){
                               exceptionCommitPrice.Min_Commit_Ceiling__c = tier.floor;
                               insertIndex = 0;
                               exceptionPriceNumber = percentDiscount ? exceptionPrice.Percent_Off__c : exceptionPrice.Flat_Price__c;
                               if(tier.floor >= exceptionPrice.Commit_Min__c){
                                   if(percentDiscount && exceptionPriceNumber > tier.percent){
                                       tier.percent = exceptionPriceNumber;
                                   }
                                   else if(!percentDiscount && exceptionPriceNumber < tier.flatPrice){
                                       tier.flatPrice = exceptionPriceNumber;
                                   }
                               }
                               inserted = true;
                           }
                       }
                       else if(tier.percentDiscount == percentDiscount && inserted && exceptionPriceNumber != null){
                           if(tier.floor >= exceptionPrice.Commit_Min__c){
                               if(percentDiscount && exceptionPriceNumber > tier.percent){
                                   tier.percent = exceptionPriceNumber;
                               }
                               else if(!percentDiscount && exceptionPriceNumber < tier.flatPrice){
                                   tier.flatPrice = exceptionPriceNumber;
                               }
                           }
                       }
                   }
                   if(!inserted){
            
                       if(!tiers.isEmpty() && tiers[tiers.size() - 1].percentDiscount == percentDiscount && exceptionPrice.Commit_Min__c > tiers[tiers.size() - 1].floor){
                          tiers[tiers.size() - 1].ceiling = exceptionPrice.Commit_Min__c;
                       }
                       tiers.add(new diT(exceptionCommitPrice));
                   }
                   else if(insertIndex != -1){
                       tiers.add(insertIndex, new diT(exceptionCommitPrice));
                   }
               }
           }
           List<QuantityTiers> quantityTiers = new List<QuantityTiers>();
           if(discount.Single_BI_Tiers__r != null && !discount.Single_BI_Tiers__r.isEmpty()){
              for(Single_BI_Tier__c tier: discount.Single_BI_Tiers__r){
                QuantityTiers newTier = new QuantityTiers(tier);
                quantityTiers.add(newTier);
              }
            }
           newWrapper.diT = tiers;
           newWrapper.quantityTiers = quantityTiers;
           if(discount.GTM_Group__r.Name != null){
                newWrapper.groupName = discount.GTM_Group__r.Name;
                newWrapper.groupType = discount.GTM_Group__r.GTM_Group_Type__c;
           }
           else{
                newWrapper.groupName = 'NO GROUP';
                newWrapper.groupType = '';
           }
           newWrapper.discount = discount.Flat_Price__c;
           newWrapper.percent = discount.Percent_Off__c;
           wrappers.add(newWrapper);
        }
        return JSON.serialize(wrappers);
    }
    
    public String getBillableItems(){
      
        List<Billable_Item__c> items = [SELECT RecordType.Name, Max_Wireless_Discount__c, Carrier_Fees__c, Requires_Quantity__c, Monthly_Recurring_Charge__c, Minimum_Support_Spend__c, Percent_of_Spend_Pricing__c, Always_Needs_Review__c, Name, Product_Family__c, Territory__c, Discount_Type__c, /*Region__c,*/ Product__c, Price__c, Capable_of_Sub_Minute_Billing__c,
                                            (SELECT GTM_Group__r.Name__c, GTM_Group__r.GTM_Group_Type__c FROM GTM_Group_Billable_Items__r),
                                            (SELECT Discount_Type__c, Flat_Price__c, Min_Commit_Ceiling__c, Min_Commit_Floor__c, Percent_Off__c FROM BI_Commit_Prices__r ORDER BY Min_Commit_Floor__c),
                                            (SELECT Tier_Floor__c, Tier_Ceiling__c, Flat_Price__c FROM Default_Tiers__r ORDER BY Tier_Floor__c)
                                        FROM Billable_Item__c 
                                        WHERE Product_Family__c != null 
                                        AND Status__c = 'ACTIVE'
                                        AND Hidden_in_Billable_Item_Manager__c = false
                                        ORDER BY Name];
        List<BillableItemWrapper> wrappers = new List<BillableItemWrapper>();
        
        for(Billable_Item__c item: items){
            BillableItemWrapper newWrapper = new BillableItemWrapper();
            newWrapper.Id = item.Id;
            newWrapper.rq = item.Requires_Quantity__c;
            newWrapper.Name = item.Name;
            newWrapper.Country = item.Territory__c;
            newWrapper.mc = item.Monthly_Recurring_Charge__c;
            newWrapper.mp = item.Max_Wireless_Discount__c;
            //newWrapper.Region = item.Region__c;
            newWrapper.mip = item.Capable_of_Sub_Minute_Billing__c;
            newWrapper.productFamily = item.Percent_of_Spend_Pricing__c ? 'Support 18' : item.Product_Family__c;
            newWrapper.tierPricing = item.Always_Needs_Review__c;
            newWrapper.ta = false;
            newWrapper.rtn = item.RecordType.Name;
            newWrapper.minPrice = item.Percent_of_Spend_Pricing__c ? item.Minimum_Support_Spend__c : null;
            newWrapper.poa = item.Percent_of_Spend_Pricing__c ? item.Price__c * 100 : null;
            if(item.GTM_Group_Billable_Items__r != null && !item.GTM_Group_Billable_Items__r.isEmpty() && item.GTM_Group_Billable_Items__r[0].GTM_Group__r.Name__c != null){
                newWrapper.GroupName = item.GTM_Group_Billable_Items__r[0].GTM_Group__r.Name__c;
                newWrapper.groupType = item.GTM_Group_Billable_Items__r[0].GTM_Group__r.GTM_Group_Type__c;
            }
            else{
                newWrapper.GroupName = 'NO GROUP';
                newWrapper.groupType = '';
            }
            List<diT> tiers = new List<diT>();
            if(item.BI_Commit_Prices__r != null && !item.BI_Commit_Prices__r.isEmpty()){
                for(BI_Commit_Price__c price: item.BI_Commit_Prices__r){
                    diT newTier = new diT(price);
                    tiers.add(newTier);
                }
            }
            List<QuantityTiers> quantityTiers = new List<QuantityTiers>();
            if(item.Default_Tiers__r != null && !item.Default_Tiers__r.isEmpty()){
                for(Default_Pricing_Tier__c tier: item.Default_Tiers__r){
                    QuantityTiers newTier = new QuantityTiers(tier);
                    quantityTiers.add(newTier);
                }
            }
            newWrapper.diT = tiers;
            newWrapper.deT = quantityTiers;
            newWrapper.listPrice = item.Carrier_Fees__c == null ? item.Price__c : item.Price__c - item.Carrier_Fees__c;
            newWrapper.percentDiscount = item.Discount_Type__c == 'Percent' || item.RecordType.Name == 'SKU Group' || item.RecordType.Name == 'Wireless SKU Group';
            //if(agreement.Average_Monthly_Committed_Revenue__c == null || agreement.Average_Monthly_Committed_Revenue__c < 1000){
            newWrapper.discount = newWrapper.listPrice;
            newWrapper.percent = 0;
            newWrapper.du = 0;
            newWrapper.inc = 0;
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
        String result = JSON.serialize(wrappers);
        return result;
    }
    
}