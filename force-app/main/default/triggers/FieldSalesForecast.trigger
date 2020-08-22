trigger FieldSalesForecast on Field_Sales_Forecast__c (before insert, after update, after delete) {
  static Boolean runBatchTriggerOnce = false;
  if( Trigger.isBefore ) {
    if( Trigger.isInsert ) {
      FieldSalesForecast.findOrCreateManagerForecasts( Trigger.new );
      FieldSalesForecast.findOrCreateOverrideForecasts( Trigger.new );
    }
  } else if( Trigger.isAfter ) {
    if( Trigger.isUpdate ) {
      if( System.isFuture() || System.isScheduled() || System.isBatch() || FieldSalesForecast.disableFuture ) {
        if(runBatchTriggerOnce) return;
        //FieldSalesForecast.updateManagerForecasts( Trigger.new );
        FieldSalesForecast.updateOverrideForecasts( Trigger.new );
        runBatchTriggerOnce = true;
      } else {
        //FieldSalesForecast.futureUpdateRollupForecasts( Trigger.newMap.keySet() );
      }
    } else if( Trigger.isDelete ) {
      FieldSalesForecast.updateManagerForecasts( Trigger.old );
      FieldSalesForecast.updateOverrideForecasts( Trigger.old );
    }
  }
}