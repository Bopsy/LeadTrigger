@isTest
private class AssetBasedQuotingServicesTest {

	private static testMethod void test() {
        Account newAcct = new Account(Name = 'Test');
        insert newAcct;
        
        Opportunity newOpp = new Opportunity(Name = 'Test Opp', StageName = 'Incubate', CloseDate = Date.today(), Launch_Date__c = Date.today(), Amount = 1200, AccountId = newAcct.Id, FY_16_Primary_Product__c = 'Programmable Messaging');
        insert newOpp;
        
        Account_SID__c testSID = new Account_SID__c(Account_SID__c = 'AC123');
        insert testSID;
        
        Test.startTest();
            insert new Opp_SID_SKU__c(Opportunity__c = newOpp.Id, Account_SID__c = testSID.Id);
        Test.stopTest();
	}

}