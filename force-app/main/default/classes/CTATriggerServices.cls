/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CTATriggerServices
*
* @description 	  Handler class executes methods based on DMLs on the Gainsight CTA object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-05-28
* @modified       2018-08-06
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*				- 2018-08-06 - Added reverse functionality to update the CTA Status when the JBCXM__Stage__c
*                              is updated.
**/
public without sharing class CTATriggerServices {
    private static Date todaysDate = Date.today();
    private static Map<String, Id> ctaPickListMap = new Map<String, Id>();
    
    public static void beforeInsert(List<JBCXM__CTA__c> ctaList){
        List<JBCXM__CTA__c> ctasForReview = new List<JBCXM__CTA__c>();
        Set<String> ctaStatuses = new Set<String>();

        /*
         * Cycle through the list of inserted CTA records and filter them as necessary.
        */
        for(JBCXM__CTA__c cta : ctaList){
            if(cta.CTA_Status__c != null){
                ctaStatuses.add(cta.CTA_Status__c);
                ctasForReview.add(cta);
            }
        }
		
		/*
		 * For the CTA records that are created with a CTA Status, update the 
		 * corresponding JBCXM__Stage__c Gainsight field to match the value.
		*/        
        if(!ctaStatuses.isEmpty()){
            getCTAStatusMap(ctaStatuses);
            for(JBCXM__CTA__c cta : ctasForReview){
                cta.JBCXM__Stage__c = ctaPickListMap.get(cta.CTA_Status__c);
                if(cta.CTA_Status__c.contains('Closed') && cta.JBCXM__ClosedDate__c == null){
                    cta.JBCXM__ClosedDate__c = todaysDate;
                }
            }
        }
    }
    
    public static void beforeUpdate(Map<Id, JBCXM__CTA__c> newCTAMap, Map<Id, JBCXM__CTA__c> oldCTAMap){
        List<JBCXM__CTA__c> ctasWithNewStatus = new List<JBCXM__CTA__c>();
        List<JBCXM__CTA__c> ctasWithNewStage = new List<JBCXM__CTA__c>();
        Set<String> ctaStatuses = new Set<String>();
        Set<Id> ctaPicklistIds = new Set<Id>();
        
        /*
         * Cycle through the new map of CTA records and filter records.
        */ 
        for(Id ctaId : newCTAMap.keySet()){
            if(oldCTAMap.get(ctaId).CTA_Status__c != newCTAMap.get(ctaId).CTA_Status__c
              && oldCTAMap.get(ctaId).JBCXM__Stage__c == newCTAMap.get(ctaId).JBCXM__Stage__c){
                ctasWithNewStatus.add(newCTAMap.get(ctaId));
                ctaStatuses.add(newCTAMap.get(ctaId).CTA_Status__c);
            }
            if(oldCTAMap.get(ctaId).JBCXM__Stage__c != newCTAMap.get(ctaId).JBCXM__Stage__c
              && oldCTAMap.get(ctaId).CTA_Status__c == newCTAMap.get(ctaId).CTA_Status__c){
                ctasWithNewStage.add(newCTAMap.get(ctaId));
                ctaPicklistIds.add(newCTAMap.get(ctaId).JBCXM__Stage__c);  
            }
        }
        
        /*
         * If there are CTA records with a new CTA Status, modify the Gainsight stage
         * with the matching status.
        */ 
        if(!ctasWithNewStatus.isEmpty()){
            getCTAStatusMap(ctaStatuses);
            for(JBCXM__CTA__c cta : ctasWithNewStatus){
                newCTAMap.get(cta.Id).JBCXM__Stage__c = ctaPickListMap.get(cta.CTA_Status__c);
                if(cta.CTA_Status__c.contains('Closed') && cta.JBCXM__ClosedDate__c == null){
                    newCTAMap.get(cta.Id).JBCXM__ClosedDate__c = todaysDate;
                }
            }
        }
        
        /*
         * If there are CTA records with a new CTA Stage, modify the Gainsight CTA Status
         * with the matching Stage Name.
        */ 
        if(!ctasWithNewStage.isEmpty()){
            Map<Id, String> picklistIdToNameMap = new Map<Id, String>();
            List<JBCXM__PickList__c> pickListRecs = [SELECT Id
                                                           ,Name
                                                     FROM JBCXM__PickList__c 
                                                     WHERE Id in :ctaPicklistIds];
            
            for(JBCXM__PickList__c pl : pickListRecs){
                picklistIdToNameMap.put(pl.Id, pl.Name);
            }
            
            for(JBCXM__CTA__c cta : ctasWithNewStage){
                newCTAMap.get(cta.Id).CTA_Status__c = picklistIdToNameMap.get(cta.JBCXM__Stage__c);
                if(picklistIdToNameMap.get(cta.JBCXM__Stage__c).contains('Closed') && cta.JBCXM__ClosedDate__c == null){
                    newCTAMap.get(cta.Id).JBCXM__ClosedDate__c = todaysDate;
                }
            }
        }
    }
    
    /*
     * Method takes a string set of CTA statuses, and returns a map of PickList record Ids
     * that correspond to them.
    */
    public static void getCTAStatusMap(Set<String> ctaStatuses){
        if(ctaStatuses.isEmpty() || !ctaPickListMap.isEmpty()){return;}
        ctaPickListMap = new Map<String, Id>();
        
        List<JBCXM__PickList__c> ctaPicklistRecords = [SELECT Id
                                                       		 ,Name
                                                       FROM JBCXM__PickList__c
                                                       WHERE Name in :ctaStatuses];
        
        for(JBCXM__PickList__c ctaPicklist : ctaPickListRecords){
            ctaPickListMap.put(ctaPicklist.Name, ctaPicklist.Id);
        }
    }
}