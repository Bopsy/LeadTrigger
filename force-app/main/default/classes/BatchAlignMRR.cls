global class BatchAlignMRR implements Database.Batchable<SObject>, Schedulable{
    
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchAlignMRR(), 50);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        DateTime lastModifiedDate = Datetime.now().addHours(-12);
        if(Test.isRunningTest()) lastModifiedDate = Datetime.now().addHours(12);
        return Database.getQueryLocator('SELECT Id, Product_Name__c, Launch_Date__c, Account_SID_Added_Date__c, Account_SID__c, Running_Added_Date__c FROM Account_SID_SKU__c WHERE New_Business_Opportunity__r.CloseDate >= 2020-01-01 AND MRR_Baseline_Override__c = null AND New_Business_Opportunity__r.IsClosed = false AND LastModifiedDate < :lastModifiedDate');
    }
    
    global void execute(Database.BatchableContext bc, List<Account_SID_SKU__c> skus){
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
            if(monthNumber == null || monthNumber == 0) monthNumber = 1;if(monthNumber > 12) monthNumber = 12;
            Account_SID_SKU__c newRec = skuMaps.get(keyString);
            if(newRec != null && existingSKU.Launch_Date__c != null){Boolean choice = skuMRRChoiceMap.get(keyString);Date newLaunchDate = newRec.Account_SID_Added_Date__c;Date oldLaunchDate = existingSKU.Launch_Date__c;
                if(oldLaunchDate.addMonths(monthNumber) > newLaunchDate && oldLaunchDate <= newLaunchDate){ skuMRRChoiceMap.put(keyString, true);}
                else{if(choice == null || choice != true){skuMRRChoiceMap.put(keyString, false);}}
            }
        }
        for(Account_SID_SKU__c sku: skus){
            String keyString = sku.Account_SID__c + '-' + sku.Product_Name__c;Boolean mrrChoice = skuMRRChoiceMap.get(keyString);if(mrrChoice == null) mrrChoice = false;sku.MRR_Choice__c = mrrChoice ? 'Last Month Usage (Rolling)' : 'Last 3 Months Avg MRR';
        }
        update skus;
        skus = [SELECT Id FROM Account_SID_SKU__c WHERE Id =: skus];
        MRRCalculationServices.recalculateNBAccountSIDDate(skus);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}