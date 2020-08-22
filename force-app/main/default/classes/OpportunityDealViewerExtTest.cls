@isTest
private class OpportunityDealViewerExtTest {
    static testMethod void testConstructor(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Deal__c testDeal = new Deal__c(Name = 'Test Deal', Account__c = testAcc.Id);
        insert testDeal;
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', CloseDate = Date.today(), StageName = 'Incubate', Deal__c = testDeal.Id, AccountId = testAcc.Id);
        insert testOpp;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        Test.startTest();
            OpportunityDealViewerExt ctrl = new OpportunityDealViewerExt(sc);
            ctrl.getPrimaryProducts();
            Deal__c dealName = ((List<Deal__c>) JSON.deserialize(ctrl.getDealNames(), List<Deal__c>.class))[0];
            Opportunity newOpp = new Opportunity(Name = 'Test Opp', CloseDate = Date.today(), StageName = 'Incubate', Deal__c = testDeal.Id, AccountId = testAcc.Id);
            OpportunityDealViewerExt.addOpp(JSON.serialize(newOpp));
            OpportunityDealViewerExt.saveOpp(JSON.serialize(new List<Opportunity>{testOpp}));
            OpportunityDealViewerExt.updateOpp(JSON.serialize(testOpp), JSON.serialize(testDeal), null);
        Test.stopTest();
    }
}