public with sharing class CustomerQuotesController {

    public String pageStyle {get;set;}
    public Integer maxSearchResults = 1000; 
    
    public Integer pageSize    { get { return (pageSize == null) ? 10 : pageSize; } set;}
    public Integer pageNumber  { get { return (pageNumber == null || pageNumber < 1) ? 1 : pageNumber; } set;}

    public Integer noOfRecords { get { return (searchResults == null) ? 0 : searchResults.size(); } }
    public Boolean hasNext     { get { return (noOfRecords == 0 || noOfRecords <= (pageSize * pageNumber)) ? false : true; } }
    public Boolean hasPrevious { get { return (noOfRecords == 0 || pageNumber <= 1) ? false : true; } }
    
    public PageReference first()    { pageNumber = 1; refresh(); return null; }
    public PageReference last()     { pageNumber = Integer.valueOf(Math.ceil(Decimal.valueOf(noOfRecords) / Decimal.valueOf(pageSize)));  refresh(); return null; }
    public PageReference previous() { pageNumber--; refresh(); return null; }
    public PageReference next()     { pageNumber++;  refresh(); return null; }
    public void refresh()           { searchResultsPage = getPage(searchResults, pageNumber, pageSize); }
    
    // the results from the search. do not init the results or a blank rows show up initially on page load
    public List<Customer_Quote__c> searchResults {get;set;}
    public List<Customer_Quote__c> searchResultsPage {get;set;}
    public Map<Id, Integer> searchResultsIndex {get;set;}
    public String totalRecordsFound {get;set;}

	// filter selections
	public String selectedPrimaryTopics {get;set;}
    public String selectedUseCaseCategories {get;set;}
    public String selectedProducts {get;set;}

    // the soql without the order and limit
    private String baseQuery() {
		String q = 'SELECT Id, Name, Account__c, Account__r.Name, Contact__c, Title__c, Quote__c, Quote_search__c, Use_Case_Category__c, Product__c, Primary_Topic__c, Additional_topic_s__c FROM Customer_Quote__c WHERE IsDeleted = false';
        return q;
    }
    private String soql {get;set;}

    public CustomerQuotesController() {
        clearSearchResults();
        processQueryParams();
        runSearch();
    }
    
    // If the query parameter "h" is not specified assume it's height should
    // be limited for use as a component in the Opportunity page layout.
    // If "h=full" then show the page in full height
    // If "h" is set otherwise assume it is a valid height specification.
    public void processQueryParams() {
        String height = Apexpages.currentPage().getParameters().get('h');
        if (String.isBlank(height)) {
            pageStyle = 'overflow: auto; height: 150px;';
        } else if (height == 'full') {
            pageStyle = '';
        } else {
            pageStyle = 'overflow: auto; height: ' + height + ';';
        }
        System.debug(LoggingLevel.Info, 'pageStyle(' + pageStyle + ')');

        String size = Apexpages.currentPage().getParameters().get('s');
        if (!String.isBlank(size)) {
            pageSize = Integer.valueOf(size);
        }
        System.debug(LoggingLevel.Info, 'pageSize(' + pageSize + ')');
    }
    
    public void clearSearchResults() {
        if (searchResults == null) {
            searchResults = new List<Customer_Quote__c>();
            searchResultsIndex = new Map<Id, Integer>();
        } else {
            searchResults.clear();
            searchResultsIndex.clear();
        }
    }
    
    public string sortField {
        get { return (sortField == null) ? 'Name' : sortField; }
        set;
    }
    
    public string sortDir {
        get { return (sortDir == null) ? 'asc' : sortDir; }
        set;
    }

    // toggles the sorting of query from asc<-->desc
    public void toggleSort() {
        // simply toggle the direction
        sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
        // run the query again
        runQuery();
    }

    // the text in the search box
    public string searchText {
        get { return (searchText == null) ? '' : searchText; }
        set;
    }

    // runs the actual query
    public void runQuery() {
        try {
            List <Customer_Quote__c> results = Database.query(soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults));

            clearSearchResults();
            Integer i = 0;
            for (Customer_Quote__c q : results) {
                searchResults.add(q);
                searchResultsIndex.put(q.Id, i++);
            }
            pageNumber = 1;
            refresh();
            System.debug(LoggingLevel.INFO, 'pageNumber(' + pageNumber + ')');
            
            if (noOfRecords == 0) {
                totalRecordsFound = 'No matches';
            } else if (noOfRecords == 1) {
                totalRecordsFound = '1 match found';
            } else if (noOfRecords == maxSearchResults) {
                totalRecordsFound = String.valueOf(results.size()) + '+ matches found (showing only ' + String.valueOf(maxSearchResults) + ')';
            } else if (noOfRecords > 1) {
                totalRecordsFound = String.valueOf(results.size()) + ' matches found';
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - ' + e.getMessage()));
        }
    }

    // fired when the search button is clicked
    public PageReference runSearch() {
        if (searchResults == null) {
            searchResults = new List<Customer_Quote__c>(); // init the list if it is null
        } else {
            searchResults.clear(); // clear out the current results if they exist
        }

        soql = baseQuery();

		// Primary Topics filter
        String primaryTopics = Apexpages.currentPage().getParameters().get('Primary_Topic__c');
        if (!String.isBlank(primaryTopics) && !primaryTopics.equals('\' \''))
            soql += ' AND Primary_Topic__c IN ('+ primaryTopics +')';

		// Use Case Categories filter
        String useCaseCategories = Apexpages.currentPage().getParameters().get('Use_Case_Category__c');
        if (!String.isBlank(useCaseCategories) && !useCaseCategories.equals('\' \''))
            soql += ' AND Use_Case_Category__c IN ('+ useCaseCategories +')';
 
		// Products filter
        String products = Apexpages.currentPage().getParameters().get('Product__c');
        if (!String.isBlank(products) && !products.equals('\' \''))
            soql += ' AND Product__c IN ('+ products +')';

		// Keyword search filter on common fields
        String searchText = Apexpages.currentPage().getParameters().get('searchText');
        if (!String.isBlank(searchText))
            soql += ' AND (Account__r.Name LIKE \'%'+ searchText +'%\' OR Quote_search__c LIKE \'%'+ searchText +'%\')';

        // run the query again
        runQuery();

        return null;
    }

    public List<String> primaryTopics {
        get {
            if (primaryTopics == null) {
                primaryTopics = new List<String>();
                for (Schema.PicklistEntry p : Customer_Quote__c.Primary_Topic__c.getDescribe().getPicklistValues())
                    primaryTopics.add(p.getLabel());
            }
            return primaryTopics;          
        }
        set;
    }
	
	public List<SelectOption> primaryTopicOptions {
		get {
			if (primaryTopicOptions == null) {
				primaryTopicOptions = new List<SelectOption>();
				for (String p : primaryTopics)
					primaryTopicOptions.add(new SelectOption(String.escapeSingleQuotes(p), p));
			}
			return primaryTopicOptions;
		}
		set;
	}
    
    public List<String> useCaseCategories {
        get {
            if (useCaseCategories == null) {
                useCaseCategories = new List<String>();
                for (Schema.PicklistEntry c : Customer_Quote__c.Use_Case_Category__c.getDescribe().getPicklistValues())
                    useCaseCategories.add(c.getLabel());
            }
            return useCaseCategories;
        }
        set;
    }

	public List<SelectOption> useCaseCategoryOptions {
		get {
			if (useCaseCategoryOptions == null) {
				useCaseCategoryOptions = new List<SelectOption>();
				for (String c : useCaseCategories)
					useCaseCategoryOptions.add(new SelectOption(String.escapeSingleQuotes(c), c));
			}
			return useCaseCategoryOptions;
		}
		set;
	}

    public List<String> products {
        get {
            if (products == null) {
                products = new List<String>();
                for (Schema.PicklistEntry p : Customer_Quote__c.Product__c.getDescribe().getPicklistValues())
                    products.add(p.getLabel());
            }
            return products;          
        }
        set;
    }

	public List<SelectOption> productOptions {
		get {
			if (productOptions == null) {
				productOptions = new List<SelectOption>();
				for (String p : products)
					productOptions.add(new SelectOption(String.escapeSingleQuotes(p), p));
			}
			return productOptions;
		}
		set;
	}
    
    private List<Customer_Quote__c> getPage(List<Customer_Quote__c> objs, Integer pageNumber, Integer pageSize) {
        Integer pageFirstItem = pageNumber <= 1 ? 0 : ((pageNumber - 1) * pageSize);
        Integer pageLastItem = (pageFirstItem + pageSize) > objs.size() ? objs.size() : (pageFirstItem + pageSize);
        System.debug(LoggingLevel.Info, 'pageFirstItem(' + pageFirstItem + ')');
        System.debug(LoggingLevel.Info, 'pageLastItem(' + pageLastItem + ')');
        List<Customer_Quote__c> newList = new List<Customer_Quote__c>();
        for (Integer i = pageFirstItem; i < pageLastItem; i++) {
            newList.add(objs.get(i));
            System.debug(LoggingLevel.Info, 'Adding(' + i + ')');
        }
        System.debug(LoggingLevel.Info, 'Page Size(' + newList.size() + ')');
        return newList;
    }

    // format the soql for display on the visualforce page
    public String debugSoql {
        get { return soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults); }
        set;
    }
  
    // format the parameters for display on the visualforce page
    public String debugParameters {
        get { return String.join(Apexpages.currentPage().getParameters().values(), ','); }
        set;
    }
}