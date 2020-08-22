/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class PartnerPortalRoutingTest {

	static User standardUser;
	static User salesOpsUser;
	
    static testMethod void general() {
    	setupTestRecords(true);

        Test.startTest();

		// Instantiate Partner Portal Routing
		PartnerPortalRouting ppRouting;
		try {
			System.debug('Initialized Partner Portal Routing map');
			ppRouting = new PartnerPortalRouting();
            System.assert(true);
		} catch (PartnerPortalRoutingException ex) {
			System.debug(ex.getMessage());
            System.assert(false);
		}
		
		System.debug('Testing DEFAULT rule match');
		System.assertEquals(salesOpsUser.Id, ppRouting.getOwnerId('XX', 'XX','XX', 'XX'));

		System.debug('Testing "US/CA/0 - 50/Test Use Case" rule match');
		System.assertEquals(standardUser.Id, ppRouting.getOwnerId('US', 'CA','0 - 50', 'Test Use Case'));
		
		System.debug('Testing "AR/.*/.*/.*" rule match');
		System.assertEquals(standardUser.Id, ppRouting.getOwnerId('AR', '','', ''));

        Test.stopTest();
    }

    static testMethod void missingDefaultRule() {
    	setupTestRecords(false);

        Test.startTest();

		// Instantiate Partner Portal Routing
		PartnerPortalRouting ppRouting;
		try {
			System.debug('Initialized Partner Portal Routing map');
			ppRouting = new PartnerPortalRouting();
            System.assert(false);
		} catch (PartnerPortalRoutingException ex) {
			System.debug(ex.getMessage());
			System.debug('Successfully threw exception for missing "DEFAULT" mapping rule');
            System.assert(true);
		}
		
        Test.stopTest();
    }

	static void setupTestRecords(Boolean createDefaultRule) {
        salesOpsUser = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

        Profile standardUserProfile = [Select Id from Profile where name = 'Standard User'];
	    standardUser = new User(
	        ProfileId = standardUserProfile.Id,
	        Username = System.now().getTime() + 'partner-portal-routing-test@test.com',
	        Alias = 'testtest',
	        Email='test@test-lead-routing-12345.com',
	        EmailEncodingKey='UTF-8',
	        Firstname='Test',
	        Lastname='Test',
	        LanguageLocaleKey='en_US',
	        LocaleSidKey='en_US',
	        TimeZoneSidKey='America/Chicago'
        );
        insert standardUser;
	
		List<Opp_Owner_Partner_Portal_Routing_Rules__c> oppOwnerPartnerPortalRoutingRules = new List<Opp_Owner_Partner_Portal_Routing_Rules__c>();
		if (createDefaultRule) {
			oppOwnerPartnerPortalRoutingRules.add(new Opp_Owner_Partner_Portal_Routing_Rules__c(
				Name = 'DEFAULT',
				CountryCode__c = '',
				State__c = '',
				Employee_Size__c = '',
				Use_Case__c = '',
				Owner_ID__c = salesOpsUser.Id
			));
		}
		oppOwnerPartnerPortalRoutingRules.add(new Opp_Owner_Partner_Portal_Routing_Rules__c(
			Name = 'US/CA/0 - 50/Test Use Case',
			CountryCode__c = 'US',
			State__c = 'CA',
			Employee_Size__c = '0 - 50',
			Use_Case__c = 'Test Use Case',
			Owner_ID__c = standardUser.Id
		));
		oppOwnerPartnerPortalRoutingRules.add(new Opp_Owner_Partner_Portal_Routing_Rules__c(
			Name = 'AR',
			CountryCode__c = 'AR',
			State__c = '.*',
			Employee_Size__c = '.*',
			Use_Case__c = '.*',
			Owner_ID__c = standardUser.Id
		));
		insert oppOwnerPartnerPortalRoutingRules;
	}
}