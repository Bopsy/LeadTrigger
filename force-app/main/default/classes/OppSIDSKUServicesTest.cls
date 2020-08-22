/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  OppSIDSKUServicesTest
*
* @description 	  Test class tests the OppSIDSKUServices and BatchUpdateOppSIDSKU class.  
*			      Ensures that correct OppSIDSKU fields are populated.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2020-03-10
* @modified       
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class OppSIDSKUServicesTest {
    @TestSetup
    static void setupData(){
        Id prtOppRecordId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Portfolio_Revenue' LIMIT 1].Id;

        Account newAcc = new Account(Name = 'Test Acc');
        
        insert newAcc;
        
        Opportunity newOpp = new Opportunity(Name= 'Test Opp', 
                                             AccountId = newAcc.Id, 
                                             StageName = 'Incubate', 
                                             CloseDate = Date.today(), 
                                             Amount = 100, 
                                             FY_16_Primary_Product__c = 'Programmable Messaging',
                                             RecordTypeId = prtOppRecordId);
        
        insert newOpp;
        
        Account_SID__c newSid = new Account_SID__c(Name = 'AC123', 
                                                   Amort_Usage_FY_18_Flex_Last_Month__c = 100, 
                                                   Amort_Usage_FY_18_Messaging_Last_Month__c = 1000,
                                                   Account_SID__c = 'AC123');
        Account_SID__c newSid2 = new Account_SID__c(Name = 'AC456', 
                                                   Amort_Usage_FY_18_Flex_Last_Month__c = 100, 
                                                   Amort_Usage_FY_18_Messaging_Last_Month__c = 1000,
                                                   Account_SID__c = 'AC456');
        insert new List<Account_SID__c>{newSid, newSid2};
        
        Twilio_Usage__c usage = new Twilio_Usage__c(AccountSid__c = 'Test', 
                                                    Currency__c = 'USD', 
                                                    Total__c = 100, 
                                                    Product__c = 'Programmable Messaging', 
                                                    Year__c = Date.today().year(), Month__c = Date.today().addMonths(-1).month(), 
                                                    Amortized_Usage_FY_18_Flex__c = 100, 
                                                    Related_Account_SID__c = newSid.Id);
        Twilio_Usage__c usage2 = new Twilio_Usage__c(AccountSid__c = 'Test', 
                                                     Currency__c = 'USD', 
                                                     Total__c = 100, 
                                                     Product__c = 'Programmable Voice', 
                                                     Year__c = Date.today().year(), Month__c = Date.today().addMonths(-1).month(), 
                                                     Amortized_Usage_FY_18_Flex__c = 100, 
                                                     Related_Account_SID__c = newSid2.Id);
        insert new List<Twilio_Usage__c>{usage, usage2};
        
        Opportunity_Product__c oppProduct = new Opportunity_Product__c(Name = 'Programmable Messaging', 
                                                                       Product_Name__c = 'Programmable Messaging', 
                                                                       Opportunity__c = newOpp.Id);
        Opportunity_Product__c oppProduct2 = new Opportunity_Product__c(Name = 'Programmable Voice', 
                                                                        Product_Name__c = 'Programmable Voice', 
                                                                        Opportunity__c = newOpp.Id);
        insert new List<Opportunity_Product__c>{oppProduct, oppProduct2};
        
        Account_SID_SKU__c accSku = new Account_SID_SKU__c (New_Business_Opportunity__c = newOpp.Id, 
                                                            Opportunity_Product__c = oppProduct.Id, 
                                                            Account_SID__c = newSid.Id);
        Account_SID_SKU__c accSku2 = new Account_SID_SKU__c (New_Business_Opportunity__c = newOpp.Id, 
                                                            Opportunity_Product__c = oppProduct2.Id, 
                                                            Account_SID__c = newSid2.Id);          
        insert new List<Account_SID_SKU__c>{accSku, accSku2};                                          
        
        /*AccountSID_to_SKU_Mappings__c setting = new AccountSID_to_SKU_Mappings__c(Name = 'Test', 
                                                                                  Product_Name__c = 'Programmable Messaging', 
                                                                                  Usage_Field__c = 'Amortized_Usage_FY_18_Flex__c', 
                                                                                  Year__c = 2018, Opp_SKU_Field__c = 'Flex_MRR__c', 
                                                                                  Account_SID_API_Name__c = 'Average_FY_18_Flex_MRR__c',  
                                                                                  SID_Last_Month_Usage_Field__c = 'Amort_Usage_FY_18_Flex_Last_Month__c');
        
        insert setting;*/
        
        Opp_SID_SKU__c sku = new Opp_SID_SKU__c(Opportunity__c = newOpp.Id, 
                                                Account_SID__c = newSid.Id);
        Opp_SID_SKU__c sku2 = new Opp_SID_SKU__c(Opportunity__c = newOpp.Id, 
                                                 Account_SID__c = newSid2.Id);
        insert new List<Opp_SID_SKU__c>{sku, sku2};
    }
	
    //Test class confirms that the batch is updating Opp SID SKU records correctly.
    private static testMethod void ensure_Opp_SID_SKUs_Update(){
        List<Account_SID__c> accSIDsForReview = [SELECT Id,
                                                        Name,
                                                        Amort_Usage_FY_18_Messaging_Last_Month__c
                                                 FROM Account_SID__c];

        accSIDsForReview[0].Amort_Usage_FY_18_Messaging_Last_Month__c = 2000;
        accSIDsForReview[1].Amort_Usage_FY_18_Messaging_Last_Month__c = 3000;
        update accSIDsForReview;
        
        List<Opp_SID_SKU__c> oppSIDSKUsForReviewBefore = [SELECT Id,
                                                                 Account_SID__r.Amort_Usage_FY_18_Messaging_Last_Month__c,
                                                                 Messaging_Usage_Last_Month__c,
                                                                 Messaging_Usage_Last_Month_Stamp__c,
                                                                 Account_SID__c
                                                          FROM Opp_SID_SKU__c];

        for(Opp_SID_SKU__c oppSIDSKURecBefore : oppSIDSKUsForReviewBefore){
            System.assertEquals(1000, oppSIDSKURecBefore.Messaging_Usage_Last_Month_Stamp__c);
        }

        test.startTest();
        Database.executeBatch(new BatchUpdateOppSIDSKU(), 100);
        test.stopTest();

        List<Opp_SID_SKU__c> oppSIDSKUsForReviewAfter = [SELECT Id,
                                                                Account_SID__r.Amort_Usage_FY_18_Messaging_Last_Month__c,
                                                                Messaging_Usage_Last_Month__c,
                                                                Messaging_Usage_Last_Month_Stamp__c,
                                                                Account_SID__c
                                                         FROM Opp_SID_SKU__c];
        Integer numberOfRecs = 0;
        for(Opp_SID_SKU__c oppSIDSKURecAfter : oppSIDSKUsForReviewAfter){
            if(oppSIDSKURecAfter.Account_SID__c == accSIDsForReview[0].Id){
                System.assertEquals(2000, oppSIDSKURecAfter.Messaging_Usage_Last_Month_Stamp__c);
                numberOfRecs++;
            } else if (oppSIDSKURecAfter.Account_SID__c == accSIDsForReview[1].Id){
                System.assertEquals(3000, oppSIDSKURecAfter.Messaging_Usage_Last_Month_Stamp__c);
                numberOfRecs++;
            }
        }
        System.assertEquals(2, numberOfRecs);
    }
    
    //Test class confirms that the batch DOES NOT update Opp SID SKU records.
    private static testMethod void ensure_Opp_SID_SKUs_Do_Not_Update(){
        
        List<Opp_SID_SKU__c> oppSIDSKUsForReviewBefore = [SELECT Id,
                                                                 Account_SID__r.Amort_Usage_FY_18_Messaging_Last_Month__c,
                                                                 Messaging_Usage_Last_Month__c,
                                                                 Messaging_Usage_Last_Month_Stamp__c,
                                                                 Account_SID__c
                                                          FROM Opp_SID_SKU__c];

        for(Opp_SID_SKU__c oppSIDSKURecBefore : oppSIDSKUsForReviewBefore){
            System.assertEquals(1000, oppSIDSKURecBefore.Messaging_Usage_Last_Month_Stamp__c);
        }

        test.startTest();
        Database.executeBatch(new BatchUpdateOppSIDSKU(), 100);
        test.stopTest();

        List<Opp_SID_SKU__c> oppSIDSKUsForReviewAfter = [SELECT Id,
                                                                Account_SID__r.Amort_Usage_FY_18_Messaging_Last_Month__c,
                                                                Messaging_Usage_Last_Month__c,
                                                                Messaging_Usage_Last_Month_Stamp__c,
                                                                Account_SID__c
                                                         FROM Opp_SID_SKU__c];
        Integer numberOfRecs = 0;
        for(Opp_SID_SKU__c oppSIDSKURecAfter : oppSIDSKUsForReviewAfter){
            System.assertEquals(1000, oppSIDSKURecAfter.Messaging_Usage_Last_Month_Stamp__c);
            numberOfRecs++;
        }
        System.assertEquals(2, numberOfRecs);
    }
}