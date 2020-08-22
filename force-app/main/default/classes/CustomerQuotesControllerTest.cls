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
private class CustomerQuotesControllerTest {
    static Integer recordMax = 10;
        
    static List<Customer_Quote__c> quoteList;
    static List<Account> accountList;
    static List<Contact> contactList;

    static String primaryTopicItem = Customer_Quote__c.Primary_Topic__c.getDescribe().getPicklistValues()[0].getValue();
    static String useCaseCategoryItem = Customer_Quote__c.Use_Case_Category__c.getDescribe().getPicklistValues()[0].getValue();
    static String productItem = Customer_Quote__c.Product__c.getDescribe().getPicklistValues()[0].getValue();
    static String additionaTopicItem = Customer_Quote__c.Additional_Topic_s__c.getDescribe().getPicklistValues()[0].getValue();

    static testMethod void pageLoad() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        System.debug('TEST METHOD: noOpptyGivenException');
    }

    static testMethod void badSoqlException() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        obj.sortField = 'Invalid_Field';
        obj.toggleSort();
        obj.runSearch();
        System.debug('TEST METHOD: badSoqlException');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void pageAdjustSize() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('s', '3');
        CustomerQuotesController obj = new CustomerQuotesController();
        System.debug('TEST METHOD: pageAdjustSize');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void pageFullHeight() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('h', 'full');
        CustomerQuotesController obj = new CustomerQuotesController();
        System.debug('TEST METHOD: pageFullHeight');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void pagePixelHeight() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('h', '100px');
        CustomerQuotesController obj = new CustomerQuotesController();
        System.debug('TEST METHOD: pagePixelHeight');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void paginationControls() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        obj.runSearch();
        Boolean hasNext = obj.hasNext;
        Boolean hasPrevious = obj.hasPrevious;
        obj.first();
        obj.next();
        obj.last();
        obj.previous();
        System.debug('TEST METHOD: paginationControls');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void searchNoMatch() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        Apexpages.currentPage().getParameters().put('searchText', 'none');
        obj.runSearch();
        System.debug('TEST METHOD: searchNoMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }
    
    static testMethod void filterSelection() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        Apexpages.currentPage().getParameters().put('Primary_Topic__c', obj.primaryTopics.isEmpty() ? 'TEST' : obj.primaryTopics[0]);
        Apexpages.currentPage().getParameters().put('Use_Case_Category__c', obj.useCaseCategories.isEmpty() ? 'TEST' : obj.useCaseCategories[0]);
        Apexpages.currentPage().getParameters().put('Product__c', obj.products.isEmpty() ? 'TEST' : obj.products[0]);
        obj.runSearch();
        System.debug('TEST METHOD: searchOneMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }
    
    static testMethod void searchOneMatch() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNT0');
        obj.runSearch();
        System.debug('TEST METHOD: searchOneMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }
    
    static testMethod void searchMultiMatch() {
        setupTestRecords(); 
        CustomerQuotesController obj = new CustomerQuotesController();
        Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNT1');
        obj.runSearch();
        System.debug('TEST METHOD: searchMultiMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }   
    
    static testMethod void searchMaxMatch() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        obj.maxSearchResults = recordMax - 1;
        Apexpages.currentPage().getParameters().put('searchText', 'TESTACCOUNT');
        obj.runSearch();
        System.debug('TEST METHOD: searchMaxMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void toggleSort() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        obj.sortField = 'Name';
        obj.toggleSort();
        obj.runSearch();
    }
    
    static testMethod void nullSearchText() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        obj.searchText = null;
        String s = obj.searchText;
        obj.runSearch();
    }
    
    static testMethod void testPicklists() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();

        List<String> primaryTopics = obj.primaryTopics;
        List<String> useCaseCategories = obj.useCaseCategories;
        List<String> products = obj.products;
        
        String selectedPrimaryTopics = obj.selectedPrimaryTopics;
        String selectedUseCaseCategories = obj.selectedUseCaseCategories;
        String selectedProducts = obj.selectedProducts;
        
        List<SelectOption> primaryTopicOptions = obj.primaryTopicOptions;
        List<SelectOption> useCaseCategoryOptions = obj.useCaseCategoryOptions;
        List<SelectOption> productOptions = obj.productOptions;
    }
    
    static testMethod void testDebug() {
        setupTestRecords();
        CustomerQuotesController obj = new CustomerQuotesController();
        String soql = obj.debugSoql;
        String params = obj.debugParameters;
    }
            
    static void setupTestRecords() {
        accountList = new List<Account>();
        for (Integer i = 0; i < recordMax; i++) {
            accountList.add(new Account(
                Name = 'TESTACCOUNT' + i
            ));
        }
        insert accountList;

        contactList = new List<Contact>();
        for (Integer i = 0; i < recordMax; i++) {
            contactList.add(new Contact(
                LastName = 'TESTCONTACT' + i,
                AccountID = accountList[i].Id
            ));
        }
        insert contactList;
        
        quoteList = new List<Customer_Quote__c>();
        for (Integer i = 0; i < recordMax; i++) {
        	quoteList.add(new Customer_Quote__c(
				Account__c = accountList[i].Id,
				Contact__c = contactList[i].Id,
				Quote__c= 'Sample quote ' + i,
				Primary_Topic__c = primaryTopicItem,
				Use_Case_Category__c = useCaseCategoryItem,
				Product__c = productItem,
				Additional_topic_s__c = additionaTopicItem
        	));
        }
		insert quoteList;
    }
}