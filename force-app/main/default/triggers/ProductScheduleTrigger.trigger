trigger ProductScheduleTrigger on Product_Schedule__c (after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            ProductScheduleServices.afterInsert(trigger.new);
        }
        else if(trigger.isUpdate){
            ProductScheduleServices.afterUpdate(trigger.new, trigger.oldMap);
        }
    }
}