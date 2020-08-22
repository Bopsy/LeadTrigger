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
private class CustomerSupportTicketBatchTest {

    static Account accForContact;
    static Account accForEmailDomain;
    static Account accForNoMatch;
    static List<Contact> contacts;
    static List<Email_Domain__c> emailDomains;
    static Account_SID__c accSidForContact;
    static Account_SID__c accSidForEmailDomain;
    static Account_SID__c accSidForNoMatch;

    static testmethod void batchTestEmailMatch() {
        setupTestRecords();
        
        Customer_Support_Ticket__c ticketLinkedByContact = new Customer_Support_Ticket__c(
            Submitters_Email__c = contacts[0].Email.toUpperCase(),
            Account_SID__c = accSidForContact.Name
        );        
        Customer_Support_Ticket__c ticketLinkedByEmailDomain = new Customer_Support_Ticket__c(
            Submitters_Email__c = 'test@' + emailDomains[0].Name.toUpperCase(),
            Account_SID__c = accSidForEmailDomain.Name
        );
        Customer_Support_Ticket__c ticketNotLinked = new Customer_Support_Ticket__c(
            Submitters_Email__c = 'test@nolinking.com'.toUpperCase(),
            Account_SID__c = accSidForNoMatch.Name
        );
        System.debug('ticketLinkedByContact: ' + ticketLinkedByContact);
        System.debug('ticketLinkedByEmailDomain: ' + ticketLinkedByEmailDomain);
        System.debug('ticketNotLinked: ' + ticketNotLinked);
        insert new List<Customer_Support_Ticket__c> { ticketLinkedByContact, ticketLinkedByEmailDomain, ticketNotLinked };

        Test.startTest();
        CustomerSupportTicketBatch batch = new CustomerSupportTicketBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Map<Id, Customer_Support_Ticket__c> c = new Map<Id, Customer_Support_Ticket__c>([
            SELECT Id, Account__c, Submitters_Email__c, Account_SID_lookup__c FROM Customer_Support_Ticket__c
        ]);
        
        System.assertEquals(accForContact.Id, c.get(ticketLinkedByContact.Id).Account__c);
        System.assertEquals(accForEmailDomain.Id, c.get(ticketLinkedByEmailDomain.Id).Account__c);
        System.assertEquals(null, c.get(ticketNotLinked.Id).Account__c);

        System.assertEquals(accSidForContact.Id, c.get(ticketLinkedByContact.Id).Account_SID_lookup__c);
        System.assertEquals(accSidForEmailDomain.Id, c.get(ticketLinkedByEmailDomain.Id).Account_SID_lookup__c);
        System.assertEquals(accSidForNoMatch.Id, c.get(ticketNotLinked.Id).Account_SID_lookup__c);
    }

    // CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    static testMethod void scheduleTest() {
        setupTestRecords();
        Test.startTest();

        // Schedule the test job
        String jobId = System.schedule('CustomerSupportTicketBatchTest',
                        CRON_EXP,
                        new CustomerSupportTicketBatch());

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
        accForContact = new Account(Name = 'TestAccountForContact');
        accForEmailDomain = new Account(Name = 'TestAccountForEmailDomain');
        accForNoMatch = new Account(Name = 'TestAccountForNoMatch');
        insert new List<Account> { accForContact, accForEmailDomain, accForNoMatch };

		accSidForContact = new Account_SID__c(
			Name = 'TESTACCOUNTSID1',
			Account_SID__c = 'TESTACCOUNTSID1',
			Account_SID_Status__c = 'ACTIVE',
			Account__c = accForContact.Id,
			Account_SID_Created_Date__c = Date.today()
		);
		accSidForEmailDomain = new Account_SID__c(
			Name = 'TESTACCOUNTSID2',
			Account_SID__c = 'TESTACCOUNTSID2',
			Account_SID_Status__c = 'ACTIVE',
			Account__c = accForEmailDomain.Id,
			Account_SID_Created_Date__c = Date.today()
		);
		accSidForNoMatch = new Account_SID__c(
			Name = 'TESTACCOUNTSID3',
			Account_SID__c = 'TESTACCOUNTSID3',
			Account_SID_Status__c = 'ACTIVE',
			Account__c = accForNoMatch.Id,
			Account_SID_Created_Date__c = Date.today()
		);
		insert new List<Account_SID__c> { accSidForContact, accSidForEmailDomain, accSidForNoMatch };

        contacts = new List<Contact> {
            new Contact(AccountId = accForContact.Id, LastName = 'TestContact1', Email = 'test@forcontact.com'),
            new Contact(AccountId = accForNoMatch.Id, LastName = 'TestContact2', Email = 'test@nomatch.com')
        };

        insert contacts;

        emailDomains = new List<Email_Domain__c> {
            new Email_Domain__c(Name = 'foremaildomain.com', Account__c = accForEmailDomain.Id),
            new Email_Domain__c(Name = 'notmatch.com', Account__c = accForEmailDomain.Id)
        };
        
        insert emailDomains;

    }
}