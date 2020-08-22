@isTest
private class BatchCalculateLaunchDateTest {

  private static testMethod void testBatch() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        Account_SID__c sid = new Account_SID__c(Name = 'Test SID');
        insert sid;
        Opportunity opp = new Opportunity(Name = 'Test opp', Amount = 10000, FY_16_Primary_Product__c = 'Programmable Messaging', CloseDate = Date.today(), Launch_Date__c = Date.today().addMonths(1), StageName = 'Closed Won', New_Business_Account_SID_Lookup__c = sid.Id);
        insert opp;
        Twilio_Usage__c usage = new Twilio_Usage__c(Related_Account_SID__c = sid.Id, Amortized_Usage_Authy__c = 2000, Month__c = Date.today().month(), Year__c = Date.today().year(), Product__c = 'Test', AccountSid__c = 'Test SID', Currency__c = 'USD', Total__c = 0);
        insert usage;
        AccountSID_to_SKU_Mappings__c setting = new AccountSID_to_SKU_Mappings__c(Name = 'Test Authy', Product_Name__c = 'Programmable Messaging', Usage_Field__c = 'Amortized_Usage_Authy__c', Account_SID_API_Name__c = 'Average_Authy_MRR__c');
        insert setting;
        
        Test.startTest();
            Database.executeBatch(new BatchCalculateLaunchDate());
        Test.stopTest();
  }

}