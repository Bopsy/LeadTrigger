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
private class OpportunitySnapshotTest {
    
    // CRON expression: midnight on March 15. 
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    static List<Opportunity> opptyList;
    static Account acc;
   
    static testMethod void batchTest() {
        Date pastDate = Date.today().addMonths(-3);
        //setupTestRecords();
        System.debug(JSON.serializePretty([ SELECT Id, Type, CloseDate, StageName, ForecastCategoryName FROM Opportunity ]));
        List<Opportunity_Snapshot__c> snapshotRecs = new List<Opportunity_Snapshot__c>();
        snapshotRecs = [SELECT Id, CreatedDate FROM Opportunity_Snapshot__c];
        for(Opportunity_Snapshot__c snapshotRec : snapshotRecs){
            System.assert(pastDate > snapshotRec.CreatedDate);
            System.assert(Date.today() != snapshotRec.CreatedDate.Date());
        }
        System.assert(!snapshotRecs.isEmpty());
        
        Test.startTest();
        Database.executeBatch(new OpportunitySnapshot());
        Test.stopTest();
        
		List<Opportunity_Snapshot__c> snapshotRecsPostBatch = new List<Opportunity_Snapshot__c>();
        snapshotRecsPostBatch = [SELECT Id, CreatedDate FROM Opportunity_Snapshot__c];
        for(Opportunity_Snapshot__c snapshotRec : snapshotRecsPostBatch){
            System.assertEquals(Date.today(), snapshotRec.CreatedDate.Date());
        }
        System.assert(!snapshotRecsPostBatch.isEmpty());
        
    }
    
    static testMethod void scheduleTest() {
        //setupTestRecords();
        
        Test.startTest();
        
        // Schedule the test job
        String jobId = System.schedule('OpportunitySnapshot', CRON_EXP, new OpportunitySnapshot());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [ SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId ];
        
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
        
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run 
        System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
        
        Test.stopTest();
    }
    @testSetup static void setup(){
    //static void setupTestRecords() {
        List<Opportunity_Snapshot_Field_Mappings__c> fieldMappingList = new List<Opportunity_Snapshot_Field_Mappings__c>();
        fieldMappingList.add(new Opportunity_Snapshot_Field_Mappings__c(
        	Name = 'CloseDate',
        	Opportunity_API_Name__c = 'CloseDate',
        	Opportunity_Snapshot_API_Name__c = 'Close_Date__c'
        ));
        fieldMappingList.add(new Opportunity_Snapshot_Field_Mappings__c(
        	Name = 'ForecastCategory',
        	Opportunity_API_Name__c = 'ForecastCategoryName',
        	Opportunity_Snapshot_API_Name__c = 'Forecast_Category__c'
        ));
        fieldMappingList.add(new Opportunity_Snapshot_Field_Mappings__c(
        	Name = 'Account Name',
        	Opportunity_API_Name__c = 'Account.Name',
        	Opportunity_Snapshot_API_Name__c = 'Account_Name_Text__c'
        ));
        insert fieldMappingList;

        List<Opportunity_Snapshot_Criteria__c> criteriaList = new List<Opportunity_Snapshot_Criteria__c>();
        criteriaList.add(new Opportunity_Snapshot_Criteria__c(
        	Name = 'CloseDate',
        	Opportunity_API_Name__c = 'CloseDate',
        	Type__c = 'date',
        	Min_Date__c = Date.today().addDays(-5),
        	Max_Date__c = Date.today().addDays(5)
        ));
        criteriaList.add(new Opportunity_Snapshot_Criteria__c(
        	Name = 'ForecastCategory',
        	Opportunity_API_Name__c = 'ForecastCategoryName',
        	Type__c = 'picklist',
        	Value__c = 'Omitted;Pipeline;Best Case;Commit;Closed'
        ));
        insert criteriaList;
        
        acc = new Account(Name = 'TESTACCOUNT');
        insert acc;
        
        opptyList = new List<Opportunity>();

		Id newBusinessRecTypeId = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Direct Sales').RecordTypeId;
		
		// Meets criteria
        opptyList.add(new Opportunity(
            Name = 'TESTOPPTY-BestCase-InsideCloseDateRange',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            Type = 'Open',
            StageName = 'Validate Solution',
			//ForecastCategoryName = 'Pipeline',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        ));

        opptyList.add(new Opportunity(
            Name = 'TESTOPPTY-BestCase-InsideCloseDateLowerRange',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(-5),
            Type = 'Open',
            StageName = 'Validate Solution',
			//ForecastCategoryName = 'Pipeline',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        ));

        opptyList.add(new Opportunity(
            Name = 'TESTOPPTY-BestCase-InsideCloseDateUpperRange',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(5),
            Type = 'Open',
            StageName = 'Validate Solution',
			//ForecastCategoryName = 'Pipeline',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        ));

		// Does not meet criteria - outside of CloseDate range (less than range)
        opptyList.add(new Opportunity(
            Name = 'TESTOPPTY-BestCase-OutsideCloseDateRange',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(-10),
            Type = 'Open',
            StageName = 'Validate Solution',
			//ForecastCategoryName = 'Pipeline',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        ));

		// Does not meet criteria - outside of CloseDate range (greater than range)
        opptyList.add(new Opportunity(
            Name = 'TESTOPPTY-BestCase-OutsideCloseDateRange',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(10),
            Type = 'Open',
            StageName = 'Validate Solution',
			//ForecastCategoryName = 'Pipeline',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        ));

		// Does not meet criteria - not in ForecastCategory picklist
        opptyList.add(new Opportunity(
            Name = 'TESTOPPTY-Pipeline-InsideCloseDateRange',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            Type = 'Open',
            StageName = 'Qualified',
			//ForecastCategoryName = 'Omitted',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        ));

		// Does not meet criteria - not in ForecastCategory picklist and outside of CloseDate range
        opptyList.add(new Opportunity(
            Name = 'TESTOPPTY-Pipeline-InsideCloseDateRange',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(-10),
            Type = 'Open',
            StageName = 'Qualified',
			//ForecastCategoryName = 'Omitted',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        ));

        insert opptyList;     
        
        Date pastDate = Date.today().addMonths(-4);
        Integer numberOfSnapshotRecs = 4;
        List<Opportunity_Snapshot__c> snapshotRecsForInsert = new List<Opportunity_Snapshot__c>();
        for(Integer i = 0; i < numberOfSnapshotRecs; i++){
            Opportunity_Snapshot__c snapshotRec = new Opportunity_Snapshot__c(Name = 'Test ' + i);
            snapshotRecsForInsert.add(snapshotRec);
        }
        insert snapshotRecsForInsert;
        
        for(Opportunity_Snapshot__c snapshotRec : snapshotRecsForInsert){
            Test.setCreatedDate(snapshotRec.Id, pastDate);
        }
    }
}