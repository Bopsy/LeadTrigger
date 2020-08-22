public without sharing class AgreementLineItemServices {
    public static Boolean bypassLineItem = false;
    public static Boolean isInFuture = false;
    static Set<String> excludeQliFields = new Set<String>{'Apttus_QPConfig__SummaryGroupId__c', 'Apttus_QPConfig__AttributeValueId__c'};
    static Set<String> quantityBIs = new Set<String>{'BI32d90555749797a046ca0e15d7daabae', 'BI938e21a35f7b885caea16d370b0973ff', 'BI3a7c833fc420b0eb7411213706f594bc',
                                                    'BI1df60828ad02d14a8a088ec4279b7e63', 'BIb3ca333196a8d3725517b450963919dd', 'BI6c0085c32f2632dc1ee7125a79942c69',
                                                    'BI7bb241fb2a6085e1caeea3b5ee26d44f'
    };
    static Map<String, String> fieldMapping{
        get{
            if(fieldMapping == null){
                fieldMapping = new Map<String, String>();
                for(ALI_to_Single_BI_Mapping__c setting: ALI_to_Single_BI_Mapping__c.getAll().values()){
                    fieldMapping.put(setting.ALI_Field__c, setting.Single_BI_Field__c);
                }
            }
            return fieldMapping;
        }
        set;
    }
    
    static Map<String, String> tierFieldMapping{
        get{
            if(tierFieldMapping == null){
                tierFieldMapping = new Map<String, String>();
                for(Usage_Price_Tier_to_Single_BI_Tier__c setting: Usage_Price_Tier_to_Single_BI_Tier__c.getAll().values()){
                    tierFieldMapping.put(setting.Usage_Price_Tier_Field__c, setting.Single_BI_Tier_Field__c);
                }
            }
            return tierFieldMapping;
        }
        set;
    }
    
    @future
    public static void updateQuotePricing(Id quoteId, Id agreementId){
        
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get('Apttus__AgreementLineItem__c').getDescribe().fields.getMap();
        Map<String, String> aliEditableFields = new Map<String, String>();
        for(Schema.SObjectField fieldRef : fields.values()) {
            Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
            if(fieldResult.isUpdateable()) {
                String fieldName = fieldResult.getName();
                List<String> nameList = fieldName.split('__');
                String localName = nameList.size() > 2 ? nameList[1] : nameList[0];
                aliEditableFields.put(localName, fieldName);
            }
        }
        
        fields = Schema.getGlobalDescribe().get('Apttus_Proposal__Proposal_Line_Item__c').getDescribe().fields.getMap();
        Map<String, String> qliEditableFields = new Map<String, String>();
        for(Schema.SObjectField fieldRef : fields.values()) {
            Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
            String fieldName = fieldResult.getName();
            List<String> nameList =  fieldName.split('__');
            String localName = nameList.size() > 2 ? nameList[1] : nameList[0];
            if(aliEditableFields.keySet().contains(localName) && !excludeQliFields.contains(fieldName)){
                qliEditableFields.put(localName, fieldName);
            }
        }

        String queryString = 'SELECT Apttus_Proposal__Product__c, Apttus_QPConfig__Quantity2__c ';
        
        for(String fieldName: qliEditableFields.values()){
            queryString += ',' + fieldName + ' ';
        }
        
        queryString += 'FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c =: quoteId';
        
        List<Apttus_Proposal__Proposal_Line_Item__c> listItems = (List<Apttus_Proposal__Proposal_Line_Item__c>) database.query(queryString);
        
        fields = Schema.getGlobalDescribe().get('Apttus_CMConfig__AgreementUsagePriceTier__c').getDescribe().fields.getMap();
        Map<String, String> autEditableFields = new Map<String, String>();
        for(Schema.SObjectField fieldRef : fields.values()) {
            Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
            if(fieldResult.isUpdateable()) {
                String fieldName = fieldResult.getName();
                List<String> nameList = fieldName.split('__');
                String localName = nameList.size() > 2 ? nameList[1] : nameList[0];
                autEditableFields.put(localName, fieldName);
            }
        }
        
        fields = Schema.getGlobalDescribe().get('Apttus_QPConfig__ProposalUsagePriceTier__c').getDescribe().fields.getMap();
        Map<String, String> qutEditableFields = new Map<String, String>();
        for(Schema.SObjectField fieldRef : fields.values()) {
            Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
            String fieldName = fieldResult.getName();
            List<String> nameList =  fieldName.split('__');
            String localName = nameList.size() > 2 ? nameList[1] : nameList[0];
            if(autEditableFields.keySet().contains(localName)){
                qutEditableFields.put(localName, fieldName);
            }
        }
        
        queryString = 'SELECT Apttus_QPConfig__LineItemId__c';
        
        for(String fieldName: qutEditableFields.values()){
            queryString += ',' + fieldName + ' ';
        }
        
        queryString += 'FROM Apttus_QPConfig__ProposalUsagePriceTier__c WHERE Apttus_QPConfig__LineItemId__c =: listItems';
        
        Map<Id, Apttus__AgreementLineItem__c> newLineItems = new Map<Id, Apttus__AgreementLineItem__c>();
        
        for(Apttus_Proposal__Proposal_Line_Item__c lineItem: listItems){
            Apttus__AgreementLineItem__c newAli = new Apttus__AgreementLineItem__c(Apttus__AgreementId__c = agreementId, Apttus__ProductId__c = lineItem.Apttus_Proposal__Product__c);
            for(String fieldName: qliEditableFields.keySet()){
                String qliField = qliEditableFields.get(fieldName);
                String aliField = aliEditableFields.get(fieldName);
                newAli.put(aliField, lineItem.get(qliField));
            }
            newAli.Apttus__Quantity__c = lineItem.Apttus_QPConfig__Quantity2__c;
            newLineItems.put(lineItem.Id, newAli);
        }
        
        //System.debug('===> delete all original alis');
        //System.debug([SELECT Id FROM Apttus__AgreementLineItem__c WHERE Apttus__AgreementId__c =: agreementId]);
        delete [SELECT Id FROM Apttus__AgreementLineItem__c WHERE Apttus__AgreementId__c =: agreementId];
        delete [SELECT Id FROM Single_BI_Discount__c WHERE Agreement__c =: agreementId];
        delete [SELECT Id FROM Apttus_CMConfig__AgreementUsagePriceTier__c WHERE Apttus_CMConfig__LineItemId__r.Apttus__AgreementId__c =: agreementId];
        delete [SELECT Id FROM Single_BI_Tier__c WHERE Agreement__c =: agreementId];
        //System.debug('===> insert all  alis again');
        insert newLineItems.values();
        
        Map<Id, List<Apttus_QPConfig__ProposalUsagePriceTier__c>> tierMap = new Map<Id, List<Apttus_QPConfig__ProposalUsagePriceTier__c>>();
        
        List<Apttus_QPConfig__ProposalUsagePriceTier__c> tiers = database.query(queryString);
        for(Apttus_QPConfig__ProposalUsagePriceTier__c tier: tiers){
            List<Apttus_QPConfig__ProposalUsagePriceTier__c> groupTiers = tierMap.get(tier.Apttus_QPConfig__LineItemId__c);
            if(groupTiers == null) groupTiers = new List<Apttus_QPConfig__ProposalUsagePriceTier__c>();
            groupTiers.add(tier);
            tierMap.put(tier.Apttus_QPConfig__LineItemId__c, groupTiers);
        }
        
        List<Apttus_CMConfig__AgreementUsagePriceTier__c> insertTiers = new List<Apttus_CMConfig__AgreementUsagePriceTier__c>();
        for(Id lineItemId: tierMap.keySet()){
            for(Apttus_QPConfig__ProposalUsagePriceTier__c tier: tierMap.get(lineItemId)){
                Apttus_CMConfig__AgreementUsagePriceTier__c newTier = new Apttus_CMConfig__AgreementUsagePriceTier__c(Apttus_CMConfig__LineItemId__c = newLineItems.get(lineItemId).Id);
                for(String fieldName: qutEditableFields.keySet()){
                    String qutField = qutEditableFields.get(fieldName);
                    String autField = autEditableFields.get(fieldName);
                    newTier.put(autField, tier.get(qutField));
                }
                insertTiers.add(newTier);
            }
        }
        
        insert insertTiers;
    }
    
    /*@future
    public static void afterTierInsert(Set<Id> ids){
        afterInsert([SELECT Id FROM Apttus_CMConfig__AgreementUsagePriceTier__c WHERE Id =: ids]);
    }
    
    @future
    public static void afterALIInsert(Set<Id> ids){
        //TODO: Need to requery back ALIs with all necessary fields.
        //All custom setting fields + all fields are using in the function.
        //afterInsert([SELECT Id FROM Apttus__AgreementLineItem__c]);
    }*/
    
    public static void afterInsert(List<Apttus_CMConfig__AgreementUsagePriceTier__c> tiers){
        String queryString = 'SELECT Apttus_CMConfig__PriceMatrixId__c, Apttus_CMConfig__AdjustmentType__c, Product_Bi_SID__c, Apttus_CMConfig__LineItemId__r.Single_BI_Discount__c, Apttus_CMConfig__LineItemId__r.Single_BI_Discount__r.Billable_Item__c, Apttus_CMConfig__LineItemId__r.Single_BI_Discount__r.Agreement__c';
        
        for(String tierField: tierFieldMapping.keySet()){
            queryString += ',' + tierField + ' ';
        }
        
        queryString += 'FROM Apttus_CMConfig__AgreementUsagePriceTier__c WHERE Id =: tiers';
        
        List<Apttus_CMConfig__AgreementUsagePriceTier__c> usageTiers = (List<Apttus_CMConfig__AgreementUsagePriceTier__c>) database.query(queryString);
       
        Map<Id, Single_BI_Tier__c> singleTiers = new Map<Id, Single_BI_Tier__c>();
        Map<Id, Id> priceMatrixId = new Map<Id, Id>();
        
        for(Apttus_CMConfig__AgreementUsagePriceTier__c tier: usageTiers){
            String biSid = tier.Product_Bi_SID__c;
            Single_BI_Tier__c singleTier = buildTierFromUsageTier(tier);
            priceMatrixId.put(tier.Apttus_CMConfig__PriceMatrixId__c, tier.Id);
            if(tier.Apttus_CMConfig__LineItemId__r.Single_BI_Discount__c != null){
                singleTier.Single_BI_Discount__c = tier.Apttus_CMConfig__LineItemId__r.Single_BI_Discount__c;
                singleTIer.Billable_Item__c = tier.Apttus_CMConfig__LineItemId__r.Single_BI_Discount__r.Billable_Item__c;
                singleTier.Agreement__c = tier.Apttus_CMConfig__LineItemId__r.Single_BI_Discount__r.Agreement__c;
                singleTiers.put(tier.Id, singleTier);
            }
        }
        
        /*Map<Id, List<Apttus_Config2__PriceMatrixEntry__c>> prices = new Map<Id, List<Apttus_Config2__PriceMatrixEntry__c>>();
        List<Apttus_Config2__PriceMatrixEntry__c> priceEntries = [SELECT Apttus_Config2__TierStartValue__c, Apttus_Config2__TierEndValue__c, Apttus_Config2__UsageRate__c, Apttus_Config2__PriceMatrixId__c FROM Apttus_Config2__PriceMatrixEntry__c WHERE Apttus_Config2__PriceMatrixId__c =: priceMatrixId.keySet()];
        for(Apttus_Config2__PriceMatrixEntry__c priceEntry: priceEntries){List<Apttus_Config2__PriceMatrixEntry__c> entries = prices.get(priceEntry.Apttus_Config2__PriceMatrixId__c); if(entries == null) entries = new List<Apttus_Config2__PriceMatrixEntry__c>(); entries.add(priceEntry);prices.put(priceEntry.Apttus_Config2__PriceMatrixId__c, entries);}
        for(Id pmId: priceMatrixId.keySet()){
            Id tierId = priceMatrixId.get(pmId);
            List<Apttus_Config2__PriceMatrixEntry__c> price = prices.get(pmId);
            Single_BI_Tier__c singleTier = singleTiers.get(tierId);
            for(Apttus_Config2__PriceMatrixEntry__c entry: price){if(singleTier.Floor__c == entry.Apttus_Config2__TierStartValue__c && singleTier.Ceiling__c == entry.Apttus_Config2__TierEndValue__c){system.assert(false, entry);singleTier.List_Price__c = entry.Apttus_Config2__UsageRate__c;break;}}
        }*/
        
        insert singleTiers.values();
    }
    
    public static void afterInsert(List<Apttus__AgreementLineItem__c> alis){
        if(bypassLineItem) return;
        Map<Id, String> sidAliMap = new Map<Id, String>();
    
        for(Apttus__AgreementLineItem__c ali: alis){
            if(ali.Product_Bi_SID__c != null){
                sidAliMap.put(ali.Id, ali.Product_Bi_SID__c);
            }
        }
        
        
        Map<String, Id> sidBIMap = new Map<String, Id>();
        for(Billable_Item__c bi: [SELECT BI_SID__c FROM Billable_Item__c WHERE BI_SID__c =: sidAliMap.values()]){
            sidBIMap.put(bi.Bi_SID__c, bi.Id);
        }
        
        Map<String, Single_BI_Discount__c> singleBis = new Map<String, Single_BI_Discount__c>();
        for(Apttus__AgreementLineItem__c ali: alis){
            Single_BI_Discount__c singleBi = buildSingleBIFromAli(ali);
            String biSid = sidAliMap.get(ali.Id);
            if(biSid != null){
                singleBi.Billable_Item__c = sidBIMap.get(biSid);
                if(ali.Apttus__Description__c.contains('Flex')){
                    singleBi.Quantity__c = null;
                    singleBi.Product_Activation_Start_Date__c = null;
                }
                else if(quantityBIs.contains(biSid)){
                    singleBi.Quantity__c = ali.Apttus__Quantity__c;
                    if(biSid != 'BI7bb241fb2a6085e1caeea3b5ee26d44f'){
                        singleBi.Flat_Price__c *= singleBi.Quantity__c;
                    }
                }
                singleBis.put(biSid, singleBi);
            }
        }
        
        insert singleBis.values();
        List<Apttus__AgreementLineItem__c> updatedItem = alis.deepClone(true, true);
        
        List<Single_BI_Tier__c> tiers = new List<Single_BI_Tier__c>();
        Single_BI_Tier__c additionalTier = new Single_BI_Tier__c();
        
        for(Apttus__AgreementLineItem__c ali: updatedItem){
            String biSid = sidAliMap.get(ali.Id);
            if(ali.Apttus__Description__c.contains('Flex') && ali.Apttus_CMConfig__OptionId__c != null){
                Single_BI_Discount__c singleBi = singleBis.get(biSid);
                if(!ali.Apttus__Description__c.contains('Additional')){
                    Single_BI_Tier__c newTier = new Single_BI_Tier__c(Agreement__c = ali.Apttus__AgreementId__c, 
                                                                      Single_BI_Discount__c = singleBi.Id,
                                                                      List_Price__c = ali.Apttus__ListPrice__c,
                                                                      Flat_Price__c = ali.Apttus_CMConfig__NetUnitPrice__c,
                                                                      Billable_Item__c = singleBi.Billable_Item__c,
                                                                      Monthly_Units_Purchased__c = ali.Apttus__Quantity__c,
                                                                      Discount_Rate_Start_Date__c = ali.Apttus_CMConfig__StartDate__c,
                                                                      Discount_Type__c = 'Flat',
                                                                      Discount_Rate_End_Date__c = ali.Apttus_CMConfig__EndDate__c,
                                                                      RecordTypeId = '0121W000000DywZ'/*'0124F000000CjNs'*/);
                    tiers.add(newTier);
                }
                else{
                    additionalTier = new Single_BI_Tier__c(Agreement__c = ali.Apttus__AgreementId__c, 
                                                                      Single_BI_Discount__c = singleBi.Id,
                                                                      List_Price__c = ali.Apttus__ListPrice__c,
                                                                      Flat_Price__c = ali.Apttus_CMConfig__NetUnitPrice__c,
                                                                      Billable_Item__c = singleBi.Billable_Item__c,
                                                                      Discount_Type__c = 'Flat',
                                                                      Monthly_Units_Purchased__c = ali.Apttus__Quantity__c,
                                                                      Last_Additional_Schedule__c = true,
                                                                      RecordTypeId = '0121W000000DywZ'/*'0124F000000CjXi'*/);
                }
            }
            if(biSid != null){
                ali.Single_BI_Discount__c = singleBis.get(biSid).Id;
                ali.Billable_Item__c = sidBIMap.get(biSid);
            }
        }
        bypassLineItem = true;
        
        update updatedItem;
        
        tiers.add(additionalTier);
        Integer tierSize = tiers.size();
        
        for(Integer i = 0; i < tierSize; i++){
            if(i >= tierSize - 2){
                tiers[i].Discount_Rate_End_Date__c = null;
            }
            tiers[i].Floor__c = i;
            if(i<9){
                tiers[i].Tier_Row__c = i+1;
            }else if(i>=9 && i<18){
                tiers[i].Tier_Row__c = i+81+1;
            }else if(i>=18 && i<27){
                tiers[i].Tier_Row__c = i+971+2;
            }else if(i>=27 && i<36){
                tiers[i].Tier_Row__c = i+9961+3;
            }
        }
        tiers[tierSize - 1].Discount_Rate_Start_Date__c = tiers[0].Discount_Rate_Start_Date__c;
        insert tiers;
        bypassLineItem = false;
        /*queryString += 'FROM Apttus_CMConfig__AgreementUsagePriceTier__c WHERE Apttus_CMConfig__LineItemId__c =: alis';
        
        List<Apttus_CMConfig__AgreementUsagePriceTier__c> usageTiers = (List<Apttus_CMConfig__AgreementUsagePriceTier__c>) database.query(queryString);
       
        List<Single_BI_Tier__c> singleTiers = new List<Single_BI_Tier__c>();

        for(Apttus_CMConfig__AgreementUsagePriceTier__c tier: usageTiers){
            String biSid = tier.Product_Bi_SID__c;
            Single_BI_Discount__c singleBi = singleBis.get(biSid);
            Single_BI_Tier__c singleTier = buildTierFromUsageTier(tier);
            singleTier.Single_BI_Discount__c = singleBi.Id;
            singleTier.Agreement__c = singleBi.Agreement__c;
            singleTiers.add(singleTier);
        }
        
        insert singleTiers;*/
    }
    
    static Single_BI_Tier__c buildTierFromUsageTier(Apttus_CMConfig__AgreementUsagePriceTier__c usageTier){
        Single_BI_Tier__c singleTier = new Single_BI_Tier__c();
        if(usageTier.Apttus_CMConfig__AdjustmentType__c == '% Discount'){
            singleTier.Discount_Type__c = 'Percent';
        }
        else{
            singleTier.Discount_Type__c = 'Flat';
        }
        for(String tierField: tierFieldMapping.keySet()){
            String singleTierField = tierFieldMapping.get(tierField);
            if(singleTierField != null){
                singleTier.put(singleTierField, usageTier.get(tierField));
            }
        }
        return singleTier;
    }
    
    static Single_BI_Discount__c buildSingleBIFromAli(Apttus__AgreementLineItem__c ali){
        Single_BI_Discount__c singleBi = new Single_BI_Discount__c();
        singleBi.Discount_Type__c = ali.Apttus__Description__c.contains('ROW') ? 'Percent' : 'Flat';
        if(ali.Apttus_CMConfig__AdjustmentType__c == '% Discount' && (ali.Fixed_Discount_on_OF__c || ali.Apttus__Description__c.contains('ROW'))){
            singleBi.Discount_Type__c = 'Percent';
            singleBi.Percent_Off__c = ali.Apttus_CMConfig__AdjustmentAmount__c;
        }
        else{
            singleBi.Discount_Type__c = 'Flat';
        }
        if(ali.Apttus_CMConfig__PriceType__c == 'Usage'){
            singleBi.Rate_Schedule__c = 'Tiered';
        }
        else if(ali.Apttus_CMConfig__PriceType__c == 'Recurring'){
            singleBi.Rate_Schedule__c = 'Monthly Recurring';
        }
        else{
            singleBi.Rate_Schedule__c = 'Metered';
        }
        if(ali.Apttus_CMConfig__PriceType__c == 'Recurring'){
            singleBi.Type__c = 'Monthly Recurring Charge';
        }
        else if(ali.Product_Display_Type__c == 'Groups'){
            if(ali.Apttus_CMConfig__OptionId__c != null && ali.Number_of_Tiers__c > 0){
                singleBi.Type__c = 'GTM Group with Tiers';
            }
            else if(ali.Apttus_CMConfig__OptionId__c != null && ali.Number_of_Tiers__c == 0){
                singleBi.Type__c = 'GTM Group without Tiers';
            }
        }
        else if(ali.Product_Display_Type__c == 'Individual Products'){
            if(ali.Number_of_Tiers__c > 0){
                singleBi.Type__c = 'No GTM Group With Tiers';
            }
            else if(ali.Number_of_Tiers__c == 0){
                singleBi.Type__c = 'No GTM Group Without Tiers';
            }
        }
        if(ali.Is_Bundle_Product__c){
             singleBi.Type__c = 'GTM Group without Tiers';
        }
        if(ali.Product_Type__c == 'SKU Group'){
            singleBi.RecordTypeId = '0121W000000MK8O';
        }
        else if(ali.Product_Type__c == 'Wireless SKU Group'){
            singleBi.RecordTypeId = '0121W0000009pe8';//'0121W0000009pe8';
        }
        else{
            singleBi.RecordTypeId = '0121W000000MK8N';
        }
        for(String aliField: fieldMapping.keySet()){
            String biField = fieldMapping.get(aliField);
            if(biField != null){
                singleBi.put(biField, ali.get(aliField));
            }
        }
        if(!ali.Apttus__Description__c.toLowerCase().contains('flex') && !ali.Apttus__Description__c.toLowerCase().contains('signal')){
            singleBi.Quantity__c = null;
        }
        return singleBi;
    }
    
    
    /***
     * Count how many AgreementLineItem with Product Min Commit == "Twilio SendGrid", 
     * then update Number_of_SendGrid_Products__c field in Agreemet object with the count number
     * 
     * @Author: Mia Cui  ncui@twilio.com
     * @CreatedDate: 9/16/19
     ***/
    //after insert, after delete, after undelete    
    public static void countSengGridLineItems(List<Apttus__AgreementLineItem__c> alisList) {
        List<ID> filterAgreenmentIDs = new List<ID>();
        List<Apttus__AgreementLineItem__c> filterALIS = new List<Apttus__AgreementLineItem__c>();
        for(Apttus__AgreementLineItem__c alisId:alisList) {
            filterAgreenmentIDs.add(alisId.Apttus__AgreementId__c);
        }
        
        List<Apttus__APTS_Agreement__c> agreementRet = [ SELECT id, Number_of_SendGrid_Products__c, 
                                                        (SELECT ID, Product_Min_Commit_Group__c FROM Apttus__AgreementLineItems__r WHERE Product_Min_Commit_Group__c ='Twilio SendGrid')
                                                         FROM Apttus__APTS_Agreement__c 
                                                         WHERE id IN :filterAgreenmentIDs];
        
        for(Apttus__APTS_Agreement__c agreement: agreementRet) {
            agreement.Number_of_SendGrid_Products__c = agreement.Apttus__AgreementLineItems__r.size();
        }
        update agreementRet;
        
    }
    
    /***
    public static void countSengGridLineItems2(List<Apttus__AgreementLineItem__c> alisList, Integer count) {
        //mapping agreement ID --> number need to added to Number_of_SendGrid_Products__c
        Map<ID, Integer> agreementMap = new Map<ID, Integer>();
        
        for(Apttus__AgreementLineItem__c alis: alisList) {
            if(alis.Product_Min_Commit_Group__c =='Twilio SendGrid') {

                if (agreementMap.get(alis.Apttus__AgreementId__c) == NULL) {
                    agreementMap.put(alis.Apttus__AgreementId__c, 0);
                }
                System.debug('====> add alis '+ alis);
                Integer newNumProd = agreementMap.get(alis.Apttus__AgreementId__c) + count;
                agreementMap.put(alis.Apttus__AgreementId__c, newNumProd);
                
            }
        }
        
        List<Apttus__APTS_Agreement__c> agreementRet = [ SELECT id, Number_of_SendGrid_Products__c
                                                         FROM Apttus__APTS_Agreement__c 
                                                         WHERE id IN :agreementMap.keySet()];
                                                     
        for(Apttus__APTS_Agreement__c agreement: agreementRet) {
            if (agreement.Number_of_SendGrid_Products__c == NULL) agreement.Number_of_SendGrid_Products__c = 0;
            agreement.Number_of_SendGrid_Products__c += agreementMap.get(agreement.ID);
        }
        update agreementRet;
        
    }***/
    
    
    //trigger on update
    public static void countSengGridLineItemsUpdate(Map<ID, Apttus__AgreementLineItem__c> newMap, Map<ID, Apttus__AgreementLineItem__c> oldMap) {
        List<ID> filterAgreenmentIDs = new List<ID>();
        List<Apttus__AgreementLineItem__c> filterALIS = new List<Apttus__AgreementLineItem__c>();
        for(ID alisId: newMap.KeySet()) {
            if (newMap.get(alisId).Apttus__AgreementId__c != oldMap.get(alisId).Apttus__AgreementId__c ||
                newMap.get(alisId).Product_Min_Commit_Group__c != oldMap.get(alisId).Product_Min_Commit_Group__c) {
                filterAgreenmentIDs.add(newMap.get(alisId).Apttus__AgreementId__c);
            }
        }
        
        if(filterAgreenmentIDs.size() == 0)return;
        
        List<Apttus__APTS_Agreement__c> agreementRet = [ SELECT id, Number_of_SendGrid_Products__c, 
                                                        (SELECT ID, Product_Min_Commit_Group__c FROM Apttus__AgreementLineItems__r WHERE Product_Min_Commit_Group__c ='Twilio SendGrid')
                                                         FROM Apttus__APTS_Agreement__c 
                                                         WHERE id IN :filterAgreenmentIDs];
                                                     
        for(Apttus__APTS_Agreement__c agreement: agreementRet) {
            agreement.Number_of_SendGrid_Products__c = agreement.Apttus__AgreementLineItems__r.size();
        }
        update agreementRet;
        
    }
}