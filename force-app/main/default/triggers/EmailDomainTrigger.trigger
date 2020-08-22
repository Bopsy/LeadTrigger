/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  EmailDomainTrigger
*
* @description 	  Trigger code on Email domain object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2018-01-25
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger EmailDomainTrigger on Email_Domain__c (before insert) {
	
    if(Trigger.isBefore && Trigger.isInsert){
        //Class to auto approve email domains. Logical test to see if email domain is created by a user in the blacklist
        EmailDomainTriggerHandler.autoApproveEmailDomains(trigger.new);
    }
}