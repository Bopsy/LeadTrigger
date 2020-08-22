trigger ConfigurationTrigger on Apttus_Config2__ProductConfiguration__c (before insert,before update,after insert,after delete, after undelete, after update) {
    if(trigger.isBefore && trigger.isUpdate){
        for(Apttus_Config2__ProductConfiguration__c config: trigger.new){
            Apttus_Config2__ProductConfiguration__c oldConfig = trigger.oldMap.get(config.Id);
            if(config.Apttus_CQApprov__Approval_Status__c != null && config.Apttus_CQApprov__Approval_Status__c == 'Cancelled'){
                config.Apttus_CQApprov__Approval_Status__c = 'Approval Required';
            }
        }
    }
    if(trigger.isBefore){
        if(trigger.isInsert){
            for(Apttus_Config2__ProductConfiguration__c config: trigger.new){
                config.Related_Quote_Email_Specialist__c = config.Email_Specialist_Id__c;
            }
            ConfigurationTriggerHandler.checkOnTotalHours(trigger.new);
        }
    }
    if(trigger.isAfter){
          
        //Added by Amrutha - To calculate total approval hours
        if(trigger.isInsert || trigger.isUndelete || trigger.isDelete){
            ConfigurationTriggerHandler.updateProposalTotalOnInsert(trigger.isDelete ? trigger.old : trigger.new, trigger.isDelete ? true : false);
            ConfigurationTriggerHandler.updateDealDeskApprovalCountOnInsert(trigger.isDelete ? trigger.old : trigger.new, trigger.isDelete ? true : false);
        }
        if(trigger.isUpdate){
        
            //Added by Apttus Support (Managed Service)
            ConfigurationTriggerHandler.updateLineItemRecordsForApproval(trigger.new,trigger.oldMap);
            
            //Added by Amrutha - To calculate total approval hours
            ConfigurationTriggerHandler.updateProposalTotalOnUpdate(trigger.new,trigger.oldMap,trigger.newMap);
            ConfigurationTriggerHandler.updateDealDeskApprovalCountOnUpdate(trigger.new,trigger.oldMap,trigger.newMap);
        }
    }
}