/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  Apts_ApprovalRequestTrigger
*
* @description 	  Trigger for Apttus_Approval__Approval_Request__c object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2018-02-28
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger Apts_ApprovalRequestTrigger on Apttus_Approval__Approval_Request__c (after insert,after delete, after undelete, after update, before insert, before update) {
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUndelete || trigger.isDelete){
       		Apts_ApprovalRequestTriggerHandler.updateConfigTotal(trigger.isDelete ? trigger.old : trigger.new,trigger.isDelete ? true : false);
        }
        if(trigger.isUpdate){
            Apts_ApprovalRequestTriggerHandler.updateConfigTotalOnUpdate(trigger.new,trigger.oldMap,trigger.newMap);
        }
    }
    if(trigger.isBefore){
        if(trigger.isInsert || trigger.isUpdate){
            Apts_ApprovalRequestTriggerHandler.updateQuote(trigger.new);
        }
    }
}