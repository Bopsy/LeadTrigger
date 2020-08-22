@isTest
private class TaskAfterTriggerTest {

	private static testMethod void test() {
	    
	    Campaign testCampaign = new Campaign(Name = 'Test');
	    insert testCampaign;
	    Lead testLead = new Lead(LastName = 'Tester', Company = 'Test Company');
	    insert testLead;
	    List<User> users = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true];
        Task testTask = new Task(Subject = 'ISL Call', OwnerId =  users[0].Id, WhoId = testLead.Id, Campaign_Id_Stamp__c = testCampaign.Id);
        insert testTask;
        
        Test.startTest();
            testTask.OwnerId = users[1].Id;
            update testTask;
        Test.stopTest();
	}

}