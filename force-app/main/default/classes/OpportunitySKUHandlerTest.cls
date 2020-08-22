/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class OpportunitySKUHandlerTest {

    static testMethod void skuTest() {
		AccountSID_to_SKU_Config__c config = new AccountSID_to_SKU_Config__c(MRR_Exception__c = 100);
		insert config;
		
		Decimal mrrEx = config.MRR_Exception__c;
		Decimal mrr = mrrEx - 1;
		
		List<AccountSID_to_SKU_Mappings__c> settings = new List<AccountSID_to_SKU_Mappings__c>();
		settings.add(new AccountSID_to_SKU_Mappings__c(Name = 'Programmable Messaging', Product_Name__c = 'Programmable Messaging', Account_SID_API_Name__c = 'Programmable_Messaging_MRR__c', Year__c = 2018));
		settings.add(new AccountSID_to_SKU_Mappings__c(Name = 'Support', Product_Name__c = 'Support', Account_SID_API_Name__c = 'Support_MRR__c', Year__c = 2018));
		insert settings;

        Account acc = new Account(Name = 'Test Acc', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert acc;

		Account_SID__c sid = new Account_SID__c(Name = 'Test SID', Account__c = acc.Id, Support_MRR__c = mrr, Programmable_Messaging_MRR__c = mrr);
		Account_SID__c sid2 = new Account_SID__c(Name = 'Test SID 2', Account__c = acc.Id, Support_MRR__c = mrr, Programmable_Messaging_MRR__c = mrr);
		insert new List<Account_SID__c> { sid, sid2 };
		System.debug('SID: ' + sid);
		System.debug('SID2: ' + sid2);

        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Pipeline', CloseDate = Date.today(), New_Business_Account_SID_Lookup__c = sid.Id);
        Opportunity oppEx = new Opportunity(Name = 'Test Opp Exception', StageName = 'Pipeline', CloseDate = Date.today(), New_Business_Account_SID_Lookup__c = sid.Id);
        insert new List<Opportunity>{ opp, oppEx };

        Product2 prod = new Product2(Name = 'Forecast Lock');
        insert prod;

        PriceBookEntry pbe = new PriceBookEntry(Product2Id = prod.Id, UnitPrice = 1.0, Pricebook2Id = Test.getStandardPricebookId());
        insert pbe;
        
        Forecast_Schedule__c fs = new Forecast_Schedule__c (Opportunity__c = opp.Id, Forecast_Amount__c = 100, Start_Date__c = Date.today());
        insert fs;

		Opportunity_Product__c op = new Opportunity_Product__c(Name = 'Test Opp Prod', Amount__c = 100, Opportunity__c = opp.Id, Primary_Product__c = true, Product_Name__c = 'Support', Launch_Date__c = Date.today(), Contract_Terms_Months__c = 12);

		Opportunity_Product__c opEx = new Opportunity_Product__c(Name = 'Test Opp Prod Exception', Amount__c = 100, Opportunity__c = oppEx.Id, Primary_Product__c = true, Product_Name__c = 'Support', Launch_Date__c = Date.today(), Contract_Terms_Months__c = 12);
		insert new List<Opportunity_Product__c> { op, opEx };

        Test.startTest();

		// New Account SID SKU
		OpportunitySKUHandler.bypassTrigger = false;  // Reset the bypass
		OpportunitySKUHandler.createSKUs(new Map<Id,Opportunity> { opp.Id => opp });
		List<Account_SID_SKU__c> newSKUs = [ SELECT Id, New_Business_Opportunity__c, Account_SID__c, Opportunity_Product__c, MRR__c FROM Account_SID_SKU__c WHERE New_Business_Opportunity__c = :opp.Id ];
		//System.assertEquals(1, newSKUs.size());
		//System.assertEquals(sid.Id, newSKUs[0].Account_SID__c, 'New SKU - Account_SID__c should be set to related Account SID');
		//System.assertEquals(opp.Id, newSKUs[0].New_Business_Opportunity__c, 'New SKU - New_Business_Opportunity__c should be set to Opportunity');
		//System.assertEquals(op.Id, newSKUs[0].Opportunity_Product__c, 'New SKU - Opportunity_Product__c should be set to related Opportunity Product');
		//System.assertEquals(mrr, newSKUs[0].MRR__c, 'New SKU - MRR should be updated');

		// Existing Account SID SKU where Opportunity.New_Business_Account_SID_Lookup__c is changed
		Opportunity oldOpp = opp.clone(true, true, true, true);
		opp.New_Business_Account_SID_Lookup__c = sid2.Id;
		update opp;

		OpportunitySKUHandler.bypassTrigger = false;  // Reset the bypass
		//OpportunitySKUHandler.createSKUs(new Map<Id,Opportunity> { opp.Id => opp }, new Map<Id,Opportunity> { oldOpp.Id => oldOpp });
		//List<Account_SID_SKU__c> existingSKUs = [ SELECT Id, New_Business_Opportunity__c, Account_SID__c, Opportunity_Product__c, MRR__c FROM Account_SID_SKU__c WHERE New_Business_Opportunity__c = :opp.Id ];
		//System.assertEquals(2, existingSKUs.size());
		//System.assertEquals(sid2.Id, existingSKUs[0].Account_SID__c, 'New SKU - Account_SID__c should be set to related Account SID');
		//System.assertEquals(opp.Id, existingSKUs[0].New_Business_Opportunity__c, 'New SKU - New_Business_Opportunity__c should be set to Opportunity');
		//System.assertEquals(op.Id, existingSKUs[0].Opportunity_Product__c, 'New SKU - Opportunity_Product__c should be set to related Opportunity Product');
		//System.assertEquals(mrr, existingSKUs[0].MRR__c, 'New SKU - MRR should be updated');

		// Add Opportunity Product to existing Account SID
		Opportunity_Product__c opNew = new Opportunity_Product__c(Name = 'Test Add Opp Prod', Amount__c = 100, Opportunity__c = opp.Id, Primary_Product__c = true, Product_Name__c = 'Programmable Messaging', Launch_Date__c = Date.today(), Contract_Terms_Months__c = 12);
		insert opNew;

		OpportunitySKUHandler.bypassTrigger = false;  // Reset the bypass
		OpportunitySKUHandler.createSKUs(new Map<Id,Opportunity_Product__c> { opNew.Id => opNew });
		List<Account_SID_SKU__c> newOppProdSKUs = [ SELECT Id, New_Business_Opportunity__c, Account_SID__c, Opportunity_Product__c, MRR__c FROM Account_SID_SKU__c WHERE New_Business_Opportunity__c = :opp.Id ];
		//System.assertEquals(3, newOppProdSKUs.size());


		// Existing Account SID SKU that is not Exception
		OpportunitySKUHandler.bypassTrigger = false;  // Reset the bypass
		OpportunitySKUHandler.createSKUs(new Map<Id,Opportunity> { oppEx.Id => oppEx });
		List<Account_SID_SKU__c> nonExceptionSKUs = [ SELECT Id, New_Business_Opportunity__c, Account_SID__c, Opportunity_Product__c, MRR__c FROM Account_SID_SKU__c WHERE New_Business_Opportunity__c = :oppEx.Id ];
		//System.assertEquals(1, nonExceptionSKUs.size());
		//System.assertEquals(sid.Id, nonExceptionSKUs[0].Account_SID__c, 'Existing SKU - Account_SID__c should be set to related Account SID');
		//System.assertEquals(oppEx.Id, nonExceptionSKUs[0].New_Business_Opportunity__c, 'Existing SKU - New_Business_Opportunity__c should be set to Opportunity');
		//System.assertEquals(opEx.Id, nonExceptionSKUs[0].Opportunity_Product__c, 'Existing SKU - Opportunity_Product__c should be set to related Opportunity Product');
		//System.assertEquals(mrr, nonExceptionSKUs[0].MRR__c, 'Existing SKU - MRR should be updated');

		// Existing Account SID SKU that is Exception
		OpportunitySKUHandler.bypassTrigger = false;  // Reset the bypass
		sid.Support_MRR__c = mrrEx;
		update sid;
		OpportunitySKUHandler.createSKUs(new Map<Id,Opportunity> { oppEx.Id => oppEx });
		List<Account_SID_SKU__c> exceptionSKUs = [ SELECT Id, New_Business_Opportunity__c, Account_SID__c, Opportunity_Product__c, MRR__c FROM Account_SID_SKU__c WHERE New_Business_Opportunity__c = :oppEx.Id ];
		//System.assertEquals(1, exceptionSKUs.size());
//		System.assertEquals(sid.Id, exceptionSKUs[0].Account_SID__c, 'SKU Exception - Account_SID__c should not be updated');
		//System.assertEquals(opEx.Id, exceptionSKUs[0].Opportunity_Product__c, 'SKU Exception - Opportunity_Product__c should be updated to related Opportunity Product');
		//System.assertEquals(mrrEx, exceptionSKUs[0].MRR__c, 'SKU Exception - MRR should be updated');

		// Existing Account SID SKU that is Exception where Opportunity.New_Business_Account_SID_Lookup__c is changed
		Opportunity oldOppEx = oppEx.clone(true, true, true, true);
		oppEx.New_Business_Account_SID_Lookup__c = sid2.Id;
		update oppEx;

		OpportunitySKUHandler.bypassTrigger = false;  // Reset the bypass
		sid.Support_MRR__c = mrrEx;
		update sid;
		//OpportunitySKUHandler.createSKUs(new Map<Id,Opportunity> { oppEx.Id => oppEx }, new Map<Id,Opportunity> { oldOppEx.Id => oldOppEx });
		//List<Account_SID_SKU__c> existingExceptionSKUs = [ SELECT Id, New_Business_Opportunity__c, Account_SID__c, Opportunity_Product__c, MRR__c FROM Account_SID_SKU__c WHERE New_Business_Opportunity__c = :oppEx.Id ];
		//System.assertEquals(1, existingExceptionSKUs.size());
//		System.assertEquals(sid2.Id, existingExceptionSKUs[0].Account_SID__c, 'SKU Exception - Account_SID__c should not be updated');
		//System.assertEquals(opEx.Id, existingExceptionSKUs[0].Opportunity_Product__c, 'SKU Exception - Opportunity_Product__c should be updated to related Opportunity Product');
		//System.assertEquals(mrrEx, existingExceptionSKUs[0].MRR__c, 'SKU Exception - MRR should be updated');

        Test.stopTest();
    }
}