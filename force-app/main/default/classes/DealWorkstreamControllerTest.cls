/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           DealWorkstreamControllerTest
*
* @description    Test class that contains the unit test related to WorkstreamTriggerHandler,WorkstreamController class.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2018-04-15
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class DealWorkstreamControllerTest {

    //Method to cover positive test case
    static testmethod void DealWorkstreamControllerTestCase(){
        Workstream_Rollup_Mapping__c setting = new Workstream_Rollup_Mapping__c();
        setting.Name = 'Agreement';
        setting.Parent_Lookup_API_Field__c = 'Agreement__c';
        setting.Parent_API_Field__c = 'Total_Workstream_Duration__c';
        setting.Child_API_Field__c = 'Total_Time__c';
        setting.Parent_Object_API_Name__c = 'Apttus__APTS_Agreement__c';
        insert setting;
        
        Account newAcc = new Account(Name = 'Test Acc');
        insert newAcc;
        Opportunity newOpp = new Opportunity(Name= 'Test Opp', AccountId = newAcc.Id, StageName = 'Incubate', CloseDate = Date.today(), Amount = 100, FY_16_Primary_Product__c = 'Flex');
        insert newOpp;
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c=newAcc.id,Related_Opportunity_APTS__c= newOpp.id,Total_Committed_Revenue_Input__c = 5000, Commit_Frequency__c = 'Monthly', Term_Range__c = '30', APTS_Agreement_Effective_Date__c= Date.newInstance(2017,10,3));
        insert testAgreement;
        
        Deal_Workstream__c  objDealWS = new Deal_Workstream__c();
        objDealWS.Agreement__c = testAgreement.Id;
        objDealWS.Type__c = 'Legal';
        objDealWS.Sub_Type__c = 'Translation';
        objDealWS.Status__c = 'Pending';
        insert objDealWS;
        
        test.startTest();
        PageReference pageRef = Page.WorkstreamAgreementPage;
		test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('id', testAgreement.id);
        DealWorkstreamController dealWorkCtrl = new DealWorkstreamController();
        dealWorkCtrl.refreshTable();
        dealWorkCtrl.chatterDisplay();
        
        dealWorkCtrl.createDealWorkstream();
        dealWorkCtrl.objDealWorkstream.Type__c = 'Billing';
        dealWorkCtrl.objDealWorkstream.Status__c = 'In Progress';
        dealWorkCtrl.saveDealWorkstream();
        
        dealWorkCtrl.createDealWorkstream();
        dealWorkCtrl.objDealWorkstream.Type__c = 'Security';
        dealWorkCtrl.objDealWorkstream.Status__c = 'Complete';
        dealWorkCtrl.saveDealWorkstream();
        
        Deal_Workstream__c  objDealWS2 = [Select Id,Status__c from Deal_Workstream__c where Type__c='Legal' limit 1];
        objDealWS2.Type__c = 'Product';
        dealWorkCtrl.objDealId = objDealWS2.Id;
        dealWorkCtrl.editDealWorkstream();
        dealWorkCtrl.saveDealWorkstream();
        dealWorkCtrl.objDealId = objDealWS2.Id;
        dealWorkCtrl.label = 'Accept';
        dealWorkCtrl.updateDealWorkstream();
        dealWorkCtrl.objDealId = objDealWS2.Id;
        dealWorkCtrl.label = 'Complete';
        dealWorkCtrl.updateDealWorkstream();
        dealWorkCtrl.objDealId = objDealWS2.Id;
        dealWorkCtrl.label = 'Reopen';
        dealWorkCtrl.updateDealWorkstream();
        dealWorkCtrl.label = 'Review';
        dealWorkCtrl.updateDealWorkstream();
        dealWorkCtrl.sortTable();
        dealWorkCtrl.getChatterFeeds();
        dealWorkCtrl.toggleContent();
        test.stopTest();
    }
    
    
    static testmethod void RiskWorkstreamControllerTestCase(){
        Case_Constants__c csData = new Case_Constants__c(Name = 'COMS', Trigger_Start_Date__c= date.newInstance(2019, 9, 12), Record_Type_ID__c = '0121W0000009pXLQAY');
        insert csData;
        
        Workstream_Rollup_Mapping__c setting = new Workstream_Rollup_Mapping__c();
        setting.Name = 'Case';
        setting.Parent_Lookup_API_Field__c = 'Case__c';
        setting.Parent_API_Field__c = 'Total_Workstream_Duration__c';
        setting.Child_API_Field__c = 'Total_Time__c';
        setting.Parent_Object_API_Name__c = 'Case';
        insert setting;
        
        Account newAcc = new Account(Name = 'Test Acc');
        insert newAcc;
        Opportunity newOpp = new Opportunity(Name= 'Test Opp', AccountId = newAcc.Id, StageName = 'Incubate', CloseDate = Date.today(), Amount = 100, FY_16_Primary_Product__c = 'Flex');
        insert newOpp;
        
        Case risk = new Case(recordtypeID ='0121W000000QP0m', accountID = newAcc.ID, Next_Step__c = 'TEST', 
                             Next_Follow_Up_Date__c = date.newInstance(2020, 11, 21), Likelihood_of_Save__c = '3', 
                             status = 'Ongoing Risk', ARR_at_Risk__c =500 );
        insert risk;
        
        Deal_Workstream__c  objDealWS = new Deal_Workstream__c(recordtypeID = '0121W000000YfHX');
        objDealWS.Case__c = risk.Id;
        objDealWS.Type__c = 'Product';
        objDealWS.Status__c = 'Pending';
        insert objDealWS;
        
        test.startTest();
        PageReference pageRef = Page.WorkstreamAgreementPage;
		test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('id', risk.id);
        DealWorkstreamController dealWorkCtrl = new DealWorkstreamController();
        dealWorkCtrl.refreshTable();
        dealWorkCtrl.chatterDisplay();
        
        dealWorkCtrl.createDealWorkstream();
        dealWorkCtrl.objDealWorkstream.Type__c = 'Billing';
        dealWorkCtrl.objDealWorkstream.Status__c = 'In Progress';
        dealWorkCtrl.saveCaseWorkstream();
        
        dealWorkCtrl.createDealWorkstream();
        dealWorkCtrl.objDealWorkstream.Type__c = 'Security';
        dealWorkCtrl.objDealWorkstream.Status__c = 'Complete';
        dealWorkCtrl.saveCaseWorkstream();
        
        Deal_Workstream__c  objDealWS2 = [Select Id,Status__c from Deal_Workstream__c where Type__c='Product' limit 1];
        objDealWS2.Type__c = 'Pricing';
        dealWorkCtrl.objDealId = objDealWS2.Id;
        dealWorkCtrl.editDealWorkstream();
        dealWorkCtrl.saveCaseWorkstream();
        dealWorkCtrl.objDealId = objDealWS2.Id;
        dealWorkCtrl.label = 'Accept';
        dealWorkCtrl.updateRiskWorkstream();
        dealWorkCtrl.objDealId = objDealWS2.Id;
        dealWorkCtrl.label = 'Complete';
        dealWorkCtrl.updateRiskWorkstream();
        
        dealWorkCtrl.getfile();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(risk);
        DealWorkstreamController dealWorkCtrl_1 = new DealWorkstreamController(sc);

        
        
        
        test.stopTest();
    }
}