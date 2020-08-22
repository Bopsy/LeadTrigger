/**********************************************************/
//Created by: Gram Bischof 8/22/2017
//Last Modified: Gram Bischof 8/22/2017
//
//Description: 
//This trigger handles logic to be run when changes occur to 
//the Leads objects.
/**********************************************************/
trigger LeadTrigger on Lead (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    try{
        TriggerHandler handler = new LeadTriggerHandler(Trigger.new, Trigger.newMap, Trigger.oldMap);
        
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                handler.executeBeforeInsert();
            }
            
            if (Trigger.isUpdate) {
                handler.executeBeforeUpdate();            
            }
            
            if (Trigger.isDelete) {
                handler.executeBeforeDelete();
            }
        }
        
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                handler.executeAfterInsert();
            }
            
            if (Trigger.isUpdate) {
                handler.executeAfterUpdate();            
            }
            
            if (Trigger.isDelete) {
                handler.executeAfterDelete();
            }
            
            if (Trigger.isUndelete) {
                handler.executeAfterUndelete();
            }
        }
    }
    catch(Exception ex){
       
    }
}