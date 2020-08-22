trigger CTATrigger on JBCXM__CTA__c (before insert, before update) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            CTATriggerServices.beforeInsert(trigger.new);
        }
        if(trigger.isUpdate){
            CTATriggerServices.beforeUpdate(trigger.newMap, trigger.oldMap);
        }
    }
}