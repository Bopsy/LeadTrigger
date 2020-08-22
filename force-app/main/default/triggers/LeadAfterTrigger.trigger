trigger LeadAfterTrigger on Lead (after insert, after update) {
    Trigger_Bypass_Settings__c trigBypass = Trigger_Bypass_Settings__c.getInstance(UserInfo.getUserId());
    if(trigBypass != null){
        if(trigBypass.Lead__c == TRUE){ 
            return; 
        }
	}	
    
	// A command Lead after trigger was created to control the sequence of operations
    if(!LeadTriggerHandler.runOnce){
    	LeadTriggerHandler.ownerUpdate(Trigger.isUpdate, Trigger.isInsert, Trigger.oldMap, Trigger.newMap);
    	// Added by Ashwani. Keep it robust. Lot of things happening on Lead.  18-Feb-2016
        LeadTriggerHandler.autoconvert(Trigger.isUpdate, Trigger.isInsert, Trigger.oldMap, Trigger.newMap);
    	// When a Lead with MQL converts into Contact and Oppty
    	//    - Set Short Code owner == Contact's Account Owner
    	if (Trigger.isAfter && Trigger.isUpdate) {
    	    List<Lead> newlyConvertedLeads = new List<Lead>();
    		for (Lead n : Trigger.new) {if (n.IsConverted && (n.IsConverted != Trigger.oldMap.get(n.Id).IsConverted)) {newlyConvertedLeads.add(n);}}if (!newlyConvertedLeads.isEmpty()) {System.debug('LeadAfterTrigger(ShortCodeTriggerHandler.setOwnershipToAccountOwner): ' + newlyConvertedLeads);ShortCodeTriggerHandler.setOwnershipToAccountOwner(newlyConvertedLeads);}
    	}
    }
    LeadTriggerHandler.partnerDealSubmission(Trigger.isUpdate, Trigger.isInsert, Trigger.oldMap, Trigger.newMap);
	LeadTriggerHandler.partnerPortalAutoConversion(Trigger.isUpdate, Trigger.isInsert, Trigger.oldMap, Trigger.newMap);
	System.debug('++++++++++# query after autoconvert executed: '+Limits.getQueries());
    
    LeadTriggerHandler.reparentChildRecords(Trigger.isUpdate, Trigger.isInsert, Trigger.oldMap, Trigger.newMap);
    System.debug('++++++++++# query after reparentChildRecords executed: '+Limits.getQueries());
	
    if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    		LeadTriggerHandler.linkAccountSidToContact(Trigger.oldMap, Trigger.newMap);
    		
	
}