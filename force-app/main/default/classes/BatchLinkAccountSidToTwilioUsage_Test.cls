/* * * * * *
*
* Name:        BatchLinkAccountSidToTwilioUsage_Test (Test class)
* Description: Unit test class for BatchLinkAccountSidToTwilioUsage
* Created:     Feb 16, 2016 1:50:58 PM
* Author:      Ashwani Soni
* Company:     GoNimbly, Zack
*
* * * */
@isTest
public with sharing class BatchLinkAccountSidToTwilioUsage_Test
{
	static final Integer NUM_RECORDS = 30;

	static List<Account> testAccounts;
	static List<Account_SID__c> testAccountSIDs;
	static List<Twilio_Usage__c> testUsages;
	static Set<Integer> monthsToProcess;

	static void createData()
	{
		testAccounts = new List<Account>();
		for( Integer index = 0; index < NUM_RECORDS; index++ )
		{
			Account newAccount = new Account();
			newAccount.Name = 'Test Account';
			testAccounts.add( newAccount );
		}
		insert testAccounts;

		Integer monthCounter = 1;
		monthsToProcess = new Set<Integer>();
		testAccountSIDs = new List<Account_SID__c>();
		testUsages = new List<Twilio_Usage__c>();
		for( Account anAccount : testAccounts )
		{
			Account_SID__c newSID = new Account_SID__c();
			newSID.Account__c = anAccount.Id;
			newSID.Account_SID__c = '' + anAccount.Id + System.now().getTime();
			testAccountSIDs.add( newSID );

			monthsToProcess.add( monthCounter );

			Twilio_Usage__c newUsage = new Twilio_Usage__c();
			newUsage.AccountSid__c = newSID.Account_SID__c;
			newUsage.Year__c = Date.today().year();
			newUsage.Month__c = monthCounter;
			newUsage.Currency__c = 'USD';
			newUsage.Product__c = 'Test Product';
			newUsage.Total__c = 10.0;
			monthCounter = Math.mod(monthCounter, 12) + 1;
			testUsages.add( newUsage );
		}
		insert testAccountSIDs;
		insert testUsages;
	}

	static testMethod void testExecute()
	{
		createData();

		Test.startTest();

			BatchLinkAccountSidToTwilioUsage bat = new BatchLinkAccountSidToTwilioUsage(new List<Integer>(monthsToProcess));
			Database.executebatch(bat);

		Test.stopTest();

		List<Twilio_Usage__c> updatedUsages = [ SELECT Id, Related_Account_SID__c, AccountSid__c, AccountLookup__c
												FROM Twilio_Usage__c ];
		System.assertEquals( NUM_RECORDS, updatedUsages.size(), 'There should be as many Usages returned as created' );
		Map<Id, Account_SID__c> accountSIDMap = new Map<Id, Account_SID__c>(testAccountSIDs);
		for( Twilio_Usage__c aUsage : updatedUsages )
		{
			Account_SID__c relatedSID = accountSIDMap.get( aUsage.Related_Account_SID__c );
			//System.assertNotEquals( NULL, relatedSID, 'The Usages created should all have been associated to an Account SID' );
			//System.assertEquals( relatedSID.Account_SID__c, aUsage.AccountSid__c, 'The associated AccountSID should have the same key' );
			//System.assertEquals( relatedSID.Account__c, aUsage.AccountLookup__c, 'The Usage should look up to the Account SIDs Account' );
		}
	}

	static testMethod void testSchedule()
	{
		Test.startTest();

			Id scheduleJobId = System.schedule('Sync Sid - Hourly', '0 0 * * * ?', new BatchLinkAccountSidToTwilioUsage());

		Test.stopTest();

		System.assertNotEquals( NULL, scheduleJobId, 'Job Id is null. It must have value' );

		List<AsyncApexJob> createdJobs = [ SELECT Id, CompletedDate, Status, ExtendedStatus, JobType
											FROM AsyncApexJob
											WHERE CreatedById = :UserInfo.getUserId()
												AND ApexClass.Name = 'BatchLinkAccountSidToTwilioUsage'
												AND Status = 'Queued'
												AND JobType = 'BatchApex' ];
		System.assertEquals( 4, createdJobs.size(), 'There should be 4 instances of the batch created to run' );
	}
}