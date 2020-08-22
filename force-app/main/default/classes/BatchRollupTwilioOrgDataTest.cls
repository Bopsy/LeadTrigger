@isTest
private class BatchRollupTwilioOrgDataTest {
    
    /*
     * Jason added 5-22-18
     * Test setup method sets up data to be used by each testMethod.
	*/
    @testSetup static void setup(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Account_SID__c testSID1 = new Account_SID__c(Account__c = testAcc.Id, Pricing_Model_Friendly_Name__c = 'testclass.org');
        Account_SID__c testSID2 = new Account_SID__c(Account__c = testAcc.Id, Pricing_Model_Friendly_Name__c = 'testclass.org');
        Account_SID__c testSID3 = new Account_SID__c(Account__c = testAcc.Id, Invoicing__c = TRUE);
        Account_SID__c testSID4 = new Account_SID__c(Account__c = testAcc.Id);
        insert new List<Account_SID__c>{testSID1, testSID2, testSID3, testSID4};
    }
    
    static testMethod void testRollupTwilioOrgData(){
        Account testAcc = [SELECT Number_of_Twilio_org_Account_SIDs__c, Number_of_Invoiced_Account_SIDs__c, 
                           (SELECT Twilio_org_Pricing_Model__c, Invoicing__c 
                            FROM Account_SIDs__r 
                            WHERE Twilio_org_Pricing_Model__c = true) 
                           FROM Account 
                           LIMIT 1];
        
        Test.startTest();
            BatchAccountSIDServices.rollupTwilioOrgData(new List<Account>{testAcc});
        Test.stopTest();
        
        testAcc = [SELECT Number_of_Twilio_org_Account_SIDs__c, Number_of_Account_SIDs__c, Number_of_Invoiced_Account_SIDs__c FROM Account LIMIT 1];
        system.assertEquals(2, testAcc.Number_of_Twilio_org_Account_SIDs__c, 'this test account should have 2 twilio org account sids.');
        system.assertEquals(4, testAcc.Number_of_Account_SIDs__c, 'This test account should have 4 Account SIDs.');
        system.assertEquals(1, testAcc.Number_of_Invoiced_Account_SIDs__c, 'This test account should have 1 Account SID.');
    }
    
    static testMethod void testScheduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        Test.startTest();
            String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchRollupTwilioOrgData());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchRollupTwilioOrgData') LIMIT 1].Status);
    }
    
    static testMethod void testBatch(){
        Test.startTest();
            Database.executeBatch(new BatchRollupTwilioOrgData());
        Test.stopTest();
        
        Account testAcc = [SELECT Number_of_Twilio_org_Account_SIDs__c, Number_of_Account_SIDs__c FROM Account LIMIT 1];
        system.assertEquals(2, testAcc.Number_of_Twilio_org_Account_SIDs__c, 'this test account should have 2 twilio org account sids.');
        system.assertEquals(4, testAcc.Number_of_Account_SIDs__c, 'This test account should have 4 Accound SIDs.');
    }
}