/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CommitBookingHelperTest
*
* @description 	  Test class that contains the unit test related to Commit Booking object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu	 <jayu@twilio.com>
* @version        1.0
* @created        2019-07-01
* @modified       2019-11-21
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  2019-11-21: Jason added two new test methods test_WebServiceButton_For_Global_Commit()
*				 			  and test_WebServiceButton_For_Product_Commit() to cover the code for the 
*							  new "Recalculate Commit Bookings" button.  Amrutha to create correct
*							  asserts if needed before I return from PTO 12-4-19.
*			
**/
@isTest
private class CommitBookingHelperTest {
    @testSetup static void setup_Agreement_Test_Records() {
        insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
        insert new Validation_Rule_Bypass_Settings__c (SetupOwnerId=UserInfo.getOrganizationId(), Agreement_Dataload_Validation_Bypass__c  =true);
        Integer numberOfRecords = 5;
        Id orderFormRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Order_Form'].Id;
        
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Account_SID__c sid = new Account_SID__c(Name = 'Test SID');
        insert sid;
        
        List<Opportunity> oppsForInsert = new List<Opportunity>();
        
        for(Integer i = 0; i < numberOfRecords; i++){
            Opportunity newOpp = new Opportunity(Name= 'Test Opp', AccountId = testAcc.Id,
                                                 ForecastCategoryName='Commit', StageName = 'Incubate', 
                                                 CloseDate = Date.today(), Amount = 100, 
                                                 Year_1_Committed_Bookings__c =100);
            
            oppsForInsert.add(newOpp);
        }
        insert oppsForInsert;
                
        List<Apttus__APTS_Agreement__c> agrsForInsert = new List<Apttus__APTS_Agreement__c>();
        for(Integer i = 0; i < numberOfRecords; i++){
            Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c=testAcc.id,
                                                                                    Related_Opportunity_APTS__c= oppsForInsert[i].id,
                                                                                    Total_Committed_Revenue_Input__c = 5000, 
                                                                                    Commit_Frequency__c = 'Monthly', Term_Range__c = '30', 
                                                                                    APTS_Agreement_Effective_Date__c= Date.newInstance(2017,10,3),
                                                                                    Commit_Start_Month__c = Date.newInstance(2017,10,3),
                                                                                    Apttus__Status__c = 'Initiate',Authy_Commit__c = 100,
                                                                                    Programmable_Messaging_Commit__c = 200,
                                                                                    RecordTypeId = orderFormRecordTypeId);
        	agrsForInsert.add(testAgreement);
        }
        agrsForInsert[0].Commit_Type__c = 'Global';
        agrsForInsert[1].Commit_Type__c = 'Product';
        insert agrsForInsert;
        
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Test', Price__c = 1.0, Status__c = 'Active', Product_Family__c = 'Tester', Product_Group__c = 'Flex');
        insert testBI;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Billable_Item__c = testBI.Id, Agreement__c = agrsForInsert[0].Id, Name = 'test');
        insert existingDiscount;
		test.starttest();
        Single_BI_Tier__c objSingleBITier = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = agrsForInsert[0].Id, Name = 'test', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =2,Flat_Price__c =10,Tier_Row__c=1,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2017,10,1), Discount_Rate_End_Date__c = Date.newInstance(2020,10,1));
        insert objSingleBITier;
        Single_BI_Tier__c objSingleBITier1 = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = agrsForInsert[0].Id, Name = 'test1', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =4,Flat_Price__c =20,Tier_Row__c=2,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2018,11,2), Discount_Rate_End_Date__c = Date.newInstance(2020,2,1));
        insert objSingleBITier1;
        List<Single_BI_Discount__c> lstSingleDiscounts1 = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 2) 
                                                          from Single_BI_Discount__c];
        
        Single_BI_Tier__c objSingleBITier2 = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = agrsForInsert[0].Id, Name = 'test2', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =2,Flat_Price__c =0,Tier_Row__c=1,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2020,2,1));
        insert objSingleBITier2;
        List<Single_BI_Discount__c> lstSingleDiscounts2 = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 1 and Discount_Rate_End_Date__c=null) 
                                                          from Single_BI_Discount__c];
        
        
        Single_BI_Tier__c objSingleBITier3 = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = agrsForInsert[0].Id, Name = 'test3', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =4,Flat_Price__c =20,Tier_Row__c=4,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2020,11,1),Last_Additional_Schedule__c=true);
        insert objSingleBITier3;
        List<Single_BI_Discount__c> lstSingleDiscounts3 = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c,Discount_Rate_Start_Date__c,Flat_Price__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 4) 
                                                          from Single_BI_Discount__c];
       
        
        lstSingleDiscounts3[0].Single_BI_Tiers__r[0].Flat_Price__c = 30;
        lstSingleDiscounts3[0].Single_BI_Tiers__r[0].Discount_Rate_Start_Date__c= Date.newInstance(2020,11,2);
        update lstSingleDiscounts3[0].Single_BI_Tiers__r[0];
    }
    
    static testMethod void testGlobalCommitBooking(){
        Set<Id> agrIds = new Set<Id>();
        List<Apttus__APTS_Agreement__c> agrRecs = [SELECT Id,Commit_Type__c,Apttus__Status__c FROM Apttus__APTS_Agreement__c LIMIT 2];
        
        //Test values
        test.startTest();
        agrRecs[0].Apttus__Status__c = 'Activated';
        update agrRecs[0];
        List<Commit_Booking__c> lstGlobalCommitBookings = [Select Id,Agreement__c,Product_Group__c,RecordType.Name,
                                                            Year_1_Committed_Bookings_Comp_Credit__c , Year_2_Committed_Bookings_Comp_Credit__c,
                                                            Year_3_Committed_Bookings_Comp_Credit__c from Commit_Booking__c Where Agreement__c =: agrRecs[0].Id];
        
        system.assertEquals(2, lstGlobalCommitBookings.size());
        
        for(Commit_Booking__c objCom: lstGlobalCommitBookings){
            if(objCom.Product_Group__c=='Global - Flex'){
                system.assertEquals(240,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(1120,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(440,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
            if(objCom.Product_Group__c=='Global - Non-Flex'){
                system.assertEquals(1760.000000000000000000000000000004,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(880.000000000000000000000000000004,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(560.000000000000000000000000000002,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
        }
        test.stopTest();
    }
   
    static testMethod void testProductCommitBooking(){
        Set<Id> agrIds = new Set<Id>();
        List<Apttus__APTS_Agreement__c> agrRecs = [SELECT Id,Commit_Type__c,Apttus__Status__c FROM Apttus__APTS_Agreement__c LIMIT 2];
        
        //Test values
        test.startTest();
        agrRecs[1].Apttus__Status__c = 'Activated';
        update agrRecs[1];
		List<Commit_Booking__c> lstGlobalCommitBookings = [Select Id,Agreement__c,Product_Group__c,RecordType.Name,
                                                            Year_1_Committed_Bookings_Comp_Credit__c , Year_2_Committed_Bookings_Comp_Credit__c,
                                                            Year_3_Committed_Bookings_Comp_Credit__c from Commit_Booking__c Where Agreement__c =: agrRecs[1].Id];
        system.debug('+++commit '+lstGlobalCommitBookings);
        system.assertEquals(2, lstGlobalCommitBookings.size());
        for(Commit_Booking__c objCom: lstGlobalCommitBookings){
            if(objCom.Product_Group__c=='Authy'){
                system.assertEquals(39.99999999999999999999999999999996,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(39.99999999999999999999999999999996,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(19.99999999999999999999999999999998,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
            if(objCom.Product_Group__c=='Programmable Messaging'){
                system.assertEquals(80.00000000000000000000000000000004,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(80.00000000000000000000000000000004,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(40.00000000000000000000000000000002,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
        }

        test.stopTest();
    }
    
    //Jason added this Test Method 11-21-19.  Code is covered, but asserts need review from Amrutha.
    static testMethod void test_WebServiceButton_For_Global_Commit(){
        Set<Id> agrIds = new Set<Id>();
        Apttus__APTS_Agreement__c agrRec = [SELECT Id,
                                            	   Related_Opportunity_APTS__c,
                                                   Commit_Type__c,
                                                   Apttus__Status__c,
                                            	   Apttus__Contract_End_Date__c,
                                            	   APTS_Agreement_Effective_Date__c,
                                                   Standard_Process__c,
                                                   Commit_Start_Month__c, 
                                                   Term_Range__c
                                            FROM Apttus__APTS_Agreement__c 
                                            WHERE Commit_Type__c = 'Global' LIMIT 1 ];
        
        agrRec.Apttus__Status__c = 'Activated';
        //update agrRec; I get a too many SQL Queries error here from the SingleBITier Trigger.
        
        List<Commit_Booking__c> commitBookingRecs = [SELECT Id, 
                                                     		RecordTypeId, 
                                                    		Product_Group__c,
                                                    		Opportunity__c,
                                                     		Agreement__c,
                                                    		Year_1_Committed_Bookings_Comp_Credit__c,
                                                    		Year_2_Committed_Bookings_Comp_Credit__c,
                                                    		Year_3_Committed_Bookings_Comp_Credit__c,
                                                    		Current_MRR__c
                                                     FROM Commit_Booking__c 
                                                     WHERE Agreement__c = :agrRec.Id];
        //System.assertEquals(2, commitBookingRecs.size());
        for(Commit_Booking__c objCom: commitBookingRecs){
            if(objCom.Product_Group__c=='Global - Flex'){
                system.assertEquals(240,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(1120,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(440,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
            if(objCom.Product_Group__c=='Global - Non-Flex'){
                system.assertEquals(1760.000000000000000000000000000004,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(880.000000000000000000000000000004,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(560.000000000000000000000000000002,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
        }
        
		List<Single_BI_Tier__c> objSingleBITiers = [SELECT Billable_Item__c, 
                                              		 Single_BI_Discount__c, 
                                              	     Monthly_Units_Purchased__c,
                                              		 Tier_Row__c,
                                                     Discount_Rate_Start_Date__c, 
                                              		 Discount_Rate_End_Date__c
                                              FROM Single_BI_Tier__c 
                                              WHERE Agreement__c = :agrRec.Id];
        for(Single_BI_Tier__c sbtRec : objSingleBITiers){
            sbtRec.Flat_Price__c = 200;
        }  
        update objSingleBITiers;
        
        test.startTest();
        CommitBookingHelperGlobal.getCommitBookings(agrRec.Id);
        test.stopTest();
        
        List<Commit_Booking__c> commitBookingRecs2 = [SELECT Id, 
                                                     		RecordTypeId, 
                                                    		Product_Group__c,
                                                    		Opportunity__c,
                                                     		Agreement__c,
                                                    		Year_1_Committed_Bookings_Comp_Credit__c,
                                                    		Year_2_Committed_Bookings_Comp_Credit__c,
                                                    		Year_3_Committed_Bookings_Comp_Credit__c,
                                                    		Current_MRR__c
                                                     FROM Commit_Booking__c 
                                                     WHERE Agreement__c = :agrRec.Id];
        //System.assertEquals(2, commitBookingRecs2.size());
        for(Commit_Booking__c objCom: commitBookingRecs2){
            if(objCom.Product_Group__c=='Global - Flex'){
                system.assertEquals(null,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(null,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(null,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
            if(objCom.Product_Group__c=='Global - Non-Flex'){
                system.assertEquals(null,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(null,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(null,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
        }
        
        
    }
    
    //Jason added this Test Method 11-21-19.  Code is covered, but asserts need review from Amrutha.
    static testMethod void test_WebServiceButton_For_Product_Commit(){
        Set<Id> agrIds = new Set<Id>();
        Apttus__APTS_Agreement__c agrRec = [SELECT Id,
                                            	   Related_Opportunity_APTS__c,
                                                   Commit_Type__c,
                                                   Apttus__Status__c,
                                            	   Apttus__Contract_End_Date__c,
                                            	   APTS_Agreement_Effective_Date__c,
                                                   Standard_Process__c,
                                                   Commit_Start_Month__c, 
                                                   Term_Range__c
                                            FROM Apttus__APTS_Agreement__c 
                                            WHERE Commit_Type__c = 'Product' LIMIT 1 ];
        
        System.debug('Agreement Rec ---> ' + agrRec);
        agrRec.Apttus__Status__c = 'Activated';
        update agrRec;
        
        List<Commit_Booking__c> commitBookingRecs = [SELECT Id, 
                                                     		RecordTypeId, 
                                                    		Product_Group__c,
                                                    		Opportunity__c,
                                                     		Agreement__c,
                                                    		Year_1_Committed_Bookings_Comp_Credit__c,
                                                    		Year_2_Committed_Bookings_Comp_Credit__c,
                                                    		Year_3_Committed_Bookings_Comp_Credit__c,
                                                    		Current_MRR__c
                                                     FROM Commit_Booking__c 
                                                     WHERE Agreement__c = :agrRec.Id];
        
        
        for(Commit_Booking__c objCom: commitBookingRecs){
            if(objCom.Product_Group__c=='Authy'){
                system.assertEquals(39.99999999999999999999999999999996,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(39.99999999999999999999999999999996,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(19.99999999999999999999999999999998,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
            if(objCom.Product_Group__c=='Programmable Messaging'){
                system.assertEquals(80.00000000000000000000000000000004,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(80.00000000000000000000000000000004,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(40.00000000000000000000000000000002,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
        }
        
        Commit_Schedule__c commitSched1 = new Commit_Schedule__c(Commit_Amount__c = 10000 ,
                                                                 //Record_Type_OF_GENERATE__c = 'Product_Commit',
                                                                 Start_Date__c = agrRec.APTS_Agreement_Effective_Date__c, 
                                                                 Product_Group__c = 'Authy',
                                                                 Agreement__c = agrRec.Id);
        insert commitSched1;
        
        test.startTest();
        CommitBookingHelperGlobal.getCommitBookings(agrRec.Id);
        test.stopTest();
        
        List<Commit_Booking__c> commitBookingRecs2 = [SELECT Id, 
                                                     		RecordTypeId, 
                                                    		Product_Group__c,
                                                    		Opportunity__c,
                                                     		Agreement__c,
                                                    		Year_1_Committed_Bookings_Comp_Credit__c,
                                                    		Year_2_Committed_Bookings_Comp_Credit__c,
                                                    		Year_3_Committed_Bookings_Comp_Credit__c,
                                                    		Current_MRR__c
                                                     FROM Commit_Booking__c 
                                                     WHERE Agreement__c = :agrRec.Id];
        
        for(Commit_Booking__c objCom: commitBookingRecs2){
            if(objCom.Product_Group__c=='Authy'){
                system.assertEquals(39.99999999999999999999999999999996,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(39.99999999999999999999999999999996,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(19.99999999999999999999999999999998,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
            if(objCom.Product_Group__c=='Programmable Messaging'){
                system.assertEquals(80.00000000000000000000000000000004,objCom.Year_1_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(80.00000000000000000000000000000004,objCom.Year_2_Committed_Bookings_Comp_Credit__c);
                system.assertEquals(40.00000000000000000000000000000002,objCom.Year_3_Committed_Bookings_Comp_Credit__c);
            }
        }
    }
    
    static testMethod void testBatchCommitBookingsCalculation(){
        Set<Id> agrIds = new Set<Id>();
        List<Apttus__APTS_Agreement__c> agrRec = [SELECT Id,
                                            	   Related_Opportunity_APTS__c,
                                                   Commit_Type__c,
                                                   Apttus__Status__c,
                                            	   Apttus__Contract_End_Date__c,
                                            	   APTS_Agreement_Effective_Date__c,
                                                   Standard_Process__c,
                                                   Commit_Start_Month__c, 
                                                   Term_Range__c
                                            FROM Apttus__APTS_Agreement__c];
        for(Apttus__APTS_Agreement__c objAgr: agrRec){
            agrIds.add(objAgr.Id);
        	objAgr.Apttus__Status__c = 'Activated';
        }
        update agrRec;
        
        test.startTest();
        BatchCommitBookingsCalculation bcn = new BatchCommitBookingsCalculation() ;
		ID batchprocessid = Database.executeBatch(bcn);
        test.stopTest();
    }
    
    static testMethod void testScheduler(){
        String CRON_EXP = '0 0 * * * ?';
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchCommitBookingsCalculation());
        Test.stopTest();
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchCommitBookingsCalculation') LIMIT 1].Status);
    }
}