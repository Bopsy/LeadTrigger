@isTest
private class AccountReassignmentServicesTest {
    final static Id VALID_USER_ID = '005400000031mD9';
    
    static testMethod void testReassignOwnerAccountSID(){
        Account_Reassignment_User__c customSetting = new Account_Reassignment_User__c(Name = 'Test', Current_User_ID__c = VALID_USER_ID);
        insert customSetting;
        List<User> users = [SELECT Id FROM User Where IsActive = true LIMIT 2];
        Account_Reassignment__c assignment1 = new Account_Reassignment__c(ISO_Country_Code__c = 'US', Usage_Ceiling__c = 2500, Usage_Floor__c = 500, New_Owner__c = users[0].Id);
        insert assignment1;
        
        Lead newLead = new Lead(LastName = 'Tester', Company = 'Test Company');
        insert newLead;
        Account testAcc = new Account(Name = 'Test Account');
        Account emailAcc = new Account(Name = 'Email Account');
        insert new List<Account>{testAcc, emailAcc};
        Email_Domain__c domain = new Email_Domain__c(Name = 'testDavis.com', Account__c = emailAcc.Id, Approved__c = true);
        insert domain;
        
        Contact testCon1 = new Contact(LastName = 'Tester1', AccountId = testAcc.Id);
        Contact testCon2 = new Contact(LastName = 'Tester2');
        insert new List<Contact>{testCon1, testCon2};
        
        Account_SID__c accountSID1 = new Account_SID__c (Name = 'Test1', Lead__c = newLead.Id, ISO_Country_Code__c = 'US', Total_Amortized_Twilio_Usage_This_Month__c = 600);
        Account_SID__c accountSID2 = new Account_SID__c (Name = 'Test2', Contact__c = testCon1.Id, ISO_Country_Code__c = 'US', NPC_Date_5__c = Date.today());
        Account_SID__c accountSID3 = new Account_SID__c (Name = 'Test3', OwnerUser_Email_Address__c = 'davis123@testDavis.com', Contact__c = testCon2.Id, ISO_Country_Code__c = 'US', Total_Amortized_Twilio_Usage_This_Month__c = 600);
        Account_SID__c accountSID4 = new Account_SID__c (Name = 'Test4', OwnerUser_Email_Address__c = 'davis321@davistest.com', ISO_Country_Code__c = 'US', NPC_Date_5__c = Date.today());
        List<Account_SID__c> newList = new List<Account_SID__c> {accountSID1, accountSID2, accountSID3, accountSID4};
        insert newList;
        
        newList = [SELECT Twilio_org_Pricing_Model__c, ISO_Country_Code__c, NPC_Date_5__c, Average_Amortized_Usage_Last_3_Months__c, Total_Amortized_Twilio_Usage_This_Month__c, Total_Amortized_Twilio_Usage_Last_Month__c, Lead__c, Email_Domain__c, Contact__c, Contact__r.AccountId FROM Account_SID__c ];
        Test.startTest();
            AccountReassignmentServices.reassignOwnerAccountSID(newList);
            AccountReassignmentServices.roundRobinOwners();
            Database.executeBatch(new BatchReassignAccountSIDs());
        Test.stopTest();
        
        
    }
    static testMethod void testUsageOwner(){
        Test.startTest();
            AccountReassignmentServices.UsageOwner testUsageOwner1 = new AccountReassignmentServices.UsageOwner(500, 2500, Id.valueOf('005000000000000002'), null);
            AccountReassignmentServices.UsageOwner testUsageOwner2 = new AccountReassignmentServices.UsageOwner(2500, null, Id.valueOf('005000000000000002'), null);
            Boolean result1 = testUsageOwner1.isOwner(1000);
            Boolean result2 = testUsageOwner2.isOwner(1000);
        Test.stopTest();
        
        system.assertEquals(true, result1, 'usage owner 1 should be the owner');
        system.assertEquals(false, result2, 'usage owner 2 should not be the owner');
    }
    
    static testMethod void testReassignOwner(){
        List<User> users = [SELECT Id FROM User Where IsActive = true LIMIT 2];
        
        Assignment_Group_Name__c testGroup1 = new Assignment_Group_Name__c(Name = 'Test Group1');
        insert testGroup1;
        Assignment_Groups__c testMember1 = buildActiveMember(DateTime.now(), 100, users[0].Id, testGroup1.Id);
        insert testMember1;
        
        Account_Reassignment__c assignment3 = buildAccountReassignment('China', 'Hunan', '410013', null, 2500, users[1].Id);
        assignment3.Assignment_Group__c = testGroup1.Id;
        
        Account_Reassignment__c assignment1 = buildAccountReassignment('United States', 'California', '94403', 2500, 500, users[0].Id);
        Account_Reassignment__c assignment2 = buildAccountReassignment('United States', 'California', '94403', null, 2500, users[1].Id);
        insert new List<Account_Reassignment__c>{assignment1, assignment2, assignment3};
        
        
        Account account1 = new Account(OwnerId = VALID_USER_ID, Name = 'Test Acc1', BillingState = 'California', BillingCountry = 'United States', BillingPostalCode = '94403', Total_Amortized_Twilio_Usage_Last_Month__c = 3000, Total_Amortized_Twilio_Usage_2_Month_Ago__c = 3000, Total_Amortized_Twilio_Usage_3_Month_Ago__c = 3000, Total_Amortized_Twilio_Usage_This_Month__c = 500);
        Account account2 = new Account(OwnerId = VALID_USER_ID, Name = 'Test Acc2', BillingState = 'California', BillingCountry = 'United States', BillingPostalCode = '94403', Total_Amortized_Twilio_Usage_Last_Month__c = 3000, Total_Amortized_Twilio_Usage_2_Month_Ago__c = 2000, Total_Amortized_Twilio_Usage_3_Month_Ago__c = 1000, Total_Amortized_Twilio_Usage_This_Month__c = 3000);
        Account account3 = new Account(OwnerId = VALID_USER_ID, Name = 'Test Acc3', BillingState = 'California', BillingCountry = 'United States', BillingPostalCode = '94403', Total_Amortized_Twilio_Usage_Last_Month__c = 200, Total_Amortized_Twilio_Usage_2_Month_Ago__c = 200, Total_Amortized_Twilio_Usage_3_Month_Ago__c = 200, Total_Amortized_Twilio_Usage_This_Month__c = 600);
        Account account4 = new Account(OwnerId = VALID_USER_ID, Name = 'Test Acc4', BillingState = 'California', BillingCountry = 'United States', BillingPostalCode = '94403', Total_Amortized_Twilio_Usage_Last_Month__c = 600, Total_Amortized_Twilio_Usage_2_Month_Ago__c = 0, Total_Amortized_Twilio_Usage_3_Month_Ago__c = 0, Total_Amortized_Twilio_Usage_This_Month__c = 200);
        Account account5 = new Account(OwnerId = VALID_USER_ID, Name = 'Test Acc5', BillingState = 'Hunan', BillingCountry = 'China', BillingPostalCode = '410013', Total_Amortized_Twilio_Usage_Last_Month__c = 6000, Total_Amortized_Twilio_Usage_2_Month_Ago__c = 6000, Total_Amortized_Twilio_Usage_3_Month_Ago__c = 6000, Total_Amortized_Twilio_Usage_This_Month__c = 6000);
        
        List<Account> accounts = new List<Account>{account1, account2, account3, account4, account5};
        insert accounts;
        
        accounts = [SELECT SFDC_Country__c, SFDC_ZipCode__c, SFDC_State__c, OwnerId, Total_Amortized_Twilio_Usage_This_Month__c, Total_Amortized_Twilio_Usage_Last_Month__c, Average_Amortized_Usage_Last_3_Months__c FROM Account];
        Test.startTest();
            AccountReassignmentServices.reassignOwner(accounts);
        Test.stopTest();
        
        system.assertEquals(users[1].Id, accounts[0].OwnerId, 'account 1 should be falling above 2500 bracket');
        system.assertEquals(users[0].Id, accounts[1].OwnerId, 'account 1 should be falling below 2500 bracket');
        system.assertEquals(users[0].Id, accounts[2].OwnerId, 'account 1 should be falling below 2500 bracket');
        system.assertEquals(users[0].Id, accounts[3].OwnerId, 'account 1 should be falling below 2500 bracket');
    }
    
    static testMethod void testBatch(){
        Account_Reassignment_User__c customSetting = new Account_Reassignment_User__c(Name = 'Test', Current_User_ID__c = VALID_USER_ID);
        insert customSetting;
        
        List<User> users = [SELECT Id FROM User Where IsActive = true LIMIT 2];
        Account_Reassignment__c assignment1 = buildAccountReassignment('United States', 'California', '94403', 2500, 500, users[0].Id);
        Account_Reassignment__c assignment2 = buildAccountReassignment('United States', 'California', '94403', null, 2500, users[1].Id);
        insert new List<Account_Reassignment__c>{assignment1, assignment2};
        
        Account account1 = new Account(OwnerId = VALID_USER_ID, Name = 'Test Acc1', BillingState = 'California', BillingCountry = 'United States', BillingPostalCode = '94403', Total_Amortized_Twilio_Usage_Last_Month__c = 3000, Total_Amortized_Twilio_Usage_2_Month_Ago__c = 3000, Total_Amortized_Twilio_Usage_3_Month_Ago__c = 3000, Total_Amortized_Twilio_Usage_This_Month__c = 500);
        Account account2 = new Account(OwnerId = VALID_USER_ID, Name = 'Test Acc2', BillingState = 'California', BillingCountry = 'United States', BillingPostalCode = '94403', Total_Amortized_Twilio_Usage_Last_Month__c = 3000, Total_Amortized_Twilio_Usage_2_Month_Ago__c = 2000, Total_Amortized_Twilio_Usage_3_Month_Ago__c = 1000, Total_Amortized_Twilio_Usage_This_Month__c = 3000);
        Account account3 = new Account(OwnerId = VALID_USER_ID, Name = 'Test Acc3', BillingState = 'California', BillingCountry = 'United States', BillingPostalCode = '94403', Total_Amortized_Twilio_Usage_Last_Month__c = 200, Total_Amortized_Twilio_Usage_2_Month_Ago__c = 200, Total_Amortized_Twilio_Usage_3_Month_Ago__c = 200, Total_Amortized_Twilio_Usage_This_Month__c = 600);
        Account account4 = new Account(OwnerId = VALID_USER_ID, Name = 'Test Acc4', BillingState = 'California', BillingCountry = 'United States', BillingPostalCode = '94403', Total_Amortized_Twilio_Usage_Last_Month__c = 600, Total_Amortized_Twilio_Usage_2_Month_Ago__c = 0, Total_Amortized_Twilio_Usage_3_Month_Ago__c = 0, Total_Amortized_Twilio_Usage_This_Month__c = 200);
        
        List<Account> accounts = new List<Account>{account1, account2, account3, account4};
        insert accounts;
        
        Test.startTest();
            Database.executeBatch(new BatchReassignAccounts());
        Test.stopTest();
        
        accounts = [SELECT OwnerId FROM Account];
        
        system.assertEquals(users[1].Id, accounts[0].OwnerId, 'account 1 should be falling above 2500 bracket');
        system.assertEquals(users[0].Id, accounts[1].OwnerId, 'account 1 should be falling below 2500 bracket');
        system.assertEquals(users[0].Id, accounts[2].OwnerId, 'account 1 should be falling below 2500 bracket');
        system.assertEquals(users[0].Id, accounts[3].OwnerId, 'account 1 should be falling below 2500 bracket');
    }
     static testMethod void testScehduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        Test.startTest();
            String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchReassignAccounts());
            String jobId2 = System.schedule('ScheduleApexClassTester',
                                            CRON_EXP,
                                            new BatchReassignAccountSIDs());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchReassignAccounts') LIMIT 1].Status);
     }
                                       
    static Account_Reassignment__c buildAccountReassignment(String country, String state, String zipCode, Decimal ceiling, Decimal floor, Id ownerId){
        return new Account_Reassignment__c(
            Country__c = country,
            State__c = state,
            Zip_Code__c = zipCode,
            Usage_Ceiling__c = ceiling,
            Usage_Floor__c = floor,
            New_Owner__c = ownerId
        );
    }
    
    static Assignment_Groups__c buildActiveMember(DateTime assignmentTime, Decimal seconds, Id userId, Id groupId){
        return new Assignment_Groups__c(Last_Assignment__c = assignmentTime, Millisecond__c = seconds, User__c = userId, Active__c = 'true', Group_Name__c = groupId);
    }
}