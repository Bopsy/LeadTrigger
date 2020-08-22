/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchRollupSendGridAccounts
*
* @description    Parent Batch class to rollup(Count) SendGrid Accounts related to a Account
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2018-02-06
* @modified       2018-05-06 (yy-mm-dd)
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes   Davis Dong <ddong@twilio.com>
* @ChangeLog Change query locator to optimize query
*
**/
global abstract class BatchRollupSendGridAccounts implements Database.Batchable<SObject>, Schedulable {
    global abstract Database.queryLocator start(Database.BatchableContext bc);
    
    global void execute(Database.BatchableContext bc, List<Account> lstAccount){
        system.debug('+++lstAccount '+lstAccount);
        BatchAccountSIDServices.rollupSendGrid(lstAccount);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}