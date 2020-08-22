@isTest
private class AgreementAttachmentEmailCtrlTest {

	private static testMethod void testConstructor() {
        AgreementAttachmentEmailComponentCtrl ctrl = new AgreementAttachmentEmailComponentCtrl();
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement', Commit_Frequency__c = 'Monthly', Term_Range__c = '12', Total_Committed_Revenue_Input__c = 1200);
        insert testAgreement;
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Test', Price__c = 1.0, Status__c = 'Active', Product_Family__c = 'Tester');
        insert testBI;
        GTM_Grouping__c testGroup = new GTM_Grouping__c(Name = 'Test Group', Status__c = 'Active');
        insert testGroup;
        GTM_Group_Billable_Item__c testJunctionObject = new GTM_Group_Billable_Item__c(GTM_Group__c = testGroup.Id, Billable_Item__c = testBI.Id);
        insert testJunctionObject;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test', Discount_Type__c = 'Flat', Flat_Price__c = 0.9, Needs_Approval_Number__c = 1);
        insert existingDiscount;
        
        Agreement_Attachment_Mapping__c setting = new Agreement_Attachment_Mapping__c(Name = 'Test Setting', Agreement_Field_Name__c = 'Commit_Frequency__c', Attachment_Field_Name__c = 'Commit_Frequency__c');
        insert setting;
        
        Attachment newAttachment = new Attachment(Name = 'Test_Order Form', Body = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body, ParentId = testAgreement.Id);
        insert newAttachment;
        
        Agreement_Attachment__c testObj = [SELECT Id FROM Agreement_Attachment__c LIMIT 1];
        
        ctrl.agreementId = testAgreement.Id;
        ctrl.agreementAttachmentId = testObj.Id;
        
        Test.startTest();
            Apttus__APTS_Agreement__c testAgr = ctrl.agreementObject;
            Agreement_Attachment__c testObject = ctrl.obj;
            List<Single_BI_Discount__c> discounts = ctrl.needApprovalBIs;
        Test.stopTest();
	}

}