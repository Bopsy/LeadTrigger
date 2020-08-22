public with sharing class BatchCopySetupAuditTrail implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
	public Boolean simulateInsertError = false;
	public Boolean simulateExistingRecord = false;
	
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Generate a list of records to batch process
        Date YESTERDAY = Date.today().addDays(-1);
        return Database.getQueryLocator(
            'SELECT Id, Action, DelegateUser, Display, Section, CreatedDate, CreatedBy.Id ' +
            'FROM SetupAuditTrail WHERE CreatedDate >=: YESTERDAY ' +
            (Test.isRunningTest() ? 'LIMIT 1' : '')
        );
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        // Build a map of the Setup Audit Trail records
        Map<Id,SetupAuditTrail> auditTrail = new Map<Id,SetupAuditTrail>();
        for (SetupAuditTrail a : (List<SetupAuditTrail>)scope) {
            auditTrail.put(a.Id, a);
        }
        System.debug('AuditTrail IDs = ' + auditTrail.keySet());
        
        // For test coverage add the first record in the batch to test deduplication
        if (simulateExistingRecord) {
        	insert new Twilio_Audit__c(Object_Id__c = scope[0].Id);
        }
                        
        // Prevent duplication by checking to see if the Twilio audit record
        // already exists for the Setup Audit record and remove it from our
        // Setup Audit record map
        List<Twilio_Audit__c> auditTrailCopy = new List<Twilio_Audit__c>();
        for (Twilio_Audit__c t : [
            SELECT Object_Id__c
            FROM Twilio_Audit__c
            WHERE Object_Id__c IN :auditTrail.keySet()
        ]) {
            auditTrail.remove(t.Object_Id__c);
        }
        
        // Create copies of the remaining Twilio audit records and insert them
        for (SetupAuditTrail a : auditTrail.values()) {
            System.debug('ADDING = ' + a);
            auditTrailCopy.add(new Twilio_Audit__c(
                Object_Id__c = a.Id,
                Action__c = a.Action,
                DelegateUser__c = a.DelegateUser,
                Display__c = a.Display,
                Section__c = a.Section,
                Audit_TimeStamp__c = a.CreatedDate,
                User__c = a.CreatedBy.Id
            ));
        }
        
        // For test coverage of exception handling force an insert error is enabled
        if (simulateInsertError) {
        	auditTrailCopy.add(new Twilio_Audit__c(Object_Id__c = 'TEST'.rightPad(50000, '1234567890')));
        }
        
        List<Database.SaveResult> saveResults = Database.insert(auditTrailCopy, false);
        
		// Aggragate any errors and throw a meaning exception
	    String errorMsg = '';
		for (Integer saveResultIndex = 0; saveResultIndex < saveResults.size(); saveResultIndex++) {
			if (!saveResults[saveResultIndex].isSuccess()) {
				for (Database.Error err : saveResults[saveResultIndex].getErrors()) {
					errorMsg += 'The following error has occurred with id: ' + auditTrailCopy[saveResultIndex].Id
						+ '\n' + err.getStatusCode() + ': ' + err.getMessage()
						+ '\n Fields that affected this error: ' + err.getFields()
						+ '\n -------------------------------------------------------';
				}
			}
		}

		// If the errorMsg is not empty and the error is not be simulated then throw an exception
		if (String.isNotBlank(errorMsg) && !simulateInsertError) {
			throw new CustomBatchInsertException(errorMsg);
		}
    }
    
    public void finish(Database.BatchableContext BC) {
        // Actions to perform when batch processing is finished
    }

    // Schedulable Interface Method
    public void execute(SchedulableContext context) {
    	// Run the batch with a size of 2000 records instead of the default of 200
        database.executebatch(new BatchCopySetupAuditTrail(), 2000);
    }

	public class CustomBatchInsertException extends Exception {}
}