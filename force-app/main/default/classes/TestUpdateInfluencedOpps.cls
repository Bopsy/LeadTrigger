@isTest
private class TestUpdateInfluencedOpps {
    
    static final Id accountRTId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Partner' LIMIT 1].Id;
    
    static final Id opptyRTId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Technology_Partner' LIMIT 1].Id;
    
    static final Id pfRTId = [SELECT Id FROM RecordType WHERE SobjectType = 'Partner_Forecast__c' AND DeveloperName = 'Revenue' LIMIT 1].Id;
    
    static final Id pfTCVRTId = [SELECT Id FROM RecordType WHERE SobjectType = 'Partner_Forecast__c' AND DeveloperName = 'TCV' LIMIT 1].Id;
    
    @isTest static void TestUpdateInfluencedOpps() {
        // Test data setup
        // Create an account with an opportunity, and then try to delete it
        Account acct = new Account(Name='Test Account', RecordTypeId= accountRTId);
        insert acct;
        Opportunity opp = new Opportunity(Name=acct.Name + ' Opportunity',
                                       StageName='Prospecting',
                                       CloseDate=System.today().addMonths(1),
                                       AccountId=acct.Id, RecordTypeId= opptyRTId);
        insert opp;
        
        
        // Perform test
        Test.startTest();
        Partner_Forecast__c pf = new Partner_Forecast__c(Fiscal_Period_Revenue__c = 'FY18 Q2', RecordTypeId=pfRTId, Close_Date__c = System.today(), Opportunity__c = opp.Id, Total_Amount__c = 12345.00);
        insert pf;
        Partner_Forecast__c pfTCV = new Partner_Forecast__c(RecordTypeId=pfTCVRTId, Close_Date__c = System.today(), Opportunity__c = opp.Id, Total_Amount__c = 12345.00);
        insert pfTCV;
        Test.stopTest();
        // Verify 
     
    }
    
}