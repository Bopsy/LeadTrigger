@isTest
private class PersonMergeServicesTest {

    private static testMethod void testContact() {
        Contact testContact1 = new Contact(LastName = 'Tester1', Email='tester1@tester1.com', Profile_Score__c = 15, Engagement_Score__c = 100);
        insert testContact1;
        
        Contact testContact2 = new Contact(LastName = 'Tester2', Email='tester2@tester1.com', Profile_Score__c = 25, Engagement_Score__c = 40);
        insert testContact2;
        
        Test.startTest();
            database.merge(testContact1, testContact2);
        Test.stopTest();
        
        testContact1 = [SELECT Profile_Score__c, Engagement_Score__c FROM Contact LIMIT 1];
        system.assertEquals(testContact1.Profile_Score__c, 25, 'Profile Score should use the highest one');
        system.assertEquals(testContact1.Engagement_Score__c, 140, 'Engagment Score should add together');
    }
    
    private static testMethod void testLead() {
        Lead testLead1 = new Lead(LastName = 'Tester1', Company = 'Test Company', Email='tester1@tester1.com', Profile_Score__c = 15, Engagement_Score__c = 100);
        insert testLead1;
        
        Lead testLead2 = new Lead(LastName = 'Tester2', Company = 'Test Company', Email='tester2@tester1.com', Profile_Score__c = 25, Engagement_Score__c = 40);
        insert testLead2;
        
        Test.startTest();
            database.merge(testLead1, testLead2);
        Test.stopTest();
        
        testLead1 = [SELECT Profile_Score__c, Engagement_Score__c FROM Lead LIMIT 1];
        system.assertEquals(testLead1.Profile_Score__c, 25, 'Profile Score should use the highest one');
        system.assertEquals(testLead1.Engagement_Score__c, 140, 'Engagment Score should add together');
    }

}