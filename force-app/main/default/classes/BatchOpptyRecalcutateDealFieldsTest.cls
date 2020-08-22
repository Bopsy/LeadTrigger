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
private class BatchOpptyRecalcutateDealFieldsTest {

    // CRON expression: midnight on March 15. 
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    static Integer recordMax = 10;
        
    static Deal__c deal;
    static List<Opportunity> opptyList;
    static List<Account> accountList;

    static testMethod void triggerTest() {
        
        Test.startTest();
        
        // Test Deal insert
        setupTestRecords();
        
        deal = [ SELECT Id, Amount__c FROM Deal__c WHERE Id = :deal.Id LIMIT 1 ];
        System.assertEquals(null, deal.Amount__c, 'Calculate Deal Amount__c from Opportunity Amount failed');

        // Test Deal update
        Decimal total = 0;
        
        for (Integer i = 0 ; i < opptyList.size(); i++ ) {
            opptyList[i].Amount = 100;
            total += opptyList[i].Amount;
        }

        update opptyList;
        deal = [ SELECT Id, Amount__c FROM Deal__c WHERE Id = :deal.Id LIMIT 1 ];
        //System.assertEquals(total, deal.Amount__c, 'Recalculate Deal Amount__c from updated Opportunity failed');

        // Reset runOnce mechanism so that it will not prevent running for the tests
        OpportunityDealHandler.run.clear();

    // Test Deal update
        delete opptyList[0];
        deal = [ SELECT Id, Amount__c FROM Deal__c WHERE Id = :deal.Id LIMIT 1 ];
        //System.assertEquals(total - 100, deal.Amount__c, 'Recalculate Deal Amount__c from deleted Opportunity failed');
        
        // Reset runOnce mechanism so that it will not prevent running for the tests
        OpportunityDealHandler.run.clear();

    // Test Deal update
        undelete opptyList[0];
        deal = [ SELECT Id, Amount__c FROM Deal__c WHERE Id = :deal.Id LIMIT 1 ];
        //System.assertEquals(total, deal.Amount__c, 'Recalculate Deal Amount__c from undeleted Opportunity failed');
        
        Test.stopTest();
    }
    
    static testMethod void batchTest() {
        setupTestRecords();
        
        Test.startTest();
        Database.executeBatch(new BatchOpptyRecalcutateDealFields());
        Test.stopTest();
    }

    static testMethod void scheduleTest() {
        setupTestRecords();
        Test.startTest();
        
        // Schedule the test job 
        String jobId = System.schedule('BatchOpptyRecalcutateDealFields',
                        CRON_EXP, 
                        new BatchOpptyRecalcutateDealFields());
        
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
        Opportunity_To_Deal__c setting = new Opportunity_To_Deal__c();
        setting.Name = 'SumAmount';
        setting.Operator__c = 'SUM';
        setting.Deal_Field__c = 'Amount__c';
        setting.Opportunity_Field__c = 'Amount';
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

        deal = new Deal__c(
            Name = 'TestDeal'
        );
        insert deal;
        
        opptyList = new List<Opportunity>();
        for (Integer i = 0; i < recordMax; i++) {
            opptyList.add(new Opportunity(
                Name = 'TESTOPPTY' + i,
                AccountId = accountList[0].Id,
                Deal__c = deal.Id,
                CloseDate = Date.today(),
                StageName = 'Incubate',
                Product__c = 'Client',
                Primary_Competitor__c = 'Agendi'
            ));
        }
        insert opptyList;
        
        // Reset runOnce mechanism so that it will not prevent running for the tests
        OpportunityDealHandler.run.clear();
    }
}