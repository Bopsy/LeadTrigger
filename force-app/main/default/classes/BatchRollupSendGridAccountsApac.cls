/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchRollupSendGridAccountsApac
*
* @description    Batch class to rollup(Count) SendGrid Accounts related to a Apac region
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     
* @version        1.0
* @created        2018-02-06 (yy-mm-dd)
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
**/
global class BatchRollupSendGridAccountsApac extends BatchRollupSendGridAccounts implements Database.Batchable<SObject>, Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchRollupSendGridAccountsApac(),10);
    }
    
    global override Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id 
                                         FROM Account
                                         WHERE Id In (SELECT Account__c FROM SendGrid_Account__c) and Owner.UserRole.Name LIKE '%APAC%']);
    }
    
}