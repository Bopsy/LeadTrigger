@isTest
private class PartnerSettingsController_Test {

    @testSetup 
    static void setup() {
        
    }

    static testMethod void testinitializeFormSettings(){
        Test.startTest();
            String response = PartnerSettingsController.initializeFormSettings();
            system.assert(response != null);
        Test.stopTest();
    }

    static testMethod void testcreateLead(){
        Test.startTest();
            String leadJSON = '{"Status":"New","Company":"Twilio","DB_State__c":"TN","Email":"Test@gmail.com","FirstName":"Twilio","Phone":"34343434","DBCountry__c":"United States","Partner_Type__c":"Technology","LastName":"Shrivastava"}';
            String response = PartnerSettingsController.createLead(leadJSON);
            system.assertEquals([Select Id from Lead].size(), 1);
        Test.stopTest();
    }

}