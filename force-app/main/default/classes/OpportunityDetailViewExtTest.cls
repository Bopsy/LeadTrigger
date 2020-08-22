@isTest
private class OpportunityDetailViewExtTest {

	private static testMethod void testConstructor() {
        Opportunity testOpp = new Opportunity(CloseDate = Date.today(), StageName = 'Incubate', Name = 'Test Opp');
        insert testOpp;
        
        ApexPages.standardController stdCtrl = new ApexPages.standardController(testOpp);
        Test.startTest();
            OpportunityDetailViewExt ctrlExt = new OpportunityDetailViewExt(stdCtrl);
            String testContacts = OpportunityDetailViewExt.contacts;
            String testFieldMap = OpportunityDetailViewExt.fieldMapString;
            OpportunityDetailViewExt.load();
            OpportunityDetailViewExt.saveData(JSON.serialize(testOpp), testOpp.Id);
            Contact testContact = new Contact(LastName = 'Tester', FirstName = 'Test', Email='test@testerabc.com');
            OpportunityDetailViewExt.createContact(JSON.serialize(testContact));
        Test.stopTest();
	}

}