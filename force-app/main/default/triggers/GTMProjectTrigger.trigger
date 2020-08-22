/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           GTMProjectTrigger
*
* @description    Trigger for GTM Project object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-08-19
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger GTMProjectTrigger on Workstream__c (after insert, after update, after undelete) {
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUndelete){
            GTMProjectTriggerHandler.handleOnInsert(trigger.new);
        }
        if(trigger.isUpdate){
            GTMProjectTriggerHandler.handleOnUpdate(trigger.oldmap, trigger.new);
        }
    }
}