@isTest
private class BatchRollupNPCAccountTest {
    
    static testMethod void testBatch(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Account_SID__c sid1 = createSID(testAcc.Id, Date.today(), Date.today().addMonths(-1), Date.today().addDays(-2), Date.today());
        Account_SID__c sid2 = createSID(testAcc.Id, Date.today().addDays(2), Date.today().addMonths(-2), Date.today().addDays(-3), Date.today().addDays(2));
        insert new List<Account_SID__c>{sid1, sid2};
        
        Test.startTest();
            Database.executeBatch(new BatchRollupNPCAccount());
        Test.stopTest();
        
        Account acc = [SELECT First_NPC_5_Date__c, First_NPC_50_Date__c, First_NPC_500_Date__c, First_Account_SID_Created_Date__c FROM Account LIMIT 1];
        system.assertEquals(Date.today(), acc.First_NPC_5_Date__c, 'the first NPC 5 Date should be equal');
        system.assertEquals(Date.today().addMonths(-2), acc.First_NPC_50_Date__c, 'the first NPC 50 Date should be equal');
        system.assertEquals(Date.today().addDays(-3), acc.First_NPC_500_Date__c, 'the first NPC 500 Date should be equal');
        system.assertEquals(Date.today(), acc.First_Account_SID_Created_Date__c, 'the first SID create Date should be equal');
    }
    
    static testMethod void testRollupNPC(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Account_SID__c sid1 = createSID(testAcc.Id, Date.today(), Date.today().addMonths(-1), Date.today().addDays(-2), Date.today());
        Account_SID__c sid2 = createSID(testAcc.Id, Date.today().addDays(2), Date.today().addMonths(-2), Date.today().addDays(-3), Date.today().addDays(2));
        
        Test.startTest();
            BatchAccountSIDServices.rollupNPC(new List<Account_SID__c>{sid1, sid2});
        Test.stopTest();
        
        Account acc = [SELECT First_NPC_5_Date__c, First_NPC_50_Date__c, First_NPC_500_Date__c, First_Account_SID_Created_Date__c FROM Account LIMIT 1];
        system.assertEquals(Date.today(), acc.First_NPC_5_Date__c, 'the first NPC 5 Date should be equal');
        system.assertEquals(Date.today().addMonths(-2), acc.First_NPC_50_Date__c, 'the first NPC 50 Date should be equal');
        system.assertEquals(Date.today().addDays(-3), acc.First_NPC_500_Date__c, 'the first NPC 500 Date should be equal');
        system.assertEquals(Date.today(), acc.First_Account_SID_Created_Date__c, 'the first SID create Date should be equal');
    }
    
    static testMethod void testMinDate(){
        Test.startTest();
            Date result1 = BatchAccountSIDServices.minDate(null, null);
            Date result2 = BatchAccountSIDServices.minDate(Date.today(), null);
            Date result3 = BatchAccountSIDServices.minDate(null, Date.today());
            Date result4 = BatchAccountSIDServices.minDate(Date.today().addDays(-1), Date.today());
            Date result5 = BatchAccountSIDServices.minDate(Date.today().addDays(1), Date.today());
        Test.stopTest();
        
        System.assertEquals(null, result1, 'the two null parameters should return a null');
        System.assertEquals(Date.today(), result2, 'the one null parameters should return today');
        System.assertEquals(Date.today(), result3, 'the one null parameters should return today');
        System.assertEquals(Date.today().addDays(-1), result4, 'the two Date parameters should return min date');
        System.assertEquals(Date.today(), result5, 'the two Date parameters should return min date');
    }
    
    static testMethod void testScheduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Account_SID__c sid1 = createSID(testAcc.Id, Date.today(), Date.today().addMonths(-1), Date.today().addDays(-2), Date.today());
        Account_SID__c sid2 = createSID(testAcc.Id, Date.today().addDays(2), Date.today().addMonths(-2), Date.today().addDays(-3), Date.today().addDays(2));
        insert new List<Account_SID__c>{sid1, sid2};
        
        Test.startTest();
            String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchRollupNPCAccount());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchRollupNPCAccount') LIMIT 1].Status);
    }
    
    static Account_SID__c createSID(Id accountId, Date NPC5, Date NPC50, Date NPC500, Date createDate){
        return new Account_SID__c(
                    Account__c = accountId,
                    NPC_Date_5__c = NPC5,
                    NPC_Date_50__c = NPC50,
                    NPC_Date_500__c = NPC500,
                    Account_SID_Created_Date__c = createDate
            );
    }
}