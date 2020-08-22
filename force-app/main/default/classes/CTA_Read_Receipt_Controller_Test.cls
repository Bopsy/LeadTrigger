/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CTA_Read_Receipt_Controller_Test
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
private class CTA_Read_Receipt_Controller_Test {
    private static testMethod void ensure_CTAs_are_read(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        CTA_Digest__c ctaDig = new CTA_Digest__c(Name = 'Test Digest');
        insert ctaDig;
            
        JBCXM__CTA__c testCTARec = new JBCXM__CTA__c(Name = 'Test Rec',
                                                   	 JBCXM__Account__c = testAcc.Id,
                                                     CTA_Digest__c = ctaDig.Id);
        insert testCTARec;
        
        JBCXM__CTA__c testCTARec2 = new JBCXM__CTA__c(Name = 'Test Rec 2',
                                                   	 JBCXM__Account__c = testAcc.Id,
                                                     CTA_Digest__c = ctaDig.Id);
        insert testCTARec2;
        
        JBCXM__CTA__c testCTARec3 = new JBCXM__CTA__c(Name = 'Test Rec 3',
                                                   	 JBCXM__Account__c = testAcc.Id);
        insert testCTARec3;
        
        JBCXM__CTA__c reviewCTABefore = [SELECT Id,
                                        	    Is_Read__c,
                                                Last_User_Read__c
                                         FROM JBCXM__CTA__c WHERE Id = :testCTARec.Id];
        System.assertEquals(FALSE, reviewCTABefore.Is_Read__c);
        System.assertEquals(null, reviewCTABefore.Last_User_Read__c);
        
        Test.StartTest();
        PageReference pageRef = Page.CTA_Read_Receipt;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(testCTARec.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testCTARec);
        CTA_Read_Receipt_Controller testController = new CTA_Read_Receipt_Controller(sc);
        testController.onLoad();
        
        Test.StopTest();
		
		JBCXM__CTA__c reviewCTAAfter = [SELECT Id,
                                        	    Is_Read__c,
                                                Last_User_Read__c
                                         FROM JBCXM__CTA__c WHERE Id = :testCTARec.Id];
        System.assertEquals(TRUE, reviewCTAAfter.Is_Read__c);
        System.assertEquals(UserInfo.getUserId(), reviewCTAAfter.Last_User_Read__c);

		CTA_Digest__c reviewCTADigestAfter = [SELECT Id,
                                             		 Is_Child_CTA_Read__c,
                                             		 CTA_Read__c
                                              FROM CTA_Digest__c
                                              WHERE Id = :ctaDig.Id];        
        System.assertEquals(reviewCTAAfter.Id, reviewCTADigestAfter.CTA_Read__c);
        System.assertEquals(TRUE, reviewCTADigestAfter.Is_Child_CTA_Read__c);
    }
    
    private static testMethod void ensure_Individual_CTA_is_read(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
            
        JBCXM__CTA__c testCTARec = new JBCXM__CTA__c(Name = 'Test Rec',
                                                   	 JBCXM__Account__c = testAcc.Id);
        insert testCTARec;
        
        JBCXM__CTA__c reviewCTABefore = [SELECT Id,
                                        	    Is_Read__c,
                                                Last_User_Read__c
                                         FROM JBCXM__CTA__c WHERE Id = :testCTARec.Id];
        System.assertEquals(FALSE, reviewCTABefore.Is_Read__c);
        System.assertEquals(null, reviewCTABefore.Last_User_Read__c);
        
        Test.StartTest();
        PageReference pageRef = Page.CTA_Read_Receipt;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(testCTARec.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testCTARec);
        CTA_Read_Receipt_Controller testController = new CTA_Read_Receipt_Controller(sc);
        testController.onLoad();
        
        Test.StopTest();
		
		JBCXM__CTA__c reviewCTAAfter = [SELECT Id,
                                        	    Is_Read__c,
                                                Last_User_Read__c
                                         FROM JBCXM__CTA__c WHERE Id = :testCTARec.Id];
        System.assertEquals(TRUE, reviewCTAAfter.Is_Read__c);
        System.assertEquals(UserInfo.getUserId(), reviewCTAAfter.Last_User_Read__c);

    }
}