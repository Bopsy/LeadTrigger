@isTest
private class OppSIDSKUTest {

	private static testMethod void test() {
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', AccountId = testAcc.Id, CloseDate = Date.today(), StageName = 'Incubate', FY_16_Primary_Product__c = 'Programmable Messaging', FY_16_Primary_Sub_Product__c = 'SMS Message');
        insert testOpp;
        
        Account_SID__c testSid = new Account_SID__C(Name = 'Test ACC SID');
        insert testSid;
        
        Opp_SID_SKU__c testSKU = new Opp_SID_SKU__c(Opportunity__c = testOpp.Id, Account_SID__c = testSid.Id);
        insert testSKU;
        
        Test.startTest();
            delete testSKU;
        Test.stopTest();
        
	}

}