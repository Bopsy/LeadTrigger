/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchCalculateUsageNamerAndLatamTest
*
* @description    Test class for BatchCalculateUsageNamerAndLatam
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2018-05-06
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class BatchCalculateUsageNamerAndLatamTest {

    @testSetup static void setup(){
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
       
        UserRole ur = new UserRole(Name = 'test LATAM');
        insert ur;
        User tuser = new User(  firstname = 'fName3',
                                lastName = 'lName3',
                                email = 'fName@test4lName.org',
                                Username = 'fName@test4lName.org',
                                EmailEncodingKey = 'ISO-8859-1',
                                Alias = 'fNam4lNa',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US',
                                ProfileId = pf.Id,
                                UserRoleId = ur.Id);
       
        System.runAs(tuser)
        {
            Account testAcc = new Account(Name = 'Test Acc');
            insert testAcc;
            Account_SID__c testAccSID = new Account_SID__c (Name = 'Test Account SID', Account__c = testAcc.Id);
            insert testAccSID;
            
            Twilio_Usage__c usage1 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = Date.today().month(), Finance_Amortized_Billings__c = 10.00, Total__c = 10.00);
            Twilio_Usage__c usage2 = new Twilio_Usage__c(AccountLookup__c = testAcc.Id, AccountSid__c = 'Test Account SID', Related_Account_SID__c = testAccSID.Id, Currency__c = 'USD', Product__c = 'Test Prod', Year__c = Date.today().year(), Month__c = Date.today().month(), Finance_Amortized_Billings__c = 20.00, Total__c = 10.00);
            insert new List<Twilio_Usage__c>{usage1, usage2};
        }
        
    }
    
    static testMethod void testBatch(){        
        Test.startTest();
            Database.executeBatch(new BatchCalculateUsageNamerAndLatam());
        Test.stopTest();
        
        Account acc = [SELECT Total_Amortized_Twilio_Usage_This_Month__c FROM Account LIMIT 1];
        system.assertEquals(30, acc.Total_Amortized_Twilio_Usage_This_Month__c, 'the total amortized usage should be calculated correctly');
    }
    
    static testMethod void testScehduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        Test.startTest();
            String jobId2 = System.schedule('ScheduleApexClassTester',
                                            CRON_EXP,
                                            new BatchCalculateUsageNamerAndLatam());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchCalculateUsageNamerAndLatam') LIMIT 1].Status);
    }
}