trigger ShortCodeTrigger on Short_Code__c (before update, before insert, after delete, after update, after insert) {
    if (Trigger.isAfter) {
	    if (Trigger.isUpdate) {
	      ShortCodeTriggerHandler.clearShortCodeOnOpportunity(Trigger.isUpdate, Trigger.isDelete, Trigger.new, Trigger.oldMap);
	    } else if (Trigger.isDelete) {
	      ShortCodeTriggerHandler.clearShortCodeOnOpportunity(Trigger.isUpdate, Trigger.isDelete, Trigger.new, Trigger.oldMap);
	    }
	    
	    // On Short Code association with:
		//   Contact with MQL: make Contact's Account Owner the Short Code Application owner and notify via email
		//   Lead with MQL: leave owner as as API Read Only
		//   Additional use cases to be defined
	    List<Short_Code__c> shortCodes = new List<Short_Code__c>();
		if (Trigger.isInsert) {
		    for (Short_Code__c n : Trigger.new) {
		    	if (n.Contact__c != null || n.Lead__c != null) {
		    		shortCodes.add(n);
		    		System.debug('ShortCodeTrigger(ShortCodeTriggerHandler.setAccountOwnership(INSERT)): ' + n);
		    	}
		    }
	    } else if (Trigger.isUpdate) {
		    for (Short_Code__c n : Trigger.new) {
		    	Short_Code__c o = Trigger.oldMap.get(n.Id);
		    	if (
		    		(n.Contact__c != null && o.Contact__c != n.Contact__c) ||
		    		(n.Lead__c != null && o.Lead__c != n.Lead__c)
		    	) {
		    		shortCodes.add(n);
		    		System.debug('ShortCodeTrigger(ShortCodeTriggerHandler.setAccountOwnership(UPDATE)): ' + n);
		    	}
		    }
	    }
	    if (!shortCodes.isEmpty()) {
	    	//System.debug('ShortCodeTrigger(ShortCodeTriggerHandler.setAccountOwnership(SHORT_CODE)): ' + shortCodes);
	    	//ShortCodeTriggerHandler.setAccountOwnership(shortCodes);
	    }
    }
    
    if (Trigger.isBefore && Trigger.isUpdate) {
    	ShortCodeTriggerHandler.linkShortCodes(Trigger.oldMap, Trigger.new);
    }
    else if(Trigger.isBefore && Trigger.isInsert){
        ShortCodeTriggerHandler.linkShortCodes(new Map<Id, Short_Code__c>(), Trigger.new);
    }
}