/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  AgreementTriggerHandlerTest
*
* @description 	  Test class tests the AgreementTriggerHandler.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-12-28
* @modified       
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class AgreementTriggerHandlerTest {
    //private static List<String> VALID_COMMIT_FREQUENCIES = new List<String>{'Monthly', 'Quarterly','Semi-Annual', 'Annual', 'Existing Commit'};
        
    @testSetup static void setup(){
        Integer numberOfRecords = 5;
        Id orderFormRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Order_Form'].Id;
        
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Account_SID__c sid = new Account_SID__c(Name = 'Test SID');
        insert sid;
        
        List<Opportunity> oppsForInsert = new List<Opportunity>();
        
        for(Integer i = 0; i < numberOfRecords; i++){
            Opportunity testOpp = new Opportunity(Name = 'Test Opp ' + String.valueOf(i), 
                                                  AccountId = testAcc.Id,
                                                  Amount = 10000, 
                                                  FY_16_Primary_Product__c = 'Programmable Messaging',
                                                  FY_16_Primary_Sub_Product__c = 'SMS',
                                                  Solution__c = 'SMS Support', 
                                                  Solution_Category__c = 'Contact Center',
                                                  CloseDate = Date.today(), 
                                                  Launch_Date__c = Date.today().addMonths(1),
                                                  StageName = 'Closed Won',
                                                  New_Business_Account_SID_Lookup__c = sid.Id); 
            
            oppsForInsert.add(testOpp);
        }
        insert oppsForInsert;
        
        List<Apttus__APTS_Agreement__c> agrsForInsert = new List<Apttus__APTS_Agreement__c>();
        for(Integer i = 0; i < numberOfRecords; i++){
            Apttus__APTS_Agreement__c agr = new Apttus__APTS_Agreement__c(Name = 'Test ' + i,
                                                                          RecordTypeId = orderFormRecordTypeId,
                                                                          Apttus__Account__c = testAcc.Id,
                                                                          Related_Opportunity_APTS__c = oppsForInsert[i].Id);
            agrsForInsert.add(agr);
        }
        insert agrsForInsert;
    }
    /*
    private static testMethod void ensure_Comp_Bookings_is_Checked_on_Opportunity_on_Agreement_Insert(){
        List<Opportunity> oppsForReview = [SELECT Id, Comp_Bookings_Automation__c, AccountId FROM Opportunity];
        for(Opportunity opp : oppsForReview){
            System.assertEquals(false, opp.Comp_Bookings_Automation__c);
        }
        
        List<Apttus__APTS_Agreement__c> agrsForInsert = new List<Apttus__APTS_Agreement__c>();
        for(Integer i = 0; i < 2; i++){
            Double randomNumber = Math.random();
			Integer randomIndex = (randomNumber * (VALID_COMMIT_FREQUENCIES.size() - 1)).intValue();
            
            Apttus__APTS_Agreement__c agr = new Apttus__APTS_Agreement__c(Name = 'Test ' + i,
                                                                          Related_Opportunity_APTS__c = oppsForReview[i].Id,
                                                                          Apttus__Account__c = oppsForReview[i].AccountId,
                                                                          Commit_Frequency__c = VALID_COMMIT_FREQUENCIES[randomIndex]);
            agrsForInsert.add(agr);
        }
        
        agrsForInsert[0].Apttus__Status__c = 'Activated';
        test.startTest();
        insert agrsForInsert;
        test.stopTest();
        
        List<Opportunity> oppsForReview2 = [SELECT Id, Comp_Bookings_Automation__c FROM Opportunity];
        Integer numberOfUpdatedOpps = 0;
        for(Opportunity opp : oppsForReview2){
            if(agrsForInsert[0].Related_Opportunity_APTS__c == opp.Id){
            	System.assertEquals(true, opp.Comp_Bookings_Automation__c);
                numberOfUpdatedOpps++;
            } else {
                System.assertEquals(false, opp.Comp_Bookings_Automation__c);
            }
        }
        
        System.assertEquals(5, oppsForReview2.size());
        System.assertEquals(1, numberOfUpdatedOpps);
    }
    
    private static testMethod void ensure_Comp_Bookings_is_Checked_on_Opportunity_on_Agreement_Update(){
        List<Opportunity> oppsForReview = [SELECT Id, Comp_Bookings_Automation__c, AccountId FROM Opportunity];
        for(Opportunity opp : oppsForReview){
            System.assertEquals(false, opp.Comp_Bookings_Automation__c);
        }
        
        Map<Id, Apttus__APTS_Agreement__c> oppIdToAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> agrsForReview = [SELECT Id, Related_Opportunity_APTS__c FROM Apttus__APTS_Agreement__c];
        List<Apttus__APTS_Agreement__c> agrsForUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Integer i = 0; i < 3; i++){
            Double randomNumber = Math.random();
			Integer randomIndex = (randomNumber * (VALID_COMMIT_FREQUENCIES.size() - 1)).intValue();
            
            agrsForReview[i].Commit_Frequency__c = VALID_COMMIT_FREQUENCIES[randomIndex];
            agrsForReview[i].Apttus__Status__c = 'Activated';
            oppIdToAgreementMap.put(agrsForReview[i].Related_Opportunity_APTS__c, agrsForReview[i]);
            agrsForUpdate.add(agrsForReview[i]);
        }
        
        test.startTest();
        update agrsForUpdate;
        test.stopTest();
        
        List<Opportunity> oppsForReview2 = [SELECT Id, Comp_Bookings_Automation__c FROM Opportunity];
        Integer numberOfUpdatedOpps = 0;
        for(Opportunity opp : oppsForReview2){
            if(oppIdToAgreementMap.get(opp.Id) != null){
                System.assertEquals(true, opp.Comp_Bookings_Automation__c);
                numberOfUpdatedOpps++;
            } else {
                System.assertEquals(false, opp.Comp_Bookings_Automation__c);
            }
        }
        
        System.assertEquals(5, oppsForReview2.size());
        System.assertEquals(3, numberOfUpdatedOpps);
    }
    
    private static testMethod void ensure_Comp_Bookings_is_UnChecked_on_Opportunity_on_Agreement_Update(){
        List<Opportunity> oppsForReview = [SELECT Id, Comp_Bookings_Automation__c, AccountId FROM Opportunity];
        for(Opportunity opp : oppsForReview){
            System.assertEquals(false, opp.Comp_Bookings_Automation__c);
        }
        
        Map<Id, Apttus__APTS_Agreement__c> oppIdToAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> agrsForReview = [SELECT Id, Related_Opportunity_APTS__c FROM Apttus__APTS_Agreement__c];
        List<Apttus__APTS_Agreement__c> agrsForUpdate = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> agrsForUpdate2 = new List<Apttus__APTS_Agreement__c>();
        for(Integer i = 0; i < 3; i++){
            Double randomNumber = Math.random();
			Integer randomIndex = (randomNumber * (VALID_COMMIT_FREQUENCIES.size() - 1)).intValue();
            
            agrsForReview[i].Commit_Frequency__c = VALID_COMMIT_FREQUENCIES[randomIndex];
            agrsForReview[i].Apttus__Status__c = 'Activated';
            oppIdToAgreementMap.put(agrsForReview[i].Related_Opportunity_APTS__c, agrsForReview[i]);
            agrsForUpdate.add(agrsForReview[i]);
        }
        
        test.startTest();
        update agrsForUpdate;
        test.stopTest();
        
        List<Opportunity> oppsForReview2 = [SELECT Id, Comp_Bookings_Automation__c FROM Opportunity];
        Integer numberOfUpdatedOpps = 0;
        for(Opportunity opp : oppsForReview2){
            if(oppIdToAgreementMap.get(opp.Id) != null){
                System.assertEquals(true, opp.Comp_Bookings_Automation__c);
                numberOfUpdatedOpps++;
            } else {
                System.assertEquals(false, opp.Comp_Bookings_Automation__c);
            }
        }
        
        System.assertEquals(5, oppsForReview2.size());
        System.assertEquals(3, numberOfUpdatedOpps);
        
        for(Integer i = 0; i < 3; i++){
            agrsForReview[i].Commit_Frequency__c = 'No Commit - PAYG';
            oppIdToAgreementMap.put(agrsForReview[i].Related_Opportunity_APTS__c, agrsForReview[i]);
            agrsForUpdate2.add(agrsForReview[i]);
        }
        
        update agrsForUpdate2;
        List<Opportunity> oppsForReview3 = [SELECT Id, Comp_Bookings_Automation__c FROM Opportunity];
        Integer numberOfUpdatedOpps2 = 0;
        for(Opportunity opp : oppsForReview3){
            if(oppIdToAgreementMap.get(opp.Id) != null){
                System.debug('Commit Frequency --> ' + oppIdToAgreementMap.get(opp.Id).Commit_Frequency__c);
                System.assertEquals(false, opp.Comp_Bookings_Automation__c);
                numberOfUpdatedOpps2++;
            } 
        }
        
        System.assertEquals(5, oppsForReview2.size());
        System.assertEquals(3, numberOfUpdatedOpps);
    }*/
    
    private static testMethod void ensure_Relevant_Agreements_Are_Activated(){
        Integer numberOfRecsToUpdate = 3;
        List<Apttus__APTS_Agreement__c> agreementsForUpdate = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> agreementsForTest = [SELECT Id FROM Apttus__APTS_Agreement__c];
        List<Apttus_DocuApi__DocuSignEnvelope__c> docEnvsForInsert = new List<Apttus_DocuApi__DocuSignEnvelope__c>();
        
        for(Integer i = 0; i < 3; i++){
            agreementsForTest[i].Apttus__Status__c = 'Fully Signed';
            agreementsForUpdate.add(agreementsForTest[i]);
            Apttus_DocuApi__DocuSignEnvelope__c docEnv = new Apttus_DocuApi__DocuSignEnvelope__c(Apttus_CMDSign__Agreement__c = agreementsForTest[i].Id,
                                                                                                 Apttus_DocuApi__Status__c = 'completed');
            docEnvsForInsert.add(docEnv);
        }
        
        insert docEnvsForInsert;
        update agreementsForUpdate;
        
        test.startTest();
        Database.executeBatch(new BatchUpdateAgreementsToActivated(), 200);
        test.stopTest();
        
        List<Apttus__APTS_Agreement__c> agreementsForReview = [SELECT Id, Apttus__Status__c, Apttus__Status_Category__c FROM Apttus__APTS_Agreement__c];
        System.assertEquals(5, agreementsForReview.size());
        Integer numberOfUpdatedRecords = 0;
        
        for(Apttus__APTS_Agreement__c agrRec : agreementsForReview){
            if(agrRec.Apttus__Status__c == 'Activated' && agrRec.Apttus__Status_Category__c == 'In Effect'){
                numberOfUpdatedRecords++;
            }
        }
        
        System.assertEquals(3, numberOfUpdatedRecords);
    }
}