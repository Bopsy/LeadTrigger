/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           UserPermissionAutoTrigger 
*
* @description    automatically give **GlobalAM user Apttus_CLM_Sales_User and Apttus_CPQ_Twilio 
				  permission sets
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui     <ncui@twilio.com>
* @modifiedBy     Mia Cui     <ncui@twilio.com>
* @version        1.0
* @created        2019-07-15
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger UserPermissionAuto on User (after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            UserPermissionAutoService.afterInsert(trigger.new);
        }
        if(trigger.isUpdate){
            UserPermissionAutoService.afterUpdate(trigger.new);
        }
    }
}