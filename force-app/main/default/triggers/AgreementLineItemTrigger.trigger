trigger AgreementLineItemTrigger on Apttus__AgreementLineItem__c (after insert, after update, after delete, after undelete) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            //if(System.isFuture() || trigger.newMap.size() <= 150){
                AgreementLineItemServices.afterInsert(trigger.new);
            //}
            //else{
            //    AgreementLineItemServices.isInFuture = true;
            //    Map<Id, Id> agreementIdMap = new Map<Id, Id>();
            //    for(Apttus__AgreementLineItem__c lineItem: trigger.new){
            //        agreementIdMap.put(lineItem.Related_Quote_ID__c, lineItem.Apttus__AgreementId__c);
            //    }
            //    for(String quoteId: agreementIdMap.keySet()){
            //        if(quoteId != null && agreementIdMap.get(quoteId) != null) AgreementLineItemServices.updateQuotePricing(quoteId, agreementIdMap.get(quoteId));
            //    }
            //}
            System.debug('===> start insert');
        	AgreementLineItemServices.countSengGridLineItems(trigger.new);
        } else if (trigger.isUpdate) {
            System.debug('===> start update');
            AgreementLineItemServices.countSengGridLineItemsUpdate(trigger.newMap, trigger.oldMap);
        } else if (trigger.isDelete) {
            System.debug('===> start delete');
            AgreementLineItemServices.countSengGridLineItems(trigger.old);
        } else if (trigger.isUnDelete) {
            System.debug('===> start undelete');
            AgreementLineItemServices.countSengGridLineItems(trigger.new);
        }
    
    }
}