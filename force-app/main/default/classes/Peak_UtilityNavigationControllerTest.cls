// ===================
// Test Utility Navigation Controller
// ===================
@isTest
public with sharing class Peak_UtilityNavigationControllerTest {

	@testSetup
	static void testSetup() {
		Contact testContact = Peak_TestUtils.createTestContact();
	}

	// Test finding a user
	@isTest
	public static void testUser(){
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

		System.runAs(testUser) {
			System.assertEquals(false,Peak_UtilityNavigationController.isGuestUser());
		}
		
	}

	// Test running as a guest
	@isTest
	public static void testGuest(){
		// Set up and run as guest user
		User guestUser = Peak_TestUtils.createGuestUser();

		System.runAs(guestUser) {
			System.assertEquals(true,Peak_UtilityNavigationController.isGuestUser());
		}
	}
}