/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CTATriggerServicesTest
*
* @description 	  Test class tests the CTATrigger and CTATriggerServices class.  Ensures that the
* 				  CTA Status picklist is correctly populating the Gainsight Status field on insert
*				  and update.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-05-28
* @modified       2018-08-06
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*				- 2018-08-06 - Added logic to test reverse functionality that updates the CTA Status 
*                              when the JBCXM__Stage__c is updated.
*                              
**/

@isTest
public class CTATriggerServicesTest {
    private static Integer numberOfRecs = 6;
    private static Date todaysDate = Date.today();
    
    @testSetup static void setup(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        List<JBCXM__CTA__c> ctasForInsert = new List<JBCXM__CTA__c>();
        for(Integer i = 0; i < numberOfRecs; i++){
        	JBCXM__CTA__c testCTA = new JBCXM__CTA__c(Name = 'Test CTA ' + i
                                                     ,JBCXM__Account__c = testAcc.Id
                                                     ,CTA_Status__c = null);
            ctasForInsert.add(testCTA);
        }
        
        insert ctasForInsert;
        
        JBCXM__PickList__c plTestRec1 = new JBCXM__PickList__c(Name = 'Event - Open'
                                                              ,JBCXM__Active__c = TRUE
                                                              ,JBCXM__SystemName__c = 'Event - Open');
        JBCXM__PickList__c plTestRec2 = new JBCXM__PickList__c(Name = 'Event - Closed Complete'
                                                              ,JBCXM__Active__c = TRUE
                                                              ,JBCXM__SystemName__c = 'Event - Closed Complete');
        JBCXM__PickList__c plTestRec3 = new JBCXM__PickList__c(Name = 'Event - Closed No Action Taken'
                                                              ,JBCXM__Active__c = TRUE
                                                              ,JBCXM__SystemName__c = 'Event - Closed No Action Taken');
        JBCXM__PickList__c plTestRec4 = new JBCXM__PickList__c(Name = 'Closed - CTA Data Incorrect'
                                                              ,JBCXM__Active__c = TRUE
                                                              ,JBCXM__SystemName__c = 'Closed - CTA Data Incorrect');
        JBCXM__PickList__c plTestRec5 = new JBCXM__PickList__c(Name = 'Event - Closed No Response'
                                                              ,JBCXM__Active__c = TRUE
                                                              ,JBCXM__SystemName__c = 'Event - Closed No Response');
        JBCXM__PickList__c plTestRec6 = new JBCXM__PickList__c(Name = 'Event - Working'
                                                              ,JBCXM__Active__c = TRUE
                                                              ,JBCXM__SystemName__c = 'Event - Working');
        insert new List<JBCXM__PickList__c>{plTestRec1, plTestRec2, plTestRec3, plTestRec4,
            plTestRec5, plTestRec6};
    }
    
	private static testMethod void ensure_CTA_Stage_and_CloseDate_Values_Are_Correct_On_Insert() {
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Map<String, Id> plMap = new Map<String, Id>();
        
        JBCXM__CTA__c ctaClosed = new JBCXM__CTA__c(Name = 'Test Insert Closed', JBCXM__Account__c = testAcc.Id,
                                                    CTA_Status__c = 'Closed - CTA Data Incorrect');
        JBCXM__CTA__c ctaOpen = new JBCXM__CTA__c(Name = 'Test Insert Open', JBCXM__Account__c = testAcc.Id,
                                                  CTA_Status__c = 'Event - Open');
        List<JBCXM__CTA__c> ctasForInsert = new List<JBCXM__CTA__c>{ctaClosed, ctaOpen};
        
        Test.startTest();
            insert ctasForInsert;
        Test.stopTest();
        
        
        /*
         * Query the PickList object to get the StageName records and put it into a map.
        */
        List<JBCXM__PickList__c> plRecords = [SELECT Id, Name FROM JBCXM__PickList__c];
        for(JBCXM__PickList__c pl : plRecords){
            plMap.put(pl.Name, pl.Id);
        } 
        
        /*
         * Query all CTAs, not just the one inserted in this method. 
        */ 
        List<JBCXM__CTA__c> ctaResults = [SELECT Id
                                          		,Name
                                          		,CTA_Status__c
                                          		,JBCXM__Stage__c
                                          		,JBCXM__ClosedDate__c
                                          FROM JBCXM__CTA__c];
        
        /*
         * Check the records and confirm the correct values are populated in JBCXM__Stage__c and JBCXM__ClosedDate__c.
		*/
        for(JBCXM__CTA__c cta : ctaResults){
            Id plId = plMap.get(cta.CTA_Status__c);
            if(cta.Name == 'Test Insert Closed'){
                System.assertEquals(plId, cta.JBCXM__Stage__c, 'The Closed CTA does not have a matching Stage lookup.');
                System.assertEquals(todaysDate, cta.JBCXM__ClosedDate__c, 'The ClosedDate should equal today\'s date.');
            } else if (cta.Name == 'Test Insert Open'){
                System.assertEquals(plId, cta.JBCXM__Stage__c, 'The Open CTA does not have a matching Stage lookup.');
            } else {
                System.assertEquals(null, cta.JBCXM__Stage__c, 'The Stage lookup should be null because the CTA_Status__c ' +
                                    		'is null.');
                System.assertEquals(null, cta.JBCXM__ClosedDate__c, 'The CTA ClosedDate should be null because the CTA_Status__c ' +
                                    'is null.');
            }
        }
	}

    private static testMethod void ensure_CTA_Stage_and_CloseDate_Values_Are_Correct_On_Update(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Map<String, Id> plMap = new Map<String, Id>();
        List<JBCXM__CTA__c> ctasForReset = new List<JBCXM__CTA__c>();
        List<JBCXM__CTA__c> ctasForUpdate = new List<JBCXM__CTA__c>();
        
        /*
         * Cycle through the CTA records and update the CTA Status.
        */
        List<JBCXM__CTA__c> ctasForReview = [SELECT Id
                                             	   ,Name
                                             	   ,CTA_Status__c
                                             	   ,JBCXM__Stage__c
                                             	   ,JBCXM__ClosedDate__c
                                             FROM JBCXM__CTA__c];
        
        for(JBCXM__CTA__c ctaRec : ctasForReview){
            System.assertEquals(null, ctaRec.CTA_Status__c);
            
            if(ctaRec.Name.Contains('0')){
                ctaRec.CTA_Status__c = 'Event - Open';
            } else if (ctaRec.Name.Contains('1')){
                ctaRec.CTA_Status__c = 'Event - Closed Complete';
            } else if (ctaRec.Name.Contains('2')){
                ctaRec.CTA_Status__c = 'Event - Closed No Action Taken';
            } else if (ctaRec.Name.Contains('3')){
                ctaRec.CTA_Status__c = 'Closed - CTA Data Incorrect';
            } else if (ctaRec.Name.Contains('4')){
                ctaRec.CTA_Status__c = 'Event - Closed No Response';
            } else if (ctaRec.Name.Contains('5')){
                ctaRec.CTA_Status__c = 'Event - Working';
            }
            ctasForUpdate.add(ctaRec);
        }
        
        Test.startTest();
            update ctasForUpdate;
        Test.stopTest();
        
        
        /*
         * Query the PickList object to get the StageName records and put it into a map.
        */
        List<JBCXM__PickList__c> plRecords = [SELECT Id, Name FROM JBCXM__PickList__c];
        for(JBCXM__PickList__c pl : plRecords){
            plMap.put(pl.Name, pl.Id);
        } 
        
        /*
         * Query all CTAs, not just the one inserted in this method. 
        */ 
        List<JBCXM__CTA__c> ctaResults = [SELECT Id
                                          		,Name
                                          		,CTA_Status__c
                                          		,JBCXM__Stage__c
                                          		,JBCXM__ClosedDate__c
                                          FROM JBCXM__CTA__c];
        for(JBCXM__CTA__c cta : ctaResults){
            Id plId = plMap.get(cta.CTA_Status__c);
            if(cta.CTA_Status__c.Contains('Closed')){
                System.debug(cta.CTA_Status__c);
                System.assertEquals(plId, cta.JBCXM__Stage__c, 'The Closed CTA does not have a matching Stage lookup.');
                System.assertEquals(todaysDate, cta.JBCXM__ClosedDate__c, 'The ClosedDate should equal today\'s date.');
            } else if (cta.CTA_Status__c.Contains('Working')){
                System.debug(cta.CTA_Status__c);
                System.assertEquals(plId, cta.JBCXM__Stage__c, 'The CTA does not have a matching Stage lookup.');
                System.assertEquals(null, cta.JBCXM__ClosedDate__c, 'The CTA ClosedDate should be null because the CTA_Status__c ' +
                                    'is open.');
            }
        }
    }
    
    private static testMethod void ensure_CTA_Status_and_CloseDate_Values_Are_Correct_On_Update(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Map<Id, JBCXM__PickList__c> plIdMap = new Map<Id, JBCXM__PickList__c>();
        Map<Integer, JBCXM__PickList__c> plMap = new Map<Integer, JBCXM__PickList__c>();
        List<JBCXM__CTA__c> ctasForReset = new List<JBCXM__CTA__c>();
        List<JBCXM__CTA__c> ctasForUpdate = new List<JBCXM__CTA__c>();
        
        /*
         * Cycle through the CTA records and update the CTA Status.
        */
        List<JBCXM__CTA__c> ctasForReview = [SELECT Id
                                             	   ,Name
                                             	   ,CTA_Status__c
                                             	   ,JBCXM__Stage__c
                                             	   ,JBCXM__ClosedDate__c
                                             FROM JBCXM__CTA__c];
        
        List<JBCXM__PickList__c> picklistRecs = [SELECT Id
                                                	   ,Name
                                                 FROM JBCXM__PickList__c];
        
        for(Integer i = 0; i < picklistRecs.size(); i++){
            plMap.put(i, picklistRecs[i]);
            plIdMap.put(picklistRecs[i].Id, picklistRecs[i]);
        }
        
        for(JBCXM__CTA__c ctaRec : ctasForReview){
            System.assertEquals(null, ctaRec.CTA_Status__c);
            
            if(ctaRec.Name.Contains('0')){
                ctaRec.JBCXM__Stage__c = plMap.get(0).Id;
            } else if (ctaRec.Name.Contains('1')){
                ctaRec.JBCXM__Stage__c = plMap.get(1).Id;
            } else if (ctaRec.Name.Contains('2')){
                ctaRec.JBCXM__Stage__c = plMap.get(2).Id;
            } else if (ctaRec.Name.Contains('3')){
                ctaRec.JBCXM__Stage__c = plMap.get(3).Id;
            } else if (ctaRec.Name.Contains('4')){
                ctaRec.JBCXM__Stage__c = plMap.get(4).Id;
            } else if (ctaRec.Name.Contains('5')){
                ctaRec.JBCXM__Stage__c = plMap.get(5).Id;
            }
            ctasForUpdate.add(ctaRec);
        }
        
        Test.startTest();
            update ctasForUpdate;
        Test.stopTest();
        
        /*
         * Query all CTAs, not just the one inserted in this method. 
        */ 
        
        List<JBCXM__CTA__c> ctaResults = [SELECT Id
                                          		,Name
                                          		,CTA_Status__c
                                          		,JBCXM__Stage__c
                                          		,JBCXM__ClosedDate__c
                                          FROM JBCXM__CTA__c];
        
        for(JBCXM__CTA__c cta : ctaResults){
            JBCXM__PickList__c testPicklistRec = plIdMap.get(cta.JBCXM__Stage__c);
            if(testPicklistRec.Name.Contains('Closed')){
                System.assertEquals(testPicklistRec.Name, cta.CTA_Status__c, 'The Closed CTA does not have a matching CTA Status.');
                System.assertEquals(todaysDate, cta.JBCXM__ClosedDate__c, 'The ClosedDate should equal today\'s date.');
            } else if (testPicklistRec.Name.Contains('Working')){
                System.assertEquals(testPicklistRec.Name, cta.CTA_Status__c, 'The CTA does not have a matching CTA Status.');
                System.assertEquals(null, cta.JBCXM__ClosedDate__c, 'The ClosedDate should equal today\'s date.');
            }
        }
    }
}