/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           orgApplicationTrigger
*
* @description    orgApplicationTrigger 
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui     <ncui@twilio.com>
* @modifiedBy     Mia Cui     <ncui@twilio.com>
* @version        1.0
* @created        2020-04-15
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger orgApplicationTrigger on org_Application__c (after insert) {
    if(trigger.isAfter) {
        orgApplicationHandler.addCampaignMember(Trigger.new);
    }
}