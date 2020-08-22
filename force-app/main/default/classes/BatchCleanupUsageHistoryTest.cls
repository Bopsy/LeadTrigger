@isTest
private class BatchCleanupUsageHistoryTest {
   
    static testMethod void testBatch(){
        Date today = Date.Today();
        Date cutoffDate = today.addYears(-1);
        Date oldDate = cutoffDate.addDays(-1);

        insert new Historical_Twilio_Usage__c(Timestamp__c = cutoffDate, Year__c = oldDate.year(), Month__c = oldDate.month());

        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;

        Account_SID__c testAccountSID = new Account_SID__c (Name = 'Test Account SID', Account__c = testAcc.Id);
        insert testAccountSID;

        Twilio_Usage__c usage1 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Acc ', Currency__c = 'USD', Product__c = 'Test Prod', Total__c = 10.0, Year__c = today.year(), Month__c = today.month());
        Twilio_Usage__c usage2 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Acc ', Currency__c = 'USD', Product__c = 'Test Prod', Total__c = 10.0, Year__c = oldDate.year(), Month__c = oldDate.month());
        insert new List<Twilio_Usage__c>{usage1, usage2};
        
        Test.startTest();
            Database.executeBatch(new BatchCleanupUsageHistory());
        Test.stopTest();
        
        List<Twilio_Usage__c> usages = [ SELECT Id FROM Twilio_Usage__c ];
        system.assertEquals(1, usages.size(), 'only 1 usage record expected');
        system.assertEquals(usage1.Id, usages[0].Id, 'this record should not be deleted');
    }
    
    static testMethod void testScehduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        Date today = Date.Today();
        Date cutoffDate = today.addYears(-1);
        Date oldDate = cutoffDate.addDays(-1);

        insert new Historical_Twilio_Usage__c(Timestamp__c = cutoffDate, Year__c = oldDate.year(), Month__c = oldDate.month());

        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;

        Account_SID__c testAccountSID = new Account_SID__c (Name = 'Test Account SID', Account__c = testAcc.Id);
        insert testAccountSID;

        Twilio_Usage__c usage1 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Acc ', Currency__c = 'USD', Product__c = 'Test Prod', Total__c = 10.0, Year__c = today.year(), Month__c = today.month());
        Twilio_Usage__c usage2 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Acc ', Currency__c = 'USD', Product__c = 'Test Prod', Total__c = 10.0, Year__c = oldDate.year(), Month__c = oldDate.month());
        insert new List<Twilio_Usage__c>{usage1, usage2};
       
        Test.startTest();
            String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchCleanupUsageHistory());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchCleanupUsageHistory') LIMIT 1].Status);
    }
}