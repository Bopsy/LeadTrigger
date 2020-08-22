public class AgreementTriggerHandlerQueueable implements Queueable {
    public List<Apttus__APTS_Agreement__c> theNewAgrmntList; 
    public Map<Id, Apttus__APTS_Agreement__c> theAgrmntOldMap; 
    public Map<Id, Apttus__APTS_Agreement__c> theAgmntNewMap;
    public Boolean isDelete; 
    public Boolean isRunOnce;
    
    public AgreementTriggerHandlerQueueable(List<Apttus__APTS_Agreement__c> theAgrmntList, Map<Id, Apttus__APTS_Agreement__c> theOldMap, Map<Id, Apttus__APTS_Agreement__c> theNewMap,Boolean theRunOnce, Boolean isDeleteTrigger) {
        this.theNewAgrmntList = theAgrmntList; 
        this.theAgrmntOldMap = theOldMap;
        this.theAgmntNewMap = theNewMap;
        this.isDelete = isDeleteTrigger;
        this.isRunOnce = theRunOnce;
        system.debug('theNewAgrmntList=>'+theNewAgrmntList);
        system.debug('theAgrmntOldMap=>'+theAgrmntOldMap);
    }
    
    public void execute(QueueableContext context) {
        system.debug('theAgrmntOldMap=>'+theAgrmntOldMap);
        system.debug('theNewAgrmntList=>'+theNewAgrmntList);
        system.debug('theAgmntNewMap=>'+theAgmntNewMap);
        if(theAgrmntOldMap.isEmpty()) {
            system.debug('afterInsert1=>'+Limits.getCpuTime());
            AgreementDocuSignerTriggerHandler.afterInsert(theNewAgrmntList);
            system.debug('afterInsert2=>'+Limits.getCpuTime());
            AgreementCommitScheduleHandler.afterInsert(theNewAgrmntList);
            system.debug('afterInsert3=>'+Limits.getCpuTime());
            List< Apttus_Proposal__Proposal__c> quotes = new List< Apttus_Proposal__Proposal__c>();
            for(Apttus__APTS_Agreement__c agreement: theNewAgrmntList){
                if(agreement.Apttus_QPComply__RelatedProposalId__c != null && agreement.Id != null) {
                     quotes.add(new Apttus_Proposal__Proposal__c(Id = agreement.Apttus_QPComply__RelatedProposalId__c, Related_Order_Form__c = agreement.Id));
                }
            }
            update quotes;
            system.debug('afterInsert4=>'+Limits.getCpuTime());
           //APTS_Agreement_Trigger_Handler.updateSingleBITiersOnInsert(theNewAgrmntList);
            system.debug('afterInsert5=>'+Limits.getCpuTime());
		   APTS_Agreement_Trigger_Handler.UpdateRelatedAccounts(theNewAgrmntList);
            system.debug('afterInsert6=>'+Limits.getCpuTime());
           AgreementHandlerForAfterTrigger.afterInsertOrUpdateTrigger(theNewAgrmntList, null);
            system.debug('afterInsert7=>'+Limits.getCpuTime());
   		   AgreementHandlerForAfterTrigger.processBuilderIntoCodeForAfterEvent(theNewAgrmntList, null);
            system.debug('afterInsert8=>'+Limits.getCpuTime());
         }
        
        if((!theAgrmntOldMap.isEmpty()) && !isDelete)  {
            system.debug('afterInsert9=>'+Limits.getCpuTime());
            APTS_Agreement_Trigger_Handler.agreementOpptyMapping(theNewAgrmntList, theAgrmntOldMap);
            APTS_Agreement_Trigger_Handler.processAfterUpdate (theAgrmntOldMap, theAgmntNewMap);
            AgreementCommitScheduleHandler.afterUpdate(theNewAgrmntList, theAgrmntOldMap);
            AgreementDocuSignerTriggerHandler.afterUpdate(theNewAgrmntList, theAgrmntOldMap);
            APTS_Agreement_Trigger_Handler.UpdateRelatedAccounts(theNewAgrmntList);
			AgreementHandlerForAfterTrigger.afterInsertOrUpdateTrigger(theNewAgrmntList, theAgrmntOldMap);
   		    AgreementHandlerForAfterTrigger.processBuilderIntoCodeForAfterEvent(theNewAgrmntList, theAgrmntOldMap);
        }
        
        if(!theAgrmntOldMap.isEmpty() && isRunOnce) {
            system.debug('Inside isRunOnce=>'+Limits.getCpuTime());
            //APTS_Agreement_Trigger_Handler.updateSingleBITiersOnUpdate(theNewAgrmntList, theAgrmntOldMap, theAgmntNewMap);
            APTS_Agreement_Trigger_Handler.processAgreementActivation(theNewAgrmntList, theAgrmntOldMap, theAgmntNewMap);
        }
        
        if(!theAgrmntOldMap.isEmpty() && isDelete) {
           APTS_Agreement_Trigger_Handler.UpdateRelatedAccounts(theNewAgrmntList);
        }
    }
    
}