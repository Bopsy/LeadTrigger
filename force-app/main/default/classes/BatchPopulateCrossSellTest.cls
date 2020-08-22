@isTest
private class BatchPopulateCrossSellTest{

	private static testMethod void test() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        
        AccountSID_to_SKU_Mappings__c setting = new AccountSID_to_SKU_Mappings__c(Name = 'Test Authy', Product_Name__c = 'Authy', Year__c = 2018, Usage_Field__c = 'Amortized_Usage_Authy__c', Account_SID_API_Name__c = 'Average_Authy_MRR__c');
        insert setting;
        
        
        Test.startTest();
            Database.executeBatch(new BatchPopulateCrossSell());
        Test.stopTest();
	}
    static testMethod void testScehduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        Test.startTest();
            String jobId2 = System.schedule('ScheduleApexClassTester',
                                            CRON_EXP,
                                            new BatchPopulateCrossSell());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchPopulateCrossSell') LIMIT 1].Status);
    }
}