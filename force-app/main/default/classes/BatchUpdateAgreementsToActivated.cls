/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  BatchUpdateAgreementsToActivated
*
* @description 	  Batch class that updates Agreement records to a status ofActivated with a status 
*				  category of In Effect.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        2.0
* @created        2019-04-09
* @modified       2020-04-23
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		2019-06-24 Increased scope of queried records.
*				2020-04-23 Added Business_Associate_Agreement RecordType to the query.
*
**/
global class BatchUpdateAgreementsToActivated implements Database.Batchable<SObject>, Schedulable{
	global void execute(SchedulableContext sc) {
        //Set scheduler action
        Database.executeBatch(new BatchUpdateAgreementsToActivated(), 1);
    }
	
    global Database.queryLocator start(Database.BatchableContext bc){
        Set<Id> recordTypeIds = new Set<Id>();
        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE DeveloperName IN ('Order_Form', 'Business_Associate_Agreement')];
        for(RecordType recType : recordTypes){
            recordTypeIds.add(recType.Id);
        }
        
        return Database.getQueryLocator([SELECT Id, 
                                                Apttus__Status__c, 
                                                Apttus__Status_Category__c,
                                                (SELECT Name, 
                                                        Apttus_DocuApi__Status__c,
                                                        Apttus_CMDSign__Agreement__c 
                                                 FROM Apttus_CMDSign__DocuSignEnvelopes__r
                                                 WHERE (Apttus_CMDSign__Agreement__r.Apttus__Status__c = 'Fully Signed' OR
                                                            (Apttus_CMDSign__Agreement__r.Apttus__Status__c = 'Activated' AND 
                                                                 (Apttus_CMDSign__Agreement__r.Apttus__Status_Category__c = 'In Authoring' OR 
                                                                  Apttus_CMDSign__Agreement__r.Apttus__Status_Category__c = 'In Signatures')))
                                                    AND Apttus_CMDSign__Agreement__r.Related_Opportunity_APTS__c != null
                                                    AND Apttus_CMDSign__Agreement__r.RecordTypeId IN :recordTypeIds
                                                    AND Apttus_DocuApi__Status__c = 'completed'
                                                 LIMIT 1)
                                         FROM Apttus__APTS_Agreement__c  
                                         WHERE (Apttus__Status__c = 'Fully Signed' OR
                                               (Apttus__Status__c = 'Activated' AND (Apttus__Status_Category__c = 'In Authoring' OR Apttus__Status_Category__c = 'In Signatures')))
                                            AND Related_Opportunity_APTS__c != null
                                            AND RecordTypeId IN :recordTypeIds]);
    }
    
    global void execute(Database.BatchableContext bc, List<Apttus__APTS_Agreement__c> agreementRecs){
        List<Apttus__APTS_Agreement__c> agreementsForReview = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> agreementsForUpdate = new List<Apttus__APTS_Agreement__c>();
        Set<Id> agreementRecIds = new Set<Id>();
        
        for(Apttus__APTS_Agreement__c agrRec : agreementRecs){
            for(Apttus_DocuApi__DocuSignEnvelope__c envRec : agrRec.Apttus_CMDSign__DocuSignEnvelopes__r){
                agreementsForReview.add(agrRec);
                break;
            }
        }
        
        if(!agreementsForReview.isEmpty()){
            agreementsForUpdate = AgreementBatchHandler.getActivatedAgreements(agreementsForReview);
            Database.update(agreementsForUpdate, false);
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}