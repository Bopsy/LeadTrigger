/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchCalculateUsageNamerAndLatam
*
* @description    Batch class for Namer and Latam regions
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
global class BatchCalculateUsageNamerAndLatam extends BatchCalculateUsage implements Database.Batchable<SObject>, Schedulable{
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCalculateUsageNamerAndLatam());
    }
    
    global override Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id FROM Account 
                                         where (Not Owner.UserRole.Name LIKE '%EMEA%') 
                                         and (Not Owner.UserRole.Name LIKE '%APAC%')]);
    }
    
}