/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CIA_Helpful_Feedback_Controller_Test
*
* @description 	  Test class tests the CTA_Read_Receipt_Controller.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-05-03
* @modified       
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class CIA_Helpful_Feedback_Controller_Test {
    public static testMethod void ensure_OnLoad_Functionality_Works(){
        CTA_Digest__c ctaDig = new CTA_Digest__c(Name = 'Test Digest');
        insert ctaDig;
        
        CTA_Digest__c testCTADigBefore = [SELECT Id,
                                         		 Was_This_Digest_Helpful__c
                                          FROM CTA_Digest__c
                                          WHERE Id = :ctaDig.Id];
        System.assertEquals(null, testCTADigBefore.Was_This_Digest_Helpful__c);
        
        Test.StartTest();
        PageReference pageRef = Page.CIA_Helpful_Feedback;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('isHelpful', 'Yes');
        pageRef.getParameters().put('Id', String.valueOf(ctaDig.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ctaDig);
        CIA_Helpful_Feedback_Controller testController = new CIA_Helpful_Feedback_Controller(sc);
        testController.onLoad();
        
        Test.StopTest();
        
        CTA_Digest__c testCTADigAfter = [SELECT Id,
                                         		 Was_This_Digest_Helpful__c
                                          FROM CTA_Digest__c
                                          WHERE Id = :ctaDig.Id];
        System.assertEquals('Yes', testCTADigAfter.Was_This_Digest_Helpful__c);
    }
    
    public static testMethod void ensure_Submit_Functionality_Works(){
        String feedback = 'This is great!';
        
        CTA_Digest__c ctaDig = new CTA_Digest__c(Name = 'Test Digest');
        insert ctaDig;
        
        CTA_Digest__c testCTADigBefore = [SELECT Id,
                                         		 Was_This_Digest_Helpful__c
                                          FROM CTA_Digest__c
                                          WHERE Id = :ctaDig.Id];
        System.assertEquals(null, testCTADigBefore.Was_This_Digest_Helpful__c);
        
        Test.StartTest();
        PageReference pageRef = Page.CIA_Helpful_Feedback;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('isHelpful', 'Yes');
        pageRef.getParameters().put('Id', String.valueOf(ctaDig.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ctaDig);
        CIA_Helpful_Feedback_Controller testController = new CIA_Helpful_Feedback_Controller(sc);
        testController.additionalFeedback = feedback;
        testController.submit();
        
        Test.StopTest();
        
        CTA_Digest__c testCTADigAfter = [SELECT Id,
                                         		 Additional_Feedback__c
                                          FROM CTA_Digest__c
                                          WHERE Id = :ctaDig.Id];
        System.assertEquals(feedback, testCTADigAfter.Additional_Feedback__c);
    }
}