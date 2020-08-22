/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  AttachmentTriggerHandlerTest
*
* @description 	  Test class for the AttachmentTrigger and AttachmentTriggerHandler.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-11-05
* @modified       2019-11-05
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  Not created by @jayu.  Updated on 2019-11-05.
*
**/
@isTest
private class AttachmentTriggerHandlerTest {
    @testSetup static void setup(){
        insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);

    }
	private static testMethod void testBeforeInsert() {
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement', Commit_Frequency__c = 'Monthly', Term_Range__c = '12', Total_Committed_Revenue_Input__c = 1200);
        insert testAgreement;
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Test', Price__c = 1.0, Status__c = 'Active', Product_Family__c = 'Tester');
        insert testBI;
        GTM_Grouping__c testGroup = new GTM_Grouping__c(Name = 'Test Group', Status__c = 'Active');
        insert testGroup;
        GTM_Group_Billable_Item__c testJunctionObject = new GTM_Group_Billable_Item__c(GTM_Group__c = testGroup.Id, Billable_Item__c = testBI.Id);
        insert testJunctionObject;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test', Discount_Type__c = 'Flat', Flat_Price__c = 0.9, Needs_Approval_Number__c = 0);
        insert existingDiscount;
        
        Attachment newAttachment = new Attachment(Name = 'Test_Order Form', Body = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body, ParentId = testAgreement.Id);
        
        Test.startTest();
            insert newAttachment;
        Test.stopTest();
	}
	
	private static testMethod void testAfterInsert() {
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement', Commit_Frequency__c = 'Monthly', Term_Range__c = '12', Total_Committed_Revenue_Input__c = 1200);
        insert testAgreement;
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Test', Price__c = 1.0, Status__c = 'Active', Product_Family__c = 'Tester');
        insert testBI;
        GTM_Grouping__c testGroup = new GTM_Grouping__c(Name = 'Test Group', Status__c = 'Active');
        insert testGroup;
        GTM_Group_Billable_Item__c testJunctionObject = new GTM_Group_Billable_Item__c(GTM_Group__c = testGroup.Id, Billable_Item__c = testBI.Id);
        insert testJunctionObject;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test', Discount_Type__c = 'Flat', Flat_Price__c = 0.9, Needs_Approval_Number__c = 0);
        insert existingDiscount;
        
        Agreement_Attachment_Mapping__c setting = new Agreement_Attachment_Mapping__c(Name = 'Test Setting', Agreement_Field_Name__c = 'Commit_Frequency__c', Attachment_Field_Name__c = 'Commit_Frequency__c');
        insert setting;
        
        Attachment newAttachment = new Attachment(Name = 'Test_Order Form', Body = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body, ParentId = testAgreement.Id);
        
        Test.startTest();
            insert newAttachment;
        Test.stopTest();
	}
	
    private static testMethod void ensure_Content_Type_Is_Updated_On_Attachment() {
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
        
        Blob body = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body;
        
        //Insert 20 Attachments with Random Content Type
        List<String> availableContentTypes = new List<String>{'.pdf','pdf'};
        Integer listSize = availableContentTypes.size();
        List<Attachment> attachmentsForInsert = new List<Attachment>();
        Integer numberOfExpectedPDFRecs = 0;
        
        for(Integer i = 0; i < 20; i++){
            Integer randomNumber = Integer.valueof((Math.random() * listSize));
        	String randomContentType = availableContentTypes[randomNumber];
            Attachment newAttachment = new Attachment(Name = 'Test_Order Form ' + i, 
                                                      Body = body, 
                                                      ParentId = testAgreement.Id, 
                                                      ContentType = randomContentType);
            attachmentsForInsert.add(newAttachment);
            System.debug('This is the content type ---> ' + randomContentType);
            if(randomContentType == '.pdf'){
                numberOfExpectedPDFRecs++;
            }
        }
        
        Test.startTest();
            insert attachmentsForInsert;
        Test.stopTest();
        
        List<Attachment> attachmentsForReview = [SELECT Id, ContentType FROM Attachment];
        Integer numberOfActualPDFRecs = 0;
        
        for(Attachment attRec : attachmentsForReview){
            if(attRec.ContentType == 'application/pdf'){
                numberOfActualPDFRecs++;
            }
        }
        
        System.assert(numberOfActualPDFRecs > 0);
        System.assertEquals(numberOfExpectedPDFRecs, numberOfActualPDFRecs);
	}
    
    private static testMethod void ensure_Content_Type_Is_Not_Updated_On_Attachment() {
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
        
        Blob body = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body;
        
        //Insert 20 Attachments with Random Content Type
        List<String> availableContentTypes = new List<String>{'.pdf','pdf'};
        Integer listSize = availableContentTypes.size();
        List<Attachment> attachmentsForInsert = new List<Attachment>();
        Integer numberOfExpectedPDFRecs = 0;
        
        for(Integer i = 0; i < 20; i++){
            Integer randomNumber = Integer.valueof((Math.random() * listSize));
        	String randomContentType = availableContentTypes[randomNumber];
            Attachment newAttachment = new Attachment(Name = 'Test_Order Form ' + i, 
                                                      Body = body, 
                                                      ParentId = testAgreement.Id, 
                                                      ContentType = randomContentType);
            attachmentsForInsert.add(newAttachment);
            
            if(randomContentType == 'pdf'){
                numberOfExpectedPDFRecs++;
            }
        }
        
        Test.startTest();
            insert attachmentsForInsert;
        Test.stopTest();
        
        List<Attachment> attachmentsForReview = [SELECT Id, ContentType FROM Attachment];
        Integer numberOfActualPDFRecs = 0;
        
        for(Attachment attRec : attachmentsForReview){
            if(attRec.ContentType == 'pdf'){
                numberOfActualPDFRecs++;
            }
        }
        
        System.assert(numberOfActualPDFRecs > 0);
        System.assertEquals(numberOfExpectedPDFRecs, numberOfActualPDFRecs);
	}
}