/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  BatchUpdateLicenseDate
*
* @description 	  Batch class that updates License's next_Billing_Date to current date when 
				  Status is Active and SID is present
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui	 <ncui@twilio.com>
* @modifiedBy     Mia Cui    <ncui@twilio.com>
* @version        1.0
* @created        2019-08-27
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		
*
**/
global class BatchUpdateLicenseDate implements Database.Batchable<SObject>, Schedulable{
    global date overrideDate;
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchUpdateLicenseDate(), 200);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT ID, Next_Billing_Date__c 
                                         FROM sfLma__License__c 
                                         WHERE sfLma__License_Status__c = 'Active'
                                         AND Account_SID__c != NULL]);
    }
    
    global void execute(Database.BatchableContext bc, List<sfLma__License__c> licenseRecs){
        for(sfLma__License__c licRec: licenseRecs) {
            licRec.Next_Billing_Date__c = Date.today();
            if (overrideDate != NULL) {
                licRec.Next_Billing_Date__c = overrideDate;
            }
        }
        update licenseRecs;
    }
    
    global void finish(Database.BatchableContext bc){
        
    }

}