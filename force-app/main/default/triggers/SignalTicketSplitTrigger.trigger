/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  SignalTicketSplitTrigger
*
* @description 	  Trigger on the Signal_Ticket_Split__c object.
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
trigger SignalTicketSplitTrigger on Signal_Ticket_Split__c (after insert, after update, after delete,
                                                            before insert) {
	if(trigger.isBefore){
        if(trigger.isInsert){
            SignalTicketSplitTriggerService.setQuotaLookups(Trigger.new);
        }
    } else if (trigger.isAfter){
        if(trigger.isInsert){
            SignalTicketSplitTriggerService.calculateSignalTicketQuota(Trigger.new);
        }
        if(trigger.isUpdate){
            SignalTicketSplitTriggerService.calculateSignalTicketQuota(Trigger.oldMap, Trigger.newMap);
        }
        if(trigger.isDelete){
            SignalTicketSplitTriggerService.calculateSignalTicketQuota(Trigger.old);
        }
    }
}