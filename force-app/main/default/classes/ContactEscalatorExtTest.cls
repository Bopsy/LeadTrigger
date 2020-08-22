@isTest
private class ContactEscalatorExtTest {

	private static testMethod void test() {
        Account testAcc = new Account(Name = 'Test');
        insert testAcc;
        
        ApexPages.standardController stdCtrl = new  ApexPages.standardController(testAcc);
        
        Test.startTest();
            ContactEscalatorExt ext = new ContactEscalatorExt(stdCtrl);
            ext.getAccountList();
            ext.getType();
            ContactEscalatorExt.saveEscalator(JSON.serialize(new List<Contact_Escalation__c>{}), testAcc.Id);
        Test.stopTest();
	}

}