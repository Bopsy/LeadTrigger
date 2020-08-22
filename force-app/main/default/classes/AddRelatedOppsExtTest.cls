@isTest
private class AddRelatedOppsExtTest {
    static testMethod void testConstructor(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', CloseDate = Date.today(), StageName = 'Incubate', AccountId = testAcc.Id);
        insert testOpp;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        Test.startTest();
            AddRelatedOppsExt ctrl = new AddRelatedOppsExt(sc);
            ctrl.addNewOpp();
        Test.stopTest();
    }
}