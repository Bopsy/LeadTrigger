@isTest
private class BatchAlignMRRTest {
   private static testMethod void test() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        Account_SID__c sid = new Account_SID__c(Name = 'Test SID');
        insert sid;
       
        Twilio_Usage__c usage = new Twilio_Usage__c(Related_Account_SID__c = sid.Id, Month__c = 7, Year__c = 2017, Product__c = 'Test', AccountSid__c = 'Test SID', Currency__c = 'USD', Total__c = 0);
        insert usage;
        AccountSID_to_SKU_Mappings__c setting = new AccountSID_to_SKU_Mappings__c(Name = 'Test Authy', Product_Name__c = 'Authy', Year__c = 2018, Usage_Field__c = 'Amortized_Usage_Authy__c', Account_SID_API_Name__c = 'Average_Authy_MRR__c');
        insert setting;
        
        Opportunity opp = new Opportunity(Name = 'Test opp', Amount = 1200, Launch_Date__c = Date.today(), CloseDate = Date.today(), StageName = 'Incubate', New_Business_Account_SID_Lookup__c = sid.Id, FY_16_Primary_Product__c = 'Authy');
        insert opp;
        
        
        Account_SID_SKU__c sku = new Account_SID_SKU__c (Account_SID__c = sid.id, New_Business_Opportunity__c = opp.Id, Opportunity_Product__c = [SELECT Id FROM Opportunity_Product__c LIMIT 1].Id);
        insert sku;
        
        Test.startTest();
            Database.executeBatch(new BatchAlignMRR());
        Test.stopTest();
	}
    static testMethod void testScehduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        Test.startTest();
            String jobId2 = System.schedule('ScheduleApexClassTester',
                                            CRON_EXP,
                                            new BatchAlignMRR());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchAlignMRR') LIMIT 1].Status);
    }
 
}