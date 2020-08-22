/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchCalculateUsageEmea
*
* @description    Batch class for Emea region
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        
* @modified       2019-05-03 (yy-mm-dd)
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
global class BatchCalculateUsageEmea extends BatchCalculateUsage implements Database.Batchable<SObject>, Schedulable{
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCalculateUsageEmea());
    }
    
    global override Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id,Owner.UserRole.Name FROM Account 
                                         where Owner.UserRole.Name LIKE '%EMEA%']);
    }
    
}