/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           DocumentVersionDetailAttachmentTest
*
* @description    Test class for Trigger handler related to Document Version Detail attchment object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2020-06-01
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class DocumentVersionDetailAttachmentTest {

    @testSetup static  void setup() {
        insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement', Commit_Frequency__c = 'Monthly', Term_Range__c = '24', Total_Committed_Revenue_Input__c = 1200);
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
    }
    
	private static testMethod void testDocumentVersionDetail1() {
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Test.startTest();
        
        Apttus__DocumentVersion__c newDocVersion = new Apttus__DocumentVersion__c(Apttus__Title__c = 'Test_Order Form.pdf',  Apttus__AgreementId__c = testAgreement.Id, Apttus__LatestVersion__c='1.0.0' );
        insert newDocVersion;
        
        Apttus__DocumentVersionDetail__c newDocVersionDetail = new Apttus__DocumentVersionDetail__c(Apttus__Title__c = 'Test_Order Form.pdf',  Apttus__DocumentVersionId__c  = newDocVersion.Id, Apttus__VersionMajor__c=1, Apttus__VersionMinor__c=0, Apttus__VersionRevision__c =0, Apttus__Action2__c='Check In',Apttus__DocumentInfo__c ='Draft');
        insert newDocVersionDetail;
        
        Attachment newAttachment = new Attachment(Name = 'Test_Order Form', Body = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body, ParentId = newDocVersionDetail.Id);
        insert newAttachment;
        
        Test.stopTest();
        Agreement_Attachment__c testObj = [SELECT Id,Deal_Desk_Approval_Status__c,Accounting_Approval_Status__c,Legal_Approval_Status__c FROM Agreement_Attachment__c LIMIT 1];
        system.assertEquals('Not Started', testObj.Deal_Desk_Approval_Status__c);
	}
    
    private static testMethod void testDocumentVersionDetail2() {
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Test.startTest();
        
        Apttus__DocumentVersion__c newDocVersion = new Apttus__DocumentVersion__c(Apttus__Title__c = 'Test_Order Form.pdf',  Apttus__AgreementId__c = testAgreement.Id, Apttus__LatestVersion__c='1.0.0' );
        insert newDocVersion;
        
        Apttus__DocumentVersionDetail__c newDocVersionDetail = new Apttus__DocumentVersionDetail__c(Apttus__Title__c = 'Test_Order Form.pdf',  Apttus__DocumentVersionId__c  = newDocVersion.Id, Apttus__VersionMajor__c=1, Apttus__VersionMinor__c=0, Apttus__VersionRevision__c =0,Apttus__Action2__c='Check In', Apttus__DocumentInfo__c ='Final');
        insert newDocVersionDetail;
        
        Attachment newAttachment = new Attachment(Name = 'Test_Order Form', Body = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body, ParentId = newDocVersionDetail.Id);
        insert newAttachment;
        
        Test.stopTest();
        Agreement_Attachment__c testObj = [SELECT Id,Deal_Desk_Approval_Status__c,Accounting_Approval_Status__c,Legal_Approval_Status__c FROM Agreement_Attachment__c LIMIT 1];
        system.assertEquals('Approved', testObj.Legal_Approval_Status__c);
	}
    
    private static testMethod void testDocumentVersionDetail3() {
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Test.startTest();
        
        Apttus__DocumentVersion__c newDocVersion = new Apttus__DocumentVersion__c(Apttus__Title__c = 'Test_Order Form.pdf',  Apttus__AgreementId__c = testAgreement.Id, Apttus__LatestVersion__c='1.0.0' );
        insert newDocVersion;
        
        Apttus__DocumentVersionDetail__c newDocVersionDetail = new Apttus__DocumentVersionDetail__c(Apttus__Title__c = 'Test_Order Form.pdf',  Apttus__DocumentVersionId__c  = newDocVersion.Id, Apttus__VersionMajor__c=1, Apttus__VersionMinor__c=0, Apttus__VersionRevision__c =0,Apttus__Action2__c='Generate Agreement');
        insert newDocVersionDetail;
        
        Attachment newAttachment = new Attachment(Name = 'Test_Order Form', Body = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body, ParentId = newDocVersionDetail.Id);
        insert newAttachment;
        
        Test.stopTest();
        Agreement_Attachment__c testObj = [SELECT Id,Deal_Desk_Approval_Status__c,Accounting_Approval_Status__c,Legal_Approval_Status__c FROM Agreement_Attachment__c LIMIT 1];
        system.assertEquals('Approved', testObj.Accounting_Approval_Status__c);
	}
}