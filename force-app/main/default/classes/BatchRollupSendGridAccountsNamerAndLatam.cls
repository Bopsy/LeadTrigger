/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchRollupSendGridAccountsNamerAndLatam
*
* @description    Batch class to rollup(Count) SendGrid Accounts related to a Namer and Latam region
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     
* @version        1.0
* @created        2018-02-06 (yy-mm-dd)
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
**/
global class BatchRollupSendGridAccountsNamerAndLatam extends BatchRollupSendGridAccounts implements Database.Batchable<SObject>, Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchRollupSendGridAccountsNamerAndLatam(),10);
    }
    
    global override Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id FROM Account WHERE Id In (SELECT Account__c FROM SendGrid_Account__c) 
                                         and (Not Owner.UserRole.Name LIKE '%EMEA%') and (Not Owner.UserRole.Name LIKE '%APAC%')]);
    }
    
}