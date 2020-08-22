/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class BatchAccountSetLastSDRActivityTest {
	static public User sdrUser;

    static testMethod void batchTest() {
        setupTestRecords();

        System.runAs(sdrUser) {
            Account acct = new Account(Name = 'Test Account 1');
            insert acct;

            Task tsk1 = new Task(WhatId = acct.Id, Subject = 'Email: apex test', ActivityDate = date.today().addDays(1), Status = 'Not Started');
            Task tsk2 = new Task(WhatId = acct.Id, Subject = 'Call: apex test', ActivityDate = date.today().addDays(-1), Status = 'Not Started');
            Task tsk3 = new Task(WhatId = acct.Id, Subject = 'Email: apex test', ActivityDate = date.today().addDays(-2), Status = 'Not Started');
            Task tsk4 = new Task(WhatId = acct.Id, Subject = 'Email: apex test', ActivityDate = date.today().addDays(1), Status = 'Completed');
            Task tsk5 = new Task(WhatId = acct.Id, Subject = 'Call: apex test', ActivityDate = date.today().addDays(-1), Status = 'Completed');
            Task tsk6 = new Task(WhatId = acct.Id, Subject = 'Email: apex test', ActivityDate = date.today().addDays(-2), Status = 'Completed');
            Task[] tskList = new List<Task>{ tsk1, tsk2, tsk3, tsk4, tsk5, tsk6 };
            insert tskList;
            
            Event evt1 = new Event(WhatId = acct.Id, Subject = 'Email: apex test', StartDateTime = date.today().addDays(1), EndDateTime = date.today().addDays(1));
            Event evt2 = new Event(WhatId = acct.Id, Subject = 'Call: apex test', StartDateTime = date.today().addDays(-1), EndDateTime = date.today().addDays(-1));
            Event evt3 = new Event(WhatId = acct.Id, Subject = 'Email: apex test', StartDateTime = date.today().addDays(-2), EndDateTime = date.today().addDays(-2));
            Event[] evtList = new List<Event>{ evt1, evt2, evt3 };
            insert evtList;
        }

        Test.startTest();
		Database.executeBatch(new BatchAccountSetLastSDRActivity());
        Test.stopTest();
    }

    static public void setupTestRecords() {
        Profile p = [Select Id, Name from Profile where name = 'Standard User'];
        UserRole ur = new UserRole(Name = 'SDR Test');
        insert ur;
        
        sdrUser = new User(
            ProfileId = p.Id,
            UserRoleId = ur.Id,
            Username = System.now().getTime() + 'test@test.com',
            Alias = 'testtest',
            Email='test@test-lead-autoconvert-12345.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'Test',
            Lastname = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        insert sdrUser;   
    }
}