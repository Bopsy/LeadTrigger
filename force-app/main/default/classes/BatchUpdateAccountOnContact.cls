//----------------------------------------------------------------------------------------------------------
// Batch class for update account on contact
//----------------------------------------------------------------------------------------------------------
global class BatchUpdateAccountOnContact implements Database.Batchable<sObject>, Schedulable {
	//----------------------------------------------------------------------------------------------------------
	// Start
	//----------------------------------------------------------------------------------------------------------
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT Id, Account_SID__c, AccountId FROM Contact Where AccountId = null AND Account_SID__c != null');
	}
	
	//----------------------------------------------------------------------------------------------------------
	// Execute of Batchable
	//----------------------------------------------------------------------------------------------------------
	global void execute(Database.BatchableContext info, List<sObject> scope) {
		List<Contact> lstContact = (List<Contact>)scope;
		ContactTriggerHandler.populateAccount(lstContact);
		update lstContact;
	}
	
	//----------------------------------------------------------------------------------------------------------
	// Finish
	//----------------------------------------------------------------------------------------------------------
	global void finish(Database.BatchableContext info) {
		
	}
	
	//----------------------------------------------------------------------------------------------------------
	// Execute of Schedulable
	//----------------------------------------------------------------------------------------------------------
	global void execute(System.SchedulableContext SC) {
		Database.executeBatch(new BatchUpdateAccountOnContact());
	}
}