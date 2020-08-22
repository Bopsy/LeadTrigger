/* 
 * Trigger: SetCompeteScoreOnLead
 * Purpose: Schedules a future job to set the value of the Lead's Compete Score field
 *          using the Compete API. (Cannot call the Compete API directly from a trigger.)
 */
trigger SetCompeteScoreOnLead on Lead (after insert, after update) {
	
	// If this is called from a future call of batch skip
	if (system.isBatch() || system.isFuture()) {
		return;
	}

	List<String> leadIds = new List<String>();
	List<String> leadDomains = new List<String>();
	Set<String> blacklistDomains = CompeteAPIClient.getBlacklist();
	
	for (Lead l : Trigger.New) {
		// only get the Compete score if there's an email domain
		//   and the compete score is blank or the value has changed
		if ( l.Email_Domain_Without_HTTP__c != null
		     && !blacklistDomains.contains(l.Email_Domain_Without_HTTP__c)
		     && (l.Compete_Score__c==null
				|| (Trigger.isUpdate &&
				    Trigger.oldMap.get(l.Id).Email_Domain_Without_HTTP__c != l.Email_Domain_Without_HTTP__c
					)))
		{
			leadIds.add(l.id);
			leadDomains.add(l.Email_Domain_Without_HTTP__c);
			
			if (leadIds.size()==Limits.getLimitCallouts()) {
				// Call future method to update lead with data from external server.
		    	// This is an async call, it returns right away, after enqueuing the request.
			    //CompeteAPIClient.futureUpdateLead(l.Id, l.Email_Domain_Without_HTTP__c);
			    
			    //if (Limits.getCallouts() < Limits.getLimitCallouts()) {
			    //	CompeteAPIClient.updateLeads(leadIds, leadDomains);
			    //} else {
			    	// schedule for future
				    CompeteAPIClient.futureUpdateLeads(leadIds, leadDomains);
			    //}
			}
	    }
	}
	
	// clean up the last set
	if (!leadIds.isEmpty()) {
		// Call future method to update lead with data from external server.
    	// This is an async call, it returns right away, after enqueuing the request.
	    //CompeteAPIClient.futureUpdateLead(l.Id, l.Email_Domain_Without_HTTP__c);
	    
	    //if (Limits.getCallouts() < Limits.getLimitCallouts()) {
		//	CompeteAPIClient.updateLeads(leadIds, leadDomains);
	    //} else {
	    	// schedule for future
		    CompeteAPIClient.futureUpdateLeads(leadIds, leadDomains);
	    //}
	}
}