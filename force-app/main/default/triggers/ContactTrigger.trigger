//----------------------------------------------------------------------------------------------------------
// Trigger on Contact
//----------------------------------------------------------------------------------------------------------
trigger ContactTrigger on Contact (before insert, before update, after insert, after update, after undelete, after delete) {
    Trigger_Bypass_Settings__c trigBypass = Trigger_Bypass_Settings__c.getInstance(UserInfo.getUserId());
    if(trigBypass != null){
        if(trigBypass.Contact__c == TRUE){ 
            return; 
        }
    }
    
    if (trigger.isBefore) {
		if(trigger.isInsert){
			ContactTriggerHandler.onBeforeInsert(trigger.new);
            EmailOptOutServices.checkDuplicateRecordsForEmailOptOut(trigger.new);
            EmailOptOutServices.checkThirdPartyDataSource(trigger.new);
		}else if(trigger.isUpdate){
			ContactTriggerHandler.onBeforeUpdate(trigger.new, trigger.oldMap); 
		}
	} else if (trigger.isAfter) {
		ContactTriggerHandler.partnerPortalShowcaseCreateOpportunity(trigger.isInsert, trigger.newMap, trigger.oldMap);
        if(trigger.isUpdate){
            EmailOptOutServices.optOutDuplicateRecordsWithMatchingEmail(trigger.new, trigger.oldMap);
            //Added by Amrutha - for MQL window creation
            if(TriggerRunOnceUtility.ContactLeadMqlWindowHandler==false){
                ContactLeadMqlWindowHandler.onUpdateContact(trigger.new, trigger.oldMap);
            }
            
        }
        if(trigger.isInsert || trigger.isUndelete){
            //Added by Amrutha - for MQL window creation
            ContactLeadMqlWindowHandler.onInsertContact(trigger.new);
        }
        if(trigger.isDelete){
            PersonMergeServices.afterDelete(trigger.old);
        }
	}

//	if (Trigger.isAfter && Trigger.isUpdate) {
//		TimeUtils.setInferredTimezoneSidKey(Trigger.oldMap, Trigger.newMap);
//	}
}