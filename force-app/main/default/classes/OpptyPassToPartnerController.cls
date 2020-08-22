public with sharing class OpptyPassToPartnerController {
    private static final string PARAM_Partner_Listing_Type ='Partner_Listing_Type__c';
    private static final string PARAM_Partner_Category ='Partner_Category__c';
    private static final string PARAM_products ='products__c';
    private static final string PARAM_Regions ='Regions__c';
    private static final string PARAM_Market_Segment='Market_Segment__c';
    private static final string PARAM_Solutions ='Solutions__c';
     private static final string PARAM_Industries ='Industries__c';
      private static final string PARAM_searchText ='searchText';
    private static final String PTP_STATUS= 'Submitted to Partner';
    
    public Opportunity o {get;set;}
    
    public String pageStyle {get;set;}
    public Integer maxSearchResults = 1000; 
    
    public Integer pageSize    { get { return (pageSize == null) ? 10 : pageSize; } set;}
    public Integer pageNumber  { get { return (pageNumber == null || pageNumber < 1) ? 1 : pageNumber; } set;}
    
    public Integer noOfRecords { get { return (searchResults == null) ? 0 : searchResults.size(); } }
    public Boolean hasNext     { get { return (noOfRecords == 0 || noOfRecords <= (pageSize * pageNumber)) ? false : true; } }
    public Boolean hasPrevious { get { return (noOfRecords == 0 || pageNumber <= 1) ? false : true; } }
    
    public PageReference first()    { pageNumber = 1; 
                                     refresh(); 
                                     return null; }
    public PageReference last()     { pageNumber = Integer.valueOf(Math.ceil(Decimal.valueOf(noOfRecords) / Decimal.valueOf(pageSize)));  
                                     refresh(); 
                                     return null; }
    public PageReference previous() { pageNumber--; 
                                     refresh(); 
                                     return null; }
    public PageReference next()     { pageNumber++; 
                                     refresh(); 
                                     return null; }
    
    public void refresh()           { 
        searchResultsPage = getPage(searchResults, pageNumber, pageSize); 
    }
    
    
    private List<Partner_Listing__c> getPage(List<Partner_Listing__c> objs, Integer pageNumber, Integer pageSize) {
        Integer pageFirstItem = pageNumber <= 1 ? 0 : ((pageNumber - 1) * pageSize);
            Integer pageLastItem = (pageFirstItem + pageSize) > objs.size() ? objs.size() : (pageFirstItem + pageSize);
                System.debug(LoggingLevel.Info, 'pageFirstItem(' + pageFirstItem + ')');
        System.debug(LoggingLevel.Info, 'pageLastItem(' + pageLastItem + ')');
        List<Partner_Listing__c> newList = new List<Partner_Listing__c>();
        for (Integer i = pageFirstItem; i < pageLastItem; i++) {
            newList.add(objs.get(i));
            System.debug(LoggingLevel.Info, 'Adding(' + i + ')');
        }
        System.debug(LoggingLevel.Info, 'Page Size(' + newList.size() + ')');
        return newList;
    }
    
    
    public List<Partner_Listing__c> searchResults {get;set;}
    public List<Partner_Listing__c> searchResultsPage {get;set;}
    public Map<Id, Integer> searchResultsIndex {get;set;}
    public String totalRecordsFound {get;set;}
    
    public String selectedListingType {get;set;}
    public String selectedPartnerCategory {get;set;}
    public String selectedProducts {get;set;}
    public String selectedRegions {get;set;}
    public String selectedMarketSegment {get;set;}
    public String selectedSolutions {get;set;}
    public String selectedIndistries {get;set;}
    
    
    
    // properties holding the selected partner information
    public String recordID {get; set;}
    public Partner_Listing__c selectedPartnerListing {get; set;} 
    public Id selectedContact {get; set;} 
    public Pass_To_Partner__c passToPartnerRecord {get; set;}
    
    public List<Pass_to_Partner__c> passToPartnerRecList {get;set;}
    
    // the soql fields retrieved
    private List<String> queryFields = new List<String> {
        'Id',
            'Name',
            'Partner_Profile__r.Account__r.name',
            'Partner_Profile__r.Account__r.Id',
            'Description__c',
            'Category__c',
            'Market_Segment__c',
            'Resell_or_Influence__c',
            'Solutions__c',
            'Geographies_Served__c',
            'Certifications__c',
            'Twilio_Technologies__c',
            'Industries__c',
            'RecordType.Name'
            };
                
                
                // the soql without the order and limit
                private String baseQuery() {
                    String q = 'SELECT ' + String.join(queryFields, ',') + ' FROM Partner_Listing__c WHERE PTP_Enabled__c = true';
                    return q;
                }
    
    private String soql {get;set;}
    
    public Boolean isLocked {
        get {
            passToPartnerRecList = [
                SELECT Id, Name, Partner_Status__c, Contact__r.Id, Contact__r.Name, Partner_Account__r.Name
                FROM Pass_to_Partner__c
                WHERE Opportunity__c = :this.o.id
                AND Partner_Status__c NOT IN ('Closed - Won', 'Closed - Lost', 'Declined', 'Closed - Duplicate', 'Disqualified')
            ];
            if (passToPartnerRecList.size() > 0 && this.o.id != null) {
                return true;
            } else {
                return false;
            }
        }
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
    
    
    public OpptyPassToPartnerController() {
        // Lookup the Opportunity record
        String oppId = Apexpages.currentPage().getParameters().get('id');
        List<Opportunity> opps = [ SELECT Id, Name, Buying_Process__c FROM Opportunity WHERE Id = :oppId ];
        if (opps.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - Opportunity not found having that record ID.'));
        } else {
            o = opps[0];
            clearSearchResults();
            processQueryParams();
            System.debug(LoggingLevel.INFO, 'PARAM - OPPORTUNITY(' + o.Id + ')');
            Apexpages.currentPage().getParameters().put('Buying_Process__c', o.Buying_Process__c);
            runSearch();
        }
    }
    
    public OpptyPassToPartnerController(ApexPages.StandardController controller) {
        // Need to add all of the fields so that they will be needed from the Opportunity
        List<String> fieldList = new List<String>();
        fieldList.add('Name');
        fieldList.add('Buying_Process__c');
        if (!Test.isRunningTest()) {
            controller.addFields(fieldList);
        }
        o = (Opportunity)controller.getRecord();
        clearSearchResults();
        processQueryParams();
        System.debug(LoggingLevel.INFO, 'CONTROLLER - OPPORTUNITY(' + o.Id + ')');   
        Apexpages.currentPage().getParameters().put('Buying_Process__c', o.Buying_Process__c);
        runSearch();
    }
    // the text in the search box
    public string searchText {
        get { return (searchText == null) ? '' : searchText; }
        set;
    }
    
    // Build select options for Opportunity Contacts
    public List<SelectOption> partnerListingTypeOptions {
        get {
            if (partnerListingTypeOptions == null) {
                partnerListingTypeOptions = new List<SelectOption>();
                for (recordtype rt : [select id, name from recordtype where sObjectType='Partner_Listing__c']) {
                    partnerListingTypeOptions.add(new SelectOption(rt.id, rt.name));
                }
            }
            return partnerListingTypeOptions;
        }
        set;
    }
    
    // Build select options for Opportunity Contacts
    public List<SelectOption> productOptions {
        get {
            if (productOptions == null) {
                productOptions = new List<SelectOption>();
                for (Schema.PicklistEntry f : Partner_Listing__c.Twilio_Technologies__c.getDescribe().getPicklistValues())
                    productOptions.add(new SelectOption(f.getValue(),f.getLabel()));
            }
            return productOptions;
        }
        set;
    }
    
    // Build select options for Opportunity Contacts
    public List<SelectOption> partnerCategoryOptions {
        get {
            if (partnerCategoryOptions == null) {
                partnerCategoryOptions = new List<SelectOption>();
                for (Schema.PicklistEntry f : Partner_Listing__c.Category__c.getDescribe().getPicklistValues())
                    partnerCategoryOptions.add(new SelectOption(f.getValue(),f.getLabel()));
            }
            return partnerCategoryOptions;  
        }
        set;
    }
    
    // Build select options for Opportunity Contacts
    public List<SelectOption> regionsOptions {
        get {
            if (regionsOptions == null) {
                regionsOptions = new List<SelectOption>();
                for (Schema.PicklistEntry f : Company_Profile__c.Geographies_Served__c.getDescribe().getPicklistValues())
                    regionsOptions.add(new SelectOption(f.getValue(),f.getLabel()));
            }
            return regionsOptions; 
        }
        set;
    }
    
    // Build select options for Opportunity Contacts
    public List<SelectOption> marketSegmentOptions {
        get {
            if (marketSegmentOptions == null) {
                marketSegmentOptions = new List<SelectOption>();
                for (Schema.PicklistEntry f : Partner_Listing__c.Market_Segment__c .getDescribe().getPicklistValues())
                    marketSegmentOptions.add(new SelectOption(f.getValue(),f.getLabel()));
            }
            return marketSegmentOptions;
        }
        set;
    }
    
    // Build select options for Opportunity Contacts
    public List<SelectOption> solutionOptions {
        get {
            if (solutionOptions == null) {
                solutionOptions = new List<SelectOption>();
                for (Schema.PicklistEntry f : Partner_Listing__c.Solutions__c .getDescribe().getPicklistValues())
                    solutionOptions.add(new SelectOption(f.getValue(),f.getLabel()));
            }
            return solutionOptions;
        } 
        set;
    }
    
    // Build select options for Opportunity Contacts
    public List<SelectOption> IndistriesOptions {
        get {
            if (IndistriesOptions == null) {
                IndistriesOptions = new List<SelectOption>();
                for (Schema.PicklistEntry f : Partner_Listing__c.Industries__c.getDescribe().getPicklistValues())
                    IndistriesOptions.add(new SelectOption(f.getValue(),f.getLabel()));
            }
            return IndistriesOptions;
        } 
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
    
    public string getEscapedvalues(String s){
        if(s!= null && !String.isBlank(s) && !s.equals('\' \'')){
            
            List<String> l = s.split(',');
            String escapedValue='';
            for(integer i=0;i<l.size();i++){
                String str = l[i] ;
                str =str.removeEnd('\'');
                str = str.removeStart('\'');
                str ='\''+String.escapeSingleQuotes(str)+'\'';
                if(i==0){
                    escapedValue = str;
                } else {
                    escapedValue =  escapedValue +','+str;
                }
                
            }
            return escapedValue;
        } return null;
    }
    // fired when the search button is clicked
    public PageReference runSearch() {
        System.debug('searchResults:'+searchResults);
        if (searchResults == null) {
            searchResults = new List<Partner_Listing__c>(); // init the list if it is null
        } else {
            searchResults.clear(); // clear out the current results if they exist
        }
        
        String partnerListingTypes = Apexpages.currentPage().getParameters().get(PARAM_Partner_Listing_Type);
        String categories = getEscapedvalues(Apexpages.currentPage().getParameters().get(PARAM_Partner_Category));
        String products = getEscapedvalues(Apexpages.currentPage().getParameters().get(PARAM_products));
        String regions = getEscapedvalues(Apexpages.currentPage().getParameters().get(PARAM_Regions));
        String marketSegemnt = getEscapedvalues(Apexpages.currentPage().getParameters().get(PARAM_Market_Segment));
        String solutions = getEscapedvalues(Apexpages.currentPage().getParameters().get(PARAM_Solutions));
        String industries = getEscapedvalues(Apexpages.currentPage().getParameters().get(PARAM_Industries));
        String searchText = Apexpages.currentPage().getParameters().get(PARAM_searchText);
        
        soql = baseQuery();
        if (!String.isBlank(partnerListingTypes) && !partnerListingTypes.equals('\' \'')) {
            soql += ' AND recordtypeId IN ('+ partnerListingTypes +')';
        }
        if (!String.isBlank(categories) && !categories.equals('\' \'')){
            soql += ' AND Category__c INCLUDES ('+ categories +')';
        }
        if (!String.isBlank(products) && !products.equals('\' \''))
            soql += ' AND Twilio_Technologies__c INCLUDES ('+ products +')';
        if (!String.isBlank(regions) && !regions.equals('\' \''))
            soql += ' AND Partner_Profile__r.Geographies_Served__c INCLUDES ('+ regions +')';
        
        if (!String.isBlank(marketSegemnt) && !marketSegemnt.equals('\' \''))
            soql += ' AND Market_Segment__c INCLUDES ('+ marketSegemnt +')';
        
        if (!String.isBlank(solutions) && !solutions.equals('\' \''))
            soql += ' AND Solutions__c INCLUDES ('+ solutions +')';
        if (!String.isBlank(industries) && !industries.equals('\' \''))
            soql += ' AND Industries__c INCLUDES ('+ industries +')';
        
        
        if (!String.isBlank(searchText))
            soql += ' AND (Name LIKE \'%'+ String.escapeSingleQuotes(searchText) +'%\' OR Description__c LIKE \'%'+ String.escapeSingleQuotes(searchText) + '%\')';
        
        // run the query again
        runQuery();
        
        return null;
    }
    
    // runs the actual query
    public void runQuery() {
        try {
            String finalQuery = soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults);
            System.debug('finalQuery-->'+finalQuery);
            List<Partner_Listing__c> results = Database.query(finalQuery);
            System.debug('results-->'+results);
            clearSearchResults();
            Integer i = 0;
            for (Partner_Listing__c pl : results) {
                searchResults.add(pl);
                searchResultsIndex.put(pl.Id, i++);
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
            System.debug(e.getStackTraceString());
        }
        
    }
    public void clearSearchResults() {
        System.debug('clearSearchResults:searchResults-->'+searchResults);
        if (searchResults == null) {
            searchResults = new List<Partner_Listing__c>();
            
        } else {
            searchResults.clear();
        }
        if(searchResultsIndex != null){
            searchResultsIndex.clear();
        } else {
            searchResultsIndex = new Map<Id, Integer>();
        }
        
    }
    
    // handle the action of the commandlink
    public PageReference selectItem() {
        System.debug('recordId: ' + recordId);
        if (recordId != null) {
            selectedPartnerListing = searchResults.get(searchResultsIndex.get(recordId));
            System.debug('selectedPartnerListing-->'+selectedPartnerListing);
            List<User> ladminUser = [select id from user where contactid in (select id from contact where Account_Admin__c =true and accountId =:selectedPartnerListing.partner_Profile__r.account__r.id )];
            System.debug('ladminUser-->'+ladminUser);
            if(ladminUser != null && !ladminUser.isEmpty() && ladminUser.get(0) != null){
                System.debug('SELECTED CONTACT(' + selectedContact + ')');
                passToPartnerRecord = new Pass_To_Partner__c(
                    Opportunity__c = this.o.Id,
                    Partner_Account__c  = selectedPartnerListing.partner_Profile__r.account__r.id,
                    Partner_Status__c = PTP_STATUS,
                    OwnerId = ladminUser.get(0).id
                );
                System.debug('passToPartnerRecord-->'+passToPartnerRecord);
            } else {
                System.debug('errrrrorr');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '"' + selectedPartnerListing.partner_Profile__r.account__r.name + '" has no user assigned as the admin user. Please set a contact as account admin' ));
                selectedPartnerListing = null;
                recordId = null;
            }
        }
        System.debug('recordId: ' + recordId);
        return null;
    }
    
    public PageReference save() {
        Boolean hasErrors = false;
        if (passToPartnerRecord == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating Pass To Partner record.'));
            hasErrors = true;
        } else {
            if (passToPartnerRecord.Opportunity__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PTP record has no opportunity associated with it.'));
                hasErrors = true;
            }
        }
        if (selectedContact == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must specify the Contact.'));
            hasErrors = true;
        }
        if (hasErrors) {
            return null;
        }
        
        try {
            passToPartnerRecord.Contact__c = selectedContact;
            insert passToPartnerRecord;
        } catch (System.DMLException e) {
            ApexPages.addMessages(e);
        }
        return null;
    }
    
    // Build select options for Opportunity Contacts
    public List<SelectOption> opportunityContactOptions {
        get {
            if (opportunityContactOptions == null) {
                opportunityContactOptions = new List<SelectOption>();
                for (OpportunityContactRole c : [ SELECT Id, ContactId, Contact.Name FROM OpportunityContactRole WHERE OpportunityId = :o.Id ORDER BY Contact.Name ]) {
                    opportunityContactOptions.add(new SelectOption(c.ContactId, c.Contact.Name));
                }
            }
            return opportunityContactOptions;
        }
        set;
    }
    
    
}