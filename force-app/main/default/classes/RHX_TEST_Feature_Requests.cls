@isTest(SeeAllData=true)
public class RHX_TEST_Feature_Requests {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Feature_Requests__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Feature_Requests__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}