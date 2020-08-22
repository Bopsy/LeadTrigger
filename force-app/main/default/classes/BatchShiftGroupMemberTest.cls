@isTest
private class BatchShiftGroupMemberTest {

	private static testMethod void testBatch() {
        Group_Member_Shift__c setting = new Group_Member_Shift__c(Name = 'Test', Shift__c = 'East', IsActive__c = false, TimeStamp__c = Datetime.newInstance(2017,1,1,5,30,0));
        insert setting;
        
        Assignment_Group_Name__c testGroup = new Assignment_Group_Name__c(Name = 'Test Group');
        insert testGroup;
        
        Assignment_Groups__c member = new Assignment_Groups__c(Group_Name__c = testGroup.Id, Active__c = 'True', Shift__c = 'East');
        insert member;
        
        Test.startTest();
            Database.executeBatch(new BatchShiftGroupMember());
        Test.stopTest();
        
        Assignment_Groups__c actual = [SELECT Active__c FROM Assignment_Groups__c LIMIT 1];
        system.assertEquals('False', actual.Active__c, 'The member active field should be changed to false by batch');
	}
    
    static testMethod void testScehduler(){
        String CRON_EXP = '0 0 * * * ?';
        
        Test.startTest();
            String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchShiftGroupMember());
        Test.stopTest();
        
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchShiftGroupMember') LIMIT 1].Status);
     }
}