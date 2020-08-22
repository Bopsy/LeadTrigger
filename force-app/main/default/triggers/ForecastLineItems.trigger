trigger ForecastLineItems on Forecast_Schedule__c (before insert, before update, after insert, after update, after delete) {
  public static Boolean runOnce = false;
  if( trigger.isBefore ) {
    if( trigger.isInsert || trigger.isUpdate && !runOnce) {
        Set<Id> usageIds = new Set<Id>();
        for(Forecast_Schedule__c schedule: trigger.new){
            if(schedule.Twilio_Usage__c != null){
                usageIds.add(schedule.Twilio_Usage__c);
            }
            schedule.Forecast_Amount__c = schedule.Forecast_Amount_Roll_Up__c;
        }
        List<Forecast_Schedule__c> schedules = [SELECT Opportunity__r.CloseDate, Opportunity__r.RecordType.Name, Twilio_Usage__c, Blocked_Usage_Forecast_Schedule_Level__c, Month_Number__c FROM Forecast_Schedule__c WHERE Twilio_Usage__c =: usageIds AND Month_Number__c <= 13 AND Opportunity__r.iARR_Special_Rules__c != 'Exclude' AND Opportunity__r.StageName = 'Closed Won' ORDER BY Month_Number__c DESC];
        //if(!schedules.isEmpty()){
            Map<Id, Forecast_Schedule__c> usageBlockedMap = new Map<Id, Forecast_Schedule__c>();
            for(Forecast_Schedule__c schedule: schedules){
                schedule.Blocked_Usage_Forecast_Schedule_Level__c = null;if(!usageBlockedMap.containsKey(schedule.Twilio_Usage__c)){usageBlockedMap.put(schedule.Twilio_Usage__c, schedule);}
            }
            for(Forecast_Schedule__c schedule: trigger.new){
                if(schedule.Twilio_Usage__c != null){
                    Forecast_Schedule__c blockedSchedule = usageBlockedMap.get(schedule.Twilio_Usage__c);
                    if(schedule.Blocked_Usage_Forecast_Schedule_Level__c == null && blockedSchedule != null && (blockedSchedule.Opportunity__r.CloseDate >= Date.newInstance(2018,1,1) || (blockedSchedule.Opportunity__r.RecordType.Name != 'Renegotiation Opportunity' && blockedSchedule.Opportunity__r.RecordType.Name != 'Programmable Wireless'))){
                        if(blockedSchedule.Id != schedule.Id /* not blocked by self*/ && blockedSchedule.Blocked_Usage_Forecast_Schedule_Level__c != schedule.Id /* not loop blocked*/){
                               schedule.Blocked_Usage_Forecast_Schedule_Level__c = blockedSchedule.Id;
                           }
                    }
                }
            }
        //}
        
        
      //FieldSalesForecast.findOrCreateForecasts( trigger.new );
    }
  }

  if( trigger.isAfter ) {
    if( trigger.isDelete ) {
      //FieldSalesForecast.updateSalesForecastsScheduleValues( trigger.old, NULL );
    } else {
      //FieldSalesForecast.updateSalesForecastsScheduleValues( trigger.new, trigger.old );
    }

    //if ( ForecastSchedule.forecastLineitemRecalc && !(System.isFuture() || System.isScheduled() || System.isBatch())){
        //ForecastSchedule.adjustAmountViaSchedsfuture(trigger.newMap.keySet());
        //return;
    //}

    //to prevent downstream issues.
    //User currentUser = [SELECT Id, Skip_Dipswitch__c FROM User WHERE Id =:UserInfo.getUserId()];
    //if (currentUser.Skip_Dipswitch__c) //the dipswitch controls if the trigger logic is skipped, necessary for large data loading
      //return;
    
    ForecastSchedule.forecastLineitemRecalc = true;
    ForecastSchedule.adjustAmountViaScheds( trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.new, trigger.oldMap );
    if(trigger.isUpdate && !runOnce){
        runOnce = true;
        List<Forecast_Schedule__c> schedules = new List<Forecast_Schedule__c>();
        for(Forecast_Schedule__c schedule: trigger.new){
            Forecast_Schedule__c oldRec = trigger.oldMap.get(schedule.Id);
            if(oldRec.Start_Date__c != schedule.Start_Date__c) schedules.add(schedule);
        }
        
        if(schedules.isEmpty()) return;
        List<Product_Schedule__c> prodSchedules = [SELECT Forecast_Schedule__c FROM Product_Schedule__c WHERE Forecast_Schedule__c =: schedules];
        for(Product_Schedule__c sch: prodSchedules){
            sch.Start_Date__c = trigger.newMap.get(sch.Forecast_Schedule__c).Start_Date__c;
        }
        update prodSchedules;
    }
  }
}