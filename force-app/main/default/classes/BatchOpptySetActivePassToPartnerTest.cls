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
private class BatchOpptySetActivePassToPartnerTest {

    // CRON expression: midnight on March 15. 
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    static Integer recordMax = 10;
        
    static Opportunity testOpp;
    static List<Account> accountList;
    static List<Contact> contactList;
    static List<User> userList;
    static List<Pass_To_Partner__c> passToPartnerList;

    static testMethod void batchTest() {
        setupTestRecords();
        
        Test.startTest();
        Database.executeBatch(new BatchOpptySetActivePassToPartner());
        Test.stopTest();
    }


    static testMethod void scheduleTest() {
        setupTestRecords();
        Test.startTest();
        PassToPartnerTriggerHandler.getPassToPartnerFieldString('StageName');
        
        // Schedule the test job 
        String jobId = System.schedule('BatchOpptySetActivePassToPartner',
                        CRON_EXP, 
                        new BatchOpptySetActivePassToPartner());
        
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
        Opportunity_to_PTP_Mappings__c setting = new Opportunity_to_PTP_Mappings__c();
        setting.Name = 'BDR_Notes__c';
        setting.PTP_API_Name__c = 'BDR_Notes__c';
        setting.Opportunity_API_Name__c = 'BDR_Notes__c';
        insert setting;
            
        accountList = new List<Account>();
        for (Integer i = 0; i < recordMax; i++) {
            accountList.add(new Account(
                Name = 'TESTACCOUNT' + i,
                //Partner_Account_Level__c = 'Tier 1',
                Partner_ID__c = 'ABC000' + i
            ));
        }
        insert accountList;

        contactList = new List<Contact>();
        for (Integer i = 0; i < recordMax; i++) {
            contactList.add(new Contact(
                LastName = 'TESTCONTACT' + i,
                AccountID = accountList[i].Id
            ));
        }
        insert contactList;

        Profile p = [Select ID, Name from Profile Where Name = '**Partner Community DREG & PTP'];
        userList = new List<User>();
        for (Integer i = 0; i < recordMax; i++) {
            String email = 'test_' + i + '@test-' + math.random() + '.com';
            userList.add(new User(
                UserName = email,
                FirstName = 'TEST-FIRST' + i,
                LastName = 'TEST-LAST' + i,
                Alias = 'test',
                Email = email,
                CommunityNickName = 'T' + i + string.valueOf(math.random()).substring(0,4),
                ProfileID = p.id,
                TimeZoneSidKey = 'America/New_York', 
                LocaleSidKey = 'en_US', 
                EmailEncodingKey = 'UTF-8', 
                LanguageLocaleKey = 'en_US',
                ContactId = contactList[i].Id
            ));
        }
        insert userList;

        // Query the created users to get the Partner_ID__c that was auto-generated.
        List<Id> ids = new List<Id>();
        for (User u : userList) { ids.add(u.Id); }
        List<User> userPartnerList = [ SELECT Id, Partner_ID__c FROM User WHERE Id IN :ids ];

        testOpp = new Opportunity(
            Name = 'TestOpp',
            AccountId = accountList[0].Id,
            CloseDate = Date.today(),
            StageName = 'Pilot',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        );
        insert testOpp;
        
        List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
        opportunityContactRoles.add(new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = contactList[0].Id
        ));
        insert opportunityContactRoles;
        
        // Updated the accounts with the Partner ID auto-generated on the User record.
        for (Integer i = 0; i < recordMax; i++) {
            accountList[i].Partner_ID__c = userPartnerList[i].Partner_ID__c;
        }
        update accountList;
        
        List<PartnerPortalMappings__c> partnerPortalMappings = new List<PartnerPortalMappings__c>();
        for (Integer i = 0; i < recordMax; i++) {
            partnerPortalMappings.add(new PartnerPortalMappings__c(
                Name = 'PPM-' + i,
                Account_ID__c = accountList[i].Id,
                User_ID__c = userList[i].Id,
                Partner_ID__c = userPartnerList[i].Partner_ID__c
            ));
            System.debug('PartnerPortalMappings__c(Name=' + partnerPortalMappings[i].Name
                + ', AccountID=' + partnerPortalMappings[i].Account_ID__c 
                + ', UserID=' + partnerPortalMappings[i].User_ID__c 
                + ', PartnerID=' + partnerPortalMappings[i].Partner_ID__c + ')');
        }
        insert partnerPortalMappings;
        
        passToPartnerList = new List<Pass_To_Partner__c>();
        passToPartnerList.add(new Pass_To_Partner__c(
            Opportunity__c = testOpp.Id,
            Partner_Status__c = 'Open',
            Contact__c = contactList[0].Id,
            FY_16_Primary_Product_Input__c = 'Support',
            FY_16_Use_Case_Input__c = 'SIP Trunking',
            Use_Case_Category_Input__c = 'SIP Trunking'
        ));
        passToPartnerList.add(new Pass_To_Partner__c(
            Opportunity__c = testOpp.Id,
            Partner_Status__c = 'Declined',
            Contact__c = contactList[0].Id,
            FY_16_Primary_Product_Input__c = 'Support',
            FY_16_Use_Case_Input__c = 'SIP Trunking',
            Use_Case_Category_Input__c = 'SIP Trunking'
        ));
        passToPartnerList.add(new Pass_To_Partner__c(
            Opportunity__c = testOpp.Id,
            Partner_Status__c = 'Closed - Lost',
            Contact__c = contactList[0].Id,
            FY_16_Primary_Product_Input__c = 'Support',
            FY_16_Use_Case_Input__c = 'SIP Trunking',
            Use_Case_Category_Input__c = 'SIP Trunking'
        ));
        insert passToPartnerList;
    }
}