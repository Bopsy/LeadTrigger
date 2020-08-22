trigger AgreementAttachmentTrigger on Agreement_Attachment__c (before insert, after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            AgreementAttachmentTriggerHandler.afterUpsert(trigger.new, new Map<Id, Agreement_Attachment__c>());
            
        }
        else if(trigger.isUpdate){
            AgreementAttachmentTriggerHandler.afterUpsert(trigger.new, trigger.oldMap);
        }
    }
    else if(trigger.isBefore){
        if(trigger.isInsert){
            AgreementAttachmentTriggerHandler.beforeInsert(trigger.new);
            AgreementAttachmentTriggerHandler.afterInsert(trigger.new);
        }
    }
}