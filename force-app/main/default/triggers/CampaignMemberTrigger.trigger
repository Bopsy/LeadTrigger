/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CampaignMemberTrigger
*
* @description 	  Main trigger for the CampaignMember object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-10-08
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*
**/
trigger CampaignMemberTrigger on CampaignMember (before insert) {
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            CampaignMemberTriggerHandler.setCoreCountryCampaignId(Trigger.new);
        }
    }
}