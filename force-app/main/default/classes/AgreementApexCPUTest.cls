@isTest
public class AgreementApexCPUTest {
    
     @istest
    public static void testApexCPUCheck() {
        
        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'TestOppBulky';
        testOpp.Description = 'ApexCPU';
        testOpp.CloseDate = system.today();
        //theOpp.Launch_Date__c = system.today();
        testOpp.StageName = 'Incubate';
        testOpp.Owner_Name__c = 'Ashish Aggarwal';
        testOpp.Solution_Category__c = 'Account Security';
        insert testOpp;
        
        List<Apttus__APTS_Agreement__c> theAptusList = new List<Apttus__APTS_Agreement__c>();
        for(Integer i=0;i<270;i++){
            Apttus__APTS_Agreement__c testAgremnt = new Apttus__APTS_Agreement__c();
            testAgremnt.Name = 'Agrename'+i;
            testAgremnt.Related_Opportunity_APTS__c = testOpp.Id;
            testAgremnt.Use_Case_Description__c	 = 'Desciption';
            theAptusList.add(testAgremnt);
        }
        insert theAptusList;
		    
        system.debug('limitsEnd=>'+limits.getCpuTime());
    }
}