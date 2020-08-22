/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name  SignalTicketSplitTriggerService
*
* @description  Service class for the Signal Ticket Split Trigger.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	<jayu@twilio.com>
* @modifiedBy     Jason Yu  <jayu@twilio.com>
* @version        1.0
* @created        2020-02-20
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*
**/
public class SignalTicketSplitTriggerService {
    public static void setQuotaLookups(List<Signal_Ticket_Split__c> signalTicketSplitsForReview){
        List<Signal_Ticket_Quota__c> signalTicketQuotas = new List<Signal_Ticket_Quota__c>();
        Integer currentYear = Date.today().year();
        Set<String> uniqueIds = new Set<String>();
        Map<String, Id> uniqueIdMap = new Map<String, Id>();
        
        for(Signal_Ticket_Split__c signalTicketSplit : signalTicketSplitsForReview){
            if(signalTicketSplit.Sales_Rep_Ticket_Credit__c != null){
                uniqueIds.add(signalTicketSplit.Sales_Rep_Ticket_Credit__c + String.valueOf(currentYear));
            } 
            if(signalTicketSplit.Sales_Manager_Ticket_Credit__c != null){
                uniqueIds.add(signalTicketSplit.Sales_Manager_Ticket_Credit__c + String.valueOf(currentYear));
            }
        }
        
        if(!uniqueIds.isEmpty()){
            //This currently relies on the Signal Ticket Quota records to be created for all Sales users prior.
            signalTicketQuotas = [SELECT Id, 
                                 		 Unique_Id__c
                                  FROM Signal_Ticket_Quota__c
                                  WHERE Unique_Id__c IN :uniqueIds];
            
            if(!signalTicketQuotas.isEmpty()){
                for(Signal_Ticket_Quota__c quotaRec : signalTicketQuotas){
                    uniqueIdMap.put(quotaRec.Unique_Id__c, quotaRec.Id);
                }
                
                for(Signal_Ticket_Split__c signalTicketSplit : signalTicketSplitsForReview){
                    if(signalTicketSplit.Sales_Rep_Ticket_Credit__c != null){
                        String repUniqueId = signalTicketSplit.Sales_Rep_Ticket_Credit__c + String.valueOf(currentYear);
                        signalTicketSplit.Sales_Rep_Quota__c = uniqueIdMap.get(repUniqueId);
                    } 
                    if(signalTicketSplit.Sales_Manager_Ticket_Credit__c != null){
                        String managerUniqueId = signalTicketSplit.Sales_Manager_Ticket_Credit__c + String.valueOf(currentYear);
                        signalTicketSplit.Sales_Manager_Quota__c = uniqueIdMap.get(managerUniqueId);
                    }
                }
                
                recalculateSignalTicketQuota(signalTicketQuotas);
            }
        }
    }
	
    public static void calculateSignalTicketQuota(List<Signal_Ticket_Split__c> signalTicketSplitsForReview){
        List<Signal_Ticket_Quota__c> quotasForRecalculation = new List<Signal_Ticket_Quota__c>();
        Set<Id> quotaRecIds = new Set<Id>();
        
        for(Signal_Ticket_Split__c signalTicketSplitRec : signalTicketSplitsForReview){
            //Filter quotaRecs based on all scenarios for recalculation.
            if(signalTicketSplitRec.Sales_Rep_Quota__c != null){
                quotaRecIds.add(signalTicketSplitRec.Sales_Rep_Quota__c);
            }
            if(signalTicketSplitRec.Sales_Manager_Quota__c != null){
                quotaRecIds.add(signalTicketSplitRec.Sales_Manager_Quota__c);
            }
        }
        
        if(!quotaRecIds.isEmpty()){
            quotasForRecalculation = [SELECT Id
                                      FROM Signal_Ticket_Quota__c
                                      WHERE Id IN :quotaRecIds];
            recalculateSignalTicketQuota(quotasForRecalculation);
        }
    }
    
    public static void calculateSignalTicketQuota(Map<Id, Signal_Ticket_Split__c> oldSignalTicketSplitsForReview, Map<Id, Signal_Ticket_Split__c> newSignalTicketSplitsForReview){
        List<Signal_Ticket_Quota__c> quotasForRecalculation = new List<Signal_Ticket_Quota__c>();
        Set<Id> quotaRecIds = new Set<Id>();
        
        for(Signal_Ticket_Split__c signalTicketSplitRec : newSignalTicketSplitsForReview.values()){
            //Filter quotaRecs based on all scenarios for recalculation.
            Signal_Ticket_Split__c oldRec = oldSignalTicketSplitsForReview.get(signalTicketSplitRec.Id);
            if((signalTicketSplitRec.Sales_Rep_Quota__c != oldRec.Sales_Rep_Quota__c)
               || (signalTicketSplitRec.Sales_Manager_Quota__c != oldRec.Sales_Manager_Quota__c)){
                   if(signalTicketSplitRec.Sales_Rep_Quota__c != null){
                       quotaRecIds.add(signalTicketSplitRec.Sales_Rep_Quota__c);
                   }
                   if(signalTicketSplitRec.Sales_Manager_Quota__c != null){
                       quotaRecIds.add(signalTicketSplitRec.Sales_Manager_Quota__c);
                   }
                   //If the Quota lookup gets updated on the Signal Ticket Split, we actually have to
                   //recalculate BOTH the old quota AND the new quota.
                   if(oldRec.Sales_Rep_Quota__c != null){
                       quotaRecIds.add(oldRec.Sales_Rep_Quota__c);
                   }
                   if(oldRec.Sales_Manager_Quota__c != null){
                       quotaRecIds.add(oldRec.Sales_Manager_Quota__c);
                   }
            }
        }
        
        if(!quotaRecIds.isEmpty()){
            quotasForRecalculation = [SELECT Id
                                      FROM Signal_Ticket_Quota__c
                                      WHERE Id IN :quotaRecIds];
            recalculateSignalTicketQuota(quotasForRecalculation);
        }
    }
    
    public static void calculateSignalTicketQuota(Map<Id, Signal_Ticket__c> oldSignalTicketsForReview, Map<Id, Signal_Ticket__c> newSignalTicketsForReview){
        List<Signal_Ticket_Quota__c> quotasForRecalculation = new List<Signal_Ticket_Quota__c>();
        List<Signal_Ticket__c> signalTicketsForReview = new List<Signal_Ticket__c>();
        
        Set<Id> quotaRecIds = new Set<Id>();
        Set<Id> signalTicketIds = new Set<Id>();
        
        for(Signal_Ticket__c signalTicketRec : newSignalTicketsForReview.values()){
            //Filter quotaRecs based on all scenarios for recalculation.
            Signal_Ticket__c oldRec = oldSignalTicketsForReview.get(signalTicketRec.Id);
            if((signalTicketRec.Quantity__c != oldRec.Quantity__c) || 
               (signalTicketRec.Signal_Ticket_Status__c != oldRec.Signal_Ticket_Status__c)){
                signalTicketIds.add(signalTicketRec.Id);   
            }
        }
        
        if(!signalTicketIds.isEmpty()){
            List<Signal_Ticket_Split__c> signalTicketSplitsForReview = new List<Signal_Ticket_Split__c>();
            signalTicketSplitsForReview = [SELECT Id,
                                          		  Sales_Rep_Quota__c,
                                          		  Sales_Manager_Quota__c
                                           FROM Signal_Ticket_Split__c 
                                           WHERE Signal_Ticket__c IN :signalTicketIds];
            for(Signal_Ticket_Split__c signalTicketSplitRec : signalTicketSplitsForReview){
                if(signalTicketSplitRec.Sales_Rep_Quota__c != null){
                    quotaRecIds.add(signalTicketSplitRec.Sales_Rep_Quota__c);
                }
                if(signalTicketSplitRec.Sales_Manager_Quota__c != null){
                    quotaRecIds.add(signalTicketSplitRec.Sales_Manager_Quota__c);
                }
            }
            
            if(!quotaRecIds.isEmpty()){
                quotasForRecalculation = [SELECT Id
                                          FROM Signal_Ticket_Quota__c
                                          WHERE Id IN :quotaRecIds];
                recalculateSignalTicketQuota(quotasForRecalculation);
            }    
        }
        
    }
    
    public static void recalculateSignalTicketQuota(List<Signal_Ticket_Quota__c> signalTicketQuotas){
        Map<Id, Signal_Ticket_Quota__c> signalTicketQuotaMap = new Map<Id, Signal_Ticket_Quota__c>();
        Map<Id, List<Signal_Ticket_Split__c>> repSignalTicketSplitMap = new Map<Id, List<Signal_Ticket_Split__c>>();
        Map<Id, List<Signal_Ticket_Split__c>> managerSignalTicketSplitMap = new Map<Id, List<Signal_Ticket_Split__c>>();
        List<Signal_Ticket_Quota__c> quotasForUpdate = new List<Signal_Ticket_Quota__c>();
        
        for(Signal_Ticket_Quota__c quotaRec : signalTicketQuotas){
            //signalTicketQuotaMap.put(quotaRec.Unique_Id__c, quotaRec);
            signalTicketQuotaMap.put(quotaRec.Id, quotaRec);
        }
        
        if(!signalTicketQuotaMap.isEmpty()){
            repSignalTicketSplitMap = getRepSignalTicketSplitMap(signalTicketQuotaMap.keySet());
            managerSignalTicketSplitMap = getManagerSignalTicketSplitMap(signalTicketQuotaMap.keySet());
            for(Signal_Ticket_Quota__c quotaRec : signalTicketQuotas){
                quotaRec.Ticket_Credits__c = 0;
                List<Signal_Ticket_Split__c> tempSplitList = new List<Signal_Ticket_Split__c>();
                
                if(repSignalTicketSplitMap.get(quotaRec.Id) != null){
                    tempSplitList.addALL(repSignalTicketSplitMap.get(quotaRec.Id));
                }
                
                if(managerSignalTicketSplitMap.get(quotaRec.Id) != null){
                    tempSplitList.addAll(managerSignalTicketSplitMap.get(quotaRec.Id));
                }
                
                if(!tempSplitList.isEmpty()){
                    Decimal signalTicketQuantity = 0;
                    
                    for(Signal_Ticket_Split__c splitRec : tempSplitList){
                        signalTicketQuantity += splitRec.Signal_Ticket_Quantity__c;
                    }
                    
                    quotaRec.Ticket_Credits__c = signalTicketQuantity;
                }
                
                quotasForUpdate.add(quotaRec);
            }
            
            if(!quotasForUpdate.isEmpty()){
                update quotasForUpdate;
            }
        }
    }
    
    public static Map<Id, List<Signal_Ticket_Split__c>> getRepSignalTicketSplitMap(Set<Id> signalTicketQuotaIds){
        Map<Id, List<Signal_Ticket_Split__c>> splitMap = new Map<Id, List<Signal_Ticket_Split__c>>();
        List<Signal_Ticket_Split__c> signalTicketSplitsForReview = new List<Signal_Ticket_Split__c>();
        
        signalTicketSplitsForReview = [SELECT Id,
                                              Sales_Rep_Quota__c,
                                              Signal_Ticket_Quantity__c,
                                              Signal_Ticket__c,
                                              Split_Attribution_Source__c,
                                              Ticket_Source__c
                                       FROM Signal_Ticket_Split__c
                                       WHERE Sales_Rep_Quota__c IN :signalTicketQuotaIds];
        
        for(Signal_Ticket_Split__c signalTicketSplitRec : signalTicketSplitsForReview){
            List<Signal_Ticket_Split__c> tempSplitList = new List<Signal_Ticket_Split__c>();
            if(splitMap.get(signalTicketSplitRec.Sales_Rep_Quota__c) != null){
                tempSplitList = splitMap.get(signalTicketSplitRec.Sales_Rep_Quota__c);
            }
            tempSplitList.add(signalTicketSplitRec);
            splitMap.put(signalTicketSplitRec.Sales_Rep_Quota__c, tempSplitList);
        }
		        
        return splitMap;
    }
    
    public static Map<Id, List<Signal_Ticket_Split__c>> getManagerSignalTicketSplitMap(Set<Id> signalTicketQuotaIds){
        Map<Id, List<Signal_Ticket_Split__c>> splitMap = new Map<Id, List<Signal_Ticket_Split__c>>();
        List<Signal_Ticket_Split__c> signalTicketSplitsForReview = new List<Signal_Ticket_Split__c>();
        
        signalTicketSplitsForReview = [SELECT Id,
                                              Sales_Manager_Quota__c ,
                                              Signal_Ticket_Quantity__c,
                                              Signal_Ticket__c,
                                              Split_Attribution_Source__c,
                                              Ticket_Source__c
                                       FROM Signal_Ticket_Split__c
                                       WHERE Sales_Manager_Quota__c IN :signalTicketQuotaIds];
        
        for(Signal_Ticket_Split__c signalTicketSplitRec : signalTicketSplitsForReview){
            List<Signal_Ticket_Split__c> tempSplitList = new List<Signal_Ticket_Split__c>();
            if(splitMap.get(signalTicketSplitRec.Sales_Manager_Quota__c) != null){
                tempSplitList = splitMap.get(signalTicketSplitRec.Sales_Manager_Quota__c);
            }
            tempSplitList.add(signalTicketSplitRec);
            splitMap.put(signalTicketSplitRec.Sales_Manager_Quota__c, tempSplitList);
        }
		        
        return splitMap;
    }
}