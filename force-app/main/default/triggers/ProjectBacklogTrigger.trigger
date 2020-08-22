/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           ProjectBacklogTrigger
*
* @description    Trigger for Project Backlog object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-08-19
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger ProjectBacklogTrigger on Project_Team__c (before insert,after insert, after update, after undelete, after delete) {

    if(trigger.isBefore){
        if(trigger.isInsert || trigger.isUndelete){
            ProjectBacklogTriggerHandler.handleOnInsert(trigger.new);
        }
    }
    
    if(trigger.isAfter){
        if(!TriggerRunOnceUtility.ProjectBacklogTrigger){
            TriggerRunOnceUtility.ProjectBacklogTrigger=true;
            
            if(trigger.isInsert || trigger.isUndelete){
                ProjectBacklogTriggerHandler.handleOnInsertTeams(trigger.new);
            }
            if(trigger.isUpdate){
                ProjectBacklogTriggerHandler.handleOnUpdate(trigger.oldmap, trigger.new);
            }
        }
        if(trigger.isDelete){
            ProjectBacklogTriggerHandler.handleOnDelete(trigger.old);
        }
    }
}