/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           SGPriceConcessionTriggerHandler
*
* @description    Service class that contains the logic related to Sendgrid price concession object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-10-02
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class SGPriceConcessionTriggerHandler {
    
    public static void onInsert(List<SendGrid_Price_Concession__c> lstSGPrice){
        Set<Id> setOppIds = new Set<Id>();
        List<SendGrid_Price_Concession__c> lstSGPrice1 = new List<SendGrid_Price_Concession__c>();
        for(SendGrid_Price_Concession__c objSGPrice: lstSGPrice){
            if(objSGPrice.Opportunity__c!=null && objSGPrice.Quote_Proposal__c==null){
                setOppIds.add(objSGPrice.Opportunity__c);
                lstSGPrice1.add(objSGPrice);
            }else if(objSGPrice.Opportunity__c==null){
                objSGPrice.Quote_Proposal__c=null;
            }
        }
        if(lstSGPrice1.size()>0){
            linkQuote(lstSGPrice1,setOppIds);
        }
    }
    
    public static void onUpdate(Map<Id,SendGrid_Price_Concession__c> oldMap,List<SendGrid_Price_Concession__c> lstSGPrice){
        Set<Id> setOppIds = new Set<Id>();
        List<SendGrid_Price_Concession__c> lstSGPrice1 = new List<SendGrid_Price_Concession__c>();
        for(SendGrid_Price_Concession__c objSGPrice: lstSGPrice){
            if(objSGPrice.Opportunity__c!=null && objSGPrice.Opportunity__c!=oldMap.get(objSGPrice.id).Opportunity__c){
                setOppIds.add(objSGPrice.Opportunity__c);
                lstSGPrice1.add(objSGPrice);
            }else if(objSGPrice.Opportunity__c==null){
                objSGPrice.Quote_Proposal__c=null;
            }
        }
        if(lstSGPrice1.size()>0){
            linkQuote(lstSGPrice1,setOppIds);
        }
    }
    
    public static void linkQuote(List<SendGrid_Price_Concession__c> lstSGPrice,Set<Id> setOppIds){
        Map<Id,Opportunity> mapOpp = new Map<Id,Opportunity>([Select Id,(Select Id,Apttus_QPApprov__Approval_Status__c from R00N70000001yUfDEAU order by lastmodifieddate desc)
                                                              from Opportunity where Id IN:setOppIds]);
        for(SendGrid_Price_Concession__c objSGPrice: lstSGPrice){
            if(mapOpp.size()>0 && mapOpp.get(objSGPrice.Opportunity__c)!=null && mapOpp.get(objSGPrice.Opportunity__c).R00N70000001yUfDEAU.size()>0){
                objSGPrice.Quote_Proposal__c = mapOpp.get(objSGPrice.Opportunity__c).R00N70000001yUfDEAU[0].Id;
                for(Apttus_Proposal__Proposal__c objQuote: mapOpp.get(objSGPrice.Opportunity__c).R00N70000001yUfDEAU){
                    if(objQuote.Apttus_QPApprov__Approval_Status__c=='Approved'){
                        objSGPrice.Quote_Proposal__c = objQuote.Id;
                        break;
                    }
                }
            }
        }
    }
}