trigger leadOwnerUpdate on Lead (after insert, after update) {
    List<Lead> updateCS = new List<Lead>();
    Map<Id,Lead> leadsEloquaOverrideOwner = new Map<Id,Lead>();
    Map<Id,Lead> leadsTempOwner = new Map<Id,Lead>();
    
    for (Lead cs : Trigger.new) {
        // Check for ELOQUA Override Owner
        if(!String.isBlank(cs.ELOQUA_Override_Ownership__c)) {
	        System.debug('>>>>> Owner ID: '+cs.ownerId+' ELOQUA Owner ID: '+cs.ELOQUA_Override_Ownership__c);
            if(cs.OwnerId != cs.ELOQUA_Override_Ownership__c) {
                leadsEloquaOverrideOwner.put(cs.id,cs);
            }
        } else {
        	// Preserved because this TempOwnerId process is unknown why it was implemented, but will be only
        	// performed if the ELOQUA_Override_Ownership__c is not set.
	        if(Trigger.isUpdate) {  
	            System.debug('>>>>> Owner ID: '+cs.ownerId+' Temp Owner ID: '+cs.TempOwnerId__c);
	            if(cs.TempOwnerId__c <> null && cs.TempOwnerId__c <> '') {
	                if(cs.OwnerId <> cs.TempOwnerId__c) {
	                    leadsTempOwner.put(cs.id,cs);
	                }
	            }           
	        }
        }
    }

	if (!leadsTempOwner.isEmpty() || !leadsEloquaOverrideOwner.isEmpty()) {

		Set<Id> allLeadIds = new Set<Id>();
		allLeadIds.addAll(leadsTempOwner.keySet());
		allLeadIds.addAll(leadsEloquaOverrideOwner.keySet());
		List<Lead> leadsToUpdate = [ SELECT OwnerId, TempOwnerId__c,ELOQUA_Override_Ownership__c FROM Lead WHERE Id in :allLeadIds ];

	    if (!leadsToUpdate.isEmpty()) {
	    	for (Lead cs : leadsToUpdate) {
				// Preserved because this TempOwnerId process is unknown why it was implemented, but will be only
				// performed if the ELOQUA_Override_Ownership__c is not set.
			    if (leadsTempOwner.containsKey(cs.Id)) {
			        cs.OwnerId = leadsTempOwner.get(cs.Id).TempOwnerId__c;
			        cs.TempOwnerId__c = 'SKIP'; //flag to stop infinite loop upon update
			        updateCS.add(cs);
			    }
			    
			    if (leadsEloquaOverrideOwner.containsKey(cs.Id)) {
			    	cs.OwnerId = leadsEloquaOverrideOwner.get(cs.Id).ELOQUA_Override_Ownership__c;
			        updateCS.add(cs);
			    }
	    	}
	    }
	
	    //
	    //Update last assignment for Assignment Group in batch
	    //
	    System.debug('>>>>>Update Leads: '+updateCS);
	    if (updateCS.size()>0) {
	        try {
	            update updateCS;
	        } catch (Exception e){
	
	        }
	    }
	}
}