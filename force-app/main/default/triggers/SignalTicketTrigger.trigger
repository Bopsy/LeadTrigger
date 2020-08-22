/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  SignalTicketTrigger
*
* @description 	  Trigger on the Signal_Ticket__c object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2020-02-20
* @modified       2020-02-20
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*
**/
trigger SignalTicketTrigger on Signal_Ticket__c (after update) {
	if(trigger.isBefore){
        if(trigger.isInsert){
            
        }
    } else if (trigger.isAfter){
        if(trigger.isInsert){
            
        }
        if(trigger.isUpdate){
            SignalTicketSplitTriggerService.calculateSignalTicketQuota(Trigger.oldMap, Trigger.newMap);
        }
        if(trigger.isDelete){
            
        }
    }
}