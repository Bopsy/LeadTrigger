/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           SGPriceConcessionTrigger
*
* @description    Trigger code on Sendgrid price concession object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-10-02
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger SGPriceConcessionTrigger on SendGrid_Price_Concession__c (before insert,before update) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            SGPriceConcessionTriggerHandler.onInsert(trigger.new);
        }
        if(trigger.isUpdate){
            SGPriceConcessionTriggerHandler.onUpdate(trigger.oldmap,trigger.new);
        }
    }
}