trigger RHX_Twilio_Usage on Twilio_Usage__c (after delete, after insert, after undelete, after update, before delete) {
    TwilioForecastHandler.calculateForecastUsage(Trigger.isDelete ? Trigger.old : Trigger.new);     

// Disabled Trigger
//    Type rollClass = System.Type.forName('rh2', 'ParentUtil');
//    
//    if(rollClass != null) {
//     rh2.ParentUtil pu = (rh2.ParentUtil) rollClass.newInstance();
//        if (trigger.isAfter) {
//            pu.performTriggerRollups(trigger.oldMap, trigger.newMap, new String[]{'Twilio_Usage__c'}, null);
//        }
//    }
}