trigger DealAfterTrigger on Deal__c (after insert, after update, after delete, after undelete) {

  if ( Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
     if(trigger.isInsert){
        OpportunityDealHandler.copyFieldsToOpportunity( Trigger.newMap );
     }
     OpportunityFSFSplitServices.upsertDealSplits(trigger.new, trigger.oldMap);
     if(trigger.isUpdate){
         OpportunityDealHandler.copyFieldsToOpportunity( OpportunityDealHandler.filterDeals(trigger.new, trigger.oldMap) );
        OpportunityDealHandler.updateTeamMembers(trigger.oldMap, trigger.new);
     }
  }
}