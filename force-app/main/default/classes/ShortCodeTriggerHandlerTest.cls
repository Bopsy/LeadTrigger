@isTest
private class ShortCodeTriggerHandlerTest {

    static testMethod void clearShortCodeOnOpportunityTest() {

    Account acc = new Account(Name = 'TestAcct');
    insert acc;

    List<Short_Code__c> shortCodeList = new List<Short_Code__c>();
    for (Integer i = 0; i<2; i++) {
      shortCodeList.add(new Short_Code__c(
        Account_SID__c = 'TESTACCOUNTSID' + i,
        Short_Code_App_Sid__c = 'SHORTCODEAPPSID' + i,
        Application_Status__c = 'Not Approved'
      ));
    }
    insert shortCodeList;

    List<Opportunity> oppList = new List<Opportunity>();
    oppList.add(new Opportunity(
      Name = 'TESTOPP-UPDATE',
      AccountId = acc.Id,
      CloseDate = Date.today(),
      StageName = 'Pilot',
      Product__c = 'Client',
      Primary_Competitor__c = 'Agendi',
      Short_Code__c = shortCodeList[0].Id
    ));
    oppList.add(new Opportunity(
      Name = 'TESTOPP-DELETE',
      AccountId = acc.Id,
      CloseDate = Date.today(),
      StageName = 'Pilot',
      Product__c = 'Client',
      Primary_Competitor__c = 'Agendi',
      Short_Code__c = shortCodeList[1].Id
    ));
    insert oppList;
    
    shortCodeList[0].Opportunity__c = oppList[0].Id;
    shortCodeList[1].Opportunity__c = oppList[1].Id;
    update shortCodeList;
    
    Test.startTest();
    shortCodeList[0].Opportunity__c = null;
    update shortCodeList;
    
    delete shortCodeList;
    Test.stopTest();
    }

  static List<User> userList = new List<User>();
  static Opportunity oppty1;
  static Opportunity oppty2;
  static Account account0;
  static Account account1;
  static Account account2;
  static Account account3;
  static Contact contact0;
  static Contact contact1;
  static Contact contact2;
  static Contact contact3;
  static Lead lead1;
  static Short_Code__c noLink;
  static Short_Code__c linkToContact1;
  static Short_Code__c linkToContact2;
  static Short_Code__c linkToLead1;
    static FSR__c mqlNoLink;
    static FSR__c mqlLinkedToContact1;
    static FSR__c mqlLinkedToContact2;
    static FSR__c mqlLinkedToLead1;

    static testMethod void linkShortCodeTest() {
    setupTestRecords();
    
    Test.startTest();

    // Change the Application_Status__c from "Created" to "Pending Twilio"
    noLink.Application_Status__c = 'Pending Twilio';
    linkToContact1.Application_Status__c = 'Pending Twilio';
    linkToContact2.Application_Status__c = 'Pending Twilio';
    linkToLead1.Application_Status__c = 'Pending Twilio';
    List<Short_Code__c> shortCodeList = new List<Short_Code__c>{ noLink, linkToContact1, linkToContact2, linkToLead1 };
    System.debug('SHORT_CODE__C(BEFORE): ' + shortCodeList);
    update shortCodeList;
    
    // Reload the short code records and verify they got linked correctly
    Map<Id,Short_Code__c> shortCodes = new Map<Id,Short_Code__c>([
      SELECT Id, Account__c, Contact__c, Lead__c
      FROM Short_Code__c
      WHERE Id IN :shortCodeList
    ]);
    System.debug('SHORT_CODE__C(AFTER): ' + shortCodes.values());

    // noLink
    Short_Code__c scNoLink = shortCodes.get(noLink.Id);
    
    System.assertEquals(account0.Id, scNoLink.Account__c);
    System.assertEquals(contact0.Id, scNoLink.Contact__c);
    System.assertEquals(null, scNoLink.Lead__c);

    // contact1
    Short_Code__c scContact1 = shortCodes.get(linkToContact1.Id);
    
    System.assertEquals(account1.Id, scContact1.Account__c);
    System.assertEquals(contact1.Id, scContact1.Contact__c);
    System.assertEquals(null, scContact1.Lead__c);

    // contact2
    Short_Code__c scContact2 = shortCodes.get(linkToContact2.Id);
    
    System.assertEquals(account2.Id, scContact2.Account__c);
    System.assertEquals(contact2.Id, scContact2.Contact__c);
    System.assertEquals(null, scContact2.Lead__c);

    // lead1
    //    NOTE:  If the email address matches a Contact too then
    //           Contact will be linked rather than the Lead.
    Short_Code__c scLead1 = shortCodes.get(linkToLead1.Id);
    
    System.assertEquals(null, scLead1.Account__c);
    System.assertEquals(null, scLead1.Contact__c);
    System.assertEquals(lead1.Id, scLead1.Lead__c);

    Test.stopTest();
    }

    static testMethod void setOwnershipShortCodeTest() {
    setupTestRecords();
    
    Test.startTest();

    // Change the Application_Status__c from "Created" to "Pending Twilio"
    noLink.Application_Status__c = 'Pending Twilio';
    linkToContact1.Application_Status__c = 'Pending Twilio';
    linkToContact2.Application_Status__c = 'Pending Twilio';
    linkToLead1.Application_Status__c = 'Pending Twilio';

    // Linked to Contact3
    Short_Code__c linkAlreadyContact3 = new Short_Code__c(
      Short_Code_App_Sid__c = 'ShortCodeTest3',
      OwnerUser_Email_Address__c = 'TestCustomer3@ShortCodeLinkTest.com',
      Application_Status__c = 'Created',
      Contact__c = contact3.Id
    );

    List<Short_Code__c> shortCodeList = new List<Short_Code__c>{ noLink, linkToContact1, linkToContact2, linkToLead1, linkAlreadyContact3 };

    System.debug('SHORT_CODE__C(BEFORE): ' + shortCodeList);

    upsert shortCodeList;
    
    // Reload the short code records and verify they got linked correctly
    Map<Id,Short_Code__c> shortCodes = new Map<Id,Short_Code__c>([
      SELECT Id, Account__c, Contact__c, Lead__c, OwnerId
      FROM Short_Code__c
      WHERE Id IN :shortCodeList
    ]);
    System.debug('SHORT_CODE__C(AFTER): ' + shortCodes.values());
    
    // Load the short code related account records and verify ownership
    List<Id> accountIdList = new List<Id>();
    for (Short_Code__c sc : shortCodes.values()) {
      if (sc.Account__c != null)
        accountIdList.add(sc.Account__c);
    }

    Map<Id,Account> accounts = new Map<Id,Account>([
      SELECT Id, OwnerId
      FROM Account
      WHERE Id IN :accountIdList
    ]);
    System.debug('SHORT_CODE__C(ACCOUNTS): ' + accounts.values());

    // noLink
    Short_Code__c scNoLink = shortCodes.get(noLink.Id);
    Account accNoLink = accounts.get(scNoLink.Account__c);

    System.assertEquals(account0.Id, scNoLink.Account__c);
    System.assertEquals(contact0.Id, scNoLink.Contact__c);
    System.assertEquals(null, scNoLink.Lead__c);
    System.assertEquals(accNoLink.OwnerId, scNoLink.OwnerId);

    // contact1
    Short_Code__c scContact1 = shortCodes.get(linkToContact1.Id);
    Account accContact1 = accounts.get(scContact1.Account__c);

    System.assertEquals(account1.Id, scContact1.Account__c);
    System.assertEquals(contact1.Id, scContact1.Contact__c);
    System.assertEquals(null, scContact1.Lead__c);
    System.assertEquals(accContact1.OwnerId, scContact1.OwnerId);

    // contact2
    Short_Code__c scContact2 = shortCodes.get(linkToContact2.Id);
    Account accContact2 = accounts.get(scContact2.Account__c);

    System.assertEquals(account2.Id, scContact2.Account__c);
    System.assertEquals(contact2.Id, scContact2.Contact__c);
    System.assertEquals(null, scContact2.Lead__c);
    System.assertEquals(accContact2.OwnerId, scContact2.OwnerId);

    Test.stopTest();
    }

    static testMethod void setOwnershipToAccountTest() {
    setupTestRecords();
    
    Test.startTest();

    // Link the Lead and MQL (FSR__c) to the Short Code
    linkToLead1.Lead__c = lead1.Id;
    linkToLead1.MQL__c = mqlLinkedToLead1.Id;
    update linkToLead1;

    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(lead1.Id);      
    lc.setOpportunityName('TEST OPP');   
      LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
      lc.setConvertedStatus(convertStatus.MasterLabel);
    Database.LeadConvertResult lcr = Database.convertLead(lc);  
        
        System.assert(lcr.isSuccess());
        System.assertNotEquals(null, lcr.getOpportunityId());
    System.debug('LEAD_CONVERT_RESULTS(AFTER): ' + lcr);

    Test.stopTest();
    
    // Reload the short code records and verify they got linked correctly
    Short_Code__c shortCode = [
      SELECT Id, Lead__r.IsConverted, Account__c, Contact__c, Opportunity__c, Contact__r.Account.OwnerId, Lead__c, OwnerId
      FROM Short_Code__c
      WHERE Id = :linkToLead1.Id
      LIMIT 1
    ];
    System.debug('SHORT_CODE__C(AFTER): ' + shortCode);
    
    // lead1
    System.assertEquals(true, shortCode.Lead__r.IsConverted);
    //System.assertEquals(lcr.getOpportunityId(), shortCode.Opportunity__c);
    //System.assertEquals(lcr.getAccountId(), shortCode.Account__c);
    //System.assertEquals(lcr.getContactId(), shortCode.Contact__c);
    //System.assertEquals(shortCode.Contact__r.Account.OwnerId, shortCode.OwnerId);
    }

    static testMethod void setOwnershipToOpptyOwnerTest() {
    setupTestRecords();

    // Setup the Opportunity
    insert oppty1;
    
    // Link the Contact, Opportunity, and MQL (FSR__c) to the Short Code
    linkToContact1.Contact__c = contact1.Id;
    linkToContact1.Opportunity__c = oppty1.Id;
    linkToContact1.MQL__c = mqlLinkedToContact1.Id;
    linkToContact1.Application_Status__c = 'Approved';
    linkToContact1.Status__c = 'Waiting for Approval';
    update linkToContact1;

    Test.startTest();

    oppty1.OwnerId = userList[0].Id;
    oppty1.Short_Code__c = linkToContact1.Id;
    update oppty1;

    Test.stopTest();

    // Reload the short code records and verify they got linked correctly
    Short_Code__c shortCode = [
      SELECT Id, OwnerId, Opportunity__r.OwnerId
      FROM Short_Code__c
      WHERE Id = :linkToContact1.Id
      LIMIT 1
    ];
    System.debug('SHORT_CODE__C(AFTER): ' + shortCode);

    System.assertEquals(userList[0].Id, shortCode.Opportunity__r.OwnerId);
    System.assertEquals(userList[0].Id, shortCode.OwnerId);
    }

    static testMethod void batchShortCodeOwnerBackfillTest() {
    setupTestRecords();
    
    // Setup the Opportunities
    oppty1.OwnerId = userList[0].Id;
    oppty1.Short_Code__c = linkToContact1.Id;

    oppty2.OwnerId = userList[1].Id;
    oppty2.Short_Code__c = linkToContact2.Id;

    insert new List<Opportunity> { oppty1, oppty2};

    // Link the Contact, Opportunity, and MQL (FSR__c) to the Short Code
    linkToContact1.Contact__c = contact1.Id;
    linkToContact1.Opportunity__c = oppty1.Id;
    linkToContact1.MQL__c = mqlLinkedToContact1.Id;
    linkToContact1.Application_Status__c = 'Approved';
    linkToContact1.Status__c = 'Waiting for Approval';

    linkToContact2.Contact__c = contact2.Id;
    linkToContact2.Opportunity__c = oppty2.Id;
    linkToContact2.MQL__c = mqlLinkedToContact2.Id;
    linkToContact2.Application_Status__c = 'Created';
    linkToContact2.Status__c = 'Approved';

    update new List<Short_Code__c> { linkToContact1, linkToContact2 };

    // Need to change the Account owner since a trigger on the Short_Code__c probably changed it
    // from what we want it to be for this test
    account2.OwnerId = userList[1].Id;
    update account2;

    Test.startTest();

    Database.executeBatch(new BatchShortCodeOwnerBackfill());

    Test.stopTest();
    
    // Reload the short code records and verify they got linked correctly
    Map<Id,Short_Code__c> shortCodes = new Map<Id,Short_Code__c>([
      SELECT Id, OwnerId, Contact__r.Account.OwnerId, Opportunity__r.OwnerId
      FROM Short_Code__c
      WHERE Id IN (:linkToContact1.Id, :linkToContact2.Id)
    ]);
    System.debug('SHORT_CODE__C(AFTER): ' + shortCodes);
    
    // contact1
    Short_Code__c scContact1 = shortCodes.get(linkToContact1.Id);
    System.assertEquals(userList[0].Id, scContact1.Opportunity__r.OwnerId, 'Opportunity Owner should be same User given when created');
    System.assertEquals(userList[0].Id, scContact1.OwnerId, 'Short Code Owner should be same as Opportunity Owner');

    // contact2
    Short_Code__c scContact2 = shortCodes.get(linkToContact2.Id);
    System.assertEquals(userList[1].Id, scContact2.Contact__r.Account.OwnerId, 'Contact Account Owner should be same User given when created');
    System.assertEquals(userList[1].Id, scContact2.OwnerId, 'Short Code Owner should be same as Contact Account Owner');
    }

   // CRON expression: midnight on March 15.
   // Because this is a test, job executes
   // immediately after Test.stopTest().
   public static String CRON_EXP = '0 0 0 15 3 ? 2022';

   static testmethod void scheduleShortCodeOwnerBackfillTest() {
      setupTestRecords();

      Test.startTest();

      // Schedule the test job
      String jobId = System.schedule('BatchShortCodeOwnerBackfill', CRON_EXP, new BatchShortCodeOwnerBackfill());

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
    
//    Profile p = [ SELECT Id FROM Profile WHERE name = 'Standard User' ];
    Profile p = [ SELECT Id FROM Profile WHERE Name LIKE '%CSM' LIMIT 1 ];
  
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

        account3 = new Account(
            Name = 'TestAccount3',
            BillingCountryCode = countries[0],
            Industry = 'Industry3',
            OwnerId = userList[0].Id
        );

    insert new List<Account>{ account0, account1, account2, account3 };

        // Related to TestAccount0 which does not link to anything
    contact0 = new Contact(
      LastName = 'TestCustomer0',
      AccountId = account0.Id,
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
    
    contact3 = new Contact(
      LastName = 'TestCustomer3',
      AccountId = account3.Id,
      Email = 'TestCustomer3@ShortCodeLinkTest.com'
    );

    insert new List<Contact>{ contact0, contact1, contact2, contact3 };

    // Related to TestAccount1
    String opptyShortCodeRecTypeName = 'Short Code Opportunity';
    RecordTypeInfo shortCodeRecTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(opptyShortCodeRecTypeName);
    
    oppty1 = new Opportunity(
      Name = 'TestOpp1',
      RecordTypeId = shortCodeRecTypeInfo.getRecordTypeId(),
      AccountId = account1.Id,
      CloseDate = Date.today(),
      StageName = 'Pilot',
      FY_16_Use_Case__c = 'UseCase 1',
      Authy_Use_Case__c = 'Call Tracking',
      Product__c = 'Client',
      Primary_Competitor__c = 'Agendi',
      New_Business_Account_SID__c = '01234567890'
    );

    oppty2 = new Opportunity(
      Name = 'TestOpp2',
      RecordTypeId = shortCodeRecTypeInfo.getRecordTypeId(),
      AccountId = account2.Id,
      CloseDate = Date.today(),
      StageName = 'Pilot',
      FY_16_Use_Case__c = 'UseCase 1',
      Authy_Use_Case__c = 'Call Tracking',
      Product__c = 'Client',
      Primary_Competitor__c = 'Agendi',
      New_Business_Account_SID__c = '01234567891'
    );

    lead1 = new Lead(
      LastName = 'ShortCodeTestLead1',
      Email = 'TestCustomerLead1@ShortCodeLinkTest.com',
      Company = 'TestCustomLead1',
      Status = 'Open'
    );
    insert lead1;
        
    // Shouldn't be Linked
    noLink = new Short_Code__c(
      Short_Code_App_Sid__c = 'ShortCodeTest0',
      OwnerUser_Email_Address__c = 'TestCustomer0@ShortCodeLinkTest.com',
      Application_Status__c = 'Created'
    );
    
    // Should Link to Contact1
    linkToContact1 = new Short_Code__c(
      Short_Code_App_Sid__c = 'ShortCodeTest1',
      OwnerUser_Email_Address__c = 'TestCustomer1@ShortCodeLinkTest.com',
      Application_Status__c = 'Created'
    );
    
    // Should Link to Contact2
    linkToContact2 = new Short_Code__c(
      Short_Code_App_Sid__c = 'ShortCodeTest2',
      OwnerUser_Email_Address__c = 'TestCustomer2@ShortCodeLinkTest.com',
      Application_Status__c = 'Created'
    );
    
    // Should Link to Lead3
    linkToLead1 = new Short_Code__c(
      Short_Code_App_Sid__c = 'ShortCodeTestLead1',
      OwnerUser_Email_Address__c = 'TestCustomerLead1@ShortCodeLinkTest.com',
      Application_Status__c = 'Created'
    );
        
    insert new List<Short_Code__c>{ noLink, linkToContact1, linkToContact2, linkToLead1 };

        // FSR__c (MQL)
        mqlNoLink = new FSR__c(Contact__c = contact0.Id);
        mqlLinkedToContact1 = new FSR__c(Contact__c = contact1.Id);
        mqlLinkedToContact2 = new FSR__c(Contact__c = contact2.Id);
        mqlLinkedToLead1 = new FSR__c(Lead__c = lead1.Id);
        
        insert new List<FSR__c>{ mqlNoLink, mqlLinkedToContact1, mqlLinkedToContact2, mqlLinkedToLead1 };

  }
}