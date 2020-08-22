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

// Due to a possible bug in SFDC custom CampaignMemberStatus records
// are not accessible when "@isTest(seeAllData=false).  However, an
// attempt to create the custom records with the same label in the test
// methods will result in a DUPLICATE_VALUE exception.  Therefore, the
// "@isTest(seeAllData=true)" must be used.
@isTest
private class CampaignMemberTriggerHandlerTest {

  @isTest(seeAllData=true)
  static void CampaignMemberInsertSuccess() {
    Profile p = [Select Id from Profile where name = 'Standard User'];
    Profile ap = [Select Id from Profile where name = 'System Administrator'];

    User u = new User();
    u.ProfileId = p.Id;
    u.Username = System.now().getTime() + 'test@test.com';
    u.Alias = 'testtest';
    u.Email='test@test-lead-autoconvert-12345.com';
    u.EmailEncodingKey='UTF-8';
    u.Firstname='Test';
    u.Lastname='Test';
    u.LanguageLocaleKey='en_US';
    u.LocaleSidKey='en_US';
    u.TimeZoneSidKey='America/Chicago';
    insert u;

    //
    // Changed run as user to be the existing "Sales Operations" user so it would be exempted
    // from the following Lead validation rules:
    //
    //    Consolidated_Last_Lead_Source_Edit_Rules
    //    Consolidation_of_LeadSource_Edit_Rules
    //    Partner_Pass_No_SQL_required_fields
    //
    User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];
    /*
        User au = new User();
        au.ProfileId = ap.Id;
        au.Username = System.now().getTime() + 'eloqua@test.com';
        au.Alias = 'eloqua';
        au.Email='eloqua@test-12345.com';
        au.EmailEncodingKey='UTF-8';
        au.Firstname='Eloqua';
        au.Lastname='Marketing';
        au.LanguageLocaleKey='en_US';
        au.LocaleSidKey='en_US';
        au.TimeZoneSidKey='America/Chicago';
        insert au;
    */

    System.RunAs(au) {
      Account a = new Account(
        Name = 'Test Account',
        OwnerId = u.Id,
        Employee_Size__c = '0 - 50',
        Website = 'http://www.checkboxtest.com'
      );
      insert a;

      List<Lead> leads = new List<Lead>();
      leads.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@checkboxtest.comm',
        LeadSource = 'Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));
      leads.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@checkboxtest.com',
        LeadSource = 'Not Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));

      // No match
      leads.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@test-lead-autoconvert-67890.com',
        LeadSource = 'Not Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));
      insert leads;

      Campaign campaign = new Campaign(Name = 'testcampaign', Type = 'Full Service Request');
      insert campaign;

      CampaignMember_Eloqua_AutoConvert_Now__c cms = new CampaignMember_Eloqua_AutoConvert_Now__c(Name = 'testcampaign', Campaign_ID__c = campaign.Id);
      insert cms;

      List<CampaignMember> member = new List<CampaignMember>();
      Integer counter = -10;
      for (Lead lead : leads) {
        member.add(new CampaignMember(
          CampaignId = campaign.id,
          LeadId = lead.id,
          Status = 'Registered',
          Eloqua_Campaign_Association_Done__c = true,
          Campaign_Member_Updated_Date__c = DateTime.now().addMinutes(counter)
        ));
        counter++;
      }

      CampaignMember_to_FSR_Mapping__c cmfsr = new CampaignMember_to_FSR_Mapping__c(
      Name = 'Campaign Member Updated Date',
      FSR_Field__c = 'Date_Submitted__c',
      CampaignMember_Field__c = 'Campaign_Member_Updated_Date__c'
      );
      insert cmfsr;

      insert member;
    }

    Test.startTest();
    Database.executeBatch(new CampaignMemberAutoConvert(), 50);
    Test.stopTest();
  }

  @isTest(seeAllData=true)
  static void CampaignMemberUpdateSuccess() {
    Profile p = [Select Id from Profile where name = 'Standard User'];
    Profile ap = [Select Id from Profile where name = 'System Administrator'];

    User u = new User();
    u.ProfileId = p.Id;
    u.Username = System.now().getTime() + 'test@test.com';
    u.Alias = 'testtest';
    u.Email='test@test-lead-autoconvert-12345.com';
    u.EmailEncodingKey='UTF-8';
    u.Firstname='Test';
    u.Lastname='Test';
    u.LanguageLocaleKey='en_US';
    u.LocaleSidKey='en_US';
    u.TimeZoneSidKey='America/Chicago';
    insert u;

    //
    // Changed run as user to be the existing "Sales Operations" user so it would be exempted
    // from the following Lead validation rules:
    //
    //    Consolidated_Last_Lead_Source_Edit_Rules
    //    Consolidation_of_LeadSource_Edit_Rules
    //    Partner_Pass_No_SQL_required_fields
    //
    User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];
    /*
        User au = new User();
        au.ProfileId = ap.Id;
        au.Username = System.now().getTime() + 'eloqua@test.com';
        au.Alias = 'eloqua';
        au.Email='eloqua@test-12345.com';
        au.EmailEncodingKey='UTF-8';
        au.Firstname='Eloqua';
        au.Lastname='Marketing';
        au.LanguageLocaleKey='en_US';
        au.LocaleSidKey='en_US';
        au.TimeZoneSidKey='America/Chicago';
        insert au;
    */

    System.RunAs(au) {
      Account a = new Account(
        Name = 'Test Account',
        OwnerId = u.Id,
        Employee_Size__c = '0 - 50',
        Website = 'http://www.checkboxtest.com'
      );
      insert a;

      List<Lead> l = new List<Lead>();
      l.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@checkboxtest.comm',
        LeadSource = 'Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));
      l.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@checkboxtest.com',
        LeadSource = 'Not Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));

      // No match
      l.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@test-lead-autoconvert-67890.com',
        LeadSource = 'Not Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));
      insert l;

      Campaign c = new Campaign(Name = 'testcampaign', Type = 'Full Service Request');
      insert c;

      CampaignMember_Eloqua_AutoConvert_Now__c cms = new CampaignMember_Eloqua_AutoConvert_Now__c(Name = 'testcampaign', Campaign_ID__c = c.Id);
      insert cms;

      List<CampaignMember> m = new List<CampaignMember>();
      Integer counter = -10;
      for (Lead x : l) {
      m.add(new CampaignMember(
        CampaignId = c.id,
        LeadId = x.id,
        Status = 'Registered',
        Eloqua_Campaign_Association_Done__c = false,
        Campaign_Member_Updated_Date__c = DateTime.now().addMinutes(counter)
      ));
      counter++;
      }
      insert m;
      for (CampaignMember x : m) {
        x.Eloqua_Campaign_Association_Done__c = true;
      }

      CampaignMember_to_FSR_Mapping__c cmfsr = new CampaignMember_to_FSR_Mapping__c(
      Name = 'Campaign Member Updated Date',
      FSR_Field__c = 'Date_Submitted__c',
      CampaignMember_Field__c = 'Campaign_Member_Updated_Date__c'
      );
      insert cmfsr;

      update m;
    }

    Test.startTest();
    Database.executeBatch(new CampaignMemberAutoConvert(), 50);
    Test.stopTest();
  }

  @isTest(seeAllData=true)
  static void CampaignMemberTaskInsertSuccess() {
    Profile p = [Select Id from Profile where name = 'Standard User'];
    Profile ap = [Select Id from Profile where name = 'System Administrator'];

    User u = new User();
    u.ProfileId = p.Id;
    u.Username = System.now().getTime() + 'test@test.com';
    u.Alias = 'testtest';
    u.Email='test@test-lead-autoconvert-12345.com';
    u.EmailEncodingKey='UTF-8';
    u.Firstname='Test';
    u.Lastname='Test';
    u.LanguageLocaleKey='en_US';
    u.LocaleSidKey='en_US';
    u.TimeZoneSidKey='America/Chicago';
    insert u;

    //
    // Changed run as user to be the existing "Sales Operations" user so it would be exempted
    // from the following Lead validation rules:
    //
    //    Consolidated_Last_Lead_Source_Edit_Rules
    //    Consolidation_of_LeadSource_Edit_Rules
    //    Partner_Pass_No_SQL_required_fields
    //
    User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

    System.RunAs(au) {
      Account a = new Account(
        Name = 'Test Account',
        OwnerId = u.Id,
        Employee_Size__c = '0 - 50',
        Website = 'http://www.checkboxtest.com'
      );
      insert a;

      List<Lead> l = new List<Lead>();
      l.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@checkboxtest.comm',
        LeadSource = 'Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));
      l.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@checkboxtest.com',
        LeadSource = 'Not Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));

      // No match
      l.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@test-lead-autoconvert-67890.com',
        LeadSource = 'Not Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));
      insert l;

      Campaign c = new Campaign(
        Name = 'testcampaign',
        Create_Task_for_Opened_Email__c = true,
        Create_Task_for_Clicked_Email__c = true,
        Task_Subject_Line__c = 'Test Subject Line',
        Task_Call_Script__c = 'Test Task Call Script'
      );
      insert c;

      CampaignMember_Eloqua_AutoConvert_Now__c cms = new CampaignMember_Eloqua_AutoConvert_Now__c(Name = 'testcampaign', Campaign_ID__c = c.Id);
      insert cms;

      //        List<CampaignMemberStatus> cms = new List<CampaignMemberStatus>();
      //        cms.add(new CampaignMemberStatus(CampaignId=c.Id, HasResponded=true, Label='Opened Email', SortOrder=2));
      //    cms.add(new CampaignMemberStatus(CampaignId=c.Id, HasResponded=true, Label='Clicked Email', SortOrder=3));
      //    insert cms;

      List<CampaignMember> m = new List<CampaignMember>();
      for (Lead x : l) {
        m.add(new CampaignMember(
          CampaignId = c.id,
          LeadId = x.id,
          Status = 'Clicked Email'
        ));
      }

      Test.startTest();
      insert m;
      Test.stopTest();
    }
  }

  @isTest(seeAllData=true)
  static void CampaignMemberTaskUpdateSuccess() {
    Profile p = [Select Id from Profile where name = 'Standard User'];
    Profile ap = [Select Id from Profile where name = 'System Administrator'];

    User u = new User();
    u.ProfileId = p.Id;
    u.Username = System.now().getTime() + 'test@test.com';
    u.Alias = 'testtest';
    u.Email='test@test-lead-autoconvert-12345.com';
    u.EmailEncodingKey='UTF-8';
    u.Firstname='Test';
    u.Lastname='Test';
    u.LanguageLocaleKey='en_US';
    u.LocaleSidKey='en_US';
    u.TimeZoneSidKey='America/Chicago';
    insert u;

    //
    // Changed run as user to be the existing "Sales Operations" user so it would be exempted
    // from the following Lead validation rules:
    //
    //    Consolidated_Last_Lead_Source_Edit_Rules
    //    Consolidation_of_LeadSource_Edit_Rules
    //    Partner_Pass_No_SQL_required_fields
    //
    User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

    System.RunAs(au) {
      Account a = new Account(
        Name = 'Test Account',
        OwnerId = u.Id,
        Employee_Size__c = '0 - 50',
        Website = 'http://www.checkboxtest.com'
      );
      insert a;

      List<Lead> l = new List<Lead>();
      l.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@checkboxtest.comm',
        LeadSource = 'Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));
      l.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@checkboxtest.com',
        LeadSource = 'Not Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));

      // No match
      l.add(new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Email = 'test12345@test-lead-autoconvert-67890.com',
        LeadSource = 'Not Full Service Request',
        Status = 'Open',
        OwnerId = u.Id
      ));
      insert l;

      Campaign c = new Campaign(
        Name = 'testcampaign',
        Create_Task_for_Opened_Email__c = true,
        Create_Task_for_Clicked_Email__c = true,
        Task_Subject_Line__c = 'Test Subject Line',
        Task_Call_Script__c = 'Test Task Call Script'
      );
      insert c;

      CampaignMember_Eloqua_AutoConvert_Now__c n = new CampaignMember_Eloqua_AutoConvert_Now__c(Name = 'testcampaign', Campaign_ID__c = c.Id);
      insert n;

      // List<CampaignMemberStatus> cms = new List<CampaignMemberStatus>();
      // cms.add(new CampaignMemberStatus(CampaignId=c.Id, HasResponded=true, Label='Opened Email', SortOrder=2));
      // cms.add(new CampaignMemberStatus(CampaignId=c.Id, HasResponded=true, Label='Clicked Email', SortOrder=3));
      // insert cms;

      List<CampaignMember> m = new List<CampaignMember>();
      for (Lead x : l) {
        m.add(new CampaignMember(
          CampaignId = c.id,
          LeadId = x.id,
          Status = 'Registered'
        ));
      }

      insert m;

      Test.startTest();
      for (CampaignMember x : m) {
        x.Status = 'Clicked Email';
      }
      update m;
      Test.stopTest();
    }
  }

  @isTest(seeAllData=false)
  static void testWhitelist_Insert()
  {
    /*Integer testObjectQty = 15;

    User ADMIN_USER = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1 ];
    List<Lead> leads = TestDataFactory.createLeadList(testObjectQty);
    List<Lead> leadsRole = TestDataFactory.createLeadList(testObjectQty);
    List<Campaign> campaigns = TestDataFactory.createCampaignList(testObjectQty);
    for(Integer i = 0; i < testObjectQty; i++)
    {
      campaigns[i].Talk_to_Sales__c = true;
      leads[i].Email = leads[i].LastName + '@test-' + i + '.com';
      leadsRole[i].Email = leadsRole[i].LastName + '@test-role-' + i + '.com';
    }
    insert leads;
    insert leadsRole;
    insert campaigns;

    User testValidOwner = TestDataFactory.createUser();
    UserRole randomRole = [ SELECT Id FROM UserRole LIMIT 1 ];
    User testValidRoleOwner = TestDataFactory.createUser();
    testValidRoleOwner.UserRoleId = randomRole.Id;

    System.runAs(ADMIN_USER)
    {
      insert new List<User>{ testValidOwner, testValidRoleOwner };
    }

    MQL_Creator_Whitelist__c userIdSetting = new MQL_Creator_Whitelist__c();
    userIdSetting.User_or_Role_Id__c = testValidOwner.id;
    userIdSetting.Name = 'Whitelisted User Id';

    MQL_Creator_Whitelist__c userRoleSetting = new MQL_Creator_Whitelist__c();
    userRoleSetting.User_or_Role_Id__c = testValidRoleOwner.UserRoleId;
    userRoleSetting.Name = 'Whitelisted User Role';

    insert new List<MQL_Creator_Whitelist__c>{ userIdSetting, userRoleSetting };

    List<CampaignMember> campaignMembersForUserID = TestDataFactory.createCampaignMemList(testObjectQty);
    List<CampaignMember> campaignMembersForUserRole = TestDataFactory.createCampaignMemList(testObjectQty);
    for (Integer i = 0; i < testObjectQty; i++)
    {
      campaignMembersForUserID[i].LeadId = leads[i].Id;
      campaignMembersForUserRole[i].LeadId = leadsRole[i].Id;
      campaignMembersForUserID[i].CampaignId = campaigns[0].Id;
      campaignMembersForUserRole[i].CampaignId = campaigns[1].Id;
    }

    Test.startTest();

      System.runAs(testValidOwner)
      {
        insert campaignMembersForUserID;
      }

      System.runAs(testValidRoleOwner)
      {
        insert campaignMembersForUserRole;
      }

    Test.stopTest();

    List<FSR__c> mqls = [ SELECT Id, OwnerId, Owner.UserRoleId FROM FSR__c ];
    // Check the quantity of MQL's is as expected
    System.assertEquals(testObjectQty * 2, mqls.size());
    // Check that the MQL's were created by whitelisted users or user roles
    for(FSR__c mql : mqls)
    {
      Boolean idIsWhitelisted = userIdSetting.User_or_Role_Id__c == mql.OwnerId;
      Boolean roleIsWhitelsted = userRoleSetting.User_or_Role_Id__c == mql.Owner.UserRoleId;
      System.assert(idIsWhitelisted || roleIsWhitelsted);
    }*/
  }

  @isTest(seeAllData=false)
  static void testWhitelist_Update()
  {
    // insert trigger might fire already - insert as ourselves, update as whitelisted user
    // same as insert, just update the campaign date changed field to kick off mql creation
    Integer testObjectQty = 15;

    User ADMIN_USER = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1 ];
    List<Lead> leads = TestDataFactory.createLeadList(testObjectQty);
    List<Campaign> campaigns = TestDataFactory.createCampaignList(testObjectQty);
    for(Integer i = 0; i < testObjectQty; i++)
    {
      campaigns[i].Talk_to_Sales__c = true;
      leads[i].Email = leads[i].LastName + '@test-' + i + '.com';
    }
    insert leads;
    insert campaigns;

    User testValidOwner = TestDataFactory.createUser();

    System.runAs(ADMIN_USER)
    {
      insert testValidOwner;
    }

    MQL_Creator_Whitelist__c userIdSetting = new MQL_Creator_Whitelist__c();
    userIdSetting.User_or_Role_Id__c = testValidOwner.id;
    userIdSetting.Name = 'Whitelisted User Id';

    insert userIdSetting;

    List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMemList(testObjectQty);
    for (Integer i = 0; i < testObjectQty; i++)
    {
      campaignMembers[i].LeadId = leads[i].Id;
      campaignMembers[i].CampaignId = campaigns[0].Id;
    }

    insert campaignMembers;

    // No MQL's should be created yet
    List<FSR__c> mqls = [ SELECT Id, OwnerId, Campaign__c, Lead__c FROM FSR__c ];
    System.assertEquals(0, mqls.size());

    for (CampaignMember campaignMember : campaignMembers)
    {
      campaignMember.Campaign_Member_Updated_Date__c = Date.today().addDays(-2);
    }

    Test.startTest();

      System.runAs(testValidOwner)
      {
        update campaignMembers;
      }

    Test.stopTest();

    List<FSR__c> mqlsAfterUpdate = [ SELECT Id, OwnerId, Campaign__c, Lead__c FROM FSR__c ];
    // Check the quantity of MQL's is as expected
    System.assertEquals(testObjectQty, mqlsAfterUpdate.size());
    // Check that the MQL's were created by whitelisted users or user roles
    for(FSR__c mql : mqlsAfterUpdate)
    {
      Boolean idIsWhitelisted = userIdSetting.User_or_Role_Id__c == mql.OwnerId;
      System.assert(idIsWhitelisted);
    }
  }
}