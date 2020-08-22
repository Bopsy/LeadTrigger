/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           DealWorkstreamTriggerHandlerTest
*
* @description    Test class that contains the unit test related to WorkstreamTriggerHandler class.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2018-04-12
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class DealWorkstreamTriggerHandlerTest {

    //Method to cover positive test case
    static testmethod void WorkstreamTriggerHandlerPositiveCase(){
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
        
        test.startTest();
        Deal_Workstream__c  objDealWS = new Deal_Workstream__c();
        objDealWS.Agreement__c = testAgreement.Id;
        objDealWS.Type__c = 'Legal';
        objDealWS.Status__c = 'Complete';
        insert objDealWS;
        
        test.stopTest();
    }
    
    //Method to cover negative test case
    static testmethod void WorkstreamTriggerHandlerNegativeCase(){
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
        
        test.startTest();
        Deal_Workstream__c  objDealWS = new Deal_Workstream__c();
        objDealWS.Agreement__c = testAgreement.Id;
        objDealWS.Type__c = 'Security';
        objDealWS.Status__c = 'Pending';
        insert objDealWS;
        
        Deal_Workstream__c  objDealWS1 = new Deal_Workstream__c();
        objDealWS1.Agreement__c = testAgreement.Id;
        objDealWS1.Type__c = 'Security';
        objDealWS1.Status__c = 'In Progress';
        try{
        	insert objDealWS1;
        }catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
        test.stopTest();
    }
    
    //Method to cover bulk test case
    static testmethod void WorkstreamTriggerHandlerBulkCase(){
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
        
        test.startTest();
        List<Deal_Workstream__c> lstDealWS = new List<Deal_Workstream__c>();
        for(integer i=0;i<100;i++){
            Deal_Workstream__c  objDealWS = new Deal_Workstream__c();
            objDealWS.Agreement__c = testAgreement.Id;
            objDealWS.Type__c = 'Billing';
            objDealWS.Status__c = 'Complete';
            lstDealWS.add(objDealWS);
        }
        insert lstDealWS;
        
		List<Deal_Workstream__c> lstDealWS1 = [Select Id,Status__c from  Deal_Workstream__c];
        for(Deal_Workstream__c  objDealWS: lstdealWS1){
            objDealWS.Status__c = 'In Progress';
        }
        TriggerRunOnceUtility.DealWorkstreamTrigger=false;
        DealWorkstreamTriggerHandler.calculateRollupTotalDays(lstDealWS);
        update lstdealWS1;
        
        delete lstdealWS1;
        
        test.stopTest();
    }
}