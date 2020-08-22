public class OpportunityUseCaseController {

    public Opportunity o {get;set;}
    public String pageStyle {get;set;}
    private Integer maxSearchResults = 500; 

	public Integer pageSize    { get { return (pageSize == null) ? 25 : pageSize; } set;}
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
    public List<Use_Case__c> searchResults {get;set;}
    public List<Use_Case__c> searchResultsPage {get;set;}
    public Map<Id, Integer> searchResultsIndex {get;set;}
    public String totalRecordsFound {get;set;}
    
    public String selectedIndustry {get;set;}
    public String selectedUseCase {get;set;}
    public String selectedCountry {get;set;}

    // the soql without the order and limit
    private String baseQuery = 'SELECT Id, Account__r.Id, Account__r.Name, Use_Case__c, Country2__c, Industry2__c, Account_Amortized_Usage_Last_Month__c, Talking_Points__c, Solution__c, Value_Drivers__c, Links__c FROM Use_Case__c WHERE IsDeleted = false AND Referenceable__c = true';
    private String soql {get;set;}

    public OpportunityUseCaseController() {
		processQueryParams(); 
        soql = baseQuery;
		runQuery();
    }

    public OpportunityUseCaseController(ApexPages.StandardController controller) {
		processQueryParams(); 
        soql = baseQuery;

        // Need to add all of the fields so that they will be needed from the Opportunity
		List<String> fieldList = new List<String>();
		fieldList.add('FY_16_Use_Case__c');
		if (!Test.isRunningTest()) {
			controller.addFields(fieldList);
		}
        this.o = (Opportunity)controller.getRecord();
        
        // Populate the Use Case filter if the Opportunity Use Case is set
        String useCase = Test.isRunningTest() ? null : o.FY_16_Use_Case__c;
        System.debug('OPPORTUNITY USE CASE = ' + useCase);
		for (String s : useCases) {
			System.debug('CHECK USE CASE(' + s + ' == ' + useCase + ')');
			if (s.equalsIgnoreCase(useCase) && !String.isBlank(useCase) && !useCase.equals('\' \'')) {
				System.debug('MATCH FOUND');
				soql += ' AND Use_Case__c = \''+ useCase +'\'';
				selectedUseCase = useCase;
	        	break;
			}
        }
        System.debug('SOQL(' + soql + ')');
		runQuery();
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
	    	searchResults = new List<Use_Case__c>();
	    	searchResultsIndex = new Map<Id, Integer>();
        } else {
            searchResults.clear();
	    	searchResultsIndex.clear();
        }
    }

    // the current sort direction. defaults to asc
    public String sortDir {
        get  { if (sortDir == null) {  sortDir = 'asc'; } return sortDir;  }
        set;
    }
    
    // the current field to sort by. defaults to last name
    public String sortField {
        get  { if (sortField == null) {sortField = 'Account__r.Name'; } return sortField;  }
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
        get {
            if (searchText == null) searchText = ''; // prefill the search box for ease of use
            return searchText;
        }
        set;
    }

	// runs the actual query
	public void runQuery() {
		try {
			List <Use_Case__c> results = Database.query(soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults));
			
            clearSearchResults();
            Set<String> c = new Set<String>();
            Set<String> i = new Set<String>();
            Set<String> u = new Set<String>();
            Integer x = 0;
            for (Use_Case__c r : results) {
            	searchResults.add(r);
            	searchResultsIndex.put(r.Id, x++);
            	if (r.Country2__c != null) c.add(r.Country2__c);
            	if (r.Industry2__c != null) i.add(r.Industry2__c);
            	if (r.Use_Case__c != null) u.add(r.Use_Case__c);
            }
            List<String> cl = new List<String>(c); cl.sort(); countries = cl;
            List<String> il = new List<String>(i); il.sort(); industries = il;
            List<String> ul = new List<String>(u); ul.sort(); useCases = ul;
            pageNumber = 1;
            refresh();
            System.debug(LoggingLevel.INFO, 'pageNumber(' + pageNumber + ')');
            
			if (searchResults.size() == 0) {
				totalRecordsFound = 'No matches';
			} else if (searchResults.size() == 1) {
				totalRecordsFound = '1 match found';
			} else if (searchResults.size() == maxSearchResults) {
				totalRecordsFound = String.valueOf(searchResults.size()) + '+ matches found (showing only ' + String.valueOf(maxSearchResults) + ')';
			} else if (searchResults.size() > 1) {
				totalRecordsFound = String.valueOf(searchResults.size()) + ' matches found';
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - ' + e.getMessage()));
		}
	}

    // fired when the search button is clicked
    public PageReference runSearch() {
        if (searchResults == null) {
            searchResults = new List<Use_Case__c>(); // init the list if it is null
        } else {
            searchResults.clear(); // clear out the current results if they exist
        }

		String industry = Apexpages.currentPage().getParameters().get('Industry2__c');
		String useCase = Apexpages.currentPage().getParameters().get('Use_Case__c');
		String country = Apexpages.currentPage().getParameters().get('Country2__c');
		String searchText = Apexpages.currentPage().getParameters().get('searchText');

		soql = baseQuery;
		if (!String.isBlank(industry) && !industry.equals('\' \''))
			soql += ' AND Industry2__c IN ('+ industry +')';
		if (!String.isBlank(useCase) && !useCase.equals('\' \''))
			soql += ' AND Use_Case__c IN ('+ useCase +')';
		if (!String.isBlank(country) && !country.equals('\' \''))
			soql += ' AND Country2__c IN ('+ country +')';
		if (!String.isBlank(searchText))
			soql += ' AND (Account__r.Name LIKE \'%'+ searchText +'%\' OR REF_Challenge__c LIKE \'%'+ searchText +'%\' OR REF_Solution__c LIKE \'%'+ searchText +'%\' OR REF_Results__c LIKE \'%'+ searchText +'%\')';

		// run the query again
		runQuery();

        return null;
    }

  // use apex describe to build the picklist values
  public List<String> industries {
    get {
      if (industries == null) {
        industries = new List<String>();
        Schema.DescribeFieldResult field = Account.Industry.getDescribe();

        for (Schema.PicklistEntry f : field.getPicklistValues())
          industries.add(f.getLabel());

      }
      return industries;          
    }
    set;
  }

  public List<SelectOption> industryOptions {
  	get {
	    if (industryOptions == null) {
	    	industryOptions = new List<SelectOption>();
	    	for (String i : industries)
				industryOptions.add(new SelectOption(String.escapeSingleQuotes(i), i));
	    }
	    return industryOptions;
  	}
  	set;
  }

  public List<String> useCases {
    get {
      if (useCases == null) {
        useCases = new List<String>();
        for (Schema.PicklistEntry f : Use_Case__c.Use_Case__c.getDescribe().getPicklistValues())
          useCases.add(f.getLabel());
      }
      return useCases;          
    }
    set;
  }

  public List<SelectOption> useCaseOptions {
  	get {
	    if (useCaseOptions == null) {
	      useCaseOptions = new List<SelectOption>();
	      for (String uc : useCases)
		    useCaseOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
	    }
	    return useCaseOptions;
  	}
  	set;
  }

  public List<String> countries {
    get {
      if (countries == null) {
	    countries = new List<String>();
	    for (Schema.PicklistEntry f : Account.BillingCountryCode.getDescribe().getPicklistValues())
          countries.add(f.getLabel());
      }
      return countries;          
    }
    set;
  }

  public List<SelectOption> countryOptions {
  	get {
    	if (countryOptions == null) {
    	  countryOptions = new List<SelectOption>();
    	  for (String c : countries)
		    countryOptions.add(new SelectOption(String.escapeSingleQuotes(c), c));
    	}
	    return countryOptions;
  	}
  	set;
  }

  private List<Use_Case__c> getPage(List<Use_Case__c> objs, Integer pageNumber, Integer pageSize) {
    Integer pageFirstItem = pageNumber <= 1 ? 0 : ((pageNumber - 1) * pageSize);
    Integer pageLastItem = (pageFirstItem + pageSize) > objs.size() ? objs.size() : (pageFirstItem + pageSize);
    System.debug(LoggingLevel.Info, 'pageFirstItem(' + pageFirstItem + ')');
    System.debug(LoggingLevel.Info, 'pageLastItem(' + pageLastItem + ')');
    List<Use_Case__c> newList = new List<Use_Case__c>();
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