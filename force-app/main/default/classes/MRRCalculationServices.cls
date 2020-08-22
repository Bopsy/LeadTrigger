public without sharing class MRRCalculationServices {
    
    public static final String LAST_6_MONTHS_STR = 'Last 3 Months Avg MRR';
    public static final String LAST_MONTH_STR = 'Last Month Usage (Rolling)';
    static Boolean bypassTrigger = false;
    
    public static void updateProductSchedule(List<Account_SID_SKU__c> skus, Map<Id, Account_SID_SKU__c> skuMap){
        
        Set<Id> filteredIds = new Set<Id>();
        
        for(Account_SID_SKU__c sku: skus){
            Account_SID_SKU__c oldSKU = skuMap.get(sku.Id);
            if(oldSku == null || sku.MRR_Final__c != oldSKU.MRR_Final__c){
                filteredIds.add(sku.New_Business_Opportunity__c);
            }
        }
        
        update [SELECT Id FROM Product_Schedule__c WHERE Forecast_Schedule__r.Opportunity__c =: filteredIds];
    }
    
    public static void populateOppSIDSKU(List<Account_SID_SKU__c> skus){
        Set<Id> oppIds = new Set<Id>();
        Set<Id> sidIds = new Set<Id>();
        Map<String, Id> oppSkuMap = new Map<String, Id>();
        List<Account_SID_SKU__c> filteredSkus = new List<Account_SID_SKU__c>();
        
        for(Account_SID_SKU__c sku: skus){
            if(sku.Opp_SID_SKU__c == null){
                filteredSkus.add(sku);oppIds.add(sku.New_Business_Opportunity__c);sidIds.add(sku.Account_SID__c);
            }
        }
        
        List<Opp_SID_SKU__c> oppSkus = [SELECT Opportunity__c, Account_SID__c FROM Opp_SID_SKU__c WHERE Opportunity__c =: oppIds AND Account_SID__c =: sidIds];
        
        for(Opp_SID_SKU__c sku: oppSkus){
            oppSkuMap.put(sku.Opportunity__c + '-' + sku.Account_SID__c, sku.Id);
        }
        
        for(Account_SID_SKU__c sku: filteredSkus){
            sku.Opp_SID_SKU__c = oppSkuMap.get(sku.New_Business_Opportunity__c + '-' + sku.Account_SID__c);
        }
    }
   
    public static void afterUpdateOpportunity(List<Opportunity> opps, Map<Id, Opportunity> oldMap){
        Set<Id> filteredId = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        
        for(Opportunity opp: opps){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(oldOpp.Launch_Date__c != opp.Launch_Date__c){
                filteredId.add(opp.Id);
            }
            //if(oldOpp.StageName != opp.StageName){
            //    accIds.add(opp.AccountId);
            //}
        }
        
        //for(Opportunity opp: [SELECT Id FROM Opportunity WHERE StageName != 'Closed Won' AND AccountId =: accIds]){
        //    filteredId.add(opp.Id);
        //}
        
        if(filteredId.isEmpty()) return;
        
        List<Account_SID_SKU__c> skus = [SELECT Product_Name__c, Launch_Date__c, Account_SID__c, Running_Added_Date__c FROM Account_SID_SKU__c WHERE New_Business_Opportunity__c =: filteredId];
        
        //beforeInsert(skus, true, false);
        //bypassTrigger = false;
        recalculateNBAccountSIDDate(skus);
    }
    
    public static void afterUpdateOppSIDSKUs(List<Opp_SID_SKU__c> oppSkus, Map<Id, Opp_SID_SKU__c> oldMap){
        Set<Id> filteredId = new Set<Id>();
        
        for(Opp_SID_SKU__c oppSku: oppSkus){
            Opp_SID_SKU__c oldRec = oldMap.get(oppSku.Id);
            if(oppSku.Opp_SID_Added_Date__c != oldRec.Opp_SID_Added_Date__c){
                filteredId.add(oppSku.Id);
            }
        }
        
        List<Account_SID_SKU__c> accSkus = [SELECT Opp_SID_SKU__c, Account_SID_Added_Date__c, Product_Name__c, Launch_Date__c, Account_SID__c, Running_Added_Date__c FROM Account_SID_SKU__c WHERE Opp_SID_SKU__c =: filteredId];
        
        recalculateNBAccountSIDDate(accSkus);
    }
    
    public static void recalculateNBAccountSIDDate(List<Account_SID_SKU__c> skus){
        if(bypassTrigger) return;
        
        
        skus = [SELECT Account_SID__c, Product_Name__c, Opp_SID_SKU__c, Account_SID_Added_Date__c,Running_Added_Date__c  FROM Account_SID_SKU__c WHERE Id = :skus];
        Map<Id, Id> accountSidMap = new Map<Id, Id>();
        Map<Id, List<Twilio_Usage__c>> usageMap = new Map<Id, List<Twilio_Usage__c>>();
        Map<String, AccountSID_to_SKU_Mappings__c> settingMap = new Map<String, AccountSID_to_SKU_Mappings__c>();
        
        for(Account_SID_SKU__c sku: skus){
            accountSidMap.put(sku.Id, sku.Account_SID__c);
        }
        
        String queryString = 'SELECT Month__c, Year__c, Related_Account_SID__c';
        
        for(AccountSID_to_SKU_Mappings__c setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
            if(setting.Year__c == 2018 && !setting.SendGrid_Product__c){
                if(setting.Usage_Field__c != null){
                    queryString += ' ,' + setting.Usage_Field__c;
                }
                settingMap.put(setting.Product_Name__c, setting);
            }
        }
        
        List<Id> sidIds = accountSidMap.values();
        queryString += ' FROM Twilio_Usage__c WHERE Related_Account_SID__c =: sidIds';
        
        List<Twilio_Usage__c> usages = database.query(queryString);
        
        for(Twilio_Usage__c usage: usages){
            List<Twilio_Usage__c> usageList = usageMap.get(usage.Related_Account_SID__c);
            if(usageList == null) usageList = new List<Twilio_Usage__c>();
            usageList.add(usage);
            usageMap.put(usage.Related_Account_SID__c, usageList);
        }
        
        Map<Id, Opp_SID_SKU__c> oppSkuMap = new Map<Id, Opp_SID_SKU__c>();
        
        for(Account_SID_SKU__c sku: skus){
            Id accountSidId = accountSidMap.get(sku.Id);
            String productName = sku.Product_Name__c;
            AccountSID_to_SKU_Mappings__c setting = settingMap.get(productName);
            Boolean oppSkuCalculated = oppSkuMap.containsKey(sku.Opp_SID_SKU__c);
            Decimal lastMonthUsage = 0;
            Decimal runningUsage = 0;
            Decimal mrr = 0;
            Decimal newMrr = 0;
            if(accountSidId != null && !oppSkuCalculated && sku.Opp_SID_SKU__c != null){
                List<Twilio_Usage__c> usageList = usageMap.get(accountSidId);
                Date nbAddedDate = sku.Account_SID_Added_Date__c;
                Date runningDate = sku.Running_Added_Date__c;
                Opp_SID_SKU__c oppSku = new Opp_SID_SKU__c(Id = sku.Opp_SID_SKU__c);
                for(AccountSID_to_SKU_Mappings__c aSetting: settingMap.values()){
                    oppSku.put(aSetting.Opp_SKU_Field__c, 0);                    
                }
                Map<String, Decimal> mrrMap = new Map<String, Decimal>();
                Map<String, Decimal> newMrrMap = new Map<String, Decimal>();
                Map<String, Decimal> monthMap = new Map<String, Decimal>();
                Map<String, Decimal> newMonthMap = new Map<String, Decimal>();
                if(usageList != null && !usageList.isEmpty()){
                    for(Twilio_Usage__c usage: usageList){
                        Date usageDate = Date.newInstance((Integer) usage.Year__c, (Integer) usage.Month__c, 1);
                        //if(usageDate.addMonths(7) > nbAddedDate && usageDate.addMonths(1) <= nbAddedDate){
                        //    for(AccountSID_to_SKU_Mappings__c aSetting: settingMap.values()){
                        //        Decimal oppSkuMrr = mrrMap.get(aSetting.Opp_SKU_Field__c);
                        //        Decimal monthNumber = monthMap.get(aSetting.Opp_SKU_Field__c);
                        //        if(monthNumber == null) monthNumber = 0;
                        //        if(oppSkuMrr == null) oppSkuMrr = 0;
                                
                        //        oppSkuMrr += (Decimal) (usage.get(aSetting.Usage_Field__c) == null ? 0 : usage.get(aSetting.Usage_Field__c));
                        //        monthNumber++;
                        //        mrrMap.put(aSetting.Opp_SKU_Field__c, oppSkuMrr);
                        //        monthMap.put(aSetting.Opp_SKU_Field__c, monthNumber);
                        //    }
                        //}
                        if(usageDate.addMonths(4) > nbAddedDate && usageDate.addMonths(1) <= nbAddedDate){
                            for(AccountSID_to_SKU_Mappings__c aSetting: settingMap.values()){
                                Decimal oppSkuMrr = newMrrMap.get(aSetting.Opp_SKU_Field__c);
                                Decimal monthNumber = newMonthMap.get(aSetting.Opp_SKU_Field__c);
                                if(monthNumber == null) monthNumber = 0;
                                if(oppSkuMrr == null) oppSkuMrr = 0;
                                
                                oppSkuMrr += (Decimal) (usage.get(aSetting.Usage_Field__c) == null ? 0 : usage.get(aSetting.Usage_Field__c));
                                monthNumber++;
                                newMrrMap.put(aSetting.Opp_SKU_Field__c, oppSkuMrr);
                                newMonthMap.put(aSetting.Opp_SKU_Field__c, monthNumber);
                            }
                        }
                    }
                }
                for(String oppSkuField: newMrrMap.keySet()){
                    Decimal oppSkuMrr = newMrrMap.get(oppSkuField) / newMonthMap.get(oppSkuField);
                    oppSku.put(oppSkuField, oppSkuMrr);
                }
                oppSkuMap.put(oppSku.Id, oppSku);
            }
            if(accountSidId != null && setting != null){
                List<Twilio_Usage__c> usageList = usageMap.get(accountSidId);
                Date nbAddedDate = sku.Account_SID_Added_Date__c;
                Date runningDate = sku.Running_Added_Date__c;
                Integer monthNumber = 0;
                Integer newMonthNumber = 0;
                if(usageList != null && !usageList.isEmpty()){
                    for(Twilio_Usage__c usage: usageList){
                        Date usageDate = Date.newInstance((Integer) usage.Year__c, (Integer) usage.Month__c, 1);
                        Decimal usageNumber = (Decimal) usage.get(setting.Usage_Field__c);
                        usageNumber = usageNumber == null ? 0 : usageNumber;
                        if(usageDate.addMonths(7) > nbAddedDate && usageDate.addMonths(1) <= nbAddedDate){
                            mrr += usageNumber;
                            if(usageDate.addMonths(4) > nbAddedDate && usageDate.addMonths(1) <= nbAddedDate){
                                newMrr += usageNumber;if(!(usageNumber == 0 && newMonthNumber == 0)) newMonthNumber++;
                            }
                            if(!(usageNumber == 0 && monthNumber == 0)) monthNumber++;
                            if(usageDate.addMonths(2) > nbAddedDate){
                                lastMonthUsage = usageNumber;
                            }
                        }
                        if(usageDate.addMonths(2) > runningDate &&  usageDate.addMonths(1) <= runningDate){
                            runningUsage = usageNumber;
                        }
                    }
                    if(monthNumber > 0) mrr = mrr / monthNumber;
                    if(newMonthNumber > 0) newMrr = newMrr / newMonthNumber;
                }
            }
            sku.MRR__c = mrr;
            sku.Last_Month_Usage_Rolling__c = runningUsage;
            sku.Last_Month_Usage__c = lastMonthUsage;
            sku.Three_Months_MRR__c = newMrr;
        }
        
        update oppSkuMap.values();
        update skus;
        bypassTrigger = true;
    }
    
    public static void beforeInsert(List<Account_SID_SKU__c> skus, Boolean forceUpdate, Boolean bypass){
        
        Map<String, Account_SID_SKU__c> skuMaps = new Map<String, Account_SID_SKU__c>();
        Set<Id> sidIds = new Set<Id>();
        Set<String> productNames = new Set<String>();
        Set<Id> skuIds = new Set<Id>();
        
        for(Account_SID_SKU__c sku: skus){
            skuMaps.put(sku.Account_SID__c + '-' + sku.Product_Name__c, sku);
            sidIds.add(sku.Account_SID__c);
            productNames.add(sku.Product_Name__c);
            if(sku.Id != null) skuIds.add(sku.Id);
        }
        
        List<Account_SID_SKU__c> existingSKUs = [SELECT Launch_Date__c, New_Business_Opportunity__r.Contract_Terms_Months__c, Product_Name__c, Account_SID__c FROM Account_SID_SKU__c WHERE Account_SID__c =: sidIds AND New_Business_Opportunity__r.StageName = 'Closed Won' AND Product_Name__c =: productNames AND Id !=: skuIds];
        
        Map<String, Boolean> skuMRRChoiceMap = new Map<String, Boolean>();
        
        for(Account_SID_SKU__c existingSKU: existingSKUs){
            String keyString = existingSKU.Account_SID__c + '-' + existingSKU.Product_Name__c;
            Integer monthNumber = (Integer) existingSKU.New_Business_Opportunity__r.Contract_Terms_Months__c;
            if(monthNumber == null || monthNumber == 0) monthNumber = 1;
            if(monthNumber > 12) monthNumber = 12;
            Account_SID_SKU__c newRec = skuMaps.get(keyString);
            if(newRec != null && existingSKU.Launch_Date__c != null){
                Boolean choice = skuMRRChoiceMap.get(keyString);
                Date newLaunchDate = newRec.Account_SID_Added_Date__c;
                Date oldLaunchDate = existingSKU.Launch_Date__c;
                if(oldLaunchDate.addMonths(monthNumber) > newLaunchDate && oldLaunchDate <= newLaunchDate){
                    skuMRRChoiceMap.put(keyString, true);
                }
                else{
                    if(choice == null || choice != true){
                        skuMRRChoiceMap.put(keyString, false);
                    }
                }
            }
        }
        
        List<AccountSID_to_SKU_Mappings__c> settings = AccountSID_to_SKU_Mappings__c.getAll().values();
        Map<String, AccountSID_to_SKU_Mappings__c> settingMap = new Map<String, AccountSID_to_SKU_Mappings__c>();
        String queryString = 'SELECT Id';
        
        for(AccountSID_to_SKU_Mappings__c setting: settings){
            if(setting.Year__c == 2018 && !setting.SendGrid_Product__c){
                if(setting.Account_SID_API_Name__c != null){
                    queryString += ' ,' + setting.Account_SID_API_Name__c;
                }
                if(setting.SID_Last_Month_Usage_Field__c != null){
                   queryString += ' ,' + setting.SID_Last_Month_Usage_Field__c;
                }
                settingMap.put(setting.Product_Name__c, setting);
            }
        }
        
        queryString += ' FROM Account_SID__c WHERE Id =: sidIds';
        
        List<Account_SID__c> sids = database.query(queryString);
        
        Map<Id, Account_SID__c> sidMap = new Map<Id, Account_SID__c>(sids);
        
        for(Account_SID_SKU__c sku: skus){
            String keyString = sku.Account_SID__c + '-' + sku.Product_Name__c;
            Boolean mrrChoice = skuMRRChoiceMap.get(keyString);
            if(mrrChoice == null) mrrChoice = false;
            sku.MRR_Choice__c = mrrChoice ? LAST_MONTH_STR : LAST_6_MONTHS_STR;
            Account_SID__c sid = sidMap.get(sku.Account_SID__c);
            if(sid != null){
                AccountSID_to_SKU_Mappings__c setting = settingMap.get(sku.Product_Name__c);
                if(setting != null){
                    String lastMonthStr = setting.SID_Last_Month_Usage_Field__c;
                    String avgMonthStr = setting.Account_SID_API_Name__c;
                    if(avgMonthStr != null) sku.Three_Months_MRR__c = (Decimal) sid.get(avgMonthStr);
                    if(lastMonthStr != null) sku.Last_Month_Usage_Rolling__c = (Decimal) sid.get(lastMonthStr);
                }
            }
        }
        
        if(forceUpdate) update skus;
        if(bypass) bypassTrigger = true; 
        
    }
}