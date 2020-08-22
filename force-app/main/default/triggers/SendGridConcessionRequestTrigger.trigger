trigger SendGridConcessionRequestTrigger on SendGrid_Concession_Request__c (after insert, after update, after delete, after undelete) {
    if(Trigger.isafter) {
        if(Trigger.isInsert || Trigger.isUndelete) {
            SendGridConcessionRequestHandler.stamp(Trigger.New, false);
        } else if(Trigger.isUpdate) {
            SendGridConcessionRequestHandler.stamp(Trigger.New, Trigger.oldMap);
        } else if(Trigger.isDelete) {
            SendGridConcessionRequestHandler.stamp(Trigger.Old, true);
        } 
    }
}