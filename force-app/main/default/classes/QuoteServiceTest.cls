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
private class QuoteServiceTest {
	
	static Account acc;
	static Opportunity opp;
	static Quote quote;
	static Quote_BI__c quoteBI;
	static Billable_Item__c bi;
	static Quote_GTM_Group__c quoteGTMGroup;
	static BI_Commit_Price__c commitPrice;

    static testMethod void testBIPIcker(){
        setupTestRecords();
        ApexPages.standardController ctrl = new ApexPages.standardController(quote);
        
        Test.startTest();
            QuoteBIPickerCtrl ext = new QuoteBIPickerCtrl(ctrl);
            String testStr1 = ext.getExistingItems();
            String testStr2 = ext.getBillableItems();
            QuoteBIPickerCtrl.saveData(JSON.serialize(new List<Quote_BI__c>{quoteBI}), quote.Id, JSON.serialize(quote), false);
            QuoteToAgreementController ext2 = new QuoteToAgreementController(ctrl);
            PageReference ref = ext2.init();
        Test.stopTest();
        
    }
    static testMethod void createAgreementsFromQuotes() {
    	setupTestRecords();

        Test.startTest();

        QuoteService.createAgreementsFromQuotes(new List<Quote>{ quote });
        List<Apttus__APTS_Agreement__c> agreementList = [ SELECT Notes__c FROM Apttus__APTS_Agreement__c WHERE Quote__c = :quote.Id ];
		System.assertEquals(1, agreementList.size());
        System.assertEquals(quote.Description, agreementList[0].Notes__c);

		List<Single_BI_Discount__c> discountList = [ SELECT Name FROM Single_BI_Discount__c WHERE Agreement__c = :agreementList[0].Id ];
		System.assertEquals(1, discountList.size());
        //System.assertEquals(quoteBI.Name, discountList[0].Name);
		
        Test.stopTest();
    }

    static testMethod void copyQuoteFieldsToAgreement() {
    	setupTestRecords();

        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(
            Name = 'Agreement1',
            Apttus__Account__c = acc.Id,
            Apttus__Related_Opportunity__c = opp.Id,
            Related_Opportunity_APTS__c = opp.Id,
            Quote__c = quote.Id
        );
        insert agreement;

        Test.startTest();

        QuoteService.copyQuoteFieldsToAgreement(new List<Quote>{ quote });
        agreement = [ SELECT Notes__c FROM Apttus__APTS_Agreement__c WHERE Id = :agreement.Id LIMIT 1 ];
        System.assertEquals(quote.Description, agreement.Notes__c);

        Test.stopTest();
    }

    private static void setupTestRecords() {
        Quote_to_Agreement_Mapping__c quoteMapping = new Quote_to_Agreement_Mapping__c(
            Name = 'Test`',
            Quote_API_Field_Name__c = 'Description',
            Agreement_API_Field_Name__c = 'Notes__c'
        );
        insert quoteMapping;

        QuoteBI_to_SingleBIDiscounts_Mapping__c biMapping = new QuoteBI_to_SingleBIDiscounts_Mapping__c(
            Name = 'Test',
            QuoteBI_API_Field_Name__c = 'Name',
            SingleBIDiscount_API_Field_Name__c = 'Name'
        );
        insert biMapping;

		acc = new Account(Name = 'TestAccount');
		insert acc;

		opp = new Opportunity(
			AccountId = acc.Id,
			Name = acc.Name,
			CloseDate = system.today(),
			StageName='Prospecting'
		);
		insert opp;

		quote = new Quote(
            Name = 'Quote1',
            Description = 'Quote1',
            OpportunityId = opp.Id,
            Total_Committed_Revenue__c = 1200,
            Commit_Frequency__c = 'Monthly',
            Term_Range__c = '12'
        );
        insert quote;

		bi = new Billable_Item__c(
			Name = 'BI1',
			Price__c = 0.09,
			Status__c = 'Active',
			Product_Family__c = 'Programmable Messaging'
		);
		insert bi;
		
		quoteGTMGroup = new Quote_GTM_Group__c(
		    Quote__c = quote.Id
		);
		insert quoteGTMGroup;
		
		
		quoteBI = new Quote_BI__c(
            Name = 'QuoteBI1',
            Quote__c = quote.Id,
            Billable_Item__c = bi.Id,
            Quote_GTM_Group__c = quoteGTMGroup.Id
        );
        insert quoteBI;
        
        commitPrice = new BI_Commit_Price__c(
            Billable_Item__c = bi.Id,
            Discount_Type__c = 'Flat',
            Flat_Price__c = 0.08,
            Min_Commit_Floor__c = 0
        );
        insert commitPrice;
    }

}