/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchCalculateUsage
*
* @description    Parent Batch class to calculate usage
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
global abstract class BatchCalculateUsage implements Database.Batchable<SObject>{
    
    global abstract Database.queryLocator start(Database.BatchableContext bc);
    
    global void execute(Database.BatchableContext bc, List<Account> accounts){
        system.debug('+++accounts '+accounts);
        AccountUsageService.calculateUsage(accounts);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}