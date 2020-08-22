/* 
 * Trigger: SetHighValueLead
 * Purpose: Sets the value of custom checkbox Lead.High_Value_Lead__c whenever a lead is inserted or updated.
 *
 * If the lead's email domain matches a High Value Domain record, then the checkbox will be set to true,
 * otherwise it will be set to false.
 *
 */
trigger SetHighValueLead on Lead (before insert, before update) {

	// extract all the email domains from the leads
	Set<String> emailDomains = new Set<String>();
	for (Lead l : trigger.New) {
		if (l.Email_Domain_Without_HTTP__c != null) {
			emailDomains.add(l.Email_Domain_Without_HTTP__c.toLowerCase());
		}
	}
	
	// query for all High Value Domains matching these email domains
	List<High_Value_Domain__c> hvdResults =
			[SELECT Id, Name FROM High_Value_Domain__c WHERE Name IN :emailDomains];
	
	// convert the query results to a Set
	Set<String> hvds = new Set<String>();
	for (High_Value_Domain__c hvd : hvdResults) {
		hvds.add(hvd.Name);		
	}
	
	// set Lead.High_Value_Lead__c to true if the query results contained the lead's email domain
	// otherwise make it false
	for (Lead l : trigger.New) {
		if (l.Email_Domain_Without_HTTP__c != null) {
			l.High_Value_Lead__c = hvds.contains(l.Email_Domain_Without_HTTP__c.toLowerCase());
		} else {
			l.High_Value_Lead__c = false;
		}
	}
}