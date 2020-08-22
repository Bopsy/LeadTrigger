/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  BatchUpdateOppSIDSKU
*
* @description 	  Batch class to update relevant Opp SID SKUs.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu	 <jayu@twilio.com>
* @version        1.0
* @created        2020-03-20
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*			
**/
global class BatchUpdateOppSIDSKU implements Database.Batchable<SObject>, Schedulable{
    global void execute(SchedulableContext sc) {
        //Set scheduler action
        Database.executeBatch(new BatchUpdateOppSIDSKU(), 1000);
    }

    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id,
                                             Account_SID__r.Amort_Usage_FY_18_Messaging_Last_Month__c,
                                             Messaging_Usage_Last_Month__c,
                                             Messaging_Usage_Last_Month_Stamp__c
                                         FROM Opp_SID_SKU__c
                                         WHERE Opportunity__r.RecordType.DeveloperName = 'Portfolio_Revenue']);
    }

    global void execute(Database.BatchableContext bc, List<Opp_SID_SKU__c> oppSIDSKUScope){
        List<Opp_SID_SKU__c> oppSIDSKUsForUpdate = new List<Opp_SID_SKU__c>();
        oppSIDSKUsForUpdate = OppSIDSKUServices.getOppSIDSKUsForUpdate(oppSIDSKUScope);
        
        if(!oppSIDSKUsForUpdate.isEmpty()){
            update oppSIDSKUsForUpdate;
        }
    }

    global void finish(Database.BatchableContext bc){
        
    }
}