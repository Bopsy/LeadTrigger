@isTest
private class BatchCalculateMRRTest {

	private static testMethod void testBatch() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        Account_SID__c sid = new Account_SID__c(Name = 'Test SID');
        insert sid;
        Opportunity opp = new Opportunity(Name = 'Test opp', CloseDate = Date.today(), StageName = 'Incubate', New_Business_Account_SID_Lookup__c = sid.Id);
        insert opp;
        Twilio_Usage__c usage = new Twilio_Usage__c(Related_Account_SID__c = sid.Id, Month__c = 7, Year__c = 2017, Product__c = 'Test', AccountSid__c = 'Test SID', Currency__c = 'USD', Total__c = 0);
        insert usage;
        AccountSID_to_SKU_Mappings__c setting = new AccountSID_to_SKU_Mappings__c(Name = 'Test Authy', Usage_Field__c = 'Amortized_Usage_Authy__c', Account_SID_API_Name__c = 'Average_Authy_MRR__c');
        insert setting;
        
        Test.startTest();
            Database.executeBatch(new BatchCalculateMRR());
        Test.stopTest();
	}

}