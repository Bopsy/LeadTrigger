/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  InsightViewControllertest
*
* @description 	  Test class for the InsightViewController
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2020-04-21
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class InsightViewControllerTest {
	private static testMethod void ensure_Accounts_Are_Read(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        List<Insight_View__c> reviewInsightViewBefore = new List<Insight_View__c>();
        reviewInsightViewBefore = [SELECT Id,
                                   		  Viewed_By__c,
                                   		  Viewed_Date__c
                                   FROM Insight_View__c WHERE Account__c = :testAcc.Id];

        System.assertEquals(0, reviewInsightViewBefore.size());
        
        Test.StartTest();
        PageReference pageRef = Page.Insight_View;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(testAcc.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testAcc);
        InsightViewController testController = new InsightViewController(sc);
        testController.onLoad();
        
        Test.StopTest();
		
		List<Insight_View__c> reviewInsightViewAfter = [SELECT Id,
                                                              Viewed_By__c,
                                                              Viewed_Date__c,
                                                              CreatedDate
                                                       FROM Insight_View__c WHERE Account__c = :testAcc.Id];
        Id currentUserId = UserInfo.getUserId();
        for(Insight_View__c iv : reviewInsightViewAfter){
            System.assertEquals(currentUserId, iv.Viewed_By__c);
            System.assertEquals(iv.CreatedDate, iv.Viewed_Date__c);    
        }
    }
    
    private static testMethod void ensure_Multiple_Insight_Views_Are_Created(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        List<Insight_View__c> reviewInsightViewBefore = new List<Insight_View__c>();
        reviewInsightViewBefore = [SELECT Id,
                                   		  Viewed_By__c,
                                   		  Viewed_Date__c
                                   FROM Insight_View__c WHERE Account__c = :testAcc.Id];

        System.assertEquals(0, reviewInsightViewBefore.size());
        
        Test.StartTest();
        PageReference pageRef = Page.Insight_View;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(testAcc.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testAcc);
        InsightViewController testController = new InsightViewController(sc);
        //Call onLoad method twice to create 2 records.
        testController.onLoad();
        testController.onLoad();
        Test.StopTest();
		
		List<Insight_View__c> reviewInsightViewAfter = [SELECT Id,
                                                              Viewed_By__c,
                                                              Viewed_Date__c,
                                                              CreatedDate
                                                       FROM Insight_View__c WHERE Account__c = :testAcc.Id];
        Id currentUserId = UserInfo.getUserId();
        for(Insight_View__c iv : reviewInsightViewAfter){
            System.assertEquals(currentUserId, iv.Viewed_By__c);
            System.assertEquals(iv.CreatedDate, iv.Viewed_Date__c);    
        }
        System.assertEquals(2, reviewInsightViewAfter.size());
    }
    
	private static testMethod void ensure_No_Insight_Views_Are_Created(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        List<Insight_View__c> reviewInsightViewBefore = new List<Insight_View__c>();
        reviewInsightViewBefore = [SELECT Id,
                                   		  Viewed_By__c,
                                   		  Viewed_Date__c
                                   FROM Insight_View__c WHERE Account__c = :testAcc.Id];

        System.assertEquals(0, reviewInsightViewBefore.size());
        
        Test.StartTest();
        PageReference pageRef = Page.Insight_View;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(testAcc.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testAcc);
        InsightViewController testController = new InsightViewController(sc);
        //Do Not Call onLoad method.
        Test.StopTest();
		
        List<Insight_View__c> reviewInsightViewAfter = new List<Insight_View__c>();
		reviewInsightViewAfter = [SELECT Id,
                                  		 Viewed_By__c,
                                  		 Viewed_Date__c,
                                  		 CreatedDate
                                  FROM Insight_View__c WHERE Account__c = :testAcc.Id];
        System.assertEquals(0, reviewInsightViewAfter.size());
    }    
}