@isTest
private class NewBillableItemPickerCtrlTest {
    static testMethod void testConstructor(){
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Total_Committed_Revenue_Input__c = 5000);
        insert testAgreement;
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Test', Price__c = 1.0, Status__c = 'ACTIVE', Product_Family__c = 'Tester', Hide_in_Billable_Item_Manager__c = false);
        insert testBI;
        GTM_Grouping__c testGroup = new GTM_Grouping__c(Name = 'Test Group', Status__c = 'Active');
        insert testGroup;
        GTM_Group_Billable_Item__c testJunctionObject = new GTM_Group_Billable_Item__c(GTM_Group__c = testGroup.Id, Billable_Item__c = testBI.Id);
        insert testJunctionObject;
        Single_GTM_Group__c testGTMGroup = new Single_GTM_Group__c(Agreement__c = testAgreement.Id, GTM_Group__c = testGroup.Id);
        insert testGTMGroup;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Single_GTM_Group__c = testGTMGroup.Id ,Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test', Flat_Price__c = 0.9, Needs_Approval_Number__c  = 1);
        insert existingDiscount;
        Single_BI_Tier__c existingTier = new Single_BI_Tier__c(Billable_Item__c = testBI.id, Agreement__c = testAgreement.Id, Flat_Price__c = 0.9);
        insert existingTier;
        Single_GTM_Group_Tier__c existingGroupTier = new Single_GTM_Group_Tier__c(GTM_Group__c = testGroup.Id, Single_GTM_Group__c = testGTMGroup.Id, Flat_Price__c = 0.9);
        insert existingGroupTier;
        BI_Commit_Price__c price = new BI_Commit_Price__c(Billable_Item__c = testBI.Id, Discount_Type__c = 'Flat', Flat_Price__c = 0.9, Min_Commit_Ceiling__c = 1000, Min_Commit_Floor__c = 2000);
        insert price;
        BI_Picker_Dependent_List__c setting = new BI_Picker_Dependent_List__c(Name = 'Test', Payment_Type__c = 'Credit Card', Prepay_Frequency__c = 'Monthly', Term_Range__c = '12', Commit_Frequency__c = 'Monthly');
        insert setting;
        
        Attachment newAttachment = new Attachment(Name = 'Test_Order Form', Body = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body, ParentId = testAgreement.Id);
        insert newAttachment;
        Exception_BI__c exceptionBi = [SELECT Deal_Desk_Flat_Price__c FROM Exception_BI__c LIMIT 1];
        exceptionBi.Deal_Desk_Flat_Price__c = 0.9;
        update exceptionBi;
        Agreement_Attachment__c testObj = [SELECT Id FROM Agreement_Attachment__c LIMIT 1];
        testObj.Manager_Approval_Status__c = 'Approved';
        testObj.Legal_Approval_Status__c = 'Approved';
        testObj.Accounting_Approval_Status__c = 'Approved';
        testObj.Deal_Desk_Approval_Status__c = 'Approved';
        
        update testObj;
        
        
        
        ApexPages.standardController stdCtrl = new ApexPages.standardController(testAgreement);
        Test.startTest();
            NewBillableItemPickerCtrl ctrl = new NewBillableItemPickerCtrl(stdCtrl);
            ctrl.getBillableItems();
            ctrl.getGroups();
            ctrl.getExistingItems();
            existingDiscount.Id = null;
            NewBillableItemPickerCtrl.saveData(JSON.serialize(new List<Single_BI_Discount__c>{existingDiscount}), 
                                               JSON.serialize(new List<Single_BI_Tier__c>{existingTier}),
                                               JSON.serialize(new List<Single_GTM_Group__c>{testGTMGroup}),
                                               JSON.serialize(new List<Single_GTM_Group_Tier__c>{existingGroupTier}),
                                                              testAgreement.Id, JSON.serialize(testAgreement));
        Test.stopTest();
    }
}