public without sharing class QuoteApprovalEmailCtrl {
    public Id configId {get; set;}
    public Apttus_Config2__ProductConfiguration__c config {
        get{
            if(config == null){
                config = [SELECT Apttus_QPConfig__Proposald__r.Commit_Type__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Proposal_Name__c, Apttus_QPConfig__Proposald__r.Total_Committed_Revenue__c, Apttus_QPConfig__Proposald__r.Commit_Frequency__c, Apttus_QPConfig__Proposald__r.Term_Range__c, Apttus_QPConfig__Proposald__r.Primary_Account_SID__c, Apttus_QPConfig__Proposald__c
                          FROM Apttus_Config2__ProductConfiguration__c
                          WHERE Id =: configId];
            }
            return config;
        }
        set;
    }
    public List<Apttus_Config2__LineItem__c> lineItems{
        get{
            if(lineItems == null){
                lineItems = [SELECT Apttus_Config2__AdjustmentType__c, Is_Bucket_Option__c, Product_Name_OF_Generate__c, List_Percentage_Discount_Support__c, Percent_of_Spend__c, Product_Family__c, List_Price_Stamp__c, Apttus_Config2__NetUnitPrice__c, Total_Discount__c, Apttus_Config2__Guidance__c, Apttus_Config2__PriceType__c 
                             FROM Apttus_Config2__LineItem__c
                             WHERE Apttus_Config2__ConfigurationId__c =: configId
                             AND Apttus_Config2__Guidance__c != 'Green'
                             AND Apttus_Config2__Guidance__c != null];
            }
            return lineItems;
        }
        set;
    }
    
    public List<Apttus_Config2__LineItem__c> flatDiscountItems {
        get{
           if(flatDiscountItems == null){
               flatDiscountItems = new List<Apttus_Config2__LineItem__c>();
               for(Apttus_Config2__LineItem__c lineItem: lineItems){
                   if(lineItem.Apttus_Config2__PriceType__c == 'One Time'){
                       flatDiscountItems.add(lineItem);
                   }
               }
           }
           return flatDiscountItems;
        }
        set;
    }
    
    public List<Apttus_Config2__LineItem__c> tieredDiscountItems {
        get{
           if(tieredDiscountItems == null){
               tieredDiscountItems = new List<Apttus_Config2__LineItem__c>();
               for(Apttus_Config2__LineItem__c lineItem: lineItems){
                   if(lineItem.Apttus_Config2__PriceType__c == 'Usage'){
                       tieredDiscountItems.add(lineItem);
                   }
               }
           }
           return tieredDiscountItems;
        }
        set;
    }
    
    public List<Apttus_Config2__LineItem__c> recurringDiscountItems {
        get{
           if(recurringDiscountItems == null){
               recurringDiscountItems = new List<Apttus_Config2__LineItem__c>();
               for(Apttus_Config2__LineItem__c lineItem: lineItems){
                   if(lineItem.Apttus_Config2__PriceType__c == 'Recurring' && !lineItem.Product_Name_OF_Generate__c.contains('Flex')){
                       recurringDiscountItems.add(lineItem);
                   }
               }
           }
           return recurringDiscountItems;
        }
        set;
    }
    
    public List<Apttus_Config2__LineItem__c> flexDiscountItems {
        get{
           if(flexDiscountItems == null){
               flexDiscountItems = new List<Apttus_Config2__LineItem__c>();
               for(Apttus_Config2__LineItem__c lineItem: lineItems){
                   if(lineItem.Apttus_Config2__PriceType__c == 'Recurring' && lineItem.Product_Name_OF_Generate__c.contains('Flex')){
                       flexDiscountItems.add(lineItem);
                   }
               }
           }
           return flexDiscountItems;
        }
        set;
    }
    
    public List<Apttus_Config2__LineItem__c> bucketDiscountItems {
        get{
           if(bucketDiscountItems == null){
               bucketDiscountItems = new List<Apttus_Config2__LineItem__c>();
               for(Apttus_Config2__LineItem__c lineItem: lineItems){
                   if(lineItem.Is_Bucket_Option__c){
                       bucketDiscountItems.add(lineItem);
                   }
               }
           }
           return bucketDiscountItems;
        }
        set;
    }
}