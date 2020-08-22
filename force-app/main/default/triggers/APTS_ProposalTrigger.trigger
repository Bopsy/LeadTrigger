trigger APTS_ProposalTrigger on Apttus_Proposal__Proposal__c (before insert,before update,after insert,after delete, after undelete, after update) {
    
    /***************************************************
        Added by Apttus Support
        Case: CAS-09701-F2Y8Y7
        Date: 15-03-2019
        Desc: To stop approval process to be fired based on the condition on TCR/Net unit price/color
    ****************************************************/
    if(trigger.isBefore){
        if(trigger.isUpdate){
            APTS_ProposalTriggerHandler.updateApprovalFields(trigger.New,trigger.oldMap);
        }
        if(trigger.isInsert){
            for(Apttus_Proposal__Proposal__c proposal: trigger.new){
                proposal.Email_Specialist__c = proposal.Email_Specialist_Id__c;
            }
            APTS_ProposalTriggerHandler.checkOnTotalHours(trigger.new);
        }
    }
    //Added by Amrutha - Change status color in line items when TCR is updated
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUndelete){
            APTS_ProposalTriggerHandler.onInsert(trigger.new);
        }
        if(trigger.isUpdate){
            APTS_ProposalTriggerHandler.callGenerateStatus(trigger.new, trigger.oldMap, trigger.newMap);
            APTS_ProposalTriggerHandler.onUpdate(trigger.oldMap, trigger.new);
            APTS_ProposalTriggerHandler.onUpdateQuote(trigger.oldMap,trigger.newMap);
        }if(trigger.isDelete){
            APTS_ProposalTriggerHandler.onInsert(trigger.old);
        }
    }
}