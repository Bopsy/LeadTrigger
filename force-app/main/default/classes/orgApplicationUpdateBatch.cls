/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  orgApplicationUpdateBatch
*
* @description 	  Batch class that populdate contact field if tagged lead is converted, and then 
				  clear the lead field
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui	 <ncui@twilio.com>
* @modifiedBy     Mia Cui    <ncui@twilio.com>
* @version        1.0
* @created        2020-02-19
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		
*
**/
global class orgApplicationUpdateBatch implements Database.Batchable<SObject>, Schedulable{
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new orgApplicationUpdateBatch(), 200);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT contact__c, lead__r.ConvertedContactId, lead__c
                                         FROM org_Application__c
                                         Where lead__c != NULL
                                         AND lead__r.isconverted = True
                                         ]);
    }
    
    global void execute(Database.BatchableContext bc, List<org_Application__c> orgApplicationList){
        for(org_Application__c orgApp: orgApplicationList) {
            orgApp.contact__c = orgApp.lead__r.ConvertedContactId ;
            orgApp.lead__c = NULL;
        }
        update orgApplicationList;
    }
    
    global void finish(Database.BatchableContext bc){
        
    }

}