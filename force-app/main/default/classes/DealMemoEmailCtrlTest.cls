@isTest
private class DealMemoEmailCtrlTest {

	private static testMethod void testVariables() {
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Opportunity opp = new Opportunity(Name = 'Test Opp', CloseDate = Date.today(), StageName = 'Incubate', Amount = 10, eARR_post_Launch__c = 10);
        insert opp;
        
        Deal_Memo__c memo = new Deal_Memo__c(Opportunity__c = opp.Id, Deal_Memo_Attribution_Type__c = 'Test', Sales_Ops_Notes__c = 'This is a test');
        insert memo;
        
        List<User> users = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 2];
        Deal_Memo_Recipient__c recipient1 = new Deal_Memo_Recipient__c(Opportunity__c = opp.Id, Deal_Memo__c = memo.Id, Deal_Memo_Recipient__c = users[0].Id, Percent_Attributed__c = 60);
        Deal_Memo_Recipient__c recipient2 = new Deal_Memo_Recipient__c(Opportunity__c = opp.Id, Deal_Memo__c = memo.Id, Deal_Memo_Recipient__c = users[1].Id, Percent_Attributed__c = 40);
        insert new List<Deal_Memo_Recipient__c>{recipient1, recipient2};
        
        Test.startTest();
            
            DealMemoEmailCtrl testCtrl = new DealMemoEmailCtrl();
            testCtrl.dealMemoId = memo.Id;
            Deal_Memo__c relatedTo = testCtrl.relatedTo;
            List<Deal_Memo_Recipient__c> recipients = testCtrl.recipients;
        Test.stopTest();
	}

}