@isTest 
private class Twilio_UsageTestClass {
	/****************************************************************
	 * Ashwani Soni has commented this class because it belongs to old logic of joining
	 * Twilio Usage with Contact and Lead.
	 * This was happenning by NimblyLinkUsage Trigger. Now in trigger old code has been commented and 
	 * new code is added. This class assets are failing in production
	 * Date commented: 18-Feb-2016 during Multi-User development project.
    /*
    static String testkey = 'BGh6Ge9sdg34TrgdIfje56nHbw7cdwHveg';
    
    static Contact testContact;
    static Lead testLead;
    static Twilio_Usage__c testUsage;
    
    static void setupTestUsage() {
        
        testContact = new Contact( LastName = 'Doe', Email = 'jane@do23423d634534.com' );
        
        testLead = new Lead( LastName = 'Doe', FirstName = 'Jane', Company = 'the does' ); 
        
        testUsage = new Twilio_Usage__c( CounterKey__c='test', Year__c=2014, 
                                         Month__c=12, Product__c='hello',
                                         Total__c=12.34, Volume__c=44, Currency__c='USD',
                                         Owner_User_Id__c = testkey, AccountSid__c='somesidstuff5weewfgwde5645egr' );
    }
    
    static testMethod void test_matchContact() {
    
        setupTestUsage();
        
        //testContact.Magic_UserSID__c = testkey;
        testContact.FY15_User_ID__c = testkey;
        insert testContact;
        
        Test.startTest();
        
            insert testUsage;
        
        Test.stopTest();
        
        Twilio_Usage__c resolvedUsage = [select contact__c from Twilio_Usage__c where id = :testUsage.Id];
        
        system.assertEquals( testContact.Id, resolvedUsage.contact__c );
    
    }
    
    static testMethod void test_matchLead() {
    
        setupTestUsage();
        
        //testLead.Magic_UserSID__c = testkey;
        testLead.FY15_User_ID__c = testkey;
        insert testLead;
        
        Test.startTest();
        
            insert testUsage;
        
        Test.stopTest();
        
        Twilio_Usage__c resolvedUsage = [select contact__c, lead__c from Twilio_Usage__c where id = :testUsage.Id];
        
        system.assertEquals( null, resolvedUsage.contact__c );
        system.assertEquals( testLead.Id, resolvedUsage.lead__c );
    
    }
    
    static testMethod void test_prioritizeContactOverLead() {
    
        setupTestUsage();
        
        //testLead.Magic_UserSID__c = testkey;
        testLead.FY15_User_ID__c = testkey;
        insert testLead;

        //testContact.Magic_UserSID__c = testkey;
        testContact.FY15_User_ID__c = testkey;
        insert testContact;
     
        Test.startTest();
        
            insert testUsage;
        
        Test.stopTest();
        
        Twilio_Usage__c resolvedUsage = [select contact__c, lead__c from Twilio_Usage__c where id = :testUsage.Id];
        
        system.assertEquals( testContact.Id, resolvedUsage.contact__c );
        system.assertEquals( null, resolvedUsage.lead__c );
    
    }
    */
}