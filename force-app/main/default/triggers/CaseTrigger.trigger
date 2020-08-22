/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           CaseTrigger
*
* @description    check input SID vadality before inser/update
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui     <ncui@twilio.com>
* @modifiedBy     Mia Cui     <ncui@twilio.com>
* @version        1.0
* @created        2019-09-19
* @modified       2019-09-19
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes 
**/


trigger CaseTrigger on Case (before insert, before update) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            CaseTriggerHandler.checkSID(trigger.new);
        }
        if(trigger.isUpdate){
            CaseTriggerHandler.checkSID(trigger.newMap, trigger.oldMap);
        }
    }
}