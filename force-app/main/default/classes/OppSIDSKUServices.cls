/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  OppSIDSKUServices
*
* @description 	  Service class that contains the logic related to Opp SID SKU records.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2020-03-10
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public with sharing class OppSIDSKUServices {
    public static List<Opp_SID_SKU__c> getOppSIDSKUsForUpdate(List<Opp_SID_SKU__c> oppSIDSKUsForReview){
        List<Opp_SID_SKU__c> oppSIDSKUsForUpdate = new List<Opp_SID_SKU__c>();

        for(Opp_SID_SKU__c oppSIDSKURec : oppSIDSKUsForReview){
            if(oppSIDSKURec.Messaging_Usage_Last_Month_Stamp__c != oppSIDSKURec.Messaging_Usage_Last_Month__c){
                oppSIDSKURec.Messaging_Usage_Last_Month_Stamp__c = oppSIDSKURec.Messaging_Usage_Last_Month__c;
                oppSIDSKUsForUpdate.add(oppSIDSKURec);
            }
        }

        return oppSIDSKUsForUpdate;
    }
}