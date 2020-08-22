trigger OpportunityProductAfterTrigger on Opportunity_Product__c (before insert, before update, after insert, after update, after delete, after undelete) {
  public static Map<String, Boolean> softwareProductMap{
     get{
         if(softwareProductMap == null){
             softwareProductMap = new Map<String, Boolean>();
             for(AccountSID_to_SKU_Mappings__c setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
                 if(setting.Year__c == 2018){
                     softwareProductMap.put(setting.Product_Name__c, setting.Software_Product__c);
                     sgProductMap.put(setting.Product_Name__c, setting.SendGrid_Product__c);
                 }
             }
         }
         return softwareProductMap;
     }
     set;
  }
  
  public static Map<String, Boolean> sgProductMap = new Map<String, Boolean>();
  if(Trigger.isAfter){
      if ( Trigger.isInsert) {
          OpportunitySKUHandler.createSKUs(trigger.newMap);
      }
  }
  else{
      if(Trigger.isInsert || Trigger.isUpdate){
          Set<Id> accountIds = new Set<Id>();
          Set<String> productNames = new Set<String>();
          List<Opportunity_Product__c> prods = new List<Opportunity_Product__c>();
          for(Opportunity_Product__c prod: trigger.new){
              if(softwareProductMap.get(prod.Product_Name__c) != null){
                  prod.Software_Product__c = softwareProductMap.get(prod.Product_Name__c);
              }
              if(sgProductMap.get(prod.Product_Name__c) != null){
                  prod.SendGrid_Product__c = sgProductMap.get(prod.Product_Name__c);
              }
              Opportunity_Product__c oldProd = null;
              if(trigger.isUpdate){
                oldProd = trigger.oldMap.get(prod.Id);
              }
              if(trigger.isInsert || (trigger.isUpdate && (oldProd.Product_Name__c != prod.Product_Name__c || prod.Account_Cross_Sell__c == null))){
                  prods.add(prod);
                  accountIds.add(prod.Account_ID__c);
                  productNames.add(prod.Product_Name__c);
              }
          }
          Map<String, Id> xsellMap = new Map<String, Id>();
          List<Opportunity_Product__c> updateProds = new List<Opportunity_Product__c>();
          for(Account_X_sells__c xsell: [SELECT Id, Product_Name__c, Account__c FROM Account_X_sells__c WHERE Account__c =: accountIds AND Product_Name__c =: productNames]){
              xsellMap.put(xsell.Account__c + '-' + xsell.Product_Name__c, xsell.Id);
          } 
          for(Opportunity_Product__c prod: prods){
                if(xsellMap.get(prod.Account_ID__c + '-' + prod.Product_Name__c) != null){
                    prod.Account_Cross_Sell__c = xsellMap.get(prod.Account_ID__c + '-' + prod.Product_Name__c);
                    
                }
          }
      }
  }
}