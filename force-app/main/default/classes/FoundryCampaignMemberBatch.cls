/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  FoundryCampaignMemberBatch
*
* @description 	  Batch class that add contact role from Foundry Request Associated Opportuhnity 
				  to the Foundry Campaign 
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui	 <ncui@twilio.com>
* @modifiedBy     Mia Cui    <ncui@twilio.com>
* @version        1.0
* @created        2020-03-04
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		
*
**/
global class FoundryCampaignMemberBatch implements Database.Batchable<SObject>, Schedulable{
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new FoundryCampaignMemberBatch(), 100);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        
        //get all Foundry Request Record that is approved && before its meeting Date 
        return Database.getQueryLocator([SELECT Opportunity__c, Campaign__c,Meeting_Date__c
                                         FROM Foundry_Deal_Support_Request__c 
                                         WHERE Status__c = 'Approved'
                                         AND Campaign__c != NULL
                                         AND Meeting_Date__c >= Today]);
        
    
    }
    
    global void execute(Database.BatchableContext bc, List<Foundry_Deal_Support_Request__c> foundryList){
        FoundryDSRTriggerService.addCampaignMember(foundryList);
        
        
        
    }
    
    global void finish(Database.BatchableContext bc){
        
    }

}