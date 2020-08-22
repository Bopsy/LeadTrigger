@isTest
private class CountrySelectorExtTest {

	private static testMethod void testConstructor() {
        
        Account testAcc = new Account(Name = 'Test');
        insert testAcc;
        Opportunity testOpp = new Opportunity(Name = 'Test', AccountId = testAcc.Id, StageName = 'Incubate', CloseDate = Date.today());
        insert testOpp;
        Country__c testCountry = new Country__c(Name = 'United States', CountryName__c = 'United States', Region__c = 'APAC');
        insert testCountry;
        
        Country__c testCountry2 = new Country__c(Name = 'United Kingdom', CountryName__c = 'United Kingdom', Region__c = 'EMEA');
        insert testCountry2;
        
        Opportunity_Country__c testOppCountry = new Opportunity_Country__c(Opportunity__c = testOpp.Id, Country__c = testCountry.Id);
        insert testOppCountry;
        
        Opportunity_Country__c testOppCountry2 = new Opportunity_Country__c(Opportunity__c = testOpp.Id, Country__c = testCountry2.Id);
        
        Phone_Number_Type_Library__c testPhoneNumber = new Phone_Number_Type_Library__c(Name = 'Local - SMS');
        insert testPhoneNumber;
        
        Country_Phone_Number_Type__c testType1 = new Country_Phone_Number_Type__c(Name = 'Test', Country__c = testCountry.Id, Status__c = 'Generally Available', Unique_Name__c = 'Test1234');
        
        Country_Phone_Number_Type__c testType2 = new Country_Phone_Number_Type__c(Name = 'Test2', Country__c = testCountry2.Id, Status__c = 'Generally Available', Unique_Name__c = 'Te');
        
        insert new List<Country_Phone_Number_Type__c>{testType1, testType2};
        
        Opportunity_Country_Number__c testOppNumber1 = new Opportunity_Country_Number__c(Opportunity_Country__c = testOppCountry.Id, Country_Number_Type__c = testType1.Id);
        insert testOppNumber1;
        
        CountrySelectorExt.Types testType22 = new CountrySelectorExt.Types();
        testType22.typeId = testType2.Id;
        testType22.countryId = testCountry2.Id;
        testType22.checked = true;
        
        CountrySelectorExt.Types testType11 = new CountrySelectorExt.Types();
        testType11.typeId = testType1.Id;
        testType11.countryId = testCountry.Id;
        testType11.checked = false;
        
        Country_Phone_Number_Type_Order__c testSetting = new Country_Phone_Number_Type_Order__c(Name = 'Local - SMS', Column__c = 'Left', Order__c = 1, Phone_Number_Type_Name__c = 'Local - SMS');
        insert testSetting;
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        
        Test.startTest();
            CountrySelectorExt ctrl = new CountrySelectorExt(sc);
            ctrl.getCountries();
            ctrl.getCountryTypeMap();
            ctrl.getExistingRecords();
            Map<String, Decimal> settingMap = CountrySelectorExt.numberOrderMap;
            CountrySelectorExt.saveData(JSON.serialize(new List<Opportunity_Country__c>{testOppCountry, testOppCountry2}), JSON.serialize(new List<CountrySelectorExt.Types>{testType11,testType22}), testOpp.Id);
            
        Test.stopTest();
	}

}