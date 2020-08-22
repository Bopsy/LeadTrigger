//Created by: Gram Bischof 10/2/2020
//Last Modified: Gram Bischof 20/2/2020
//
//Description: 
//This trigger is used to change the Event_Certification__c status if event type is webinar.
/**********************************************************/

trigger EventCertification_Trigger on Event_Certification__c (before insert,after insert,after update) {
    try{
      
        TriggerHandlar handler = new EventCertificationController(Trigger.new, Trigger.newMap);
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
               handler.executeBeforeInsert();
            }
        }
    }
    catch(Exception ex){
        
    }
   
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
        EventCertificationController.UpdateCertificationStageAndCertificationDate(Trigger.new);
    }
    
}