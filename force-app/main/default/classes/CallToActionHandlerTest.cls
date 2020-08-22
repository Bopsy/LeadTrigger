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
@isTest(seeAllData=true)
private class CallToActionHandlerTest {
	static Account acc;
	static Contact con;
	static List<Use_Case__c> useCases;
	static Task existingTask;
	static JBCXM__CTA__c cta;
	static JBCXM__PickList__c jbcxmPickListOpen;
	static JBCXM__PickList__c jbcxmPickListClosed;

    static testMethod void setStatusByTask() {
        setupTestRecords();

        Test.startTest();

		// Create Task
		Task t = new Task(
			Subject = 'Call New Test Task',
			ActivityDate = System.Today(),
			WhoId = con.id,
			Status = 'Completed',
			Type = 'Call'
		);
		insert t;
		
		cta = [ SELECT JBCXM__Stage__r.Name FROM JBCXM__CTA__c WHERE Id = :cta.Id LIMIT 1 ];
		System.AssertEquals(CallToActionHandler.jbcxmPickListClosedLabel, cta.JBCXM__Stage__r.Name);

        Test.stopTest();
    }

    static testMethod void setStatusByUseCase() {
        setupTestRecords();

        Test.startTest();

		// Create Task
		List<Task> t = new List<Task>();
		t.add(new Task(
			Subject = 'Call New Test Task',
			ActivityDate = System.Today(),
			WhoId = con.id,
			Status = 'Completed',
			Type = 'Call'
		));
		t.add(new Task(
			Subject = 'Call New Test Task',
			ActivityDate = System.Today(),
			WhoId = con.id,
			Status = 'Completed',
			Type = 'Call'
		));
		insert t;
        JBCXM__Playbook__c playbook = [SELECT Id FROM  JBCXM__Playbook__c WHERE Name = 'New Managed Customer - No Email' LIMIT 1];
		// Create JBCXM__CTA__c
		cta = new JBCXM__CTA__c(
			JBCXM__Account__c = acc.Id,
			JBCXM__Stage__c = jbcxmPickListOpen.Id,
			JBCXM__CreatedDate__c = System.Today().addDays(-5),
			JBCXM__Playbook__c = playbook.Id
		);
		insert cta;
		
		// Update Use_Case__c
		Use_Case__c uc = new Use_Case__c(
            Account__c = acc.Id,
            Primary_Use_Case__c = false,
            Use_Case__c = 'UseCase Test',
            Use_Case_Notes__c = 'UseCaseNotes Test',
            Referenceable__c = true
        );
        insert uc;

		for (JBCXM__CTA__c c : [
			SELECT JBCXM__Stage__r.Name
			FROM JBCXM__CTA__c
			WHERE JBCXM__Account__c = :acc.Id
		]) {
			System.AssertEquals(CallToActionHandler.jbcxmPickListClosedLabel, c.JBCXM__Stage__r.Name);
		}

        Test.stopTest();
    }


	public class MyException extends Exception {}

    static testMethod void setStatusByTaskMissingCTAPicklistValue() {
        setupTestRecords();

        Test.startTest();

		try
		{
	        CallToActionHandler.jbcxmPickListClosedLabel = 'Bad Value 1234567890';

			// Create Task
			Task t = new Task(
				Subject = 'Call New Test Task',
				ActivityDate = System.Today(),
				WhatId = acc.id,
				WhoId = con.id,
				Status = 'Completed',
				Type = 'Call'
			);
			insert t;

			// 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
			throw new MyException('An exception should have been thrown by the trigger but was not.');
		}
		catch(Exception e)
		{
			Boolean expectedExceptionThrown =  e.getMessage().contains(CallToActionHandler.jbcxmPickListClosedLabel) ? true : false;
			System.AssertEquals(true, expectedExceptionThrown);
		} 

        Test.stopTest();
    }

    static testMethod void setStatusByUseCaseMissingCTAPicklistValue() {
        setupTestRecords();

        Test.startTest();

		try
		{
			// Create Task
			List<Task> t = new List<Task>();
			t.add(new Task(
				Subject = 'Call New Test Task',
				ActivityDate = System.Today(),
				WhoId = con.id,
				Status = 'Completed',
				Type = 'Call'
			));
			t.add(new Task(
				Subject = 'Call New Test Task',
				ActivityDate = System.Today(),
				WhoId = con.id,
				Status = 'Completed',
				Type = 'Call'
			));
			insert t;
	        JBCXM__Playbook__c playbook = [SELECT Id FROM  JBCXM__Playbook__c WHERE Name = 'New Managed Customer - No Email' LIMIT 1];
			// Create JBCXM__CTA__c
			cta = new JBCXM__CTA__c(
				JBCXM__Account__c = acc.Id,
				JBCXM__Stage__c = jbcxmPickListOpen.Id,
				JBCXM__CreatedDate__c = System.Today().addDays(-5),
				JBCXM__Playbook__c = playbook.Id
			);
			insert cta;
			
	        CallToActionHandler.jbcxmPickListClosedLabel = 'Bad Value 1234567890';

			// Update Use_Case__c
			Use_Case__c uc = new Use_Case__c(
	            Account__c = acc.Id,
	            Primary_Use_Case__c = false,
	            Use_Case__c = 'UseCase Test',
	            Use_Case_Notes__c = 'UseCaseNotes Test',
	            Referenceable__c = true
	        );
	        insert uc;

			// 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
			throw new MyException('An exception should have been thrown by the trigger but was not.');
		}
		catch(Exception e)
		{
			Boolean expectedExceptionThrown =  e.getMessage().contains(CallToActionHandler.jbcxmPickListClosedLabel) ? true : false;
			System.AssertEquals(true, expectedExceptionThrown, 'JBCMX__Picklist__c did not have: ' + CallToActionHandler.jbcxmPickListClosedLabel);
		} 

        Test.stopTest();
    }

    static public void setupTestRecords() {
		// Create Account
		acc = new Account(Name='Test Account');
		insert acc;

		// Create Contact
		con = new Contact(LastName='Test Contact', AccountId=acc.Id);
		insert con;

		// Create Use Cases
        useCases = new List<Use_Case__c>();
        for (Integer i = 0; i<10; i++) {
            useCases.add(new Use_Case__c(
                Account__c = acc.Id,
                Primary_Use_Case__c = false,
                Use_Case__c = 'UseCase ' + i,
                Use_Case_Notes__c = 'UseCaseNotes ' + i,
                Referenceable__c = true
            )); 
        }   
        insert useCases;

		// Create Task
		existingTask = new Task(
			Subject = 'Test Task',
			ActivityDate = System.Today().addDays(-1),
			WhoId = con.Id,
			Status = 'Open'
		);
		insert existingTask;
		
		// Lookup up the 'Open' picklist value so that it can be used to set
		// the Call To Action Status.
		try {
			jbcxmPickListOpen = [ SELECT Id FROM JBCXM__PickList__c WHERE Name = :CallToActionHandler.jbcxmPickListOpenLabel LIMIT 1];
		} catch (Exception e) {
			System.assert(false, 'Missing JBCXM__PickList__c value \'' + CallToActionHandler.jbcxmPickListOpenLabel + '\'');
		}

		// Lookup up the 'Event - Closed Complete' picklist value so that it can be used to set
		// the Call To Action Status.
		try {
			jbcxmPickListClosed = [ SELECT Id FROM JBCXM__PickList__c WHERE Name = :CallToActionHandler.jbcxmPickListClosedLabel LIMIT 1];
		} catch (Exception e) {
			System.assert(false, 'Missing JBCXM__PickList__c value \'' + CallToActionHandler.jbcxmPickListClosedLabel + '\'');
		}
        JBCXM__Playbook__c playbook = [SELECT Id FROM  JBCXM__Playbook__c WHERE Name = 'New Managed Customer - No Email' LIMIT 1];
		// Create JBCXM__CTA__c
		cta = new JBCXM__CTA__c(
			JBCXM__Account__c = acc.Id,
			JBCXM__Stage__c = jbcxmPickListOpen.Id,
			JBCXM__CreatedDate__c = System.Today().addDays(-5),
			JBCXM__Playbook__c = playbook.Id
		);
		insert cta;
    }
}