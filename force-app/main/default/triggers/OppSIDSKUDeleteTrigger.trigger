trigger OppSIDSKUDeleteTrigger on Opp_SID_SKU__c (before delete, after update, after insert) {
    if(trigger.isBefore){
        if(trigger.isDelete){
            Set<Id> oppId = new Set<Id>();
            Set<Id> sidId = new Set<Id>();
            for(Opp_SID_SKU__c sku: trigger.old){
                oppId.add(sku.Opportunity__c);
                sidId.add(sku.Account_SID__c);
            }
            delete [SELECT Id FROM Account_SID_SKU__c WHERE Opportunity_Product__r.Opportunity__c =: oppId AND Account_SID__c =: sidId];
        }
    }
    else if(trigger.isAfter){
        if(trigger.isUpdate){
            MRRCalculationServices.afterUpdateOppSIDSKUs(trigger.new, trigger.oldMap);
        }
        else if(trigger.isInsert){
            OpportunitySKUHandler.createSKUs(trigger.new);
            Set<Id> oppSIDSKUIds = new Set<Id>();
            for(Opp_SID_SKU__c oppSKU: trigger.new){
                oppSIDSKUIds.add(oppSKU.Id);
            }
            AssetBasedQuotingServices.createAssetBasedLineItems(oppSIDSKUIds);
        }
    }
}