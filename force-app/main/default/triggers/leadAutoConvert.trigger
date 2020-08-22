trigger leadAutoConvert on Lead (after insert, after update) {

//	Set<String> apiUsers = new Set<String> { 'Kevin Eloqua', 'API-Read Only', 'Eloqua Marketing' };
	Set<String> apiUsers = new Set<String> { 'Kevin Eloqua', 'Jonathan Eloqua', 'API-Read Only', 'Eloqua Marketing' };
//	Set<String> apiUsers = new Set<String> { 'API-Read Only', 'Eloqua Marketing' };
	Set<String> leadSourcesToExclude  = new Set<String>{
		'PPortal - Open Deal Reg',
		'PPortal - Closed Deal Reg',
		'WebForm - Open Deal Reg',
		'WebForm - Closed Deal Reg'
	};
	
    Map<Id,Lead> leads = new Map<Id,Lead>();
    
	// Get the list of profile IDs that should be excluded from auto-conversion on record update only
	// Query the lead's profile owner ID to determine if it should be excluded
	// If the lead should be exclude remove it from the leadsToProcess
	Set<String> userProfilesToExclude = new Set<String>();
	for (DoNotAutoConvert__c d : DoNotAutoConvert__c.getAll().values()) {
		userProfilesToExclude.add(d.Profile_ID__c);
	}
	
	List<Lead> leadsToProcess = new List<Lead>();
	for (Lead l : [
		SELECT Id, Owner.ProfileId
		FROM Lead
		WHERE Id IN :Trigger.newMap.keySet()
		AND IsConverted != true
		AND (NOT (
			Owner.ProfileId IN :userProfilesToExclude
			AND Owner.UserRole.Name LIKE '%Outbound%'
		))
	]) {
		leadsToProcess.add(Trigger.newMap.get(l.Id));
	}
	
    // Process the remain leads
    for(Lead l : leadsToProcess){
    	System.debug('===> LEAD UPDATE('
    		+ 'isApiUser=' + apiUsers.contains(UserInfo.getName()) + '/' + UserInfo.getName()
			+ ', isEmailBlank=' + (String.isBlank(l.Email) && String.isBlank(l.Preferred_Email__c)) + '/' + l.Email + '/' + l.Preferred_Email__c
			+ ', isLeadSourceToExclude=' + leadSourcesToExclude.contains(l.LeadSource) + '/' + l.LeadSource
			+ ', Status=' + l.Status
			+ ')');
        if(!l.isConverted
        	&& !apiUsers.contains(UserInfo.getName())
			&& !(String.isBlank(l.Email) && String.isBlank(l.Preferred_Email__c))
			&& !leadSourcesToExclude.contains(l.LeadSource)
			&& l.Status == 'Open'
		){
        	leads.put(l.Id, l);
        }
    }

    if (!leads.isEmpty()) {
		LeadAutoConvertHandler.convert(leads);
    }
}