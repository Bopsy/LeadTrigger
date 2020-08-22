@isTest
private class CountryPhoneNumberInterestTriggerTest {

	private static testMethod void testTrigger() {
	    Test.startTest();
            insert new Opportunity_Country_Number__c(Country_Input__c = 'United States', Type_Input__c = 'Local', Capability_Input__c = 'SMS');
        Test.stopTest();
	}

}