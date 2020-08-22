@isTest
public class AgreementHandlerAsyncSyncTest {
    @testSetup
    public static void setup() {
        Account testAcnt = new Account();
        testAcnt.Name = 'AcntName';
        insert testAcnt;
        
        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'TestOppBulky';
        testOpp.AccountId = testAcnt.Id;
        testOpp.CloseDate = system.today();
        testOpp.StageName = 'Incubate';
        insert testOpp;
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c();
        testAgreement.Name = 'Agrement1';
        testAgreement.Related_Opportunity_APTS__c = testOpp.Id;
        testAgreement.Apttus__Account__c = testAcnt.Id;
        testAgreement.Apttus__Workflow_Trigger_Viewed_Final__c = false;
        testAgrmntList.add(testAgreement);
        
        Apttus__APTS_Agreement__c testAgreement1 = new Apttus__APTS_Agreement__c();
        testAgreement1.Name = 'Agrement2';
        testAgreement1.Related_Opportunity_APTS__c = testOpp.Id;
        testAgreement1.Apttus__Account__c = testAcnt.Id;
        testAgreement1.Apttus__Workflow_Trigger_Viewed_Final__c = false;
        testAgrmntList.add(testAgreement1);
        insert testAgrmntList;
        
    } 
    
    public static testMethod void forSupplementalandSupersedingWarnings() {
        Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        
        List<Apttus__APTS_Agreement__c> testAgremntForUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c testAgrmnt : testAgrmntList) {
            testAgrmnt.Agreement_History__c = 'Supersedes Existing';
            //testAgrmnt.RecordTypeId = thePartnerAgrmntRecordId;
            testAgrmnt.Twilio_Legal_Contact__c = UserInfo.getUserId();
            testAgremntForUpdate.add(testAgrmnt);
        }
        
        test.startTest();
        update testAgremntForUpdate;
        test.stopTest();
    }
    
    public static testMethod void forAgreementisSupplemental() {
        Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        Opportunity testOpp = [SELECT Id, Amount FROM Opportunity];
        Account testAcnt = [SELECT Id FROM Account];
        
        Apttus__APTS_Agreement__c testParentAgreement = new Apttus__APTS_Agreement__c();
        testParentAgreement.Name = 'Agrement1';
        testParentAgreement.Related_Opportunity_APTS__c = testOpp.Id;
        testParentAgreement.Apttus__Account__c = testAcnt.Id;
        insert testParentAgreement;
        
        List<Apttus__APTS_Agreement__c> testAgremntForUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c testAgrmnt : testAgrmntList) {
            testAgrmnt.Agreement_History__c = 'Supplements Existing';
            //testAgrmnt.RecordTypeId = thePartnerAgrmntRecordId;
            testAgrmnt.Twilio_Legal_Contact__c = UserInfo.getUserId();
            testAgrmnt.Commit_Frequency__c = 'Existing Commit';
            testAgrmnt.Apttus__Parent_Agreement__c = testParentAgreement.Id;
            testAgremntForUpdate.add(testAgrmnt);
        }
        
        test.startTest();
        update testAgremntForUpdate;
        test.stopTest();
    }
    
    public static testMethod void forAgreementUpdatetoAccount() {
        Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
        Account testAcnt = [SELECT Id, Name FROM Account];
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        
        List<Apttus__APTS_Agreement__c> testAgremntForUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c testAgrmnt : testAgrmntList) {
            //testAgrmnt.RecordTypeId = thePartnerAgrmntRecordId;
            testAgrmnt.Apttus__Account__c = testAcnt.Id;
            testAgrmnt.Account_Legal_Name_Update__c = 'AcntLegalName';
            testAgremntForUpdate.add(testAgrmnt);
        }
        
        test.startTest();
        update testAgremntForUpdate;
        test.stopTest();
        
        Account testAcntForAssertion = [SELECT Id, Account_Legal_Name__c FROM Account];
        system.assertEquals('AcntLegalName', testAcntForAssertion.Account_Legal_Name__c);
    }
    
    
    public static testMethod void forAgreementUpdatetoAccountReferenceConsentStatus() {
        Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
        Account testAcnt = [SELECT Id, Name FROM Account];
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        
        List<Apttus__APTS_Agreement__c> testAgremntForUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c testAgrmnt : testAgrmntList) {
            testAgrmnt.RecordTypeId = thePartnerAgrmntRecordId;
            testAgrmnt.Apttus__Account__c = testAcnt.Id;
            testAgrmnt.Apttus__Status__c = 'Activated';
            testAgrmnt.Reference_Name_and_Logo__c = 'Yes';
            testAgrmnt.Reference_Story__c = 'Yes';
            testAgrmnt.Reference_Use_Case__c = 'Yes';
            testAgremntForUpdate.add(testAgrmnt);
        }
        
        test.startTest();
        update testAgremntForUpdate;
        test.stopTest();
        
        Account testAcntForAssertion = [SELECT Id, Name_and_Logo__c, Story__c, Use_Case__c FROM Account];
        system.assertEquals('Yes', testAcntForAssertion.Name_and_Logo__c);
        system.assertEquals('Yes', testAcntForAssertion.Story__c);
        system.assertEquals('Yes', testAcntForAssertion.Use_Case__c);
    }
    
    public static testMethod void forAgreementUpdatetoAccountIncorporation() {
        Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
        Account testAcnt = [SELECT Id, Name FROM Account];
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        
        List<Apttus__APTS_Agreement__c> testAgremntForUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c testAgrmnt : testAgrmntList) {
            //testAgrmnt.RecordTypeId = thePartnerAgrmntRecordId;
            testAgrmnt.Apttus__Account__c = testAcnt.Id;
            testAgrmnt.State_Country_of_Incorporation_Update__c = 'StateOf';
            testAgremntForUpdate.add(testAgrmnt);
        }
        
        test.startTest();
        update testAgremntForUpdate;
        test.stopTest();
        
        Account testAcntForAssertion = [SELECT Id, State_or_Country_of_Incorporation__c FROM Account];
        system.assertEquals('StateOf', testAcntForAssertion.State_or_Country_of_Incorporation__c);
    }
    
    
    public static testMethod void forAgreementUpdatetoAccountTypeofBusiness() {
        Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
        Account testAcnt = [SELECT Id, Name FROM Account];
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        
        List<Apttus__APTS_Agreement__c> testAgremntForUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c testAgrmnt : testAgrmntList) {
            //testAgrmnt.RecordTypeId = thePartnerAgrmntRecordId;
            testAgrmnt.Apttus__Account__c = testAcnt.Id;
            testAgrmnt.Type_of_Business_Entity_Update__c = 'LLC';
            testAgremntForUpdate.add(testAgrmnt);
        }
        
        test.startTest();
        update testAgremntForUpdate;
        test.stopTest();
        
        Account testAcntForAssertion = [SELECT Id, Type_of_Business_Entity__c FROM Account];
        system.assertEquals('LLC', testAcntForAssertion.Type_of_Business_Entity__c);
    }
    
    public static testMethod void forAgreementDeleteTrigger() {
        Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
        Account testAcnt = [SELECT Id, Name FROM Account];
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        
        List<Apttus__APTS_Agreement__c> testAgremntForDelete = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c testAgrmnt : testAgrmntList) {
            //testAgrmnt.RecordTypeId = thePartnerAgrmntRecordId;
            testAgrmnt.Apttus__Account__c = testAcnt.Id;
            testAgrmnt.Type_of_Business_Entity_Update__c = 'LLC';
            testAgremntForDelete.add(testAgrmnt);
        }
        
        test.startTest();
        Delete testAgremntForDelete;
        test.stopTest();
    }
    
    //#PB 1 : Agreement Status Update_new
    public static testMethod void forAgreementStatusUpdate_new() {
        
        Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        Opportunity testOpp = [SELECT Id, Amount FROM Opportunity];
        Account testAcnt = [SELECT Id FROM Account];
        
        Apttus__APTS_Agreement__c testParentAgreement = new Apttus__APTS_Agreement__c();
        testParentAgreement.Name = 'Agrement1';
        testParentAgreement.Related_Opportunity_APTS__c = testOpp.Id;
        testParentAgreement.Apttus__Account__c = testAcnt.Id;
        insert testParentAgreement;
        
        List<Apttus__APTS_Agreement__c> testAgremntForUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c testAgrmnt : testAgrmntList) {
            testAgrmnt.Agreement_History__c = 'Supersedes Existing';
            testAgrmnt.Apttus__Status_Category__c = 'In Effect';
            testAgrmnt.Apttus__Status__c = 'Activated';
            testAgrmnt.Apttus__Parent_Agreement__c = testParentAgreement.Id;
            testAgremntForUpdate.add(testAgrmnt);
        }
        
        test.startTest();
        update testAgremntForUpdate;
        test.stopTest();
        
        List<Apttus__APTS_Agreement__c> testAgrmntListForAssertion = [SELECT Id, Apttus__Status_Category__c, Apttus__Status__c, Superseded_by__c FROM Apttus__APTS_Agreement__c WHERE Id =: testParentAgreement.Id];
        system.assertEquals('Expired', testAgrmntListForAssertion[0].Apttus__Status_Category__c);
        system.assertEquals('Superseded', testAgrmntListForAssertion[0].Apttus__Status__c);
    }
    
    //#PB 1 : Agreement update for Supplemental Agreements
    ///Creteria 1: Supplement OF
    public static testMethod void forAgreementSupplementOfCreteria() {
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        Opportunity testOpp = [SELECT Id, Amount FROM Opportunity];
        Account testAcnt = [SELECT Id FROM Account];
        
        Apttus__APTS_Agreement__c testParentAgreement = new Apttus__APTS_Agreement__c();
        testParentAgreement.Name = 'Agrement1';
        testParentAgreement.Related_Opportunity_APTS__c = testOpp.Id;
        testParentAgreement.Apttus__Account__c = testAcnt.Id;
        testParentAgreement.Notification_Days_Reqd_to_Change_Price__c = '1';
        testParentAgreement.Payment_Type__c = 'Invoice';
        testParentAgreement.Prepay_Frequency__c = 'One-time';
        testParentAgreement.Prepayment_Amount_Input__c = 2000;
        testParentAgreement.Related_MSA__c = testAgrmntList[0].Id;
        testParentAgreement.Total_Committed_Revenue_Input__c = 2000;
        testParentAgreement.Underlying_Agreement__c = 'MSA';
        insert testParentAgreement;
        
        Id theOrderFormRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Order Form').getRecordTypeId();
        
        List<Apttus__APTS_Agreement__c> testAgremntForInsert = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c testChildAgreement = new Apttus__APTS_Agreement__c();
        testChildAgreement.Name = 'Agrement1';
        testChildAgreement.Related_Opportunity_APTS__c = testOpp.Id;
        testChildAgreement.Apttus__Account__c = testAcnt.Id;
        testChildAgreement.Apttus__Parent_Agreement__c = testParentAgreement.Id;
        testChildAgreement.RecordTypeId = theOrderFormRecordId;
        
        test.startTest();
        insert testChildAgreement;
        test.stopTest();
        
        List<Apttus__APTS_Agreement__c> testAgrmntListForAssertion = [SELECT Id, Underlying_Agreement__c, Total_Committed_Revenue_Input__c, Related_MSA__c, Prepayment_Amount_Input__c, Notification_Days_Reqd_to_Change_Price__c, Payment_Type__c, Prepay_Frequency__c FROM Apttus__APTS_Agreement__c WHERE Id =: testChildAgreement.Id];
        system.assertEquals('MSA', testAgrmntListForAssertion[0].Underlying_Agreement__c);
        system.assertEquals(2000, testAgrmntListForAssertion[0].Total_Committed_Revenue_Input__c);
        system.assertEquals(testAgrmntList[0].Id, testAgrmntListForAssertion[0].Related_MSA__c);
        system.assertEquals(2000, testAgrmntListForAssertion[0].Prepayment_Amount_Input__c);
        system.assertEquals('1', testAgrmntListForAssertion[0].Notification_Days_Reqd_to_Change_Price__c);
        system.assertEquals('Invoice', testAgrmntListForAssertion[0].Payment_Type__c);
        system.assertEquals('One-time', testAgrmntListForAssertion[0].Prepay_Frequency__c);
    }
    
    //#PB 2 : Agreement update for Supplemental Agreements
    //Creteria 2: Amendment/Addendum
    public static testMethod void forAgreementAmendmentAddendumCreteria() {
        
        List<Apttus__APTS_Agreement__c> testAgrmntList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        Opportunity testOpp = [SELECT Id, Amount FROM Opportunity];
        Account testAcnt = [SELECT Id FROM Account];
        
        Apttus__APTS_Agreement__c testParentAgreement = new Apttus__APTS_Agreement__c();
        testParentAgreement.Name = 'Agrement1';
        testParentAgreement.Related_Opportunity_APTS__c = testOpp.Id;
        testParentAgreement.Apttus__Account__c = testAcnt.Id;
        insert testParentAgreement;
        
        Id theAmendmentAddendumRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Amendment/Addendum').getRecordTypeId();
        
        Apttus__APTS_Agreement__c testChildAgreement = new Apttus__APTS_Agreement__c();
        testChildAgreement.Name = 'Agrement1';
        testChildAgreement.Related_Opportunity_APTS__c = testOpp.Id;
        testChildAgreement.Apttus__Account__c = testAcnt.Id;
        testChildAgreement.Apttus__Parent_Agreement__c = testParentAgreement.Id;
        testChildAgreement.RecordTypeId = theAmendmentAddendumRecordId;
        
        test.startTest();
        insert testChildAgreement;
        test.stopTest();
        
        List<Apttus__APTS_Agreement__c> testAgrmntListForAssertion = [SELECT Id, Apttus__Term_Months__c FROM Apttus__APTS_Agreement__c WHERE Id =: testChildAgreement.Id];
        system.assertEquals(0, testAgrmntListForAssertion[0].Apttus__Term_Months__c);
        
    }
}