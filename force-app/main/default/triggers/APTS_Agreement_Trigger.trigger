/**********************************************************************************
Trigger   :  APTS_Agreement_Trigger.trigger
Developer :  mmurphy@apttus.com
Created   :  December 07, 2015
Modified  :  Feb 27,2020
Objective :  Handles relevent events raised by Apttus__APTS_Agreement__c collections.
Handler   :  APTS_Agreement_Trigger_Handler.cls
Test Class:  APTS_Agreement_Trigger_Handler_Test.cls

**********************************************************************************/

trigger APTS_Agreement_Trigger on Apttus__APTS_Agreement__c
( after update, after insert, after delete, before insert, before update)
{
    
    if ( trigger.isAfter )
    {
        if ( trigger.isInsert )       
        {
            //AgreementDocuSignerTriggerHandler.afterInsert(trigger.new);
            AgreementCommitScheduleHandler.afterInsert(trigger.new);
            //AgreementTriggerHandler.updateCompBookingsAutomationOnOpportunity(new Map<Id, Apttus__APTS_Agreement__c>(), Trigger.newMap);
            //List< Apttus_Proposal__Proposal__c> quotes = new List< Apttus_Proposal__Proposal__c>();
            /*for(Apttus__APTS_Agreement__c agreement: trigger.new){
			if(agreement.Apttus_QPComply__RelatedProposalId__c != null && agreement.Id != null){
			quotes.add(new Apttus_Proposal__Proposal__c(Id = agreement.Apttus_QPComply__RelatedProposalId__c, Related_Order_Form__c = agreement.Id));
			}
			}
			update quotes;*/
            
            //Added by Amrutha- Update single BI tiers if agreement has effective date or commint start date
            //APTS_Agreement_Trigger_Handler.updateSingleBITiersOnInsert(trigger.new);
            //System.enqueueJob(new AgreementTriggerHandlerQueueable(Trigger.New, new Map<Id,Apttus__APTS_Agreement__c>(), Trigger.newMap, false, false));
            AgreementHandlerForAfterTrigger.updateParentAgreementFromChild(Trigger.new, null);
            //AgreementTriggerHandlerFuture.agreementFutureOnInsert(JSON.serialize(Trigger.new));
            AgreementTriggerHandlerFuture.agreementFutureOnInsert(trigger.newmap.keyset());
        }
        
        else if(trigger.isUpdate )
        {
            //Added by Mia 2019/10/30 - Mapping data from OF to Oppty
            //APTS_Agreement_Trigger_Handler.agreementOpptyMapping(trigger.new, trigger.oldMap);
            
            //APTS_Agreement_Trigger_Handler.processAfterUpdate (trigger.oldMap, trigger.newMap);
            AgreementCommitScheduleHandler.afterUpdate(trigger.new, trigger.oldMap);
            //AgreementTriggerHandler.updateCompBookingsAutomationOnOpportunity(Trigger.oldMap, Trigger.newMap);
            //AgreementDocuSignerTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
            //APTS_Agreement_Trigger_Handler.createCommitBookingsRecords(trigger.new, trigger.oldMap, trigger.newMap);
            
            if(!TriggerRunOnceUtility.APTS_Agreement_Trigger){
                TriggerRunOnceUtility.APTS_Agreement_Trigger=true;
                //Added by Amrutha- Update single BI tiers if agreement effective date or commint start date are updated
                //APTS_Agreement_Trigger_Handler.updateSingleBITiersOnUpdate(trigger.new,trigger.oldMap,trigger.newMap);
                //Added by Jason 2019-06-24
                //APTS_Agreement_Trigger_Handler.processAgreementActivation(trigger.new, trigger.oldMap, trigger.newMap);
                //System.enqueueJob(new AgreementTriggerHandlerQueueable(trigger.New, trigger.oldMap, trigger.newMap, true, false));
                //AgreementTriggerHandlerFuture.agreementFutureOnUpdate(JSON.serialize(Trigger.new), JSON.serialize(Trigger.OldMap), JSON.serialize(Trigger.newMap), true);     
                AgreementTriggerHandlerFuture.agreementFutureOnUpdate(trigger.newmap.keyset(),JSON.serialize(Trigger.OldMap),true);     
            }
            //if(Limits.getQueueableJobs() == 0) System.enqueueJob(new AgreementTriggerHandlerQueueable(trigger.New, trigger.oldMap, trigger.newMap, false, false));
            //AgreementTriggerHandlerFuture.agreementFutureOnUpdate(JSON.serialize(Trigger.new), JSON.serialize(Trigger.OldMap), JSON.serialize(Trigger.newMap), false);
            AgreementTriggerHandlerFuture.agreementFutureOnUpdate(trigger.newmap.keyset(),JSON.serialize(Trigger.OldMap),false);
            AgreementHandlerForAfterTrigger.updateParentAgreementFromChild(trigger.new, trigger.oldMap);
        }   
        
    } //  isAfter
    else if(trigger.isBefore){
        if(trigger.isInsert){
            Set<Id> quoteIds = new Set<Id>();
            for(Apttus__APTS_Agreement__c agreement: trigger.new){
                if(agreement.Apttus_QPComply__RelatedProposalId__c != null){
                    agreement.Related_Opportunity_APTS__c = agreement.Parent_Opportunity_Id_Proposal_Quote__c;
                }
                //covid-19 logic to check if 6th level discount was applied
                if(agreement.Apttus_QPComply__RelatedProposalId__c != null){
                    quoteIds.add(agreement.Apttus_QPComply__RelatedProposalId__c);
                }
            }
            //covid-19 logic to check if 6th level discount was applied
            APTS_Agreement_Trigger_Handler.getQuoteData(trigger.new,quoteIds);
            //AgreementHandlerForAsync.agreementWorkflowsFromTrigger(trigger.new,trigger.oldMap);
            AgreementHandlerForAsync.processBuilderIntoCodeForBeforeEvent(trigger.new,trigger.oldMap);
        }
        if(trigger.isUpdate){
            AgreementCommitScheduleHandler.beforeUpdate(trigger.new, trigger.oldMap);
            APTS_Agreement_Trigger_Handler.prepareQuoteData(trigger.new, trigger.oldMap);
            //AgreementHandlerForAsync.agreementWorkflowsFromTrigger(trigger.new,trigger.oldMap);
            AgreementHandlerForAsync.processBuilderIntoCodeForBeforeEvent(trigger.new,trigger.oldMap);
        }
    }
    
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
        
        //APTS_Agreement_Trigger_Handler.UpdateRelatedAccounts(trigger.new);
    }
    
    if(trigger.isAfter && (trigger.isDelete)){
        //APTS_Agreement_Trigger_Handler.UpdateRelatedAccounts(trigger.old);
        //System.enqueueJob(new AgreementTriggerHandlerQueueable(Trigger.old, trigger.oldMap, Trigger.newMap, false, Trigger.isDelete));
        AgreementTriggerHandlerFuture.agreementFutureOnDelete(JSON.serialize(trigger.old));
    }
}