@isTest
private class FeatureRequestTriggerTest {

	private static testMethod void testTrigger() {
        
        JIRA_Ticket__c ticket = new JIRA_Ticket__c(Name = 'Test', Product_Group__c = 'Super Network');
        
        Test.startTest();
            insert ticket;
            Feature_Requests__c req = new Feature_Requests__c(Name = 'Test Req', JIRA_Ticket__c = ticket.Id);
            ticket.Status__c = 'Planned';
            ticket.Target_Timeframe__c = '2HFY18';
            update ticket;
            ticket.Status__c = 'Completed';
            update ticket;
        Test.stopTest();
        
        
        
        
	}

}