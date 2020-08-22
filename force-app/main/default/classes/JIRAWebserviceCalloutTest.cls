@isTest
private class JIRAWebserviceCalloutTest {
    
	private static testMethod void testCallout() {
        Test.setMock(HttpCalloutMock.class, new MockHttpJirqResponse());
        
        Opportunity_Milestone__c testOne = new Opportunity_Milestone__c(JIRA_ID__c = 'TL-1234');
        Test.startTest();
            insert testOne;
            testOne.JIRA_ID__c = 'TL-2345';
            update testOne;
        Test.stopTest();
	}

    private static testMethod void testBatch(){
        Test.setMock(HttpCalloutMock.class, new MockHttpJirqResponse());
        
        Opportunity_Milestone__c testOne = new Opportunity_Milestone__c(JIRA_ID__c = 'TL-1234');
        insert testOne;
        
        Test.startTest();
            Database.executeBatch(new BatchUpdateJIRATicket());
        Test.stopTest();
    }
    
    private static testMethod void testScheduler(){
        Test.setMock(HttpCalloutMock.class, new MockHttpJirqResponse());
        
        Opportunity_Milestone__c testOne = new Opportunity_Milestone__c(JIRA_ID__c = 'TL-1234');
        insert testOne;
        
        String CRON_EXP = '0 0 * * * ?';
        
        Test.startTest();
            String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchUpdateJIRATicket());
        Test.stopTest();
    }
}