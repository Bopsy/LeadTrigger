/******************************************
//Created By: Davis Dong
//Last Modified by: Gram Bischof {02/11/2019}
//Description: This is the test class of AccountUsageService
//
*******************************************/
@isTest
private class AccountUsageServiceTest {
/*
    static testMethod void testValidYearToMonths_Mar(){
        
        Test.startTest();
            Map<Integer, Set<Integer>> yearMap = AccountUsageService.getValidYearsMap(3, 2016, 2, 1, 12);
        Test.stopTest();
        
        system.assertEquals(2, yearMap.size(), 'this map should have two years');
        system.assertEquals(new Set<Integer>{12}, yearMap.get(2015), 'the year 2015 should have December' );
        system.assertEquals(new Set<Integer>{1,2,3}, yearMap.get(2016), 'the year 2016 should have January, February and March' );
    }
    
    static testMethod void testValidYearToMonths_Feb(){
        
        Test.startTest();
            Map<Integer, Set<Integer>> yearMap = AccountUsageService.getValidYearsMap(2, 2016, 1, 12, 11);
        Test.stopTest();
        
        system.assertEquals(2, yearMap.size(), 'this map should have two years');
        system.assertEquals(new Set<Integer>{11, 12}, yearMap.get(2015), 'the year 2015 should have Novemeber and December' );
        system.assertEquals(new Set<Integer>{1,2}, yearMap.get(2016), 'the year 2016 should have January and February' );
    }
    
    static testMethod void testValidYearToMonths_Jan(){
        
        Test.startTest();
            Map<Integer, Set<Integer>> yearMap = AccountUsageService.getValidYearsMap(1, 2016, 12, 11, 10);
        Test.stopTest();
        
        system.assertEquals(2, yearMap.size(), 'this map should have two years');
        system.assertEquals(new Set<Integer>{10, 11, 12}, yearMap.get(2015), 'the year 2015 should have October' );
        system.assertEquals(new Set<Integer>{1}, yearMap.get(2016), 'the year 2016 should have January' );
    }
    
    static testMethod void testValidYearToMonths_SameYear(){
        
        Test.startTest();
            Map<Integer, Set<Integer>> yearMap = AccountUsageService.getValidYearsMap(12, 2016, 11, 10, 9);
        Test.stopTest();
        
        system.assertEquals(1, yearMap.size(), 'this map should have one year');
        system.assertEquals(new Set<Integer>{9, 10, 11, 12}, yearMap.get(2016), 'the year 2015 should have October' );
    }
*/    
    static testMethod void testCalculateUsage(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;

		Account_SID__c testAccSID = new Account_SID__c(Name = 'Test Account SID', Account__c = testAcc.Id);
		insert testAccSID;

        Twilio_Usage__c usage1 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = Date.today().month(), Finance_Amortized_Billings__c = 10.00, Total__c = 10.00);
        Twilio_Usage__c usage2 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = Date.today().month(), Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        insert new List<Twilio_Usage__c>{usage1, usage2};

        testAcc = [SELECT Id, (SELECT Year__c, Month__c, Finance_Amortized_Billings__c FROM Twilio_Usages__r) FROM Account LIMIT 1];
        testAccSid = [SELECT Id, (SELECT Year__c, Month__c, Finance_Amortized_Billings__c FROM Twilio_Usages__r) FROM Account_SID__c LIMIT 1];

        Test.startTest();
            AccountUsageService.calculateUsage(new List<Account>{testAcc});
            AccountUsageService.calculateUsage(new List<Account_SID__c>{testAccSid});
        Test.stopTest();
        
        Account acc = [SELECT Total_Amortized_Twilio_Usage_This_Month__c FROM Account LIMIT 1];
        system.assertEquals(30, acc.Total_Amortized_Twilio_Usage_This_Month__c, 'the total amortized usage should be calculated correctly');

        Account_SID__c accSID = [SELECT Total_Amortized_Twilio_Usage_This_Month__c FROM Account_SID__c LIMIT 1];
        system.assertEquals(30, acc.Total_Amortized_Twilio_Usage_This_Month__c, 'the total amortized usage should be calculated correctly');
        
    }
    
    static testMethod void testCalculateQuarterlyUsage(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;

		Account_SID__c testAccSID = new Account_SID__c(Name = 'Test Account SID', Account__c = testAcc.Id);
		insert testAccSID;

        Twilio_Usage__c usage1 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = 1, Finance_Amortized_Billings__c = 100.00, Total__c = 10.00);
        Twilio_Usage__c usage2 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = 2, Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        Twilio_Usage__c usage3 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = 5, Finance_Amortized_Billings__c = 110.00, Total__c = 10.00);
        Twilio_Usage__c usage4 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = 6, Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        Twilio_Usage__c usage5 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = 7, Finance_Amortized_Billings__c = 10.00, Total__c = 10.00);
        Twilio_Usage__c usage6 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = 8, Finance_Amortized_Billings__c = 200.00, Total__c = 10.00);
        Twilio_Usage__c usage7 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = 10, Finance_Amortized_Billings__c = 150.00, Total__c = 10.00);
        Twilio_Usage__c usage8 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = 11, Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        Twilio_Usage__c usage9 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().addYears(-1).year(), Month__c = 1, Finance_Amortized_Billings__c = 50.00, Total__c = 10.00);
        Twilio_Usage__c usage10 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().addYears(-1).year(), Month__c = 2, Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        Twilio_Usage__c usage11 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().addYears(-1).year(), Month__c = 4, Finance_Amortized_Billings__c = 150.00, Total__c = 10.00);
        Twilio_Usage__c usage12 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().addYears(-1).year(), Month__c = 6, Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        Twilio_Usage__c usage13 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().addYears(-1).year(), Month__c = 7, Finance_Amortized_Billings__c = 120.00, Total__c = 10.00);
        Twilio_Usage__c usage14 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().addYears(-1).year(), Month__c = 9, Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        Twilio_Usage__c usage15 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().addYears(-1).year(), Month__c = 11, Finance_Amortized_Billings__c = 130.00, Total__c = 10.00);
        Twilio_Usage__c usage16 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().addYears(-1).year(), Month__c = 12, Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        insert new List<Twilio_Usage__c>{usage1, usage2, usage3, usage4, usage5, usage6, usage7, usage8,
            							 usage9, usage10, usage11, usage12, usage13, usage14, usage15, usage16};
        
        testAcc = [SELECT Id, (SELECT Year__c, Month__c, Finance_Amortized_Billings__c FROM Twilio_Usages__r) FROM Account LIMIT 1];
        testAccSid = [SELECT Id, (SELECT Year__c, Month__c, Finance_Amortized_Billings__c FROM Twilio_Usages__r) FROM Account_SID__c LIMIT 1];

        Test.startTest();
            AccountUsageService.calculateUsage(new List<Account>{testAcc});
            AccountUsageService.calculateUsage(new List<Account_SID__c>{testAccSid});
        Test.stopTest();
        
        Account acc = [SELECT Q1_Revenue_This_Year__c,
                       		  Q2_Revenue_This_Year__c,
                       		  Q3_Revenue_This_Year__c,
                       		  Q4_Revenue_This_Year__c,
                       	      Q1_Revenue_Last_Year__c,
                              Q2_Revenue_Last_Year__c,
                              Q3_Revenue_Last_Year__c,
                              Q4_Revenue_Last_Year__c
                       FROM Account LIMIT 1];
        system.assertEquals(120, acc.Q1_Revenue_This_Year__c, 'The total amortized usage should be calculated correctly');
        system.assertEquals(130, acc.Q2_Revenue_This_Year__c, 'The total amortized usage should be calculated correctly');
        system.assertEquals(210, acc.Q3_Revenue_This_Year__c, 'The total amortized usage should be calculated correctly');
        system.assertEquals(170, acc.Q4_Revenue_This_Year__c, 'The total amortized usage should be calculated correctly');
        system.assertEquals(70, acc.Q1_Revenue_Last_Year__c, 'The total amortized usage should be calculated correctly');
        system.assertEquals(170, acc.Q2_Revenue_Last_Year__c, 'The total amortized usage should be calculated correctly');
        system.assertEquals(140, acc.Q3_Revenue_Last_Year__c, 'The total amortized usage should be calculated correctly');
        system.assertEquals(150, acc.Q4_Revenue_Last_Year__c, 'The total amortized usage should be calculated correctly');
    }
    
    static testMethod void testBatch(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Account_SID__c testAccSID = new Account_SID__c (Name = 'Test Account SID', Account__c = testAcc.Id);
        insert testAccSID;

        Twilio_Usage__c usage1 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = Date.today().month(), Finance_Amortized_Billings__c = 10.00, Total__c = 10.00);
        Twilio_Usage__c usage2 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = Date.today().month(), Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        insert new List<Twilio_Usage__c>{usage1, usage2};
        
        Test.startTest();
            Database.executeBatch(new BatchCalculateUsage());
            Database.executeBatch(new BatchCalculateAccountSIDUsage());
        Test.stopTest();
        
        
        Account acc = [SELECT Total_Amortized_Twilio_Usage_This_Month__c FROM Account LIMIT 1];
        system.assertEquals(30, acc.Total_Amortized_Twilio_Usage_This_Month__c, 'the total amortized usage should be calculated correctly');
    }
    
    static testMethod void testScehduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Twilio_Usage__c usage1 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Acc ', Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = Date.today().month(), Finance_Amortized_Billings__c = 10.00, Total__c = 10.00);
        Twilio_Usage__c usage2 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Acc ', Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = Date.today().month(), Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
        insert new List<Twilio_Usage__c>{usage1, usage2}; 
        
        Test.startTest();
            String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchCalculateUsage());
            String jobId2 = System.schedule('ScheduleApexClassTester',
                                            CRON_EXP,
                                            new BatchCalculateAccountSIDUsage());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchCalculateUsage') LIMIT 1].Status);
    }
}