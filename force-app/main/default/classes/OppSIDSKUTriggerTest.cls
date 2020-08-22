@isTest
private class OppSIDSKUTriggerTest {

	private static testMethod void test() {
        Account newAcc = new Account(Name = 'Test Acc');
        
        insert newAcc;
        
        Opportunity newOpp = new Opportunity(Name= 'Test Opp', AccountId = newAcc.Id, StageName = 'Incubate', CloseDate = Date.today(), Amount = 100, FY_16_Primary_Product__c = 'Programmable Messaging');
        
        insert newOpp;
        
        Account_SID__c newSid = new Account_SID__c(Name = 'AC123', Amort_Usage_FY_18_Flex_Last_Month__c = 100, Account_SID__c = 'AC123');
        
        insert newSid;
        
        Twilio_Usage__c usage = new Twilio_Usage__c(AccountSid__c = 'Test', Currency__c = 'USD', Total__c = 100, Product__c = 'Flex', Year__c = Date.today().year(), Month__c = Date.today().addMonths(-1).month(), Amortized_Usage_FY_18_Flex__c = 100, Related_Account_SID__c = newSid.Id);
        
        insert usage;
        
        Opportunity_Product__c oppProduct = new Opportunity_Product__c(Name = 'Programmable Messaging', Product_Name__c = 'Programmable Messaging', Opportunity__c = newOpp.Id);
        
        insert oppProduct;
        
        Account_SID_SKU__c accSku = new Account_SID_SKU__c (New_Business_Opportunity__c = newOpp.Id, Opportunity_Product__c = oppProduct.Id, Account_SID__c = newSid.Id);
        
        AccountSID_to_SKU_Mappings__c setting = new AccountSID_to_SKU_Mappings__c(Name = 'Test', Product_Name__c = 'Programmable Messaging', Usage_Field__c = 'Amortized_Usage_FY_18_Flex__c', Year__c = 2018, Opp_SKU_Field__c = 'Flex_MRR__c', Account_SID_API_Name__c = 'Average_FY_18_Flex_MRR__c',  SID_Last_Month_Usage_Field__c = 'Amort_Usage_FY_18_Flex_Last_Month__c');
        
        insert setting;
        
        Opp_SID_SKU__c sku = new Opp_SID_SKU__c(Opportunity__c = newOpp.Id, Account_SID__c = newSid.Id);
        
        Test.startTest();
            insert sku;
            insert accSku;
            sku.Account_SID_Added_Date_Override__c = Date.today().addDays(1);
            update sku;
            delete sku;
        Test.stopTest();
	}

}