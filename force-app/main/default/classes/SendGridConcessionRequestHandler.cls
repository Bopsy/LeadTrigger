/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           SendGridConcessionRequestHandler
*
* @description    Handler class for SendGridConcessionRequest Trigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui     <ncui@twilio.com>
* @modifiedBy     Mia Cui     <ncui@twilio.com>
* @version        1.0
* @created        2019-10-02
* @modified       2019-10-02
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes 
**/
public class SendGridConcessionRequestHandler {
    public static void stamp(List<SendGrid_Concession_Request__c> requests, Boolean isdelete) {
        List<SendGrid_Concession_Request__c> ret = new List<SendGrid_Concession_Request__c>();
        for(SendGrid_Concession_Request__c scr: requests) {
            if((scr.Approval_Status__c != NULL 
               || scr.Requested_Payment_Method__c != NULL 
               || scr.Requested_Payment_Terms__c != NULL)
               && (scr.Concession_Type__c == 'Payment Terms / Payment Method / Pre-Payment')) {
                   ret.add(scr);
               }
        }
        
        if(ret.size() > 0) syncStamp(ret,isdelete);  
    }
    
    public static void stamp(List<SendGrid_Concession_Request__c> newConcessionList, 
                             Map<ID,SendGrid_Concession_Request__c> oldMap) {
        List<SendGrid_Concession_Request__c> ret = new List<SendGrid_Concession_Request__c>();
        for(SendGrid_Concession_Request__c scr: newConcessionList) {
            if((scr.Approval_Status__c != oldMap.get(scr.ID).Approval_Status__c 
               || scr.Requested_Payment_Terms__c != oldMap.get(scr.ID).Requested_Payment_Terms__c
               || scr.Requested_Payment_Method__c != oldMap.get(scr.ID).Requested_Payment_Method__c)
               && (scr.Concession_Type__c == 'Payment Terms / Payment Method / Pre-Payment')){
                   
                ret.add(scr);
            }
        }
        if(ret.size() > 0) syncStamp(ret,false);                                                        
    }
    
    
    
    public static void syncStamp(List<SendGrid_Concession_Request__c> requests, Boolean isDelete) {
        Map<ID, SendGrid_Concession_Request__c> agreementMap = new Map<ID, SendGrid_Concession_Request__c>();
        for(SendGrid_Concession_Request__c scr: requests) {
            if(scr.Agreement__c != NULL) agreementMap.put(scr.Agreement__c, scr);
        }
        if(agreementMap.size() > 0) {
            List<Apttus__APTS_Agreement__c> agreements = [ SELECT ID, SendGrid_Concession_Approval_Status__c, 
                                                                  SendGrid_Concession_Approval_Date_Time__c
                                                           FROM Apttus__APTS_Agreement__c 
                                                           WHERE ID IN: agreementMap.keySet()];
            for(Apttus__APTS_Agreement__c agr: agreements) {
                if(isDelete) {
                    agr.SendGrid_Concession_Approval_Date_Time__c = NULL;
                    agr.SendGrid_Concession_Approval_Status__c = NULL;
                    agr.SendGrid_Concession_Payment_Terms__c  = NULL;
                    agr.SendGrid_Concession_Payment_Method__c  = NULL;
                    continue;
                }
                agr.SendGrid_Concession_Approval_Status__c = agreementMap.get(agr.Id).Approval_Status__c;
                if(agr.SendGrid_Concession_Approval_Status__c == 'Approved'){
    				agr.SendGrid_Concession_Payment_Terms__c  = agreementMap.get(agr.Id).Requested_Payment_Terms__c;
                	agr.SendGrid_Concession_Payment_Method__c  = agreementMap.get(agr.Id).Requested_Payment_Method__c;
                    if(agr.SendGrid_Concession_Approval_Date_Time__c == NULL) agr.SendGrid_Concession_Approval_Date_Time__c = System.now();
                } else {
                    agr.SendGrid_Concession_Approval_Date_Time__c = NULL;
                }
            }
            update agreements;
        }
    }
    
    
    
    
    
}