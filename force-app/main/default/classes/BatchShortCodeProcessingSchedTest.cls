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
private class BatchShortCodeProcessingSchedTest {

	static List<User> userList = new List<User>();
	static List<Account> accountList = new List<Account>();
	static List<Contact> contactList = new List<Contact>();
	static List<Opportunity> opptyList = new List<Opportunity>();
	static List<Lead> leadList = new List<Lead>();
	static List<Short_Code__c> shortCodeList = new List<Short_Code__c>();

   // CRON expression: midnight on March 15.
   // Because this is a test, job executes
   // immediately after Test.stopTest().
   public static String CRON_EXP = '0 0 0 15 3 ? 2022';

   static testmethod void ScheduleBatchJob() {
      setupTestRecords();
      
      Test.startTest();

      // Schedule the test job
      String jobId = System.schedule('BatchShortCodeProcessingScheduler',
                        CRON_EXP, 
                        new BatchShortCodeProcessingScheduler());
         
      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(CRON_EXP, 
         ct.CronExpression);

      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the next time the job will run
      System.assertEquals('2022-03-15 00:00:00', 
      String.valueOf(ct.NextFireTime));
      Test.stopTest();
   }

	static void setupTestRecords() {

		// IMPORTANT:  It is required that the UserRole are added to the list in this order
		//    "AM" is index 0
		//    "CSM" is index 1
		//    At least one other is greater than index 1
		List<UserRole> roleList = [ SELECT Id, Name FROM UserRole WHERE Name LIKE 'AM%' LIMIT 1 ];
		roleList.add([ SELECT Id, Name FROM UserRole WHERE Name LIKE 'CSM%' LIMIT 1 ]);
		roleList.add([ SELECT Id, Name FROM UserRole WHERE Name LIKE 'EMEA%' LIMIT 1 ]);
		if (roleList.size() != 3) {
			System.debug('Missing a required UserRole.  There must be 3 roles where one of each contains "AM", "CSM", and "EMEA" in their Name field.');
		}
		
		Profile p = [ SELECT Id FROM Profile WHERE name = 'Standard User' ];
		
		// Create a User record for each User Role
		//    User with "AM" role is index 0
		//    User with "CSM" role is index 1
		//    User with other role is greater than index 1
		for (Integer i = 0; i < roleList.size(); i++) {
			User u = new User();
			u.ProfileId = p.Id;
			u.UserRoleId = roleList[i].Id;
			u.Username = System.now().getTime() + 'test@ShortCodeLinkTest' + i + '.com';
			u.Alias = 'test' + i;
			u.Email='test@ShortCodeLinkTest' + i + '.com';
			u.EmailEncodingKey='UTF-8';
			u.Firstname='Test';
			u.Lastname='Test';
			u.LanguageLocaleKey='en_US';
			u.LocaleSidKey='en_US';
			u.TimeZoneSidKey='America/Chicago';
			userList.add(u);
		}

		// Trick to avoid the following exception:
		//   System.DmlException: Insert failed. First exception on row 0; first error: MIXED_DML_OPERATION, 
		//   DML operation on setup object is not permitted after you have updated a non-setup object
		//   (or vice versa): Account, original object: User: []
		User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
		System.runAs ( thisUser ) {
			insert userList;
		}

		List<String> countries = new List<String>();
        Schema.DescribeFieldResult field = Account.BillingCountryCode.getDescribe();
        for (Schema.PicklistEntry f : field.getPicklistValues())
          countries.add(f.getValue());

		// AM Account
		accountList.add(new Account(
			Name = 'TestAccount1',
			BillingCountryCode = countries[0],
			Industry = 'Industry1',
			OwnerId = userList[0].Id
		));

		// CSM Account
		accountList.add(new Account(
			Name = 'TestAccount2',
			BillingCountryCode = countries[1],
			Industry = 'Industry2',
			OwnerId = userList[1].Id
		));
		insert accountList;

		// EMEA Account
		accountList.add(new Account(
			Name = 'TestAccount0',
			BillingCountryCode = countries[2],
			Industry = 'Industry0',
			OwnerId = userList[2].Id
		));

		// Role Team should be 'AM' and will be related to TestAccount1
		contactList.add(new Contact(
			LastName = 'TestCustomer1',
			AccountId = accountList[0].Id,
			Email = 'TestCustomer1@ShortCodeLinkTest.com'
		));
		
		// Role Team should be 'CSM' and will be related to TestAccount2
		contactList.add(new Contact(
			LastName = 'TestCustomer2',
			AccountId = accountList[1].Id,
			Email = 'TestCustomer2@ShortCodeLinkTest.com'
		));
		insert contactList;

		// Related to TestAccount1
		String opptyShortCodeRecTypeName = 'Short Code Opportunity';
		RecordTypeInfo shortCodeRecTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(opptyShortCodeRecTypeName);
		
		opptyList.add(new Opportunity(
			Name = 'TestOpp',
			RecordTypeId = shortCodeRecTypeInfo.getRecordTypeId(),
			AccountId = accountList[0].Id,
			CloseDate = Date.today(),
			StageName = 'Pilot',
			FY_16_Use_Case__c = 'UseCase 1',
			Authy_Use_Case__c = 'Call Tracking',
			Product__c = 'Client',
			Primary_Competitor__c = 'Agendi',
			New_Business_Account_SID__c = '01234567890'
		));
		insert opptyList;
		
		leadList.add(new Lead(
			LastName = 'ShortCodeTest3',
			Email = 'TestCustomer3@ShortCodeLinkTest.com',
			Company = 'TestCustom3',
			Status = 'Open'
		));
		insert leadList;
				
		// Shouldn't be Linked
		shortCodeList.add(new Short_Code__c(
			Short_Code_App_Sid__c = 'ShortCodeTest0',
			OwnerUser_Email_Address__c = 'TestCustomer0@ShortCodeLinkTest.com',
			Application_Status__c = 'Pending Twilio'
		));
		
		// Should Link to Contact1
		shortCodeList.add(new Short_Code__c(
			Short_Code_App_Sid__c = 'ShortCodeTest1',
			OwnerUser_Email_Address__c = 'TestCustomer1@ShortCodeLinkTest.com',
			Application_Status__c = 'Pending Twilio'
		));

		// Should Link to Contact2
		shortCodeList.add(new Short_Code__c(
			Short_Code_App_Sid__c = 'ShortCodeTest2',
			OwnerUser_Email_Address__c = 'TestCustomer2@ShortCodeLinkTest.com',
			Application_Status__c = 'Pending Twilio'
		));

		// Should Link to Lead3
		shortCodeList.add(new Short_Code__c(
			Short_Code_App_Sid__c = 'ShortCodeTest3',
			OwnerUser_Email_Address__c = 'TestCustomer3@ShortCodeLinkTest.com',
			Application_Status__c = 'Pending Twilio'
		));
				
		insert shortCodeList;
	}
}