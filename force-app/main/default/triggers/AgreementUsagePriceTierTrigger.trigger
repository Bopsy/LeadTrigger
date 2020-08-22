trigger AgreementUsagePriceTierTrigger on Apttus_CMConfig__AgreementUsagePriceTier__c (after insert, after delete) {
    if(Trigger.isInsert){
        //if(!AgreementLineItemServices.isInFuture) 
        AgreementLineItemServices.afterInsert(trigger.new);
        AgreementUsagePriceTierTriggerHandler.countSendGridTier(Trigger.new);
    }
    if(Trigger.isDelete){
        AgreementUsagePriceTierTriggerHandler.countSendGridTier(Trigger.old);
    }
}