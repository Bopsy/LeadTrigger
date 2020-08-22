@isTest
private class BillableItemPickerCtrlTest {
    static testMethod void testConstructor(){
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Total_Committed_Revenue_Input__c = 5000);
        insert testAgreement;
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Test', Price__c = 1.0, Status__c = 'Active', Product_Family__c = 'Tester');
        insert testBI;
        GTM_Grouping__c testGroup = new GTM_Grouping__c(Name = 'Test Group', Status__c = 'Active');
        insert testGroup;
        GTM_Group_Billable_Item__c testJunctionObject = new GTM_Group_Billable_Item__c(GTM_Group__c = testGroup.Id, Billable_Item__c = testBI.Id);
        insert testJunctionObject;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test');
        insert existingDiscount;
        ApexPages.standardController stdCtrl = new ApexPages.standardController(testAgreement);
        Test.startTest();
            BillableItemPickerCtrl ctrl = new BillableItemPickerCtrl(stdCtrl);
            ctrl.getBillableItems();
            ctrl.getGroups();
            ctrl.getExistingItems();
            existingDiscount.Id = null;
            BillableItemPickerCtrl.saveData(JSON.serialize(new List<Single_BI_Discount__c>{existingDiscount}), testAgreement.Id, '1234192391ajda');
        Test.stopTest();
    }
}