trigger CreditCheckRequest on Credit_Check__c (after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            CreditCheckRequestServices.afterInsert(trigger.new);
        }
        if(trigger.isUpdate){
            CreditCheckRequestServices.afterUpdate(trigger.new, trigger.oldMap);
        }
    }
}