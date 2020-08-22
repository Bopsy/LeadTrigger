@isTest
private class SuperNetworkChildAccountsControllerTest {

	private static testMethod void test() {
        Account testAcc = new Account(Name = 'Test');
        insert testAcc;
        
        Account testChildAcc = new Account(Name = 'Test Child', ParentId = testAcc.Id);
        insert testChildAcc;
        
        ApexPages.standardController stdCtrl = new ApexPages.standardController(testAcc);
        
        Test.startTest();
            SuperNetworkChildAccountsController ext = new SuperNetworkChildAccountsController(stdCtrl);
        Test.stopTest();
	}

}