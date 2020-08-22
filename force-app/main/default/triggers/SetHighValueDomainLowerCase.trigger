/* 
 * Trigger: SetHighValueDomainLowerCase
 * Purpose: Sets the value of the High Value Domain's Name field to lower case,
 *          ensuring case-sensitive queries will match.
 *
 */
trigger SetHighValueDomainLowerCase on High_Value_Domain__c (before insert, before update) {

	for (High_Value_Domain__c hvd : trigger.new) {
		hvd.Name = hvd.Name.toLowerCase();
	}

}