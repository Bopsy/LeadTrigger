public with sharing class OpportunityShortCodeController {

    public Opportunity o {get;set;}
    public String pageStyle {get;set;}
    public Integer maxSearchResults = 1000; 
    public Boolean displayPopUp {get; set;}
	
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
    public List<ShortCode> searchResults {get;set;}
    public List<ShortCode> searchResultsPage {get;set;}
    public Map<Id, Integer> searchResultsIndex {get;set;}
    public String totalRecordsFound {get;set;}

	// properties holding the selected account SID information
    public String recordID {get; set;}
    public ShortCode selectedShortCode {get; set;} 

    // the soql without the order and limit
    private String baseQuery() { return 'SELECT Id, Name, Account_SID__c, Application_Status__c, Application_Submitted_Date__c, OwnerUser_Email_Address__c, CreatedDate, LastModifiedDate FROM Short_Code__c WHERE Application_Status__c != \'Created\''; }
    private String soql {get;set;}
    public List<Short_Code__c> existingShortCodes {get; set;}
	private Set<String> accountSIDs;
    private String accountSidLookupCriteria() {
        if (accountSIDs == null) {
            accountSIDs = new Set<String>();
            if (o.New_Business_Account_SID_Lookup__r.Account_SID__c != null) {
                accountSIDs.add(o.New_Business_Account_SID_Lookup__r.Account_SID__c);
            }
            if (o.Exception_Account_SID_Lookup__r.Account_SID__c != null) {
                accountSIDs.add(o.Exception_Account_SID_Lookup__r.Account_SID__c);
            }
        }
        return accountSIDs.isEmpty() ? '' : ' AND Account_SID__c IN :accountSIDs';
    }

    public Boolean isLocked {
        get { return (this.o.Short_Code__c != null); }
  	}

    public OpportunityShortCodeController() {
		// Lookup the Opportunity record
    	String oppId = Apexpages.currentPage().getParameters().get('id');
		List<Opportunity> opps = [
			SELECT Id, Name, Owner.Email,
				Short_Code__c, Short_Code__r.Name, Short_Code__r.Account_SID__c, Short_Code__r.OwnerUser_Email_Address__c,
				New_Business_Account_SID_Lookup__c, New_Business_Account_SID_Lookup__r.Account_SID__c,
				Exception_Account_SID_Lookup__c, Exception_Account_SID_Lookup__r.Account_SID__c
			FROM Opportunity
			WHERE Id = :oppId
		];
		if (opps.isEmpty()) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - Opportunity not found having that record ID.'));
		} else {
			o = opps[0];
			clearSearchResults();
			processQueryParams();
			System.debug(LoggingLevel.INFO, 'PARAM - OPPORTUNITY(' + o.Id + ')');
			runSearch();
		}
    }

    public OpportunityShortCodeController(ApexPages.StandardController controller) {
        // Need to add all of the fields so that they will be needed from the Opportunity
        List<String> fieldList = new List<String>();
        fieldList.add('Name');
        fieldList.add('Owner.Email');
        fieldList.add('Short_Code__c');
        fieldList.add('Short_Code__r.Name');
        fieldList.add('Short_Code__r.Account_SID__c');
        fieldList.add('Short_Code__r.OwnerUser_Email_Address__c');
        fieldList.add('New_Business_Account_SID_Lookup__c');
        fieldList.add('New_Business_Account_SID_Lookup__r.Account_SID__c');
        fieldList.add('Exception_Account_SID_Lookup__c');
        fieldList.add('Exception_Account_SID_Lookup__r.Account_SID__c');
        if (!Test.isRunningTest()) {
            controller.addFields(fieldList);
        }
        o = (Opportunity)controller.getRecord();
        clearSearchResults();
		processQueryParams(); 
		System.debug(LoggingLevel.INFO, 'CONTROLLER - OPPORTUNITY(' + o.Id + ')');   
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
	    	searchResults = new List<ShortCode>();
	    	searchResultsIndex = new Map<Id, Integer>();
        } else {
            searchResults.clear();
	    	searchResultsIndex.clear();
        }
    }

    // the text in the search box
    public string searchText {
        get { return (searchText == null) ? '' : searchText; }
        set;
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
    // runs the actual query
    public void runQuery() {
        try {
        	List <Short_Code__c> results = Database.query(
            	soql
				+ accountSidLookupCriteria()
				+ ' ORDER BY ' + sortField + ' ' + sortDir
				+ ' LIMIT ' + String.valueOf(maxSearchResults)
			);

            clearSearchResults();
            Integer i = 0;
            existingShortCodes = [SELECT Name, Account_SID__c, OwnerUser_Email_Address__c FROM Short_Code__c WHERE Opportunity__c =: o.Id];
            Set<Id> scIds = new Set<Id>();
            if(existingShortCodes != null){
                for(Short_Code__c sc: existingShortCodes){
                    scIds.add(sc.Id);
                }
            }
            for (Short_Code__c sc : results) {
                if(!scIds.contains(sc.Id)){
            	    searchResults.add(new ShortCode(sc));
            	    searchResultsIndex.put(sc.Id, i++);
                }
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
        String searchText = Apexpages.currentPage().getParameters().get('searchText');

        soql = baseQuery();
        if (!String.isBlank(searchText))
            soql += ' AND (OwnerUser_Email_Address__c LIKE \'%'+ searchText +'%\' OR Account_SID__c LIKE \'%' + searchText + '%\')';

        // run the query again
        runQuery();

        return null;
    }
    
    // handle the action of the commandlink
    public void selectItem() {
        displayPopUp = true;
        System.debug('recordId: ' + recordId);
        if (recordId != null) {
			selectedShortCode = searchResults.get(searchResultsIndex.get(recordId));
        }
        save();
        clearSearchResults();
        runSearch();
        //return null;
    }
    
    public void save() {
    	try {
    	    Opportunity shortCodeOppty = [SELECT Short_Code__c FROM Opportunity WHERE Id =:o.Id LIMIT 1];
    		if(shortCodeOppty.Short_Code__c == null){
    		    o.Short_Code__c = recordId;
    		    update o;
    		}
    		
    		Short_Code__c sc = selectedShortCode.sc;
    		sc.Opportunity__c = o.Id;
    		update sc;

			List<Opportunity> opps = [
				SELECT Id, Name, Owner.Email,
					Short_Code__c, Short_Code__r.Name, Short_Code__r.Account_SID__c, Short_Code__r.OwnerUser_Email_Address__c,
					New_Business_Account_SID_Lookup__c, New_Business_Account_SID_Lookup__r.Account_SID__c,
					Exception_Account_SID_Lookup__c, Exception_Account_SID_Lookup__r.Account_SID__c
				FROM Opportunity
				WHERE Id = :o.Id
			];
			if (!opps.isEmpty()) {
				o = opps[0];
			}
			
    	} catch (System.DMLException e) {
    		ApexPages.addMessages(e);
    	}
    	displayPopUp = false;
    	//return null;
	}
	
	private List<ShortCode> getPage(List<ShortCode> objs, Integer pageNumber, Integer pageSize) {
		Integer pageFirstItem = pageNumber <= 1 ? 0 : ((pageNumber - 1) * pageSize);
		Integer pageLastItem = (pageFirstItem + pageSize) > objs.size() ? objs.size() : (pageFirstItem + pageSize);
		System.debug(LoggingLevel.Info, 'pageFirstItem(' + pageFirstItem + ')');
		System.debug(LoggingLevel.Info, 'pageLastItem(' + pageLastItem + ')');
		List<ShortCode> newList = new List<ShortCode>();
		for (Integer i = pageFirstItem; i < pageLastItem; i++) {
			newList.add(objs.get(i));
			System.debug(LoggingLevel.Info, 'Adding(' + i + ')');
		}
		System.debug(LoggingLevel.Info, 'Page Size(' + newList.size() + ')');
		return newList;
	}

	// format the soql for display on the visualforce page
	public String debugSoql {
		get { return soql + accountSidLookupCriteria() + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults); }
	}
  
	// format the parameters for display on the visualforce page
	public String debugParameters {
		get { return String.join(Apexpages.currentPage().getParameters().values(), ','); }
	}

	public String debugAccountSIDs {
		get { return String.join(new List<String>(accountSIDs), ','); }
	}

	public class ShortCode {
	  	public Short_Code__c sc {get;set;}
	    
		public ShortCode(Short_Code__c sc) {
			this.sc = sc;
		}
	}
}