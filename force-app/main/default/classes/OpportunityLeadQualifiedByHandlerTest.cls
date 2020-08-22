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
private class OpportunityLeadQualifiedByHandlerTest {
    static User usr;
    static Account acc;
    static Opportunity opp;
    
    static testMethod void insertWithNoMatchingLeadQualifiedBy() {
    	setupTestRecords();
        Test.startTest();

        insert opp;
        
        Opportunity o = [ SELECT Id, Lead_Qualified_By__c, Lead_Qualified_By_Lookup__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1 ];
        if (o.Lead_Qualified_By__c == null) {
	        System.assertEquals(null, o.Lead_Qualified_By_Lookup__c, 'Lead_Qualified_By__c is null and Lead_Qualified_By_Lookup__c should be null');
        } else {
	        User u = [ SELECT Name FROM User Where Id = :o.Lead_Qualified_By_Lookup__c LIMIT 1];
	        System.assertEquals(u.Name, o.Lead_Qualified_By__c, 'Lead_Qualified_By_Lookup__c not matching name of user in Lead_Qualified_By__c');
        }

        Test.stopTest();
    }

    static testMethod void insertWithMatchingLeadQualifiedBy() {
    	setupTestRecords();
        Test.startTest();

        opp.Lead_Qualified_By__c = usr.Name;
        insert opp;
        
        Opportunity o = [ SELECT Id, Lead_Qualified_By__c, Lead_Qualified_By_Lookup__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1 ];
        if (o.Lead_Qualified_By__c == null) {
	        System.assertEquals(null, o.Lead_Qualified_By_Lookup__c, 'Lead_Qualified_By__c is null and Lead_Qualified_By_Lookup__c should be null');
        } else {
	        User u = [ SELECT Name FROM User Where Id = :o.Lead_Qualified_By_Lookup__c LIMIT 1];
	        System.assertEquals(u.Name, o.Lead_Qualified_By__c, 'Lead_Qualified_By_Lookup__c not matching name of user in Lead_Qualified_By__c');
        }
  
        Test.stopTest();
    }
        
    static testMethod void updateWithNoMatchingLeadQualifiedBy() {
    	setupTestRecords();
        Test.startTest();

        insert opp;
        
        opp.Lead_Qualified_By__c = usr.Name + '-Mismatch';
        update opp;
        
        Opportunity o = [ SELECT Id, Lead_Qualified_By__c, Lead_Qualified_By_Lookup__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1 ];
        if (o.Lead_Qualified_By__c == null) {
	        System.assertEquals(null, o.Lead_Qualified_By_Lookup__c, 'Lead_Qualified_By__c is null and Lead_Qualified_By_Lookup__c should be null');
        } else {
	        List<User> userList = [ SELECT Name FROM User Where Id = :o.Lead_Qualified_By_Lookup__c ];
        	System.assert(userList.isEmpty(), 'No matching User should have been found for Lead_Qualified_By__c');
        }

        Test.stopTest();
    }

    static testMethod void updateWithMatchingLeadQualifiedBy() {
    	setupTestRecords();
        Test.startTest();

        insert opp;
        
        opp.Lead_Qualified_By__c = usr.Name;
        update opp;
        
        Opportunity o = [ SELECT Id, Lead_Qualified_By__c, Lead_Qualified_By_Lookup__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1 ];
        if (o.Lead_Qualified_By__c == null) {
	        System.assertEquals(null, o.Lead_Qualified_By_Lookup__c, 'Lead_Qualified_By__c is null and Lead_Qualified_By_Lookup__c should be null');
        } else {
	        User u = [ SELECT Name FROM User Where Id = :o.Lead_Qualified_By_Lookup__c LIMIT 1];
	        System.assertEquals(u.Name, o.Lead_Qualified_By__c, 'Lead_Qualified_By_Lookup__c not matching name of user in Lead_Qualified_By__c');
        }

        Test.stopTest();
    }

    static testMethod void updateClearingLeadQualifiedBy() {
    	setupTestRecords();
        Test.startTest();

        opp.Lead_Qualified_By__c = usr.Name;
        insert opp;
        
        opp.Lead_Qualified_By__c = null;
        update opp;
        
        Opportunity o = [ SELECT Id, Lead_Qualified_By_Lookup__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1 ];
        System.assertEquals(null, o.Lead_Qualified_By_Lookup__c, 'Lead_Qualified_By_Lookup__c should be null');

        Test.stopTest();
    }
    
    static testMethod void batchTest() {
        setupTestRecords();
        insert opp;
        
        Test.startTest();
        Database.executeBatch(new OpportunityLeadQualifiedByHandler());

        Opportunity o = [ SELECT Id, Lead_Qualified_By__c, Lead_Qualified_By_Lookup__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1 ];
        if (o.Lead_Qualified_By__c == null) {
	        System.assertEquals(null, o.Lead_Qualified_By_Lookup__c, 'Lead_Qualified_By__c is null and Lead_Qualified_By_Lookup__c should be null');
        } else {
	        User u = [ SELECT Name FROM User Where Id = :o.Lead_Qualified_By_Lookup__c LIMIT 1];
	        System.assertEquals(u.Name, o.Lead_Qualified_By__c, 'Lead_Qualified_By_Lookup__c not matching name of user in Lead_Qualified_By__c');
        }

        Test.stopTest();
    }
    
    // CRON expression: midnight on March 15. 
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    static testMethod void scheduleTest() {
        setupTestRecords();
        
        Test.startTest();
        
        // Schedule the test job
        String jobId = System.schedule('OpportunityLeadQualifiedByHandler', CRON_EXP, new OpportunityLeadQualifiedByHandler());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [ SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId ];
        
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
        
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run 
        System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
        
        Test.stopTest();
    }


    static void setupTestRecords() {
    	Profile p = [ SELECT Id FROM Profile WHERE Name='Standard User' ]; 
        usr = new User(
			FirstName = 'User',
        	LastName = 'Testing',
        	Alias = 'standt',
			Email = 'standarduser@testorg.com', 
            EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US',
			ProfileId = p.Id, 
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = UserInfo.getOrganizationId() + System.now().millisecond() + 'standarduser@testorg.com'
        );
        insert usr;
        usr = [ SELECT Id, Name, UserName FROM User WHERE Id = :usr.Id LIMIT 1 ];
    	
        acc = new Account(Name = 'TESTACCOUNT');
        insert acc;

        opp = new Opportunity(
            Name = 'TESTOPPTY-No-LeadQualifiedBy',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            Type = 'Open',
            StageName = 'Validate Solution',
            ForecastCategoryName = 'Pipeline',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        );
    }
}