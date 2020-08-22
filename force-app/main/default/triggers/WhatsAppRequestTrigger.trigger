/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           WhatsAppRequestTrigger
*
* @description    Trigger for whatsapp request object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-08-12
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger WhatsAppRequestTrigger on WhatsApp_Request__c (before insert, before update) {
    
    if(Trigger.isBefore){
        if(Trigger.isInsert){
           // WhatsAppRequestTriggerHandler.linkOnInsert(Trigger.new);
           WhatsAppRequestTriggerHandler.updateMQLOnInsert(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
           // WhatsAppRequestTriggerHandler.linkOnUpdate(Trigger.oldMap, Trigger.new);
           WhatsAppRequestTriggerHandler.updateMQLOnUpdate(Trigger.oldMap, Trigger.new);
        }
    } 
        
}