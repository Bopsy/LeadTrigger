/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  UsagePriceTierTriggerServices
*
* @description 	  Service class for UsagePriceTierTrigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2019-04-29
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class UsagePriceTierTriggerServices {
    public static void beforeInsert(List<Apttus_Config2__UsagePriceTier__c> tierItems){
        Map<String, List<Apttus_Config2__UsagePriceTier__c>> priceMatrixIdtoLineItemIdMap = new Map<String, List<Apttus_Config2__UsagePriceTier__c>>();
        for(Apttus_Config2__UsagePriceTier__c tier: tierItems){
            List<Apttus_Config2__UsagePriceTier__c> priceTiers = priceMatrixIdtoLineItemIdMap.get(tier.Apttus_Config2__PriceMatrixId__c);
            if(priceTiers == null) priceTiers = new List<Apttus_Config2__UsagePriceTier__c>();
            priceTiers.add(tier);
            priceMatrixIdtoLineItemIdMap.put(tier.Apttus_Config2__PriceMatrixId__c , priceTiers);
        }
        
        List<Apttus_Config2__PriceMatrixEntry__c> priceEntries = [SELECT Apttus_Config2__TierStartValue__c, Apttus_Config2__TierEndValue__c, Apttus_Config2__UsageRate__c, Apttus_Config2__PriceMatrixId__c FROM Apttus_Config2__PriceMatrixEntry__c WHERE Apttus_Config2__PriceMatrixId__c =: priceMatrixIdtoLineItemIdMap.keySet()];
        if(priceEntries.isEmpty()) return;
        
        Map<String, List<Apttus_Config2__PriceMatrixEntry__c>> priceMaps = new Map<String, List<Apttus_Config2__PriceMatrixEntry__c>>();
        for(Apttus_Config2__PriceMatrixEntry__c priceEntry: priceEntries){List<Apttus_Config2__PriceMatrixEntry__c> entries = priceMaps.get(priceEntry.Apttus_Config2__PriceMatrixId__c); if(entries == null) entries = new List<Apttus_Config2__PriceMatrixEntry__c>(); entries.add(priceEntry);priceMaps.put(priceEntry.Apttus_Config2__PriceMatrixId__c, entries);}
        
        for(String priceMatrixId: priceMatrixIdtoLineItemIdMap.keySet()){
            List<Apttus_Config2__UsagePriceTier__c> tiers = priceMatrixIdtoLineItemIdMap.get(priceMatrixId);
            List<Apttus_Config2__PriceMatrixEntry__c> entries = priceMaps.get(priceMatrixId);
            if(tiers!=null && tiers.size()>0){
                for(Apttus_Config2__UsagePriceTier__c tier: tiers){
                    if(entries!=null && entries.size()>0){
                        for(Apttus_Config2__PriceMatrixEntry__c entry: entries){
                            if(tier.Apttus_Config2__TierStartValue__c == entry.Apttus_Config2__TierStartValue__c && tier.Apttus_Config2__TierEndValue__c == entry.Apttus_Config2__TierEndValue__c){
                                entry.Apttus_Config2__UsageRate__c = entry.Apttus_Config2__UsageRate__c == null ? 0 : entry.Apttus_Config2__UsageRate__c;
                                tier.Tier_List_Price_Stamp__c = entry.Apttus_Config2__UsageRate__c;
                                break;
                            }
                        }
                    }
                }
            }
        }
        for(Apttus_Config2__UsagePriceTier__c tier: tierItems){
            tier.Tier_Floor_Stamp__c = tier.Apttus_Config2__TierStartValue__c;
            tier.Tier_Ceiling_Stamp__c = tier.Apttus_Config2__TierEndValue__c;
            tier.Apttus_Config2__UsageRate__c = tier.Tier_List_Price_Stamp__c;
        }
    }
}