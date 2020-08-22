public without sharing class CommitDiscountController {
    public Id cartId {get; set;}
    public Id configRequestId {get; set;}
    public Boolean flagUpdatePrice {get; set;}
    public Decimal priceValue {get; set;}
    public Apttus_Proposal__Proposal__c aQuote {get; set;}
    public Id quoteId {get ;set;}
    public Decimal previousPrice {get; set;}
    
    public CommitDiscountController(){
        cartId = ApexPages.currentPage().getParameters().get('id');
        configRequestId = ApexPages.currentPage().getParameters().get('configRequestId');
        quoteId = [SELECT Apttus_QPConfig__Proposald__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id = : cartId LIMIT 1].Apttus_QPConfig__Proposald__c;
        previousPrice = [SELECT Commit_Level_Discount__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =: cartId LIMIT 1].Commit_Level_Discount__c;
        aQuote = [SELECT Id, Commit_Frequency__c, Term_Range__c, Total_Committed_Revenue__c FROM Apttus_Proposal__Proposal__c WHERE Id =:quoteId];
    }
    
    public void reprice(){
        String FlatDiscountField = null;
        String PercentDiscountField = null;
        List<CPQ_discount_and_field_mapping__c> settings = CPQ_discount_and_field_mapping__c.getAll().values();
        Map<String, CPQ_discount_and_field_mapping__c> settingMap = new Map<String, CPQ_discount_and_field_mapping__c>();
        for(CPQ_discount_and_field_mapping__c setting: settings){
            settingMap.put(setting.Commit_Level_Discount__c , setting);
        }
        if(priceValue > 0.00 && settingMap.containsKey(String.valueof(priceValue))){
            FlatDiscountField = 'Apttus_Config2__PriceListItemId__r.'+settingMap.get(String.valueof(priceValue)).Flat_Field_API_Name__c ;
			PercentDiscountField = 'Apttus_Config2__PriceListItemId__r.'+settingMap.get(String.valueof(priceValue)).Percent_Field_API_Name__c ;
            
            String queryString = 'SELECT Apttus_Config2__AdjustmentAmount__c ,Apttus_Config2__AdjustmentType__c ,' +
                					'Apttus_Config2__ListPrice__c,Percent_of_Spend__c,Apttus_Config2__ChargeType__c,Apttus_Config2__ProductId__r.Percent_of_Spend_Pricing__c, '+ 
                					 FlatDiscountField +', '+ PercentDiscountField +' FROM Apttus_Config2__LineItem__c ' +
                					'WHERE Apttus_Config2__ConfigurationId__c =:cartId and Is_Bucket_Option__c='+false;
            List<Apttus_Config2__LineItem__c> lineItems =  database.query(queryString);
            
            for(Apttus_Config2__LineItem__c lineItem : lineItems){
                if(lineItem.getSobject('Apttus_Config2__PriceListItemId__r')!=null){
                    if(lineItem.Apttus_Config2__ProductId__r.Percent_of_Spend_Pricing__c==true && lineItem.Apttus_Config2__ChargeType__c =='Subscription Fee' &&
                       lineItem.getSobject('Apttus_Config2__PriceListItemId__r').get(settingMap.get(String.valueof(priceValue)).Percent_Field_API_Name__c) !=null){
                           lineItem.Percent_of_Spend__c = (Decimal) lineItem.getSobject('Apttus_Config2__PriceListItemId__r').get(settingMap.get(String.valueof(priceValue)).Percent_Field_API_Name__c);
                       }else{
                           if(lineItem.getSobject('Apttus_Config2__PriceListItemId__r').get(settingMap.get(String.valueof(priceValue)).Flat_Field_API_Name__c) !=null){
                               lineItem.Apttus_Config2__AdjustmentAmount__c = (Decimal) lineItem.getSobject('Apttus_Config2__PriceListItemId__r').get(settingMap.get(String.valueof(priceValue)).Flat_Field_API_Name__c );
                               lineItem.Apttus_Config2__AdjustmentType__c = 'Base Price Override';
                               lineItem.Apttus_Config2__NetUnitPrice__c = lineItem.Apttus_Config2__AdjustmentAmount__c;
                           }
                       }
                    lineItem.Apttus_Config2__PricingStatus__c = 'Pending';
                    lineItem.Commit_Level_Discount__c = priceValue;
                }
            }
            update aQuote;
            update lineItems;
            
        }else{
            String queryString = 'SELECT Apttus_Config2__AdjustmentAmount__c ,Apttus_Config2__AdjustmentType__c ,' +
                					'Apttus_Config2__ListPrice__c, Apttus_Config2__PriceListItemId__c FROM Apttus_Config2__LineItem__c ' +
                					'WHERE Apttus_Config2__ConfigurationId__c =:cartId and Is_Bucket_Option__c='+false;
            List<Apttus_Config2__LineItem__c> lineItems =  database.query(queryString);
            
            for(Apttus_Config2__LineItem__c lineItem : lineItems){
                lineItem.Apttus_Config2__PricingStatus__c = 'Pending';
                lineItem.Commit_Level_Discount__c = priceValue;
                lineItem.Apttus_Config2__AdjustmentAmount__c = null;
                lineItem.Apttus_Config2__AdjustmentType__c = null;
                lineItem.Apttus_Config2__NetUnitPrice__c = lineItem.Apttus_Config2__ListPrice__c;
            }
            update aQuote;
            update lineItems;
        }
    }
    
    public PageReference cancel(){
        return new PageReference('/apex/Apttus_Config2__Cart?configRequestId=' + configRequestId + '&id=' + cartId + '&flow=NewFlowTest&launchState=cart#!/cart');
    } 
    
    public PageReference savePage(){
        update aQuote;
        return new PageReference('/apex/Apttus_Config2__Cart?configRequestId=' + configRequestId + '&id=' + cartId + '&flow=NewFlowTest&launchState=cart#!/cart');
    }
}