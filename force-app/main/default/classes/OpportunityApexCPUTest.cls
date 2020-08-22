@istest
public class OpportunityApexCPUTest {
    
    @istest
    public static void testApexCPUCheck() {
        
        try {
            List<Opportunity> theOppList = new List<Opportunity>();
            
            //Account testAcc = new Account();
            //testAcc.Name = 'test Account';
            //insert testAcc;
            Id OppRecordTypeID = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName().get('Direct Sales').getRecordTypeId();
            
            for(Integer i=0;i<225;i++){
                
                Opportunity testOpp =  new Opportunity();
                //testOpp.RecordTypeId = OppRecordTypeID;
                testOpp.StageName = 'Qualified';
                testOpp.Name = 'testOppConsulting';
                testOpp.Type = 'New Buisness';
                //testOpp.AccountId = testAcc.Id;
                testOpp.Amount = 0;
                testOpp.CloseDate = system.today().addDays(2);
                testOpp.Launch_Date__c = system.today();
                // insert testOpp;
                theOppList.add(testOpp);    
            }
            
            test.startTest();
            insert theOppList;
            //system.debug('Limits.getCPUTime=>'+Limits.getCpuTime());
            test.stopTest();
            
            //system.debug('theOppList=>'+theOppList);
        }
        catch(Exception e) {
            //eaddError('Error is '+e.getMessage());
            System.debug('in catch '+ e.getMessage());
        }
        
    }
}