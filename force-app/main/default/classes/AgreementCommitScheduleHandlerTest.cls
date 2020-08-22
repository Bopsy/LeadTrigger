@isTest
private class AgreementCommitScheduleHandlerTest {

	private static testMethod void testAfterInsert() {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement', Commit_Frequency__c = 'Monthly', Term_Range__c = '12', Total_Committed_Revenue_Input__c = 1200);
        
        Test.startTest();
            insert agreement;
        Test.stopTest();
	}
    
    private static testMethod void testAfterUpdate() {
        
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement', Commit_Frequency__c = 'Monthly', Term_Range__c = '12', Total_Committed_Revenue_Input__c = 1200);

        insert agreement;
        Test.startTest();
           agreement.Commit_Frequency__c = 'Quarterly';
           agreement.Other_Minimum_Commit__c = 20000;
           agreement.Commit_Type__c = 'Product';
           update agreement;
           agreement.Commit_Type__c = 'Global';
           update agreement;
        Test.stopTest();
	}
}