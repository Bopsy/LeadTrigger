/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchRollupSendGridAccountsNamerAndLatamTest
*
* @description    Test class for BatchRollupSendGridAccountsNamerAndLatam
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
public class BatchRollupSendGridActsNamerAndLatamTest {

    @testSetup static void setup(){
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
       
        UserRole ur = new UserRole(Name = 'test NAMER');
        insert ur;
        User tuser = new User(  firstname = 'fName',
                                lastName = 'lName',
                                email = 'fName@testlName.org',
                                Username = 'fName@testlName.org',
                                EmailEncodingKey = 'ISO-8859-1',
                                Alias = 'fNam2lNa',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US',
                                ProfileId = pf.Id,
                                UserRoleId = ur.Id);
       
        System.runAs(tuser)
        {
            Account testAcc = new Account(Name = 'Test Acc');
            insert testAcc;
            SendGrid_Account__c testSG1 = new SendGrid_Account__c(Account__c = testAcc.Id, Major_Account__c=true, Invoice_Total_Last_Month__c = 1);
            SendGrid_Account__c testSG2 = new SendGrid_Account__c(Account__c = testAcc.Id, Portfolio_Account__c=true, Invoice_Total_Last_Month__c = 1);
            SendGrid_Account__c testSG3 = new SendGrid_Account__c(Account__c = testAcc.Id, Invoice_Total_Last_Month__c = 1);
            SendGrid_Account__c testSG4 = new SendGrid_Account__c(Account__c = testAcc.Id, Invoice_Total_Last_Month__c = 1);
            insert new List<SendGrid_Account__c>{testSG1, testSG2, testSG3, testSG4};
        }
        
    }
    
    static testMethod void testBatchRollupSendGridAccounts(){
        test.startTest();
        BatchRollupSendGridAccountsNamerAndLatam bcn = new BatchRollupSendGridAccountsNamerAndLatam() ;
        ID batchprocessid = Database.executeBatch(bcn);
        test.stopTest();
        Account testAcc = [SELECT Number_of_SendGrid_Accounts__c,SendGrid_Major_Account__c,SendGrid_Portfolio_Account__c FROM Account LIMIT 1];
        system.assertEquals(4, testAcc.Number_of_SendGrid_Accounts__c);
        system.assertEquals(true, testAcc.SendGrid_Major_Account__c);
        system.assertEquals(true, testAcc.SendGrid_Portfolio_Account__c);
    }
    
    static testMethod void testScheduler(){
        String CRON_EXP = '0 0 * * * ?';
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchRollupSendGridAccountsNamerAndLatam());
        Test.stopTest();
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchRollupSendGridAccountsNamerAndLatam') LIMIT 1].Status);
    }
    
    static testMethod void testBatch(){
        Test.startTest();
        Database.executeBatch(new BatchRollupSendGridAccountsNamerAndLatam());
        Test.stopTest();
        
        Account testAcc = [SELECT Number_of_SendGrid_Accounts__c,SendGrid_Major_Account__c,SendGrid_Portfolio_Account__c FROM Account LIMIT 1];
        system.assertEquals(4, testAcc.Number_of_SendGrid_Accounts__c);
        system.assertEquals(true, testAcc.SendGrid_Major_Account__c);
        system.assertEquals(true, testAcc.SendGrid_Portfolio_Account__c);
    }
}