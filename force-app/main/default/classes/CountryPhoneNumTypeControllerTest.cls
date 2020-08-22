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
private class CountryPhoneNumTypeControllerTest {
    static Integer recordMax = 10;

    static List<Schema.PicklistEntry> regionPicklist;
    static List<Schema.PicklistEntry> capabilityPicklist;
    static List<Schema.PicklistEntry> typePicklist;
    static List<Schema.PicklistEntry> statusPicklist;
    static List<Schema.PicklistEntry> nextStatusPicklist;

    static List<Country_Phone_Number_Type__c> countryPhoneNumTypeList;

    static testMethod void badSoqlException() {
        setupTestRecords();
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        obj.sortField = 'Invalid_Field';
        obj.toggleSort();
        obj.runSearch();
        System.debug('TEST METHOD: badSoqlException');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void searchNoMatch() {
        setupTestRecords();
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        Apexpages.currentPage().getParameters().put('searchText', 'NO-RECORD');
        obj.runSearch();
        System.debug('TEST METHOD: searchNoMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }
    
    static testMethod void filterSelection() {
        setupTestRecords();
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        Apexpages.currentPage().getParameters().put('Capability__c', obj.capabilities.isEmpty() ? 'TEST' : obj.capabilities[0]);
        Apexpages.currentPage().getParameters().put('Type__c', obj.types.isEmpty() ? 'TEST' : obj.types[0]);
        Apexpages.currentPage().getParameters().put('Status__c', obj.statuses.isEmpty() ? 'TEST' : obj.statuses[0]);
        Apexpages.currentPage().getParameters().put('Next_Status__c', obj.nextStatuses.isEmpty() ? 'TEST' : obj.nextStatuses[0]);
        obj.runSearch();
        System.debug('TEST METHOD: filterSelection');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }
    
    static testMethod void searchOneMatch() {
        setupTestRecords();
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        Apexpages.currentPage().getParameters().put('searchText', countryPhoneNumTypeList[0].Name);
        obj.runSearch();
        System.debug('TEST METHOD: searchOneMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }
    
    static testMethod void searchMultiMatch() {
        setupTestRecords(); 
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        Apexpages.currentPage().getParameters().put('searchText', countryPhoneNumTypeList[0].Capability__c);
        obj.runSearch();
        System.debug('TEST METHOD: searchMultiMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }
    
    static testMethod void searchMaxMatch() {
        setupTestRecords();
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        obj.maxSearchResults = recordMax - 1;
        obj.runSearch();
        System.debug('TEST METHOD: searchMaxMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void toggleSort() {
        setupTestRecords();
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        obj.sortField = 'Name';
        obj.toggleSort();
        obj.runSearch();
    }
    
    static testMethod void nullSearchText() {
        setupTestRecords();
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        obj.searchText = null;
        String s = obj.searchText;
        obj.runSearch();
    }
    
    static testMethod void testPicklists() {
        setupTestRecords();
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        List<String> capabilities = obj.capabilities;
        List<String> types = obj.types;
        List<String> statuses = obj.statuses;
        List<String> nextStatuses = obj.nextStatuses;
        List<String> origins = obj.origins;
        
        String selectedCapabilities = obj.selectedCapabilities;
        String selectedTypes = obj.selectedTypes;
        String selectedStatuses = obj.selectedStatuses;
        String selectedNextStatuses = obj.selectedNextStatuses;
        String selectedOrigins = obj.selectedOrigins;
        
        List<SelectOption> capabilityOptions = obj.capabilityOptions;
        List<SelectOption> typeOptions = obj.typeOptions;
        List<SelectOption> statusOptions = obj.statusOptions;
        List<SelectOption> nextStatusOptions = obj.nextStatusOptions;
        List<SelectOption> originOptions = obj.originOptions;
    }
    
    static testMethod void testDebug() {
        setupTestRecords();
        CountryPhoneNumTypeController obj = new CountryPhoneNumTypeController();
        String soql = obj.debugSoql;
        String params = obj.debugParameters;
    }
            
    static void setupTestRecords() {
        regionPicklist = Country__c.Region__c.getDescribe().getPicklistValues();
        capabilityPicklist = Country_Phone_Number_Type__c.Capability__c.getDescribe().getPicklistValues();
        typePicklist = Country_Phone_Number_Type__c.Type__c.getDescribe().getPicklistValues();
        statusPicklist = Country_Phone_Number_Type__c.Status__c.getDescribe().getPicklistValues();
        nextStatusPicklist = Country_Phone_Number_Type__c.Next_Status__c.getDescribe().getPicklistValues();

		// NOTE:  The Country_Phone_Number_Type__c's Unique_Name__c field is populated by a
		//        workflow that uses a combination of Country__r.Name, Type__c, and Capability__c,
		//        therefore, a series of unique country names are created to prevent a duplicate
		//        value exception.

		List<Country__c> countries = new List<Country__c>();
		for (Integer i = 0; i < recordMax; i++) {
        	countries.add(new Country__c(
        		Name = EncodingUtil.convertToHex(Crypto.generateAesKey(128)),
				CountryName__c = 'United States',
				Region__c = regionPicklist[Math.mod(i, regionPickList.size())].getLabel())
			);
		}
        insert countries;
		
        countryPhoneNumTypeList = new List<Country_Phone_Number_Type__c>();
        for (Integer i = 0; i < recordMax; i++) {
            countryPhoneNumTypeList.add(new Country_Phone_Number_Type__c(
                //Name = 'TEST(' + i + ')',
                Country__c = countries[i].id,
                Capability__c = capabilityPicklist[0].getLabel(),
                Type__c = typePicklist[0].getLabel(),
                Status__c = statusPicklist[0].getLabel(),
                Next_Status__c = nextStatusPicklist[0].getLabel()
            ));
            System.debug('RECORD: ' + countryPhoneNumTypeList.get(countryPhoneNumTypeList.size() -1));
        }
        insert countryPhoneNumTypeList;
        
        // Requery the records because that Name is updated by a workflow
        countryPhoneNumTypeList = [ SELECT Name, Country__c, Capability__c, Type__c, Status__c, Next_Status__c FROM Country_Phone_Number_Type__c ];
        System.debug('RECORDS: ' + countryPhoneNumTypeList);
    }
}