/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  MQLWindowTrigger
*
* @description 	  Main trigger for the MQL_Window__c object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-11-05
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*
**/
trigger MQLWindowTrigger on MQL_Window__c (after insert, after update) {
    if(Trigger.isBefore){
        
    } else if (Trigger.isAfter){
        if(Trigger.isInsert){
            //MQLWindowTriggerHandler.deleteDuplicateMQLWindows(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isUpdate){
            MQLWindowTriggerHandler.deleteDuplicateMQLWindows(Trigger.new, Trigger.oldMap);
        }
    }
}