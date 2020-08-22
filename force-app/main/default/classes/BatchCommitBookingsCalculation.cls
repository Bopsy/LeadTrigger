/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchCommitBookingsCalculation
*
* @description    Batch class to run commit booking calculation
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-12-19
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes   
* @ChangeLog 
*
**/
public class BatchCommitBookingsCalculation implements Database.Batchable<SObject>, Schedulable {
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCommitBookingsCalculation(),1);
    }
    
    public List<sObject> start(Database.BatchableContext bc){
        List<sObject> scope = new List<sObject>();
        scope.addAll([Select Id from Apttus__APTS_Agreement__c Where Lastmodifieddate = LAST_N_DAYS:7 and Apttus__Status__c= 'Activated']);
        scope.addAll([Select Id, Agreement__c from Single_BI_Tier__c Where Lastmodifieddate = LAST_N_DAYS:7 and Agreement__c!=null and Agreement__r.Apttus__Status__c= 'Activated']);
        scope.addAll([Select Id, Agreement__c from Commit_Schedule__c Where Lastmodifieddate = LAST_N_DAYS:7 and Agreement__c!=null and Agreement__r.Apttus__Status__c= 'Activated']);
        return scope;
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        Set<Id> agreementIds = new Set<Id>();
        if(scope.size()>0){
            for(sObject rec: scope){
                if (rec.getSObjectType() == Apttus__APTS_Agreement__c.sObjectType) {
                    agreementIds.add(((Apttus__APTS_Agreement__c) rec).Id);
                } else if (rec.getSObjectType() == Single_BI_Tier__c.sObjectType){
                    agreementIds.add(((Single_BI_Tier__c) rec).Agreement__c);
                } else if (rec.getSObjectType() == Commit_Schedule__c.sObjectType) {
                    agreementIds.add(((Commit_Schedule__c) rec).Agreement__c);
                }
            }
        }
        List<Apttus__APTS_Agreement__c> lstAgreements = [SELECT Id,Apttus__Status__c,Related_Opportunity_APTS__c,APTS_Agreement_Effective_Date__c,Commit_Type__c
                                                         FROM Apttus__APTS_Agreement__c WHERE Apttus__Status__c = 'Activated' AND RecordType.Name = 'Order Form' 
                                                         AND Commit_Type__c != null AND Related_Opportunity_APTS__c != null and ID IN: agreementIds and Id In 
                                                         (SELECT Agreement__c FROM Commit_Booking__c where Comp_Validation_Status__c='Auto-Validated' 
                                                          and Opportunity__r.Committed_Bookings_Sales_Ops_Verified__c=false)];
        System.debug('++lstAgreements size '+lstAgreements.size());
        System.debug('++lstAgreements '+lstAgreements);
        CommitBookingHelper.getCommitBookings(lstAgreements);
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}