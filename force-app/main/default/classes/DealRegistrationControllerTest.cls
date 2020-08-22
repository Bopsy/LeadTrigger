@isTest
public class DealRegistrationControllerTest {
    
    static testMethod void Test_DealRegistrationController(){
        Pass_to_Partner__c testLead = new Pass_to_Partner__c(Name = 'Test', FY_16_Primary_Product_Input__c='Flex', Contact_Email_Text__c = 'test@tester.com', Contact_Name_Text__c = 'Davis Tester', Company_Name__c = 'Test company');
        DealRegistrationController.mainWrapper testDealRegWrap = new DealRegistrationController.mainWrapper(); 
        DealRegistrationController.onloadLead();
        String strWrap = JSON.serialize(testDealRegWrap);
        String strLead = JSON.serialize(testLead);
        Test.startTest();
        DealRegistrationController.saveLeadDetails(strLead, strWrap, new List<String>{'Flex'});
        Test.stopTest();
        List<Pass_to_Partner__c> testLeadList = [SELECT Id FROM Pass_to_Partner__c];
        //System.assertEquals(1, testLeadList.Size());
    }
}