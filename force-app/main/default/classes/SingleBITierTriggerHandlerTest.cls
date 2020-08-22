/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  SingleBITierTriggerHandlerTest
*
* @description 	  Test class that contains the unit test related to single BI tier object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2018-01-30
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class SingleBITierTriggerHandlerTest {
    
    //Method to cover positive test case
    static testmethod void SingleBITierTriggerHandlerPositiveCase(){
        Account newAcc = new Account(Name = 'Test Acc');
        insert newAcc;
        Opportunity newOpp = new Opportunity(Name= 'Test Opp', AccountId = newAcc.Id,ForecastCategoryName='Commit', StageName = 'Incubate', CloseDate = Date.today(), Amount = 100, FY_16_Primary_Product__c = 'Flex', Year_1_Committed_Bookings__c =100);
        insert newOpp;
        Agreement_Attachment_Mapping__c setting = new Agreement_Attachment_Mapping__c(Name = 'Test Setting', Agreement_Field_Name__c = 'Commit_Frequency__c', Attachment_Field_Name__c = 'Commit_Frequency__c');
        insert setting;
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c=newAcc.id,Related_Opportunity_APTS__c= newOpp.id,Total_Committed_Revenue_Input__c = 5000, Commit_Frequency__c = 'Monthly', Term_Range__c = '30', APTS_Agreement_Effective_Date__c= Date.newInstance(2017,10,3),Apttus__Status__c='Activated');
        insert testAgreement;
        Agreement_Attachment__c  newAttachment = new Agreement_Attachment__c  (Name = 'Test_2', Agreement__c  = testAgreement.Id);
        insert newAttachment;
        
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Test', Price__c = 1.0, Status__c = 'Active', Product_Family__c = 'Tester', Product_Group__c = 'Flex');
        insert testBI;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test');
        insert existingDiscount;
		test.starttest();
        Single_BI_Tier__c objSingleBITier = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =2,Flat_Price__c =10,Tier_Row__c=1,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2017,10,1), Discount_Rate_End_Date__c = Date.newInstance(2018,10,1));
        insert objSingleBITier;
        List<Single_BI_Discount__c> lstSingleDiscounts = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 1) 
                                                          from Single_BI_Discount__c];
        system.assertEquals(240, lstSingleDiscounts[0].Total_Flex_Commit__c);
        system.assertEquals(12, lstSingleDiscounts[0].Single_BI_Tiers__r[0].Flex_Tier_Duration__c);
        
        Single_BI_Tier__c objSingleBITier1 = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test1', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =4,Flat_Price__c =20,Tier_Row__c=2,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2018,11,2), Discount_Rate_End_Date__c = Date.newInstance(2020,2,1));
        insert objSingleBITier1;
        List<Single_BI_Discount__c> lstSingleDiscounts1 = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 2) 
                                                          from Single_BI_Discount__c];
        system.assertEquals(1440, lstSingleDiscounts1[0].Total_Flex_Commit__c);
        system.assertEquals(15, lstSingleDiscounts1[0].Single_BI_Tiers__r[0].Flex_Tier_Duration__c);
        Single_BI_Tier__c objSingleBITier2 = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test2', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =2,Flat_Price__c =0,Tier_Row__c=1,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2020,2,1));
        insert objSingleBITier2;
        List<Single_BI_Discount__c> lstSingleDiscounts2 = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 1 and Discount_Rate_End_Date__c=null) 
                                                          from Single_BI_Discount__c];
        system.assertEquals(1440, lstSingleDiscounts2[0].Total_Flex_Commit__c);
        system.assertEquals(2, lstSingleDiscounts2[0].Single_BI_Tiers__r[0].Flex_Tier_Duration__c);
        
        Single_BI_Tier__c objSingleBITier3 = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test3', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =4,Flat_Price__c =20,Tier_Row__c=4,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2020,11,1),Last_Additional_Schedule__c=true);
        insert objSingleBITier3;
        List<Single_BI_Discount__c> lstSingleDiscounts3 = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c,Discount_Rate_Start_Date__c,Flat_Price__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 4) 
                                                          from Single_BI_Discount__c];
        system.assertEquals(1440, lstSingleDiscounts3[0].Total_Flex_Commit__c);
        system.assertEquals(null, lstSingleDiscounts3[0].Single_BI_Tiers__r[0].Flex_Tier_Duration__c);
        
        lstSingleDiscounts3[0].Single_BI_Tiers__r[0].Flat_Price__c = 30;
        lstSingleDiscounts3[0].Single_BI_Tiers__r[0].Discount_Rate_Start_Date__c= Date.newInstance(2020,11,2);
        update lstSingleDiscounts3[0].Single_BI_Tiers__r[0];
        List<Single_BI_Discount__c> lstSingleDiscounts4 = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c,Discount_Rate_Start_Date__c,Flat_Price__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 4) 
                                                          from Single_BI_Discount__c ];
        system.assertEquals(1440, lstSingleDiscounts4[0].Total_Flex_Commit__c);
        system.assertEquals(0, lstSingleDiscounts4[0].Single_BI_Tiers__r[0].Flex_Tier_Duration__c);
        
        delete lstSingleDiscounts4[0].Single_BI_Tiers__r[0];
        List<Single_BI_Discount__c> lstSingleDiscounts5 = [Select Id,Total_Flex_Commit__c from Single_BI_Discount__c ];
        system.assertEquals(1440, lstSingleDiscounts5[0].Total_Flex_Commit__c);
        
        Opportunity objOpp = [Select Id,Software_Validation__c,Y1_Software_Committed_Bookings_Validated__c,
                                                                 Y2_Software_Committed_Bookings_Validated__c ,Y3_Software_Committed_Bookings_Validated__c 
                                                                FROM Opportunity where accountId =:newAcc.Id];
        system.assertEquals(240, objOpp.Y1_Software_Committed_Bookings_Validated__c);
        system.assertEquals(880, objOpp.Y2_Software_Committed_Bookings_Validated__c);
        system.assertEquals(320, objOpp.Y3_Software_Committed_Bookings_Validated__c);
        system.assertEquals('False', objOpp.Software_Validation__c);
		test.stoptest();
    }
 
    //Method to cover positive test case
    static testmethod void SingleBITierTriggerHandlerNegativeCase(){
        Account newAcc = new Account(Name = 'Test Acc');
        insert newAcc;
        Opportunity newOpp = new Opportunity(Name= 'Test Opp', AccountId = newAcc.Id,ForecastCategoryName='Commit', StageName = 'Incubate', CloseDate = Date.today(), Amount = 100, FY_16_Primary_Product__c = 'Flex');
        insert newOpp;
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c=newAcc.id,Related_Opportunity_APTS__c= newOpp.id,Total_Committed_Revenue_Input__c = 5000, Commit_Frequency__c = 'Monthly', Term_Range__c = '12');
        insert testAgreement;
        Agreement_Attachment__c  newAttachment = new Agreement_Attachment__c  (Name = 'Test_2', Agreement__c  = testAgreement.Id);
        insert newAttachment;
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Test', Price__c = 1.0, Status__c = 'Active', Product_Family__c = 'Tester', Product_Group__c = 'Flex');
        insert testBI;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test');
        insert existingDiscount;
        test.startTest();
        Single_BI_Tier__c objSingleBITier = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test2', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =2,Flat_Price__c =0,Tier_Row__c=3,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2017,10,1));
        insert objSingleBITier;
        List<Single_BI_Discount__c> lstSingleDiscounts = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 3) 
                                                          from Single_BI_Discount__c];
        system.assertEquals(0, lstSingleDiscounts[0].Total_Flex_Commit__c);
        system.assertEquals(null, lstSingleDiscounts[0].Single_BI_Tiers__r[0].Flex_Tier_Duration__c);
        
        Single_BI_Tier__c objSingleBITier1 = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test3', 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =4,Flat_Price__c =20,Tier_Row__c=2,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2018,11,2));
        insert objSingleBITier1;
        List<Single_BI_Discount__c> lstSingleDiscounts1 = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c = 2) 
                                                          from Single_BI_Discount__c];
        system.assertEquals(0, lstSingleDiscounts1[0].Total_Flex_Commit__c);
        system.assertEquals(null, lstSingleDiscounts1[0].Single_BI_Tiers__r[0].Flex_Tier_Duration__c);
        Opportunity objOpp = [Select Id,Software_Validation__c,Y1_Software_Committed_Bookings_Validated__c,
                                                                 Y2_Software_Committed_Bookings_Validated__c ,Y3_Software_Committed_Bookings_Validated__c 
                                                                FROM Opportunity where accountId =:newAcc.Id];
        system.assertEquals(null, objOpp.Y1_Software_Committed_Bookings_Validated__c);
        system.assertEquals(null, objOpp.Y2_Software_Committed_Bookings_Validated__c);
        system.assertEquals(null, objOpp.Y3_Software_Committed_Bookings_Validated__c);
        system.assertEquals('NA', objOpp.Software_Validation__c);
        test.stopTest();
    }
    
    //Method to cover bulk test case
    static testmethod void SingleBITierTriggerHandlerBulkCase(){
        Account newAcc = new Account(Name = 'Test Acc');
        insert newAcc;
        Opportunity newOpp = new Opportunity(Name= 'Test Opp', AccountId = newAcc.Id,ForecastCategoryName='Commit', StageName = 'Incubate', CloseDate = Date.today(), Amount = 100, FY_16_Primary_Product__c = 'Flex', Year_1_Committed_Bookings__c =100);
        insert newOpp;
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c=newAcc.id,Related_Opportunity_APTS__c= newOpp.id,Total_Committed_Revenue_Input__c = 5000, Commit_Frequency__c = 'Monthly', Term_Range__c = '40',Commit_Start_Month__c=Date.newInstance(2017,10,1),APTS_Agreement_Effective_Date__c= Date.newInstance(2017,12,3),Apttus__Status__c='Activated');
        insert testAgreement;
        Agreement_Attachment__c  newAttachment = new Agreement_Attachment__c  (Name = 'Test_2', Agreement__c  = testAgreement.Id);
        insert newAttachment;
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Test', Price__c = 1.0, Status__c = 'Active', Product_Family__c = 'Tester', Product_Group__c = 'Flex');
        insert testBI;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test');
        insert existingDiscount;
        test.startTest();
        List<Single_BI_Tier__c> lstSingleTier = new List<Single_BI_Tier__c>();
        for(integer i=0;i<100;i++){
            Single_BI_Tier__c objSingleBITier = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test'+i, 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =2,Flat_Price__c =10,Tier_Row__c=1+i,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2017,10,1), Discount_Rate_End_Date__c = Date.newInstance(2021,10,1));
        	lstSingleTier.add(objSingleBITier);
        }
        insert lstSingleTier;
        List<Single_BI_Tier__c> lstSingleTier1 = new List<Single_BI_Tier__c>();
        for(integer i=0;i<200;i++){
            Single_BI_Tier__c objSingleBITier = new Single_BI_Tier__c(Billable_Item__c = testBI.Id, Agreement__c = testAgreement.Id, Name = 'test'+i, 
                                                                  Single_BI_Discount__c =existingDiscount.id, Monthly_Units_Purchased__c =2,Flat_Price__c =10,Tier_Row__c=1+i,
                                                                 Discount_Rate_Start_Date__c = Date.newInstance(2021,11,3));
        	lstSingleTier1.add(objSingleBITier);
        }
        insert lstSingleTier1;
        
        List<Single_BI_Discount__c> lstSingleDiscounts = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c,Tier_Row__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c=105) 
                                                          from Single_BI_Discount__c];
        system.assertEquals(80000, lstSingleDiscounts[0].Total_Flex_Commit__c);
        system.assertEquals(9, lstSingleDiscounts[0].Single_BI_Tiers__r[0].Flex_Tier_Duration__c);
        
        Apttus__APTS_Agreement__c testAgreement1 = [Select Id, Commit_Start_Month__c from Apttus__APTS_Agreement__c limit 1];
        testAgreement1.Commit_Start_Month__c=Date.newInstance(2021,9,3);
        update testAgreement1;
        List<Single_BI_Discount__c> lstSingleDiscounts2 = [Select Id,Total_Flex_Commit__c, 
                                                          (Select Id,Flex_Tier_Duration__c,Tier_Row__c, Total_Committed_Amount__c,Product_Group__c from Single_BI_Tiers__r where Tier_Row__c=105) 
                                                          from Single_BI_Discount__c];
        system.assertEquals(80000, lstSingleDiscounts2[0].Total_Flex_Commit__c);
        system.assertEquals(9, lstSingleDiscounts2[0].Single_BI_Tiers__r[0].Flex_Tier_Duration__c);
        
        List<Single_BI_Tier__c> lstSingleBITiers = [Select Id from  Single_BI_Tier__c];
        delete lstSingleBITiers;
        List<Single_BI_Discount__c> lstSingleDiscounts1 = [Select Id,Total_Flex_Commit__c from Single_BI_Discount__c];
        system.assertEquals(0, lstSingleDiscounts1[0].Total_Flex_Commit__c);
        
        Opportunity objOpp = [Select Id,Software_Validation__c,Y1_Software_Committed_Bookings_Validated__c,
                                                                 Y2_Software_Committed_Bookings_Validated__c ,Y3_Software_Committed_Bookings_Validated__c 
                                                                FROM Opportunity where accountId =:newAcc.Id];
        system.assertEquals(24000, objOpp.Y1_Software_Committed_Bookings_Validated__c);
        system.assertEquals(240, objOpp.Y2_Software_Committed_Bookings_Validated__c);
        system.assertEquals(240, objOpp.Y3_Software_Committed_Bookings_Validated__c);
        system.assertEquals('False', objOpp.Software_Validation__c);
        test.stopTest();
    }
}