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
private class CountryPhoneNumTypeBatchTest {

    static User includedUser;
    static User excludedUser;

    static List<Opportunity_Country_Number__c> includedCountryPhoneNumberTypes;
    static List<Opportunity_Country_Number__c> excludedCountryPhoneNumberTypes;

    static Account acc;
    static List<Contact> contacts;
    static List<Lead> leads;
    
    static List<FSR__c> mqls; 
    static List<Use_Case_Interest__c> ucis;

    static testmethod void batchTestEmailMatch() {
        setupTestRecords();
        Test.startTest();
        CountryPhoneNumTypeBatch batch = new CountryPhoneNumTypeBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        for (Opportunity_Country_Number__c c : [ SELECT Id, Contact__c, Lead__c, MQL__c, Use_Case_Interest__C FROM Opportunity_Country_Number__c ]) {
            if (includedCountryPhoneNumberTypes[0].Id == c.Id) {
                System.assertEquals(contacts[0].Id, c.Contact__c);
                System.assertEquals(null, c.Lead__c);
                //System.assertEquals(mqls[0].Id, c.MQL__c);
//              System.assertEquals(ucis[0].Id, c.Use_Case_Interest__c);
            } else if (includedCountryPhoneNumberTypes[1].Id == c.Id) {
                System.assertEquals(null, c.Contact__c);
                System.assertEquals(leads[0].Id, c.Lead__c);
                //System.assertEquals(mqls[1].Id, c.MQL__c);
//              System.assertEquals(ucis[1].Id, c.Use_Case_Interest__c);
            } else if (excludedCountryPhoneNumberTypes[0].Id == c.Id) {
                System.assertEquals(null, c.Contact__c);
                System.assertEquals(null, c.Lead__c);
                //System.assertEquals(null, c.MQL__c);
//              System.assertEquals(null, c.Use_Case_Interest__c);
            } else if (excludedCountryPhoneNumberTypes[1].Id == c.Id) {
                System.assertEquals(null, c.Contact__c);
                System.assertEquals(null, c.Lead__c);
                //System.assertEquals(null, c.MQL__c);
//              System.assertEquals(null, c.Use_Case_Interest__c);
            }
        }
    }

    static testmethod void batchTestRelatedToContactLead() {
        setupTestRecords();

        includedCountryPhoneNumberTypes[0].Contact__c = contacts[0].Id;
        includedCountryPhoneNumberTypes[1].Lead__c = leads[0].Id;
        update includedCountryPhoneNumberTypes;

        excludedCountryPhoneNumberTypes[0].Contact__c = contacts[0].Id;
        excludedCountryPhoneNumberTypes[1].Lead__c = leads[0].Id;
        update excludedCountryPhoneNumberTypes;
        
        Test.startTest();
        CountryPhoneNumTypeBatch batch = new CountryPhoneNumTypeBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        for (Opportunity_Country_Number__c c : [ SELECT Id, Contact__c, Lead__c, MQL__c, Use_Case_Interest__C FROM Opportunity_Country_Number__c ]) {
            if (includedCountryPhoneNumberTypes[0].Id == c.Id) {
                System.assertEquals(contacts[0].Id, c.Contact__c);
                System.assertEquals(null, c.Lead__c);
                //System.assertEquals(mqls[0].Id, c.MQL__c);
                //System.assertEquals(ucis[0].Id, c.Use_Case_Interest__c);
            } else if (includedCountryPhoneNumberTypes[1].Id == c.Id) {
                System.assertEquals(null, c.Contact__c);
                System.assertEquals(leads[0].Id, c.Lead__c);
                //System.assertEquals(mqls[1].Id, c.MQL__c);
                //System.assertEquals(ucis[1].Id, c.Use_Case_Interest__c);
            } else if (excludedCountryPhoneNumberTypes[0].Id == c.Id) {
                System.assertEquals(contacts[0].Id, c.Contact__c);
                System.assertEquals(null, c.Lead__c);
                //System.assertEquals(null, c.MQL__c);
                //System.assertEquals(null, c.Use_Case_Interest__c);
            } else if (excludedCountryPhoneNumberTypes[1].Id == c.Id) {
                System.assertEquals(null, c.Contact__c);
                System.assertEquals(leads[0].Id, c.Lead__c);
                //System.assertEquals(null, c.MQL__c);
                //System.assertEquals(null, c.Use_Case_Interest__c);
            }
        }
    }

    // CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    static testMethod void scheduleTest() {
        setupTestRecords();
        Test.startTest();

        // Schedule the test job
        String jobId = System.schedule('CountryPhoneNumTypeBatchTest',
                        CRON_EXP,
                        new CountryPhoneNumTypeBatch());

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
        // Create users to be included and excluded by the CreatedBy filter
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];

        includedUser = new User();
        includedUser.ProfileId = profile1.Id;
        includedUser.Username = System.now().getTime() + System.now().millisecond() + 'testtwilioinclude@test.com';
        includedUser.Alias = 'include';
        includedUser.Email='testIncludedUser@test.com';
        includedUser.EmailEncodingKey='UTF-8';
        includedUser.Firstname='Test';
        includedUser.Lastname='Test';
        includedUser.LanguageLocaleKey='en_US';
        includedUser.LocaleSidKey='en_US';
        includedUser.TimeZoneSidKey='America/Chicago';

        excludedUser = new User();
        excludedUser.ProfileId = profile1.Id;
        excludedUser.Username = System.now().getTime() + System.now().millisecond() + 'testtwilioexclude@test.com';
        excludedUser.Alias = 'exclude';
        excludedUser.Email='testExcludedUser@test.com';
        excludedUser.EmailEncodingKey='UTF-8';
        excludedUser.Firstname='Test';
        excludedUser.Lastname='Test';
        excludedUser.LanguageLocaleKey='en_US';
        excludedUser.LocaleSidKey='en_US';
        excludedUser.TimeZoneSidKey='America/Chicago';

        insert new List<User> { includedUser, excludedUser };
        
        // Add the includedUser's ID to the filter      
        CountryPhoneNumTypeHandler.includedCreatedByUserIds = new Set<Id> { includedUser.Id };

        acc = new Account(Name = 'TestAcct');
        insert acc;

        contacts = new List<Contact> {
            new Contact(AccountId = acc.Id, LastName = 'TestContact1', Email = 'test@contact1.com'),
            new Contact(AccountId = acc.Id, LastName = 'TestContact2', Email = 'test@contact2.com'),
            new Contact(AccountId = acc.Id, LastName = 'TestContact3', Email = 'test@contact3.com')
        };
        
        leads = new List<Lead> {
            new Lead(Company = 'TestLead1', LastName = 'TestLead1', Email = 'test@lead1.com'),
            new Lead(Company = 'TestLead2', LastName = 'TestLead2', Email = 'test@lead2.com'),
            new Lead(Company = 'TestLead3', LastName = 'TestLead3', Email = 'test@lead3.com')
        };

        List<Schema.PicklistEntry> regionPicklist = Country__c.Region__c.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> capabilityPicklist = Country_Phone_Number_Type__c.Capability__c.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> typePicklist = Country_Phone_Number_Type__c.Type__c.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> statusPicklist = Country_Phone_Number_Type__c.Status__c.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> nextStatusPicklist = Country_Phone_Number_Type__c.Next_Status__c.getDescribe().getPicklistValues();

        // NOTE:  The Opportunity_Country_Number__c's Unique_Name__c field is populated by a
        //        workflow that uses a combination of Country__r.Name, Type__c, and Capability__c,
        //        therefore, a series of unique country names are created to prevent a duplicate
        //        value exception.

        List<Country__c> countries = new List<Country__c>();
        for (Integer i = 0; i < 10; i++) {
            countries.add(new Country__c(
                Name = EncodingUtil.convertToHex(Crypto.generateAesKey(128)),
                CountryName__c = 'United States',
                Region__c = regionPicklist[Math.mod(i, regionPickList.size())].getLabel())
            );
        }
        insert countries;

        Integer i = 0;
        Country_Phone_Number_Type__c testType = new Country_Phone_Number_Type__c(Name = 'Davis Test', Status__c = 'Preview');
        insert testType;
        System.runAs ( includedUser ) {
            includedCountryPhoneNumberTypes = new List<Opportunity_Country_Number__c> {
                new Opportunity_Country_Number__c(
                    Customer_Email__c = contacts[0].Email,
                    //Country__c = countries[i++].Id,
                    Capability_Input__c = capabilityPicklist[0].getLabel(),
                    Type_Input__c = typePicklist[0].getLabel(),
                    Country_Number_Type__c = testType.Id
                    //Status_Input__c = statusPicklist[0].getLabel()
                    //Next_Status__c = nextStatusPicklist[0].getLabel()
                ),
                new Opportunity_Country_Number__c(
                    Customer_Email__c = leads[0].Email,
                    //Country__c = countries[i++].Id,
                    Capability_Input__c = capabilityPicklist[0].getLabel(),
                    Type_Input__c = typePicklist[0].getLabel(),
                    Country_Number_Type__c = testType.Id
                    //Status__c = statusPicklist[0].getLabel(),
                    //Next_Status__c = nextStatusPicklist[0].getLabel()
                ),
                new Opportunity_Country_Number__c(
                    Customer_Email__c = contacts[2].Email,
                    //Country__c = countries[i++].Id,
                    Capability_Input__c = capabilityPicklist[0].getLabel(),
                    Type_Input__c = typePicklist[0].getLabel(),
                    Country_Number_Type__c = testType.Id
                    //Status__c = statusPicklist[0].getLabel(),
                    //Next_Status__c = nextStatusPicklist[0].getLabel()
                )
            };
            insert includedCountryPhoneNumberTypes;
        }

        System.runAs ( excludedUser ) {
            excludedCountryPhoneNumberTypes = new List<Opportunity_Country_Number__c> {
                new Opportunity_Country_Number__c(
                    Customer_Email__c = contacts[1].Email,
                    //Country__c = countries[i++].Id,
                    Capability_Input__c = capabilityPicklist[0].getLabel(),
                    Type_Input__c = typePicklist[0].getLabel(),
                    Country_Number_Type__c = testType.Id
                    //Status__c = statusPicklist[0].getLabel(),
                    //Next_Status__c = nextStatusPicklist[0].getLabel()
                ),
                new Opportunity_Country_Number__c(
                    Customer_Email__c = leads[1].Email,
                    //Country__c = countries[i++].Id,
                    Capability_Input__c = capabilityPicklist[0].getLabel(),
                    Type_Input__c = typePicklist[0].getLabel(),
                    Country_Number_Type__c = testType.Id
                    //Status__c = statusPicklist[0].getLabel(),
                    //Next_Status__c = nextStatusPicklist[0].getLabel()
                ),
                new Opportunity_Country_Number__c(
                    Customer_Email__c = leads[2].Email,
                    //Country__c = countries[i++].Id,
                    Capability_Input__c = capabilityPicklist[0].getLabel(),
                    Type_Input__c = typePicklist[0].getLabel(),
                    Country_Number_Type__c = testType.Id
                    //Status__c = statusPicklist[0].getLabel(),
                    //Next_Status__c = nextStatusPicklist[0].getLabel()
                )
            };
            insert excludedCountryPhoneNumberTypes;
        }

        // Must insert Opportunity_Country_Number__c records before the Contacts and the Leads
        // to avoid the trigger processoring them if it is active
        insert contacts;
        insert leads;

        mqls = new List<FSR__c> {
            new FSR__c(Contact__c = contacts[0].id),
            new FSR__c(Lead__c = leads[0].Id),
            new FSR__c(Contact__c = contacts[1].id),
            new FSR__c(Lead__c = leads[1].Id),
            new FSR__c(Contact__c = contacts[2].id)
        };
        insert mqls;

        ucis = new List<Use_Case_Interest__c> {
            new Use_Case_Interest__c(Contact__c = contacts[0].Id, MQL__c = mqls[0].Id),
            new Use_Case_Interest__c(Lead__c = leads[0].Id, MQL__c = mqls[1].Id),
            new Use_Case_Interest__c(Contact__c = contacts[1].Id, MQL__c = mqls[2].Id),
            new Use_Case_Interest__c(Lead__c = leads[1].Id, MQL__c = mqls[3].Id),
            new Use_Case_Interest__c(Contact__c = contacts[2].Id, MQL__c = mqls[4].Id)
        };
        insert ucis;
        
        // Only need to link UCI since Contact and MQL are already linked.
        update new Opportunity_Country_Number__c(
            Id = includedCountryPhoneNumberTypes[2].Id,
            Customer_Email__c = contacts[2].Email,
            Contact__c = contacts[2].Id,
            MQL__c = mqls[4].Id
        );
    }
}