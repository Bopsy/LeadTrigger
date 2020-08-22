trigger CampaignMemberAfterTrigger on CampaignMember (after insert, after update, after delete, after undelete) {

	// Create a task activity for the owner of the Lead/Contact wheneven the CampaignMember
	// status reports "Open Email" or "Click Email.
	CampaignMemberTriggerHandler.createTask(Trigger.isUpdate, Trigger.isInsert, Trigger.oldMap, Trigger.newMap);
	
	// Create an FSR record whenever a Eloqua imports a Lead that is a Full Service Request
	CampaignMemberTriggerHandler.fsrUpsert(Trigger.isUpdate, Trigger.isInsert, Trigger.oldMap, Trigger.newMap);

	// When a CampaignMember has the Eloqua_Campaign_Association_Done__c set to true process
	// the lead to determine if a matching account can be found and if so convert the lead
	// and relate it to the account.
	//CampaignMemberTriggerHandler.autoconvert(Trigger.isUpdate, Trigger.isInsert, Trigger.oldMap, Trigger.newMap);
    
    //Added by Amrutha 08/12/2019 - To create whatsapp request records
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUndelete){
            WhatsAppRequestTriggerHandler.onInsertCampaignMembers(Trigger.new);
        }
        if(trigger.isUpdate){
            WhatsAppRequestTriggerHandler.onUpdateCampaignMembers(Trigger.new,trigger.oldmap);
        }
    }

}