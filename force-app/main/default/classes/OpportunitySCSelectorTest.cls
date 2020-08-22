@isTest
public class OpportunitySCSelectorTest {
    static testMethod void shortCodeSelecorTest() {
        Account acc = new Account(name = 'testAcc');
        insert acc;
        
        Opportunity oppty = new Opportunity(AccountID = acc.ID, name = 'testOpp', stagename = 'Incubate', closeDate = Date.today());
        insert oppty;
        
        Account_SID__c sid = new Account_SID__c(Account__c = acc.ID, name = 'testAccID');
        insert sid;
        
        Short_Code__c sc = new Short_Code__c(OwnerUser_Email_Address__c = 'maitest@twilio.com', Short_Code_App_Sid__c = 'da');
        insert sc;
        List<Short_Code__c> scList = OpportunitySCSelectorController.getShortCodeList('maitest@twilio.com', oppty.Id);
        System.assert(scList.size() == 1);
        
        OpportunitySCSelectorController.linkOppty(sc, Oppty.ID);
        
        scList = OpportunitySCSelectorController.getShortCodeList('maitest@twilio.com', oppty.Id);
        System.assert(scList.size() == 0);
        
        List<Short_Code__c> scExistList = OpportunitySCSelectorController.getExistShortCodeList(oppty.Id);
        System.assert(scExistList.size() == 1);
        
    }
}