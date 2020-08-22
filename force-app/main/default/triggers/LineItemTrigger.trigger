trigger LineItemTrigger on Apttus_Config2__LineItem__c (before insert, before update, after delete, after update, after insert) {
    
    if(trigger.isBefore){
        if(trigger.isInsert){
            for(Apttus_Config2__LineItem__c lineItem: trigger.new){
                if(lineItem.Apttus_Config2__AssetLineItemId__c != null){
                    lineItem.Apttus_Config2__AdjustmentType__c = 'Base Price Override';
                    lineItem.Apttus_Config2__AdjustmentAmount__c = lineItem.Apttus_Config2__NetUnitPrice__c;
                }
            }
        }
        Map<Id, Decimal> bundleNetPriceMap = new Map<Id, Decimal>();
        for(Apttus_Config2__LineItem__c lineItem: trigger.new){
            if(lineItem.Is_Bundle_Product__c){
                bundleNetPriceMap.put(lineItem.Apttus_Config2__ProductId__c, lineItem.Custom_Unit_Price__c);
            }
            if(trigger.isInsert && lineItem.Apttus_Config2__DerivedFromId__c != null){
                lineItem.Apttus_CQApprov__Approval_Status__c = lineItem.Derived_Approval_Status__c;
            }
        }
        
        for(Apttus_Config2__LineItem__c lineItem: trigger.new){
            if(lineItem.Is_Bucket_Option__c){
                Decimal netUnitPrice = bundleNetPriceMap.get(lineItem.Apttus_Config2__ProductId__c);
                if(netUnitPrice != null){
                    lineItem.Apttus_Config2__ListPrice__c = netUnitPrice;
                    lineItem.Apttus_Config2__BasePrice__c = netUnitPrice;
                    lineItem.Apttus_Config2__NetUnitPrice__c = netUnitPrice;
                }
            }
        }
        
        LineItemTriggerServices.workFlowsIntoCode(trigger.new);
        
        if(trigger.isUpdate){
            LineItemTriggerServices.beforeUpdate(trigger.new, trigger.oldMap);
        }
        else if(trigger.isInsert){
            LineItemTriggerServices.beforeInsert(trigger.new);
        }
    }
    
    if(trigger.isAfter){
        //Apttus deletes and inserts line items when discount is updated, so handling on delete
        if(trigger.isInsert){
            LineItemTriggerServices.populateAttributeValue(trigger.new);
        }
        if(trigger.isDelete){
            LineItemTriggerServices.afterDelete(trigger.old);
        }
        //Apttus updates first line item when discount is updated, so handling on update
        if(trigger.isUpdate){
            LineItemTriggerServices.afterUpdate(trigger.new, trigger.oldmap);
        }
    }
}