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
private class TwilioZendeskTicketHandlerTest {
    static List<Account> accounts = new List<Account>();
    static List<Email_Domain__c> domains = new List<Email_Domain__c>();

    static testMethod void emailNotSet() {
        setupTestRecords();

        Twilio_Zendesk_Ticket__c t = new Twilio_Zendesk_Ticket__c();
        insert t;
        
        Twilio_Zendesk_Ticket__c q = [
            SELECT Id, Submitter_Email__c, Account__c
            FROM Twilio_Zendesk_Ticket__c
            WHERE Id = :t.Id
            LIMIT 1
        ];
        
        System.assertEquals(null, q.Account__c);
    }

    static testMethod void emailSetAndNoMatches() {
        setupTestRecords();

        Twilio_Zendesk_Ticket__c t = new Twilio_Zendesk_Ticket__c(Submitter_Email__c = 'test@testaccount0.com');
        insert t;
        
        Twilio_Zendesk_Ticket__c q = [
            SELECT Id, Submitter_Email__c, Account__c
            FROM Twilio_Zendesk_Ticket__c
            WHERE Id = :t.Id
            LIMIT 1
        ];
        
        System.assertEquals(null, q.Account__c);

    }

    static testMethod void emailSetAndUnapprovedMatch() {
        setupTestRecords();

        Twilio_Zendesk_Ticket__c t = new Twilio_Zendesk_Ticket__c(Submitter_Email__c = 'test@testaccount3.com');
        insert t;
        
        Twilio_Zendesk_Ticket__c q = [
            SELECT Id, Submitter_Email__c, Account__c
            FROM Twilio_Zendesk_Ticket__c
            WHERE Id = :t.Id
            LIMIT 1
        ];
        
        System.assertEquals(null, q.Account__c);
    }

    static testMethod void emailSetAndApprovedMatch() {
        setupTestRecords();

        Twilio_Zendesk_Ticket__c t = new Twilio_Zendesk_Ticket__c(Submitter_Email__c = 'test@testaccount1.com');
        insert t;
        
        Twilio_Zendesk_Ticket__c q = [
            SELECT Id, Submitter_Email__c, Account__c
            FROM Twilio_Zendesk_Ticket__c
            WHERE Id = :t.Id
            LIMIT 1
        ];
        
        //System.assertEquals(accounts[0].Id, q.Account__c);
        
        q.Submitter_Email__c = 'test@testaccount2.com';
        update q;
        
        Twilio_Zendesk_Ticket__c u = [
            SELECT Id, Submitter_Email__c, Account__c
            FROM Twilio_Zendesk_Ticket__c
            WHERE Id = :q.Id
            LIMIT 1
        ];
        
        //System.assertEquals(accounts[1].Id, u.Account__c);
        
        u.Submitter_Email__c = 'test@testaccount3.com';
        update u;
        
        Twilio_Zendesk_Ticket__c z = [
            SELECT Id, Submitter_Email__c, Account__c
            FROM Twilio_Zendesk_Ticket__c
            WHERE Id = :u.Id
            LIMIT 1
        ];
        
        //System.assertEquals(null, z.Account__c);
    }
    
    static testMethod void testBatch(){
        setupTestRecords();

        Twilio_Zendesk_Ticket__c t = new Twilio_Zendesk_Ticket__c(Submitter_Email__c = 'test@testaccount3.com');
        insert t;
        
        Test.startTest();
            Database.executeBatch(new BatchAssignZendeskTickets());
        Test.stopTest();
     
    }
    
    static testMethod void testScheduler(){
        setupTestRecords();
         String CRON_EXP = '0 0 * * * ?';

        Twilio_Zendesk_Ticket__c t = new Twilio_Zendesk_Ticket__c(Submitter_Email__c = 'test@testaccount3.com');
        insert t;
        
        Test.startTest();
            String jobId = System.schedule('ScheduleZendeskTickets',
                                            CRON_EXP,
                                            new BatchAssignZendeskTickets());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchAssignZendeskTickets') LIMIT 1].Status);
    }
    
    static public void setupTestRecords() {
        accounts.add(new Account(
            Name = 'Test Account1',
            Employee_Size__c = '0 - 50',
            Website = 'http://www.testaccount1.com'
        ));
        accounts.add(new Account(
            Name = 'Test Account2',
            Employee_Size__c = '0 - 50',
            Website = 'http://www.testaccount2.com'
        ));
        accounts.add(new Account(
            Name = 'Test Account3',
            Employee_Size__c = '0 - 50',
            Website = 'http://www.testaccount3.com'
        ));
        insert accounts;

        domains.add(new Email_Domain__c(
            Name = 'testaccount1.com',
            Account__c = accounts[0].Id,
            Approved__c = true
        ));
        domains.add(new Email_Domain__c(
            Name = 'testaccount2.com',
            Account__c = accounts[1].Id,
            Approved__c = true
        ));
        domains.add(new Email_Domain__c(
            Name = 'testaccount3.com',
            Account__c = accounts[2].Id,
            Approved__c = false
        ));        
        insert domains;     
    }

}