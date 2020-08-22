/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class AgreementAttachmentControllerTest {

    private static Account account;
	private static Apttus__APTS_Agreement__c agreement;
	
    static testMethod void uploadAndDelete() {
    	setupTestRecords();
    	
        ApexPages.StandardController con = new ApexPages.StandardController(agreement);
        AgreementAttachmentController acon = new AgreementAttachmentController(con);
        
        Test.startTest();

		// Test use access to agreement attachment object
        System.assertEquals(acon.canView, true);
        System.assertEquals(acon.canAdd, true);
        System.assertEquals(acon.canDelete, true);

		// Test initial agreement that has no attachments
        System.assertEquals(acon.hasAgreement, true);
        System.assertEquals(acon.hasAttachments, false);
        System.assertEquals(acon.hasReadOnlyAttachments, false);
        System.assertEquals(acon.hasUserAttachments, false);

		// Add read-only test attachment
		Attachment a = new Attachment(
			Name = 'UNIT TEST Attachment 0 Order Form',
			Body = Blob.valueOf('UNIT TEST Attachment Body 0'),
			ContentType = 'text/plain',
			ParentId = acon.agreement.Id
		);
		insert a;

		// Reload the controller since uploads require a page refresh
		acon = new AgreementAttachmentController(con);
        System.assertEquals(acon.hasAttachments, true);
        System.assertEquals(acon.hasReadOnlyAttachments, true);
        System.assertEquals(acon.hasUserAttachments, false);

		// Upload user test attachments
		acon.attachmentName = 'UNIT TEST Attachment 1';
		acon.attachmentBody = Blob.valueOf('UNIT TEST Attachment Body 1');
		acon.attachment.ContentType = 'text/plain';
		acon.upload();

		// Reload the controller since uploads require a page refresh
		acon = new AgreementAttachmentController(con);
        System.assertEquals(acon.hasAttachments, true);
        System.assertEquals(acon.hasReadOnlyAttachments, true);
        System.assertEquals(acon.hasUserAttachments, true);

		// Upload another user test attachments
		acon.attachmentName = 'UNIT TEST Attachment 2';
		acon.attachmentBody = Blob.valueOf('UNIT TEST Attachment Body 2');
		acon.attachment.ContentType = 'text/plain';
		acon.upload();

		// Reload the controller since uploads require a page refresh
		acon = new AgreementAttachmentController(con);
        System.assertEquals(acon.hasAttachments, true);
        System.assertEquals(acon.hasReadOnlyAttachments, true);
        System.assertEquals(acon.hasUserAttachments, true);

		// Delete read-only test attachment
		delete a;

		// Reload the controller since uploads require a page refresh
		acon = new AgreementAttachmentController(con);
        System.assertEquals(acon.hasAttachments, true);
        System.assertEquals(acon.hasReadOnlyAttachments, false);
        System.assertEquals(acon.hasUserAttachments, true);

		// Delete first user test attachment
		acon.attachmentId = acon.userAttachments[0].Id;
		acon.agreementAttachmentId = acon.userAttachments[0].ParentId;
		//acon.submitAttachment();
		acon.deleteAttachment();
		acon.closePopup();
		acon.closeUploadWindow();
		acon.showPopup();
		acon.showUploadWindow();
        System.assertEquals(acon.hasAttachments, true);
        System.assertEquals(acon.hasReadOnlyAttachments, false);
        System.assertEquals(acon.hasUserAttachments, true);

		// Delete second user test attachment
		acon.attachmentId = acon.userAttachments[0].Id;
		acon.agreementAttachmentId = acon.userAttachments[0].ParentId;
		acon.deleteAttachment();
        System.assertEquals(acon.hasAttachments, false);
        System.assertEquals(acon.hasReadOnlyAttachments, false);
        System.assertEquals(acon.hasUserAttachments, false);
		
        Test.stopTest();
    }

    static testMethod void convertSize() {
        Test.startTest();

        System.assertEquals(AgreementAttachmentController.convertSize(1073741824), '1.00 GB');
        System.assertEquals(AgreementAttachmentController.convertSize(1048576), '1.00 MB');
        System.assertEquals(AgreementAttachmentController.convertSize(1024), '1.00 KB');
        System.assertEquals(AgreementAttachmentController.convertSize(100), '100 bytes');
        System.assertEquals(AgreementAttachmentController.convertSize(1), '1 byte');
        System.assertEquals(AgreementAttachmentController.convertSize(0), '0 byte');
		
        Test.stopTest();
    }

	private static void setupTestRecords() {
        try{
            insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
            account = new Account(
	            Name = 'TestAccount',
	            Channel_Account_Status__c = 'Healthy'
            );
            insert account;

            agreement = new Apttus__APTS_Agreement__c(
	            Name = 'TestApptusAgreement',
	            Company_Description__c = 'TestDescription',
	            Apttus__Account__c = account.Id,
	            Use_Case_Internal_External__c = 'Other',
	            Product__c = 'SMS',
	            Directional_Messaging__c = 'Inbound Only',
	            Twilio_Paper__c = 'Yes',
	            Use_Case_Description__c = 'Test use case description',
	            Apttus__Term_Months__c = 8,
	            Apttus__Status_Category__c = 'Initiate',
	            Account_SIDs__c = ''
            );
            insert agreement;
        }catch(DmlException ex){
			throw ex;
        }
	}
}