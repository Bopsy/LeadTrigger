/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchCommitStartDateIncludesShortCode
*
* @description    Batch class to update commit start date to 1st of month (runs 1st of every month)
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-26-12
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes   
* @ChangeLog 
*
**/
public class BatchCommitStartDateIncludesShortCode implements Database.Batchable<SObject>, Schedulable {
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCommitStartDateIncludesShortCode(),10);
    }
    
    public Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([Select Id, Commit_Start_Month__c from Apttus__APTS_Agreement__c where RecordType.Name = 'Order Form'
                                         and Apttus__Status__c != 'Activated' and Apttus__Status__c != 'In DocuSign' 
                                         and Apttus__Status__c != 'Contract Cancelled' and Apttus__Status__c != 'Closed Duplicate'
                                         and Apttus__Status__c != 'Closed - Duplicate' and Apttus__Status__c != 'Expired'
                                         and Apttus__Status__c != 'Terminated' and Apttus__Status__c != 'Cancelled' 
                                         and Allow_Backdated_Commit__c=false
                                         and Commit_Start_Month__c < Today]);
    }
    
    public void execute(Database.BatchableContext bc, List<Apttus__APTS_Agreement__c> lstAgreements){
        Date firstOfThisMonth = Date.today().toStartOfMonth();
        for(Apttus__APTS_Agreement__c objAgr: lstAgreements){
            objAgr.Commit_Start_Month__c = firstOfThisMonth;
        }
        database.update(lstAgreements,false);
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}