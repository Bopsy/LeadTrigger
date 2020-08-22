public without sharing class CountryPhoneNumTypeController {

    // NOTE: When a list has more than 1,000 entries as error like below will be thrown.
    //       Collection size 1,476 exceeds maximum size of 1,000.     public Integer maxSearchResults = 1000; 
    public Integer maxSearchResults = 1000; 

    public Integer noOfRecords {get;set;}

    // the results from the search. do not init the results or a blank rows show up initially on page load
    public List<RegionSection> searchResults {get;set;}
    public String totalRecordsFound {get;set;}

    public String selectedCapabilities {get;set;}
    public String selectedTypes {get;set;}
    public String selectedOrigins {get; set;}
    public String selectedStatuses {get;set;}
    public String selectedNextStatuses {get;set;}

    // the soql fields retrieved
    private List<String> queryFields = new List<String> {
        'Id',
        'Name',
        'Capability__c',
        'Country__c',
        'Country__r.Name',
        'Phone_Number_Type__c',
        'Status__c',
        'Next_Status__c',
        'Type__c',
        'Region__c',
        'Unique_Name__c',
        'Origin__c',
        'Target_Date__c',
        'Notes__c'
    };

    // the soql without the order and limit
    private String baseQuery() {
        return 'SELECT ' + String.join(queryFields, ',') + ' FROM Country_Phone_Number_Type__c WHERE IsDeleted = false AND Show_in_roadmap__c = true';
    }
    private String soql {get;set;}

    public CountryPhoneNumTypeController() {
        clearSearchResults();
        runSearch();
    }
    
    public void clearSearchResults() {
        if (searchResults == null) {
            searchResults = new List<RegionSection>();
        } else {
            searchResults.clear();
        }
    }
    
    public string sortField {
        get { return (sortField == null) ? 'Region__c, Name' : 'Region__c,' + sortField; }
        set;
    }
    
    public string sortDir {
        get { return (sortDir == null) ? 'asc' : sortDir; }
        set;
    }

    // toggles the sorting of query from asc<-->desc
    public void toggleSort() {
        // simply toggle the direction and run the query again
        sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
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
            clearSearchResults();

            String query = soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults + 1);
            System.debug('QUERY = ' + query);
            List<Country_Phone_Number_Type__c> results = Database.query(query);
			noOfRecords = results.size();
			System.debug('noOfRecords=' + noOfRecords + ', maxSearchResults=' + maxSearchResults);

            if (noOfRecords == 0) {
                totalRecordsFound = 'No matches found';
            } else if (noOfRecords == 1) {
                totalRecordsFound = '1 match found';
            } else if (noOfRecords > maxSearchResults) {
                totalRecordsFound = String.valueOf(maxSearchResults) + '+ matches found (showing only ' + String.valueOf(maxSearchResults) + ')';
            } else {
                totalRecordsFound = String.valueOf(noOfRecords) + ' matches found';
            }

			if (results.isEmpty())
				return;

			// Stub out regions in case there are no entries for regions after searching
			for (Schema.PicklistEntry r : Country__c.Region__c.getDescribe().getPicklistValues())
            	searchResults.add(new RegionSection(r.getLabel(), new List<Country_Phone_Number_Type__c>()));
			searchResults.add(new RegionSection('Not Specified', new List<Country_Phone_Number_Type__c>()));

            List<Country_Phone_Number_Type__c> tmp = new List<Country_Phone_Number_Type__c>();
            String current_region = results[0].Region__c;
            Integer max = (noOfRecords > maxSearchResults) ? maxSearchResults : noOfRecords;
            Set<String> regionsAdded = new Set<String>();
            for (Integer i = 0; i < max; i++) {
	            Country_Phone_Number_Type__c rec = results[i];
	            
                // If region name changed adds the records for that region
                // and setup processing for next region section
            	if (rec.Region__c != current_region) {
                    System.debug('Region Transition(' + current_region + ' > ' + rec.Region__c + ')');
	            	for (RegionSection r : searchResults)
	            		if (r.name == (current_region == null ? 'Not Specified' : current_region))
	            			r.records = tmp;
					current_region = rec.Region__c;
					tmp = new List<Country_Phone_Number_Type__c>();
            	}
				tmp.add(rec);
            }
            // Add the last region section processed
        	for (RegionSection r : searchResults)
        		if (r.name == (current_region == null ? 'Not Specified' : current_region))
        			r.records = tmp;


        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - ' + e.getMessage()));
        }
    }

    // fired when the search button is clicked
    public PageReference runSearch() {
        String capabilities = Apexpages.currentPage().getParameters().get('Capability__c');
        String types = Apexpages.currentPage().getParameters().get('Type__c');
        String statuses = Apexpages.currentPage().getParameters().get('Status__c');
        String origins = Apexpages.currentPage().getParameters().get('Origin__c');
        String searchText = Apexpages.currentPage().getParameters().get('searchText');

        soql = baseQuery();
        if (!String.isBlank(capabilities) && !capabilities.equals('\' \''))
            soql += ' AND Capability__c IN ('+ capabilities +')';
        if (!String.isBlank(types) && !types.equals('\' \''))
            soql += ' AND Type__c IN ('+ types +')';
        if (!String.isBlank(statuses) && !statuses.equals('\' \''))
            soql += ' AND Status__c IN ('+ statuses +')';
        if (!String.isBlank(origins) && !origins.equals('\' \''))
            soql += ' AND Origin__c IN ('+ origins +')';

        if (!String.isBlank(searchText))
            soql += ' AND Name LIKE \'%'+ searchText +'%\'';

        // run the query again
        runQuery();

        return null;
    }

    public List<String> capabilities {
        get {
            if (capabilities == null) {
                capabilities = new List<String>();
                for (Schema.PicklistEntry f : Country_Phone_Number_Type__c.Capability__c.getDescribe().getPicklistValues())
                    capabilities.add(f.getLabel());
            }
            return capabilities;          
        }
        set;
    }
    
    public List<SelectOption> capabilityOptions {
        get {
            if (capabilityOptions == null) {
                capabilityOptions = new List<SelectOption>();
                for (String uc : capabilities)
                    capabilityOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
            }
            return capabilityOptions;
        }
        set;
    }
    
    public List<String> types {
        get {
            if (types == null) {
                types = new List<String>();
                for (Schema.PicklistEntry f : Country_Phone_Number_Type__c.Type__c.getDescribe().getPicklistValues())
                    types.add(f.getLabel());
                types.sort();
            }
            return types;          
        }
        set;
    }
    
    public List<SelectOption> typeOptions {
        get {
            if (typeOptions == null) {
                typeOptions = new List<SelectOption>();
                for (String uc : types)
                    typeOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
            }
            return typeOptions;
        }
        set;
    }
    
    public List<String> statuses {
        get {
            if (statuses == null) {
                statuses = new List<String>();
                for (Schema.PicklistEntry f : Country_Phone_Number_Type__c.Status__c.getDescribe().getPicklistValues())
                    statuses.add(f.getLabel());
            }
            return statuses;          
        }
        set;
    }
    
    public List<SelectOption> statusOptions {
        get {
            if (statusOptions == null) {
                statusOptions = new List<SelectOption>();
                for (String uc : statuses){
                    if(uc != 'Unavailable') statusOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
                }
            }
            return statusOptions;
        }
        set;
    }
    
    public List<String> nextStatuses {
        get {
            if (nextStatuses == null) {
                nextStatuses = new List<String>();
                for (Schema.PicklistEntry f : Country_Phone_Number_Type__c.Next_Status__c.getDescribe().getPicklistValues())
                    nextStatuses.add(f.getLabel());
            }
            return nextStatuses;          
        }
        set;
    }
    
    
    public List<String> Origins {
        get {
            if (Origins == null) {
                Origins = new List<String>();
                for (Schema.PicklistEntry f : Country_Phone_Number_Type__c.Origin__c.getDescribe().getPicklistValues())
                    Origins.add(f.getLabel());
            }
            return Origins;          
        }
        set;
    }
    
    public List<SelectOption> OriginOptions {
        get {
            if (OriginOptions == null) {
                OriginOptions = new List<SelectOption>();
                for (String uc : Origins)
                    OriginOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
            }
            return OriginOptions;
        }
        set;
    }
    
    public List<SelectOption> nextStatusOptions {
        get {
            if (nextStatusOptions == null) {
                nextStatusOptions = new List<SelectOption>();
                for (String uc : nextStatuses)
                    nextStatusOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
            }
            return nextStatusOptions;
        }
        set;
    }

	public Class RegionSection {
		public String name {get;set;}
		public List<Country_Phone_Number_Type__c> records {get;set;}
		public RegionSection(String name, List<Country_Phone_Number_Type__c> records) {
			this.name = String.isBlank(name) ? 'Not Specified' : name;
			this.records = records;
		}
	}
    
    // format the soql for display on the visualforce page
    public String debugSoql {
        get { return soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults + 1); }
        set;
    }
  
    // format the parameters for display on the visualforce page
    public String debugParameters {
        get { return String.join(Apexpages.currentPage().getParameters().values(), ','); }
        set;
    }
}