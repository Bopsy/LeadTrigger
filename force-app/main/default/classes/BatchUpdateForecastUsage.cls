global class BatchUpdateForecastUsage implements Database.Batchable<sObject>, Schedulable {
	global Database.QueryLocator start(Database.BatchableContext BC) {
		TwilioUsageLastUpdate__c lastSyncDt = TwilioUsageLastUpdate__c.getOrgDefaults();
		DateTime lstSyncTime = lastSyncDt.Last_Sync_Date__c;
		if (lastSyncDt.Last_Sync_Date__c != null) { 
			return Database.getQueryLocator('SELECT Account__c FROM Twilio_Forecast__c where Account__c != null AND LastModifiedDate > :lstSyncTime Order By Account__c');
		}
		return Database.getQueryLocator('SELECT Account__c FROM Twilio_Forecast__c');
	}
	 
	global void execute(Database.BatchableContext info, List<sObject> scope) {
		Set<Id> accIds = new Set<Id>();
		for (Twilio_Forecast__c tf : (List<Twilio_Forecast__c>) scope) {
			accIds.add(tf.Account__c); 
		}
		List<Twilio_Usage__c> lstToUpdt = [Select Id, Usage_Date__c, Month__c, Year__c, AccountLookup__c, Fiscal_Year__c, 
											Current_Month_Forecast__c, Last_Month_Forecast__c, Twilio_Forecast_3__c  
																							From Twilio_Usage__c 
																							Where AccountLookup__c in :accIds 
																							AND Usage_Date__c != null];
		TwilloUsageTriggerHandler.updateForeCast(lstToUpdt); 
		update lstToUpdt; 
	}
	
	global void finish(Database.BatchableContext info) {
		
		TwilioUsageLastUpdate__c lastSyncDt = TwilioUsageLastUpdate__c.getOrgDefaults();
		lastSyncDt.Last_Sync_Date__c = system.now();
		upsert lastSyncDt;
	}
	
	global void execute(System.SchedulableContext SC) {
		Database.executeBatch(new BatchUpdateForecastUsage());
	}
}