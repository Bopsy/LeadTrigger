trigger TaskAfterTrigger on Task (after insert, after update) {
	Set<Id> accountIds = new Set<Id>();
	for (Task t : Trigger.new) {
		if (t.SDR_Assigned__c) accountIds.add(t.AccountId);
	}
	AccountActivityHandler.setLastSDRActivity(accountIds); 
	
	// Call To Action Processing
	CallToActionHandler.setStatus(Trigger.newMap);
	
	Map<Id, Task> ISLTasks = new Map<Id, Task>();
	if(trigger.isUpdate){
    	for(Task t: trigger.new){
    	    Task oldTask = trigger.oldMap.get(t.Id);
    	    if(t.Subject != null && (t.Subject.contains('to Queue: Inbound Sales Line') || t.Subject.contains('ISL Call')) && t.WhoId != null && t.Campaign_Id_Stamp__c != null
    	        && t.OwnerId != oldTask.OwnerId){
    	        ISLTasks.put(t.WhoId, t);
    	    }
    	}
    	
    	List<FSR__c> mqls = [SELECT OwnerId, Lead__c, Contact__c FROM FSR__c WHERE MQL_Status__c in ('1 - Open', '2 - Working') AND Campaign__r.SubType__c = 'Phone Lead' AND (Lead__c =: ISLTasks.keySet() OR Contact__c =: ISLTasks.keySet())];
    	
    	List<FSR__c> updateMQLs = new List<FSR__c>();
    	
    	for(FSR__c mql: mqls){
    	    Task t = ISLTasks.get(mql.Lead__c);
    	    if(t == null) t = ISLTasks.get(mql.Contact__c);
    	    if(t != null && t.OwnerId != mql.OwnerId){
    	        mql.OwnerId = t.OwnerId;
    	        updateMQLs.add(mql);
    	    }
    	}
    	update updateMQLs;
	}
	
}