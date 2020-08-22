@istest
public class orgApplicationHandlerTest {
    public testmethod static void addCampaignMemberTest() {
        insert(new CampaignMember_orgApplication_Mapping__c(name = 'org Campaign', Status__c = 'added', Campaign_ID__c = '7011W000001TW1aQAG'));
        Lead lead1 = new Lead(LastName = 'Test', Company = 'testInc', Status='Open');
        insert lead1;
        
        Contact contact1 = new Contact( LastName = 'conTest', Title = 'tester',
                                        Preferred_Email__c='mia@fseoihfo.com', Contact_Type__c='Billing Contact');
        insert contact1;                            
        
        Test.startTest();
        org_Application__c app1 = new org_Application__c(name = 'app TEST1', Lead__c = lead1.ID);
        insert app1;
        
        org_Application__c app2 = new org_Application__c(name = 'app TEST2', Contact__c = contact1.ID);
        insert app2;
        
        
        Test.stopTest();
    }
}