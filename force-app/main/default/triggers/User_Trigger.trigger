trigger User_Trigger on User (after update,after insert) {
    
      if (Trigger.isAfter && Trigger.isUpdate) {
         UserTriggerHandler.afterUpdate(Trigger.newMap, Trigger.oldMap);
     }
     if (Trigger.isAfter && Trigger.isInsert) {
             UserTriggerHandler.sharepassToPartner(trigger.new);
              system.debug('inside sharepassToPartner');
     }

    
}