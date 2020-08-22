trigger UsagePriceTierTrigger on Apttus_Config2__UsagePriceTier__c (before insert, after update) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            //Added by Amrutha - set tier price from price matrix entry
            UsagePriceTierTriggerServices.beforeInsert(trigger.new);
        }
    }
    else if(trigger.isAfter){
        if(trigger.isUpdate){
            Map<Id, Apttus_Config2__LineItem__c> updateLineItems = new Map<Id, Apttus_Config2__LineItem__c>();
            for(Apttus_Config2__UsagePriceTier__c tier: trigger.new){
                if(tier.Apttus_Config2__UsageRate__c != tier.Tier_List_Price_Stamp__c || tier.Tier_Floor_Stamp__c != tier.Apttus_Config2__TierStartValue__c || tier.Tier_Ceiling_Stamp__c != tier.Apttus_Config2__TierEndValue__c){
                    updateLineItems.put(tier.Apttus_Config2__LineItemId__c,  new Apttus_Config2__LineItem__c(Tier_Changed_Number__c = 1, Id = tier.Apttus_Config2__LineItemId__c, Apttus_Config2__Guidance__c = 'Red'));
                }
            }
            for(Apttus_Config2__UsagePriceTier__c tier: trigger.new){
                if(!updateLineItems.containsKey(tier.Apttus_Config2__LineItemId__c)){
                    updateLineItems.put(tier.Apttus_Config2__LineItemId__c,  new Apttus_Config2__LineItem__c(Tier_Changed_Number__c = 0,Id = tier.Apttus_Config2__LineItemId__c, Apttus_Config2__Guidance__c = 'Green'));
                }
            }
            if(!updateLineItems.isEmpty()){
                update updateLineItems.values();
            }
        }
    }

}