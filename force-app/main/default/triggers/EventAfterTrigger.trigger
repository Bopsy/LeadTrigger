trigger EventAfterTrigger on Event (after insert, after update) {
	Set<Id> accountIds = new Set<Id>();
	for (Event e : Trigger.new) {
		if (e.SDR_Assigned__c) accountIds.add(e.AccountId);
	}
	AccountActivityHandler.setLastSDRActivity(accountIds);
}