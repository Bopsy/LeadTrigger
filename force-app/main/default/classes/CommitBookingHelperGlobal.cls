/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name  CommitBookingHelperGlobal
*
* @description  Global Helper class for Commit Booking functionality.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	<jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-11-20
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
global with sharing class CommitBookingHelperGlobal {
    webservice static void getCommitBookings(Id agreementId){
        Apttus__APTS_Agreement__c agrRec = [SELECT Id, Commit_Type__c, Related_Opportunity_APTS__c FROM Apttus__APTS_Agreement__c WHERE Id = :agreementId];
        List<RecordType> recTypes = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Commit_Booking__c'];
        Map<String, Id> recTypeMap = new Map<String, Id>();
        for(RecordType recType : recTypes){
            recTypeMap.put(recType.DeveloperName, recType.Id);
        }
        
        if(agrRec.Commit_Type__c == 'Global'){
            Id globalId = recTypeMap.get('Global');
            CommitBookingHelper.createUpdateGlobalCommitBookings(new List<Apttus__APTS_Agreement__c>{agrRec}, globalId);
        } else if (agrRec.Commit_Type__c == 'Product'){
            Id productId = recTypeMap.get('Product');
            CommitBookingHelper.getProductCommitBookings(agrRec.Id, productId);
        }
    }
}