/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  QuoteSOPDataStampBatch
*
* @description 	  Batch class that Stamping First LI date, First Created Date, First Approval time 
				  on Quote/Proposal
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
global class QuoteSOPDataStampBatch implements Database.Batchable<SObject>, Schedulable{
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new QuoteSOPDataStampBatch(), 20);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, First_LI_created_date__c,
                                            First_Configuration_Finalized_Date__c,First_Configuration_Approval_Time__c,
                                        (SELECT First_LI_created_date__c, Apttus_Config2__FinalizedDate__c,Total_Hours_to_Approve_Request__c 
                                                     FROM Apttus_QPConfig__Configurations__r 
                                                     ORDER BY First_LI_created_date__c NULLS LAST)
                                         FROM Apttus_Proposal__Proposal__c 
                                         WHERE First_LI_created_date__c = NULL
                                         OR First_Configuration_Finalized_Date__c = NULL
                                         OR First_Configuration_Approval_Time__c = NULL]);
    }
    
    global void execute(Database.BatchableContext bc, List<Apttus_Proposal__Proposal__c> quotes){

        QuoteSOPDataStampService.stampQuote(quotes);
        
    }
    
    global void finish(Database.BatchableContext bc){
        
    }

}