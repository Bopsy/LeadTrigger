@isTest
private class BatchRollupTwilioOrgCampaignMemberTest {

	private static testMethod void testBatch() {
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Campaign testCampaign = new Campaign(Name = 'twilio.org');
        insert testCampaign;
        
        Contact testContact1 = new Contact(LastName = 'tester1', AccountId = testAcc.Id);
        Contact testContact2 = new Contact(LastName = 'tester2', AccountId = testAcc.Id);
        Contact testContact3 = new Contact(LastName = 'tester3', AccountId = testAcc.Id);
        Contact testContact4 = new Contact(LastName = 'tester4', AccountId = testAcc.Id);
        Contact testContact5 = new Contact(LastName = 'tester5', AccountId = testAcc.Id);
        insert new List<Contact>{testContact1, testContact2, testContact3, testContact4, testContact5};
        
        
        CampaignMember testMember1 = new CampaignMember(ContactId = testContact1.Id, CampaignId = testCampaign.Id, Status = 'Accepted');
        CampaignMember testMember2 = new CampaignMember(ContactId = testContact2.Id, CampaignId = testCampaign.Id, Status = 'Applied');
        CampaignMember testMember3 = new CampaignMember(ContactId = testContact3.Id, CampaignId = testCampaign.Id, Status = 'Pending');
        CampaignMember testMember4 = new CampaignMember(ContactId = testContact4.Id, CampaignId = testCampaign.Id, Status = 'Re-applied');
        CampaignMember testMember5 = new CampaignMember(ContactId = testContact5.Id, CampaignId = testCampaign.Id, Status = 'Rejected');
        insert new List<CampaignMember>{testMember1, testMember2, testMember3, testMember4, testMember5};
        
        Test.startTest();
            Database.executeBatch(new BatchRollupTwilioOrgCampaignMember());
        Test.stopTest();
	}

}