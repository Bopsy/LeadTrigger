/******************************************
//Created By: Davis Dong
//Last Modified by: Bopsy {11/25/2019}
//Description: This is the test class of PTPConversionController
//
*******************************************/
@isTest
private class PTPConversionControllerTest {
    
    private static testMethod void test() {
        Account acct = new Account(Name = 'Test Acc');
        insert acct;
        Contact cont = new Contact(LastName = 'Test Contact', AccountId = acct.Id);
        insert cont;
        
        Case_Constants__c testcaseConstant = new Case_Constants__c(Name = 'COMS', Trigger_Start_Date__c= system.today(), Record_Type_ID__c = '0121W0000009pXLQAY');
        insert testcaseConstant;
        
        Pass_to_Partner__c ptp = new Pass_to_Partner__c(Contact__c = cont.Id, FY_16_Primary_Product_Input__c = 'Flex', Launch_Date__c = Date.today());
        insert ptp;
        
        ApexPages.standardController std = new ApexPages.standardController(ptp);
        
        PTPConversionController newExt = new PTPConversionController(std);
        ApexPages.currentPage().getParameters().put('Id', ptp.Id);
        
        Test.startTest();
        newExt.convert();
        newExt.cancel();
        Test.stopTest();
    }
    
}