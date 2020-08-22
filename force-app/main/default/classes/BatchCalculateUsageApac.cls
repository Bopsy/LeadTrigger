/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchCalculateUsageApac
*
* @description    Batch class for Apac region
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
global class BatchCalculateUsageApac extends BatchCalculateUsage implements Database.Batchable<SObject>, Schedulable{
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCalculateUsageApac());
    }
    
    global override Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id,Owner.UserRole.Name FROM Account 
                                         where Owner.UserRole.Name LIKE '%APAC%']);
    }
    
}