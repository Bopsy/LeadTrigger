public without sharing class OpportunityPassToPartnerController {

    public Opportunity o {get;set;}
    public String pageStyle {get;set;}
    public Integer maxSearchResults = 1000; 
    
    public Set<String> partnerDirectoryAccountTypeLimitedOptions = new Set<String> { 'SaaS', 'Development', 'Technology' };
    
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
    public List<PartnerProfile> searchResults {get;set;}
    public List<PartnerProfile> searchResultsPage {get;set;}
    public Map<Id, Integer> searchResultsIndex {get;set;}
    public String totalRecordsFound {get;set;}

    // vf page indentification
    public static String vfPageNameDefault = 'PassToPartnerSelector';
    public String vfPageName {
        get {
            if (vfPageName == null) {
                // Split apart the URL to identify the VF page name
                // (e.g. for /apex/PageA?id=001457932524698 "PageA" is the VF page name) 
                // If the VF page name cannot be determine fallback to PassToPartnerSelector
                String url = ApexPages.currentPage().getUrl();
                if (url == null) {
                    vfPageName = vfPageNameDefault;
                } else {
                    List<String> urlParts = ApexPages.currentPage().getUrl().split('[/\\?]', 4);
                    vfPageName = (urlParts.size() > 1) ? urlParts[2] : vfPageNameDefault; 
                }
            }
            return vfPageName;
        } set;}

    // properties holding the selected partner information
    public String recordID {get; set;}
    public PartnerProfile selectedPartnerProfile {get; set;} 
    public Id selectedContact {get; set;} 
    public Pass_To_Partner__c passToPartnerRecord {get; set;}
    
    public String selectedPartnerTypes {get;set;}
    public String selectedPartnerUseCases {get;set;}
    public String selectedPartnerProducts {get;set;}
    public String selectedBuyingProcesses {get;set;}

    // the soql fields retrieved
    private List<String> queryFields = new List<String> {
        'Id',
        'Name',
        'Partner_ID__c',
        'Partner_Type__c',
        'Partner_Description__c',
        'Partner_Account_Level__c',
        'Partner_Use_Cases__c',
        'Partner_Products__c',
        'Dot_Org_Offering__c',
        'Vertical_Markets_Served__c',
        'Customer_Size__c',
        'Customer_Rating__c',
        'Customer_Examples__c',
        'Pricing_and_Sales_Cycle__c',
        'Software_Integrations_and_Compatibility__c',
        'Reference_Materials__c',
        'Partner_Intro_Contact_Information__c',
        'Partner_Solution_Category__c',
        'Regions_Served__c'
    };

    // the soql without the order and limit
    private String baseQuery() {
        // Only query 'Tier 1' partners
        String q = 'SELECT ' + String.join(queryFields, ',') + ' FROM Account WHERE IsPartner = true AND Partner_Account_Level__c = \'Tier 1\'';

        return q;
    }
    private String soql {get;set;}

    public Boolean isLocked {
        get {
            List<Pass_to_Partner__c> p = [
                SELECT Id, Name, Partner_Status__c, Contact__r.Id, Contact__r.Name, Partner_Account__r.Name
                FROM Pass_to_Partner__c
                WHERE Opportunity__c = :this.o.id
                AND Partner_Status__c NOT IN ('Closed - Won', 'Closed - Lost', 'Declined', 'Closed - Duplicate', 'Disqualified')
            ];
            if (p.size() > 0 && this.o.id != null) {
                passToPartnerRecord = p[0];
                return true;
            } else {
                return false;
            }
        }
    }

    public OpportunityPassToPartnerController() {
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
            selectedBuyingProcesses = o.Buying_Process__c;
            Apexpages.currentPage().getParameters().put('Buying_Process__c', o.Buying_Process__c);
            runSearch();
        }
    }

    public OpportunityPassToPartnerController(ApexPages.StandardController controller) {
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
        selectedBuyingProcesses = o.Buying_Process__c;
        Apexpages.currentPage().getParameters().put('Buying_Process__c', o.Buying_Process__c);
        runSearch();
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
    
    // Build a mapping of Partner to assigned User from the customer setting data where the Partner Id is the key for lookup
    public Map<String,User> partnerUserMap {
        get {
            if (partnerUserMap == null) {
                partnerUserMap = new Map<String,User>();
                
                Set<String> userIds = new Set<String>();
                for (PartnerPortalMappings__c p : PartnerPortalMappings__c.getAll().values()) {
                    if (!String.isBlank(p.Partner_ID__c) && !String.isBlank(p.User_ID__c)) {
                        userIds.add(p.User_ID__c);
                    }
                }
                
                Map<Id,User> users = new Map<Id,User>([ SELECT Id, Name, ContactId FROM User WHERE Id IN :userIds ]);
                for (PartnerPortalMappings__c p : PartnerPortalMappings__c.getAll().values()) {
                    if (!String.isBlank(p.Partner_ID__c) && !String.isBlank(p.User_ID__c)) {
                        System.debug(LoggingLevel.INFO, 'Matching Partner (' + p.Partner_ID__c + ' = ' + p.User_ID__c + ' / ' + (users.containsKey(p.User_ID__c) ? users.get(p.User_ID__c).Name : 'not found') + ')');
                        partnerUserMap.put(p.Partner_ID__c, users.get(p.User_ID__c));
                    }
                }
            }
            return partnerUserMap;
        }
        set;
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
            searchResults = new List<PartnerProfile>();
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
            List <Account> results = Database.query(soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults));

            clearSearchResults();
            Integer i = 0;
            for (Account a : results) {
                searchResults.add(new PartnerProfile(a, partnerUserMap.get(a.Partner_ID__c)));
                searchResultsIndex.put(a.Id, i++);
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
            searchResults = new List<PartnerProfile>(); // init the list if it is null
        } else {
            searchResults.clear(); // clear out the current results if they exist
        }

        String partnerTypes = Apexpages.currentPage().getParameters().get('Partner_Type__c');
        String partnerUseCases = Apexpages.currentPage().getParameters().get('Partner_Use_Cases__c');
        String partnerProducts = Apexpages.currentPage().getParameters().get('Partner_Products__c');
        String buyingProcesses = Apexpages.currentPage().getParameters().get('Buying_Process__c');
        String searchText = Apexpages.currentPage().getParameters().get('searchText');

        soql = baseQuery();
        if (!String.isBlank(partnerTypes) && !partnerTypes.equals('\' \'')) {
            soql += ' AND Partner_Type__c IN ('+ partnerTypes +')';
        } else if (vfPageName.equalsIgnoreCase('PartnerDirectory')) {
            soql += ' AND Partner_Type__c IN (\''+ String.join(new List<String>(partnerDirectoryAccountTypeLimitedOptions), '\',\'') +'\')';
        }
        if (!String.isBlank(partnerUseCases) && !partnerUseCases.equals('\' \''))
            soql += ' AND Partner_Use_Cases__c INCLUDES ('+ partnerUseCases +')';
        if (!String.isBlank(partnerProducts) && !partnerProducts.equals('\' \''))
            soql += ' AND Partner_Products__c INCLUDES ('+ partnerProducts +')';

        if (!String.isBlank(buyingProcesses) && !buyingProcesses.equals('\' \'')) {
            List<String> partnerTypesList = new List<String>();
            if (buyingProcesses.containsIgnoreCase('Wants to buy a Twilio-powered SaaS solution'))
                partnerTypesList.add('\'SaaS\'');
            if (buyingProcesses.containsIgnoreCase('Looking for a Development Partner to build or integrate Twilio'))
                partnerTypesList.add('\'Development\'');
            if (!partnerTypesList.isEmpty())
                soql += ' AND Partner_Type__c IN (' + String.join(partnerTypesList, ',') + ')';
        }

        if (!String.isBlank(searchText))
            soql += ' AND (Name LIKE \'%'+ searchText +'%\' OR Partner_Type__c LIKE \'%'+ searchText +'%\' OR Partner_Description__c LIKE \'%'+ searchText + '%\')';

        // run the query again
        runQuery();

        return null;
    }
    
    // handle the action of the commandlink
    public PageReference selectItem() {
        System.debug('recordId: ' + recordId);
        if (recordId != null) {
            selectedPartnerProfile = searchResults.get(searchResultsIndex.get(recordId));
            
            if (partnerUserMap.containsKey(selectedPartnerProfile.account.Partner_ID__c)) {
                System.debug('SELECTED CONTACT(' + selectedContact + ')');
                passToPartnerRecord = new Pass_To_Partner__c(
                    Opportunity__c = this.o.Id,
                    Partner_Account__c  = selectedPartnerProfile.account.Id,
                    Partner_Status__c = 'Submitted to Partner',
                    OwnerId = partnerUserMap.get(selectedPartnerProfile.account.Partner_ID__c).Id
                );
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '"' + selectedPartnerProfile.account.Name + '" has no user assigned to Partner ID ' + selectedPartnerProfile.account.Partner_ID__c + '.'));
                selectedPartnerProfile = null;
                recordId = null;
            }
        }
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

    public List<String> partnerTypes {
        get {
            if (partnerTypes == null) {
                partnerTypes = new List<String>();
                for (Schema.PicklistEntry f : Account.Partner_Type__c.getDescribe().getPicklistValues()) {
                    // If it is the PartnerDirectory VF page and the partnerType is not in the limited options then do not add
                    if (vfPageName.equalsIgnoreCase('PartnerDirectory') && !partnerDirectoryAccountTypeLimitedOptions.contains(f.getLabel()))
                        continue;

                    partnerTypes.add(f.getLabel());
                }
            }
            return partnerTypes;          
        }
        set;
    }
    
    public List<SelectOption> partnerTypeOptions {
        get {
            if (partnerTypeOptions == null) {
                partnerTypeOptions = new List<SelectOption>();
                for (String uc : partnerTypes) {
                    // If it is the PartnerDirectory VF page and the partnerType is not in the limited options then do not add
                    if (vfPageName.equalsIgnoreCase('PartnerDirectory') && !partnerDirectoryAccountTypeLimitedOptions.contains(uc))
                        continue;

                    partnerTypeOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
                }
            }
            return partnerTypeOptions;
        }
        set;
    }

    public List<String> partnerUseCases {
        get {
            if (partnerUseCases == null) {
                partnerUseCases = new List<String>();
                for (Schema.PicklistEntry f : Account.Partner_Use_Cases__c.getDescribe().getPicklistValues())
                    partnerUseCases.add(f.getLabel());
            }
            return partnerUseCases;          
        }
        set;
    }
    
    public List<SelectOption> partnerUseCaseOptions {
        get {
            if (partnerUseCaseOptions == null) {
                partnerUseCaseOptions = new List<SelectOption>();
                for (String uc : partnerUseCases)
                    partnerUseCaseOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
            }
            return partnerUseCaseOptions;
        }
        set;
    }

    public List<String> partnerProducts {
        get {
            if (partnerProducts == null) {
                partnerProducts = new List<String>();
                for (Schema.PicklistEntry f : Account.Partner_Products__c.getDescribe().getPicklistValues())
                    partnerProducts.add(f.getLabel());
            }
            return partnerProducts;          
        }
        set;
    }
    
    public List<SelectOption> partnerProductOptions {
        get {
            if (partnerProductOptions == null) {
                partnerProductOptions = new List<SelectOption>();
                for (String uc : partnerProducts)
                    partnerProductOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
            }
            return partnerProductOptions;
        }
        set;
    }

    public List<String> buyingProcesses {
        get {
            if (buyingProcesses == null) {
                buyingProcesses = new List<String>();
                for (Schema.PicklistEntry f : Opportunity.Buying_Process__c.getDescribe().getPicklistValues())
                    buyingProcesses.add(f.getLabel());
            }
            return buyingProcesses;          
        }
        set;
    }
    
    public List<SelectOption> buyingProcessOptions {
        get {
            if (buyingProcessOptions == null) {
                buyingProcessOptions = new List<SelectOption>();
                for (String uc : buyingProcesses)
                    buyingProcessOptions.add(new SelectOption(String.escapeSingleQuotes(uc), uc));
            }
            return buyingProcessOptions;
        }
        set;
    }
    
    private List<PartnerProfile> getPage(List<PartnerProfile> objs, Integer pageNumber, Integer pageSize) {
        Integer pageFirstItem = pageNumber <= 1 ? 0 : ((pageNumber - 1) * pageSize);
        Integer pageLastItem = (pageFirstItem + pageSize) > objs.size() ? objs.size() : (pageFirstItem + pageSize);
        System.debug(LoggingLevel.Info, 'pageFirstItem(' + pageFirstItem + ')');
        System.debug(LoggingLevel.Info, 'pageLastItem(' + pageLastItem + ')');
        List<PartnerProfile> newList = new List<PartnerProfile>();
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
    
    public class PartnerProfile {
        public Account account {get;set;}
        public User user {get;set;}
        
        public PartnerProfile(Account a, User u) {
            this.account = a;
            this.user = u;
        }
    }
}