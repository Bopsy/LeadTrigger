/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  UCIQuickActionController
*
* @description 	  Apex class that contains the logic related to UCIQickActionCmp lightning component.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2018-03-11
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class UCIQuickActionController {
    
    @AuraEnabled
    public static wrappClass getMQLobject(String MqlId){
        wrappClass wrapcls = new wrappClass();
        FSR__c mql = new FSR__c();
        try{
            mql = [Select Id, contact__r.Name, contact__c, contact__r.account.Id, Lead__c , Lead__r.name from FSR__c
                    where Id=:MqlId limit 1];
            if(mql!=null){
                if(mql.contact__c!=null){
                    wrapcls.Contact = mql.contact__c;
                    if(mql.contact__r.account!=null){
                        wrapcls.Account = mql.contact__r.account.Id;
                    }
                }
                if(mql.Id!=null){
                    wrapcls.MqlId = mql.Id;
                }
                if(mql.Lead__c!=null){
                    wrapcls.Lead = mql.Lead__c;
                }
            }
            wrapcls.RecordTypeId = [SELECT Id, SobjectType, Name, DeveloperName FROM RecordType
                                WHERE SobjectType='Use_Case_Interest__c'
                                and DeveloperName='Use_Case_Interest' LIMIT 1].Id; 
        }catch(Exception ex){
            System.debug('Exction Occured'+ex.getMessage());
        }
        return wrapcls;
    }

    public class wrappClass{
        @AuraEnabled
        public Id RecordTypeId {get;set;}
        @AuraEnabled
        public Id Contact {get;set;}
        @AuraEnabled
        public Id Account {get;set;}
        @AuraEnabled
        public Id MqlId {get;set;}
        @AuraEnabled
        public Id Lead {get;set;}
    }

}