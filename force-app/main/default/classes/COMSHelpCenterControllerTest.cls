@isTest

public class COMSHelpCenterControllerTest {
    public static String testCase {public get; public set;}
    
    @testSetup static void SetupData() {
        List<COMS_RecordType_Map__mdt> testCOMSRecType = [SELECT Type_of_Help__c FROM COMS_RecordType_Map__mdt WHERE Type_of_Help__c= :COMSHelpCenterControllerTest.testCase];
    }
    
    static testMethod void tets_COMSHelpCenterController() {
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', CloseDate = Date.today(), StageName = 'Incubate', AccountId = testAcc.Id);
        insert testOpp;
        /*Apttus__APTS_Agreement__c testagreement = new Apttus__APTS_Agreement__c(
            Name = 'TestApptusAgreement',
            Company_Description__c = 'TestDescription',
            Apttus__Account__c = testAcc.Id,
            Use_Case_Internal_External__c = 'Other',
            Product__c = 'SMS',
            Directional_Messaging__c = 'Inbound Only',
            Twilio_Paper__c = 'Yes',
            Use_Case_Description__c = 'Test use case description',
            Apttus__Term_Months__c = 8,
            Apttus__Status_Category__c = 'Initiate',
            Account_SIDs__c = ''
        );
        insert testagreement;*/
        
        Launch_Plan__c testlp = new Launch_Plan__c(Name = 'LP ',Opportunity__c = testOpp.Id);
        insert testlp;
        
        Risk__c testr = new Risk__c(Name = 'LP',
                                    Account__c = testAcc.Id,
                                    Resolution_Date__c = System.today(),
                                    ARR_at_Risk__c  = 1,
                                    Risk_Source__c = 'CTA',
                                    Risk_Type__c = 'Customer Churn',
                                    Risk_Status__c = 'Draft',
                                    Reason_for_Risk__c = 'Billing',
                                    Likelihood_of_Save__c = '1',
                                    Relevant_Products__c = 'Authy - Software');
        insert testr;
        
        
        COMSHelpCenterController.fetchTypeOfHelp();
        COMSHelpCenterController.fetchRecordTypeOfHelp('Customer Success Team Support');
        Id RecordTypeIdCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Ops Request: CSM Risk Assessment').getRecordTypeId();
        COMSHelpCenterController.getPicklistValueBasedonRecordType('Case', 'Type_of_Help__c', RecordTypeIdCase);
        String acc = COMSHelpCenterController.queryAccountName('Account',testAcc.Id);
        //acc = COMSHelpCenterController.queryAccountName('Apttus__APTS_Agreement__c',null);
        acc = COMSHelpCenterController.queryAccountName('Opportunity',testOpp.Id);
        acc = COMSHelpCenterController.queryAccountName('Launch_Plan__c',testlp.Id);
        acc = COMSHelpCenterController.queryAccountName('Risk__c',testr.Id);
        acc = COMSHelpCenterController.queryAccountName('',testr.Id);
    }
}