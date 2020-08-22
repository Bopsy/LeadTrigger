trigger AccSIDSKUTrigger on Account_SID_SKU__c (before insert, before update, after insert) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            MRRCalculationServices.populateOppSIDSKU(trigger.new);
            MRRCalculationServices.beforeInsert(trigger.new, false, false);
        }
        if(trigger.isUpdate){
            MRRCalculationServices.populateOppSIDSKU(trigger.new);
            MRRCalculationServices.updateProductSchedule(trigger.new, trigger.oldMap);
        }
    }
    else if(trigger.isAfter){
        if(trigger.isInsert){
            MRRCalculationServices.updateProductSchedule(trigger.new, new Map<Id, Account_SID_SKU__c>());
            MRRCalculationServices.recalculateNBAccountSIDDate(trigger.new.deepClone(true, true));
        }
    }

}