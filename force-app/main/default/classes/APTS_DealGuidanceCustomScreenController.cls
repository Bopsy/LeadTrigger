/*************************************************************
@Name: APTS_DealGuidanceCustomScreenController
@Author: Nikunj Vedia
@Description: This class serves as Controller for Deal Guidance Custom Screen
******************************************************************/
public without sharing class APTS_DealGuidanceCustomScreenController{

    public APTS_DealGuidanceJSON json{get;set;}
    public Apttus_Config2__LineItem__c lineItem{get;set;}
    public List<APTS_DealGuidanceJSON.Entries> entries{get;set;}
    public map<Integer,APTS_DealGuidanceJSON.Entries> mapofSequenceToEntries{get;set;}
    public Integer sequence{get;set;}
    public String Measure{get;set;}
    public Boolean isSupportProd{get; set;}
    public Boolean isSubminuteBilling{get; set;}
    private Boolean isSendGrid {get; set;}
    
    public APTS_DealGuidanceCustomScreenController() {
        
        id lineitemid = Apexpages.currentpage().getParameters().get('lineitemid');
        lineItem = [Select BI_SID__c, Product_Family__c, SG_Product_Type__c, Fixed_Discount_on_OF__c, Apttus_Config2__Description__c, Apttus_Config2__AdjustmentType__c, 
                    Apttus_Config2__Guidance__c, Apttus_Config2__ProductId__r.Percent_of_Spend__c, 
                    Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Monthly_Committed_Revenue__c, 
                    id,Name,Apttus_Config2__ProductId__c, Apttus_Config2__OptionId__c, Apttus_Config2__PricingGuidance__c,
                    Billing_Increment__c,Billing_Minute__c,Apttus_Config2__ProductId__r.Capable_of_Sub_Minute_Billing__c,Apttus_Config2__ChargeType__c,Apttus_Config2__ProductId__r.Percent_of_Spend_Pricing__c,
                    Apttus_Config2__OptionId__r.Capable_of_Sub_Minute_Billing__c,Apttus_Config2__OptionGroupLabel__c, Max_Flex_Quantity__c,Apttus_Config2__NetUnitPrice__c,
                    Is_Bundle_Product__c,Bucket_Floor_Price__c,Rule_Measure__c
                    from Apttus_Config2__LineItem__c  where id=:lineitemid];
        id productid = lineItem.Apttus_Config2__OptionId__c == null ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
        Decimal mcr = (lineItem.Is_Bundle_Product__c) ? lineItem.Bucket_Floor_Price__c : lineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Monthly_Committed_Revenue__c;
        //Added by Amrutha - flex discount
        if(lineItem.Apttus_Config2__OptionGroupLabel__c != null && lineItem.Apttus_Config2__OptionGroupLabel__c.contains('Flex') && lineItem.BI_SID__c != null){
            mcr = lineItem.Max_Flex_Quantity__c;
        }
        isSupportProd = lineItem.Rule_Measure__c!='Unit Price';
        isSendGrid = false;
        if(lineItem.Product_Family__c!=null && lineItem.Product_Family__c.equalsignorecase('Sendgrid') && lineItem.SG_Product_Type__c!=null && lineItem.SG_Product_Type__c.equalsignorecase('Email')){
            isSendGrid = true;
        }
        
        
        //Added by Amrutha - Subminute billing
        if(lineItem.Apttus_Config2__ProductId__c!=null){
            if((lineItem.Apttus_Config2__ProductId__r.Capable_of_Sub_Minute_Billing__c==true) &&
               (lineItem.Billing_Increment__c!=null || lineItem.Billing_Minute__c!=null)){
                   isSubminuteBilling = true;
            }
        }if(lineItem.Apttus_Config2__OptionId__c!=null){
            if((lineItem.Apttus_Config2__OptionId__r.Capable_of_Sub_Minute_Billing__c==true) &&
               (lineItem.Billing_Increment__c!=null || lineItem.Billing_Minute__c!=null)){
                   isSubminuteBilling = true;
            }
        }
        List<Apttus_DealMgr__DealGuidanceRuleEntry__c> prices = new List<Apttus_DealMgr__DealGuidanceRuleEntry__c>();        
        if(isSupportProd){
            prices = [SELECT Name,Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__Measure__c, Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__CustomMeasureSource__c,
                                                                 Apttus_DealMgr__Band1Value__c,Apttus_DealMgr__Band2Value__c, Apttus_DealMgr__Band3Value__c, Apttus_DealMgr__Dimension1Value__c 
                                                                 FROM Apttus_DealMgr__DealGuidanceRuleEntry__c 
                                                                 WHERE Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__ProductScope__c = :productid and
                                                                 Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__Measure__c='Custom' 
                                                                 ORDER BY Apttus_DealMgr__Sequence__c];
        }else{
            prices = [SELECT Name,Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__Measure__c, Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__CustomMeasureSource__c,
                                                                 Apttus_DealMgr__Band1Value__c,Apttus_DealMgr__Band2Value__c, Apttus_DealMgr__Band3Value__c, Apttus_DealMgr__Dimension1Value__c 
                                                                 FROM Apttus_DealMgr__DealGuidanceRuleEntry__c 
                                                                 WHERE Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__ProductScope__c = :productid and
                                                                 Apttus_DealMgr__GuidanceRuleId__r.Apttus_DealMgr__Measure__c!='Custom' 
                                                                 ORDER BY Apttus_DealMgr__Sequence__c];
        }
        
        json = APTS_DealGuidanceJSON.parse(lineItem.Apttus_Config2__PricingGuidance__c);
        entries = new List<APTS_DealGuidanceJSON.Entries>();
        mapofSequenceToEntries = New Map<Integer,APTS_DealGuidanceJSON.Entries>();
        String color = lineItem.Apttus_Config2__Guidance__c;
        
        for(APTS_DealGuidanceJSON.Entries entry : json.Entries){
            sequence = entry.Sequence;
            entries.add(entry);
            entry.IsItemRating = color != null && color == entry.Rating ? true : false;
            mapofSequenceToEntries.put(sequence,entry);
        }
       
        Integer index = -1;
        
            for(Integer i = 0; i < prices.size() - 1; i++){
                if(mcr >= Decimal.valueOf(prices[i].Apttus_DealMgr__Dimension1Value__c) && mcr < Decimal.valueOf(prices[i+1].Apttus_DealMgr__Dimension1Value__c)){
                    index = i; break;
                }
            }
        if(index == -1 && prices.size() > 0 && mcr >= Decimal.valueOf(prices[prices.size() -1].Apttus_DealMgr__Dimension1Value__c)) index = prices.size() -1;
        
        for(APTS_DealGuidanceJSON.Entries currentEntry : entries){
            if(currentEntry.Rating == 'Green' && index != -1){
                currentEntry.PriceFrom = null;
                currentEntry.PriceTo = Decimal.valueOf(prices[index].Apttus_DealMgr__Band1Value__c);
            }
            else if(currentEntry.Rating == 'Yellow' && index != -1){
                currentEntry.PriceFrom = Decimal.valueOf(prices[index].Apttus_DealMgr__Band1Value__c);
                currentEntry.PriceTo =  Decimal.valueOf(prices[index].Apttus_DealMgr__Band2Value__c);
            }
            else if(currentEntry.Rating == 'Orange' && index != -1){
                currentEntry.PriceFrom = Decimal.valueOf(prices[index].Apttus_DealMgr__Band2Value__c);
                currentEntry.PriceTo =  Decimal.valueOf(prices[index].Apttus_DealMgr__Band3Value__c);
            }
            else if(currentEntry.Rating == 'Red' && index != -1){
                currentEntry.PriceFrom = Decimal.valueOf(prices[index].Apttus_DealMgr__Band3Value__c);
                currentEntry.PriceTo = isSendGrid ? 100 : 0;
            }
            if(currentEntry.PriceTo != NULL){
                //currentEntry.customPriceToFormatted = lineItem.CurrencyIsoCode + ' ' + currentEntry.PriceTo.format();
                currentEntry.customPriceToFormatted = '$' + ' ' + currentEntry.PriceTo.format();
            }
            
            if(currentEntry.PriceFrom != NULL){
                //currentEntry.customPriceFromFormatted = lineItem.CurrencyIsoCode + ' ' + currentEntry.PriceFrom.format();
                currentEntry.customPriceFromFormatted = '$' + ' ' + currentEntry.PriceFrom.format();
            }
            
            Measure = currentEntry.MeasureType;
            
            
        }
    }
}