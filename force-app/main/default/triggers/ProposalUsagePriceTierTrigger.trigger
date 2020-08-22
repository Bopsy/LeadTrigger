trigger ProposalUsagePriceTierTrigger on Apttus_QPConfig__ProposalUsagePriceTier__c (before insert) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            Map<String, List<Apttus_QPConfig__ProposalUsagePriceTier__c>> priceMatrixIdtoLineItemIdMap = new Map<String, List<Apttus_QPConfig__ProposalUsagePriceTier__c>>();
            for(Apttus_QPConfig__ProposalUsagePriceTier__c tier: trigger.new){
                List<Apttus_QPConfig__ProposalUsagePriceTier__c> priceTiers = priceMatrixIdtoLineItemIdMap.get(tier.Apttus_QPConfig__PriceMatrixId__c);
                if(priceTiers == null) priceTiers = new List<Apttus_QPConfig__ProposalUsagePriceTier__c>();
                priceTiers.add(tier);
                priceMatrixIdtoLineItemIdMap.put(tier.Apttus_QPConfig__PriceMatrixId__c, priceTiers);
            }
            
            List<Apttus_Config2__PriceMatrixEntry__c> priceEntries = [SELECT Apttus_Config2__TierStartValue__c, Apttus_Config2__TierEndValue__c, Apttus_Config2__UsageRate__c, Apttus_Config2__PriceMatrixId__c FROM Apttus_Config2__PriceMatrixEntry__c WHERE Apttus_Config2__PriceMatrixId__c =: priceMatrixIdtoLineItemIdMap.keySet()];
            if(priceEntries.isEmpty()) return;
            
            Map<String, List<Apttus_Config2__PriceMatrixEntry__c>> priceMaps = new Map<String, List<Apttus_Config2__PriceMatrixEntry__c>>();
            for(Apttus_Config2__PriceMatrixEntry__c priceEntry: priceEntries){List<Apttus_Config2__PriceMatrixEntry__c> entries = priceMaps.get(priceEntry.Apttus_Config2__PriceMatrixId__c); if(entries == null) entries = new List<Apttus_Config2__PriceMatrixEntry__c>(); entries.add(priceEntry);priceMaps.put(priceEntry.Apttus_Config2__PriceMatrixId__c, entries);}
            
            for(String priceMatrixId: priceMatrixIdtoLineItemIdMap.keySet()){
                List<Apttus_QPConfig__ProposalUsagePriceTier__c> tiers = priceMatrixIdtoLineItemIdMap.get(priceMatrixId);
                List<Apttus_Config2__PriceMatrixEntry__c> entries = priceMaps.get(priceMatrixId);
                for(Apttus_QPConfig__ProposalUsagePriceTier__c tier: tiers){
                    for(Apttus_Config2__PriceMatrixEntry__c entry: entries){
                        if(tier.Apttus_QPConfig__TierStartValue__c == entry.Apttus_Config2__TierStartValue__c && tier.Apttus_QPConfig__TierEndValue__c == entry.Apttus_Config2__TierEndValue__c){
                            entry.Apttus_Config2__UsageRate__c = entry.Apttus_Config2__UsageRate__c == null ? 0 : entry.Apttus_Config2__UsageRate__c;
                            tier.Tier_List_Price_Stamp__c = entry.Apttus_Config2__UsageRate__c;
                            break;
                        }
                    }
                }
            }
        }
    }
}