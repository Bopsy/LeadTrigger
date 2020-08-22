// ===================
// Featured User Controller Test
// ===================
@isTest
public with sharing class Peak_FeaturedUserControllerTest {

	@testSetup
	static void testSetup() {
		Contact testContact = Peak_TestUtils.createTestContact();
	}
	
	// Test getting the user
	@isTest
	public static void testFeaturedUser(){
		// Set up and run as a standard user
		List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];

		User testUser = Peak_TestUtils.createStandardUserNoContact();
		try {
			testUser.ContactId = testContacts[0].Id;
			insert testUser;
		}catch(Exception e){
			testUser.ContactId = NULL;
			insert testUser;
		}

		User queryUser = Peak_FeaturedUserController.getUserInformation(testUser.Id);
		system.assertEquals(Peak_TestConstants.FIRSTNAME + ' ' + Peak_TestConstants.LASTNAME,queryUser.Name);
	}

	// Test getting the site prefix
	@isTest
	public static void testSitePrefix(){
		String prefix = Peak_FeaturedUserController.getSitePrefix();
		System.assertNotEquals(null, prefix);
	}
}