/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  AttachmentTrigger
*
* @description 	  Trigger on the Attachment object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-11-05
* @modified       2019-11-05
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  Not created by @jayu.  Updated on 2019-11-05.
*
**/
trigger AttachmentTrigger on Attachment (before insert, after insert) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            AttachmentTriggerHandler.beforeInsertAgreement(trigger.new);
            AttachmentTriggerHandler.setContentTypeToPDF(trigger.new);
        }
    }
    else if(trigger.isAfter){
        if(trigger.isInsert){
            AttachmentTriggerHandler.afterInsertAgreement(trigger.new);
            AttachmentTriggerHandler.afterInsertDocVersionDetail(trigger.new);
        }
    }
}