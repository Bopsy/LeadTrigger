/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           DealWorkstreamTrigger
*
* @description    Trigger related to deal workstream object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-04-11
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger DealWorkstreamTrigger on Deal_Workstream__c (after insert, after undelete, after delete, after update, before insert, before update) {
   if(trigger.isBefore){
        if(trigger.isInsert){
            DealWorkstreamTriggerHandler.validateType(trigger.new);
        }
    }
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUndelete){
            DealWorkstreamTriggerHandler.workstreamTimelineOnInsert(trigger.new);
        }
        if(trigger.isUpdate){
            if(TriggerRunOnceUtility.DealWorkstreamTrigger==false){
                TriggerRunOnceUtility.DealWorkstreamTrigger=true;
                DealWorkstreamTriggerHandler.workstreamTimelineOnUpdate(trigger.new,trigger.oldMap);
            }
        }
        if(trigger.isDelete){
            DealWorkstreamTriggerHandler.workstreamTimelineOnDelete(trigger.old);
        }
    }
}