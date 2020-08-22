/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  BatchUpdateRecordsWithLeadEmailOptOut
*
* @description 	  Batch class that updates Opportunities and Risk Reports with a lookup to a relevant CTA.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-11-13
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
global class BatchUpdateRecordsWithLeadEmailOptOut implements Database.Batchable<SObject>, Schedulable{
    global void execute(SchedulableContext sc) {
        //Set scheduler action
        Database.executeBatch(new BatchUpdateRecordsWithLeadEmailOptOut(), 200);
    }
	
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, Email, HasOptedOutOfEmail FROM Lead WHERE HasOptedOutOfEmail = TRUE AND Email != null]);
    }
    
    global void execute(Database.BatchableContext bc, List<Lead> leadRecs){
        Set<String> uniqueOptedOutEmails = new Set<String>();
        List<Lead> leadsForUpdate = new List<Lead>();
        List<Contact> contsForUpdate = new List<Contact>();
        uniqueOptedOutEmails = EmailOptOutServices.getEmailSet(leadRecs);
        leadsForUpdate = EmailOptOutServices.getLeadsForEmailOptOut(uniqueOptedOutEmails);
        contsForUpdate = EmailOptOutServices.getContactsForEmailOptOut(uniqueOptedOutEmails);
        
        if(!leadsForUpdate.isEmpty()){
            Database.update(leadsForUpdate, false);
        }
        
        if(!contsForUpdate.isEmpty()){
            Database.update(contsForUpdate, false);
        }
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}