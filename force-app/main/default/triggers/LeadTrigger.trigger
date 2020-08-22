trigger LeadTrigger on Lead (before insert, after update, before update,after insert,after undelete, after delete) {
    Trigger_Bypass_Settings__c trigBypass = Trigger_Bypass_Settings__c.getInstance(UserInfo.getUserId());
    if(trigBypass != null){
        if(trigBypass.Lead__c == TRUE){ 
            return; 
        }
	}
    
	if (trigger.isBefore) {
		if(trigger.isInsert){
            EmailOptOutServices.checkDuplicateRecordsForEmailOptOut(trigger.new);
            EmailOptOutServices.checkThirdPartyDataSource(trigger.new);
            //add webstie Function
            LeadTriggerHandlerService.websiteFieldUpdate(new Map<Id, Lead>(), trigger.new);
        } else if (trigger.isUpdate) {
            //add website Function
            LeadTriggerHandlerService.websiteFieldUpdate(trigger.oldMap, trigger.new);
        }
    } else if (trigger.isAfter){
        if(trigger.isUpdate){
            EmailOptOutServices.optOutDuplicateRecordsWithMatchingEmail(trigger.new, trigger.oldMap);
            //Added by Amrutha - for MQL window creation
            if(TriggerRunOnceUtility.ContactLeadMqlWindowHandler==false){
            	ContactLeadMqlWindowHandler.onUpdateLead(trigger.new, trigger.oldMap);
            }
        }
        if(trigger.isInsert || trigger.isUndelete){
            //Added by Amrutha - for MQL window creation
            ContactLeadMqlWindowHandler.onInsertLead(trigger.new);
        }
        if(trigger.isDelete){
            PersonMergeServices.afterDelete(trigger.old);
        }
    }
}