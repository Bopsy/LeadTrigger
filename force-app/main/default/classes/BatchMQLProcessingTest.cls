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
private class BatchMQLProcessingTest {

    static List<User> userList = new List<User>();
    static List<Opportunity> opptyList = new List<Opportunity>();
    static Account account0;
    static Account account1;
    static Account account2;
    static Contact contact0;
    static Contact contact1;
    static Contact contact2;
    static Lead lead1;
    static Short_Code__c shortCodeNoLink;
    static Short_Code__c shortCodeLinkedToContact1;
    static Short_Code__c shortCodeLinkedToContact2;
    static Short_Code__c shortCodeLinkedToLead1;
    static FSR__c mqlNoLink;
    static FSR__c mqlLinkedToContact1;
    static FSR__c mqlLinkedToContact2;
    static FSR__c mqlLinkedToLead1;

    @isTest(SeeAllData=true)
    static void requiredCampaignFound() {
    	Test.startTest();
        
        List<Campaign> c = [ SELECT Id FROM Campaign WHERE Name = :BatchMQLProcessing.campaignName ];
        
        Test.stopTest();
        
        System.assertEquals(1, c.size());
    }

    static testMethod void runBatchJob() {
        setupTestRecords();
		List<Short_Code__c> sc = [
            SELECT Id, MQL__c, Contact__c, Lead__c
            FROM Short_Code__c
            WHERE Application_Status__c != 'Rejected'
            AND (Lead__c != null OR Contact__c != null)
            AND MQL__c = null
        ];
        System.debug('SHORT_CODE__C(SETUP): ' + sc);
        
        Test.startTest();

        // Link MQL (FSR__c) to Short_Code__c via Contact__c or Lead__c
        Database.executeBatch(new BatchMQLProcessing());

        Test.stopTest();
        
        // Add the Short_Code__c records to a list for easy querying
        List<Short_Code__c> shortCodeList = new List<Short_Code__c>{ shortCodeNoLink, shortCodeLinkedToContact1, shortCodeLinkedToContact2, shortCodeLinkedToLead1 };
        System.debug('SHORT_CODE__C(BEFORE): ' + shortCodeList);
        
        // Reload the short code records and verify they got linked correctly
        Map<Id,Short_Code__c> shortCodes = new Map<Id,Short_Code__c>([
            SELECT Id, MQL__c, Contact__c, Lead__c
            FROM Short_Code__c
            WHERE Id IN :shortCodeList
        ]);
        System.debug('SHORT_CODE__C(AFTER): ' + shortCodes.values());

        System.assertEquals(null, shortCodes.get(shortCodeNoLink.Id).MQL__c, 'No MQL to link to Short Code');
        System.assertEquals(mqlLinkedToContact1.Id, shortCodes.get(shortCodeLinkedToContact1.Id).MQL__c, 'MQL to link to Short Code by Contact');
        System.assertEquals(mqlLinkedToContact2.Id, shortCodes.get(shortCodeLinkedToContact2.Id).MQL__c, 'MQL to link to Short Code by Contact');
        System.assertEquals(mqlLinkedToLead1.Id, shortCodes.get(shortCodeLinkedToLead1.Id).MQL__c, 'MQL to link to Short Code by Lead');

    }

   // CRON expression: midnight on March 15.
   // Because this is a test, job executes
   // immediately after Test.stopTest().
   public static String CRON_EXP = '0 0 0 15 3 ? 2022';

   static testmethod void scheduleBatchJob() {
      setupTestRecords();

      Test.startTest();

      // Schedule the test job
      String jobId = System.schedule('BatchShortCodeProcessingScheduler', CRON_EXP, new BatchMQLProcessing());

      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId ];

      // Verify the expressions are the same
      System.assertEquals(CRON_EXP, ct.CronExpression);

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

        // Account that does not link to anything
        account0 = new Account(
            Name = 'TestAccount0',
            BillingCountryCode = countries[0],
            Industry = 'Industry0',
            OwnerId = userList[0].Id
        );

        // AM Account
        account1 = new Account(
            Name = 'TestAccount1',
            BillingCountryCode = countries[0],
            Industry = 'Industry1',
            OwnerId = userList[0].Id
        );

        // CSM Account
        account2 = new Account(
            Name = 'TestAccount2',
            BillingCountryCode = countries[1],
            Industry = 'Industry2',
            OwnerId = userList[1].Id
        );
        insert new List<Account>{ account0, account1, account2 };

        // Related to TestAccount0 which does not link to anything
        contact0 = new Contact(
            LastName = 'TestCustomer0',
            AccountId = account1.Id,
            Email = 'TestCustomer0@ShortCodeLinkTest.com'
        );
        
        // Role Team should be 'AM' and will be related to TestAccount1
        contact1 = new Contact(
            LastName = 'TestCustomer1',
            AccountId = account1.Id,
            Email = 'TestCustomer1@ShortCodeLinkTest.com'
        );
        
        // Role Team should be 'CSM' and will be related to TestAccount2
        contact2 = new Contact(
            LastName = 'TestCustomer2',
            AccountId = account2.Id,
            Email = 'TestCustomer2@ShortCodeLinkTest.com'
        );
        insert new List<Contact>{ contact0, contact1, contact2 };

        // Related to TestAccount1
        String opptyShortCodeRecTypeName = 'Short Code Opportunity';
        RecordTypeInfo shortCodeRecTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(opptyShortCodeRecTypeName);
        
        opptyList.add(new Opportunity(
            Name = 'TestOpp',
            RecordTypeId = shortCodeRecTypeInfo.getRecordTypeId(),
            AccountId = account1.Id,
            CloseDate = Date.today(),
            StageName = 'Pilot',
            FY_16_Use_Case__c = 'UseCase 1',
            Authy_Use_Case__c = 'Call Tracking',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi',
            New_Business_Account_SID__c = '01234567890'
        ));
        insert opptyList;
        
        lead1 = new Lead(
            LastName = 'ShortCodeTest3',
            Email = 'TestCustomer3@ShortCodeLinkTest.com',
            Company = 'TestCustom3',
            Status = 'Open'
        );
        insert lead1;
                
		// Add CampaignMembers
		Campaign c = new Campaign(Name = BatchMQLProcessing.campaignName, Type = 'Test Type');
		insert c;

		insert new List<CampaignMember>{
			new CampaignMember(CampaignId = c.Id, Status = 'Sent', ContactId = contact0.Id),
			new CampaignMember(CampaignId = c.Id, Status = 'Sent', ContactId = contact1.Id),
			new CampaignMember(CampaignId = c.Id, Status = 'Sent', ContactId = contact2.Id),
			new CampaignMember(CampaignId = c.Id, Status = 'Sent', LeadId = lead1.Id)
		};

        // Created FSR__c (MQL) before Short_Code__c so batch job can link
        mqlNoLink = new FSR__c(Contact__c = contact0.Id);
        mqlLinkedToContact1 = new FSR__c(Contact__c = contact1.Id);
        mqlLinkedToContact2 = new FSR__c(Contact__c = contact2.Id);
        mqlLinkedToLead1 = new FSR__c(Lead__c = lead1.Id);
        
        insert new List<FSR__c>{ mqlNoLink, mqlLinkedToContact1, mqlLinkedToContact2, mqlLinkedToLead1 };

        // Shouldn't be Linked
        shortCodeNoLink = new Short_Code__c(
            Short_Code_App_Sid__c = 'ShortCodeTest0',
            OwnerUser_Email_Address__c = 'TestCustomer0@ShortCodeLinkTest.com',
            Application_Status__c = 'Pending Twilio'
        );
        
        // Should Link to Contact1
        shortCodeLinkedToContact1 = new Short_Code__c(
            Short_Code_App_Sid__c = 'ShortCodeTest1',
            OwnerUser_Email_Address__c = 'TestCustomer1@ShortCodeLinkTest.com',
            Application_Status__c = 'Pending Twilio',
            Contact__c = contact1.Id
        );
        
        // Should Link to Contact2
        shortCodeLinkedToContact2 = new Short_Code__c(
            Short_Code_App_Sid__c = 'ShortCodeTest2',
            OwnerUser_Email_Address__c = 'TestCustomer2@ShortCodeLinkTest.com',
            Application_Status__c = 'Pending Twilio',
            Contact__c = contact2.Id
        );
        
        // Should Link to Lead1
        shortCodeLinkedToLead1 = new Short_Code__c(
            Short_Code_App_Sid__c = 'ShortCodeTest3',
            OwnerUser_Email_Address__c = 'TestCustomer3@ShortCodeLinkTest.com',
            Application_Status__c = 'Pending Twilio',
            Lead__c = lead1.Id
        );
                
        insert new List<Short_Code__c>{ shortCodeNoLink, shortCodeLinkedToContact1, shortCodeLinkedToContact2, shortCodeLinkedToLead1 };
    }
}