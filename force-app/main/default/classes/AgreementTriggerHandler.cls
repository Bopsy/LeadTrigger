/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  AgreementTriggerHandler
*
* @description 	  Service class that contains the logic related to the Apttus Agreement record.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-12-27
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public with sharing class AgreementTriggerHandler {
    /*
    private static Set<String> VALID_COMMIT_FREQUENCIES = new Set<String>{'Monthly', 'Quarterly','Semi-Annual', 'Annual', 'Existing Commit'};
        
	public static void updateCompBookingsAutomationOnOpportunity(Map<Id, Apttus__APTS_Agreement__c> oldMap, Map<Id, Apttus__APTS_Agreement__c> newMap){
        Set<Id> oppIdsForReview = new Set<Id>();
        Map<Id, Boolean> oppIdsToCommittedBookingsBooleanMap = new Map<Id, Boolean>();
        for(Apttus__APTS_Agreement__c newAgr : newMap.values()){
            if(newAgr.Related_Opportunity_APTS__c != null){
                if(newAgr.Commit_Frequency__c != null && newAgr.Apttus__Status__c == 'Activated'){
                    Boolean isCommitted = false;
                    if(VALID_COMMIT_FREQUENCIES.contains(newAgr.Commit_Frequency__c)){
                        isCommitted = true;
                    }
                    
                    if(oldMap.get(newAgr.Id) == null){
                        oppIdsToCommittedBookingsBooleanMap.put(newAgr.Related_Opportunity_APTS__c, isCommitted);
                    } else {
                        Apttus__APTS_Agreement__c oldAgr = oldMap.get(newAgr.Id);
                        if(newAgr.Commit_Frequency__c != oldAgr.Commit_Frequency__c || newAgr.Apttus__Status__c != oldAgr.Apttus__Status__c){
                            oppIdsToCommittedBookingsBooleanMap.put(newAgr.Related_Opportunity_APTS__c, isCommitted);
                        }
                    }  
                }
            }
        }
        
        if(!oppIdsToCommittedBookingsBooleanMap.keySet().isEmpty()){
            List<Opportunity> oppsForUpdate = getOppsForCommittedBookingsUpdate(oppIdsToCommittedBookingsBooleanMap);
            if(!oppsForUpdate.isEmpty()){
                update oppsForUpdate;
            }
        }
    }
    
    private static List<Opportunity> getOppsForCommittedBookingsUpdate(Map<Id, Boolean> oppIdsToCommittedBookingsValueMap){
        List<Opportunity> oppsForUpdate = new List<Opportunity>();
        List<Opportunity> oppsForReview = [SELECT Id FROM Opportunity WHERE ID in :oppIdsToCommittedBookingsValueMap.keySet()];
        
        if(!oppsForReview.isEmpty()){
        	for(Opportunity opp : oppsForReview){
                opp.Comp_Bookings_Automation__c = oppIdsToCommittedBookingsValueMap.get(opp.Id);
                oppsForUpdate.add(opp);
            }    
        }
        
        return oppsForUpdate;
    }
    */
    public static List<Apttus__APTS_Agreement__c> getActivatedAgreements(List<Apttus__APTS_Agreement__c> agreementsForReview){
        List<Apttus__APTS_Agreement__c> agreementsForUpdate = new List<Apttus__APTS_Agreement__c>();
        
        for(Apttus__APTS_Agreement__c agrRec : agreementsForReview){
            agrRec.Apttus__Status__c = 'Activated';
            agrRec.Apttus__Status_Category__c = 'In Effect';
            agreementsForUpdate.add(agrRec);
        }
        
        return agreementsForUpdate;
    }
}