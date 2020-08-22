trigger FoundryDSRTrigger on Foundry_Deal_Support_Request__c (after update) {
    if(trigger.isUpdate) FoundryDSRTriggerService.clearCampaignMember(trigger.new, trigger.oldMap);

}