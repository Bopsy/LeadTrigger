@isTest
public class X7S_ThemeControllerTest {
	@isTest
	static void test_UberTheme() {
		Profile adminProfile = [
				SELECT Id
				FROM profile
				WHERE Name = 'System Administrator'
				LIMIT 1
		];

		User admin = new User(LastName = 'test user 1',
				Username = 'test.user.1@example.com',
				Email = 'test.1@example.com',
				Alias = 'testu1',
				TimeZoneSidKey = 'GMT',
				LocaleSidKey = 'en_US',
				EmailEncodingKey = 'ISO-8859-1',
				ProfileId = adminProfile.Id,
				LanguageLocaleKey = 'en_US');

		System.runAs(admin) {
			Test.startTest();

			// call method to get Site Prefix
			String strSitePathPrefix = X7S_ThemeController.getSiteName();
			system.assertEquals(strSitePathPrefix, System.Site.getPathPrefix());

            Test.stopTest();
		}
	}
}