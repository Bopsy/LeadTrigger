global without sharing class BatchPopulateCrossSell implements Database.Batchable<SObject>, Schedulable, Database.Stateful{
    
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchPopulateCrossSell(), 200);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accounts){
        
        accounts = [SELECT Id, (SELECT Product_Name__c FROM Account_X_Sells__r) FROM Account WHERE Id =: accounts];
        List<Account_X_Sells__c> insertxsells = new List<Account_X_Sells__c>();
        
        Set<String> productNames = new Set<String>();
        
        for(AccountSID_to_SKU_Mappings__c setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
           if(setting.Year__c == 2018 && setting.Product_Name__c != 'Long Code Carrier Fees'){
               productNames.add(setting.Product_Name__c);
           }
        }
        for(Account acc: accounts){
           Set<String> accProds = productNames.clone();
           for(Account_X_Sells__c xsell: acc.Account_X_sells__r){
              if(accProds.contains(xsell.Product_Name__c)){accProds.remove(xsell.Product_Name__c);}
           }
           for(String prodName: accProds){
               Account_X_Sells__c newXsell = new Account_X_Sells__c(Account__c = acc.Id, Product_Name__c = prodName, MRR__c = 0, Eligibility__c = true, No_Usage_on_Product__c = true);
               insertxsells.add(newXsell);
           }
        }
        
        insert insertxsells;

    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}