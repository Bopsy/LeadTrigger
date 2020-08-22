public class OpportunityAccountSidController {

    // instance variable for the standard controller
    private ApexPages.StandardController controller {get; set;}

    private static String NEW_PRODUCT = 'New Product';
    private static String EXISTING_PRODUCT = 'Existing Product in 1 Year';
    
    private Integer maxSearchResults = 50; 
    static Map<String, String> oppSKUFieldMap{
        get{
            if(oppSKUFieldMap == null){
                oppSKUFieldMap = new Map<String, String>();
                for(AccountSID_to_SKU_Mappings__c setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
                    if(setting.Year__c == 2018){
                        if(setting.Software_Product__c){
                            oppSKUFieldMap.put(setting.Account_SID_API_Name__c + '-SW Category', setting.Opp_SKU_Field__c);
                        }
                        else{
                            oppSKUFieldMap.put(setting.Account_SID_API_Name__c + '-Non SW Category', setting.Opp_SKU_Field__c);
                        }
                    }
                }
            }
            return oppSKUFieldMap;
        }
        set;
    }
    private String baseQuery() {
/* REMOVED LIMITATION TO ONLY SHOW ACCCOUNT SID'S RELATED TO THE OPPORTUNITY
    	return 'SELECT Id, Name, New_Business_Opportunity__c, Exception_Opportunity__c, NPC_Date_50__c, Account_SID_Created_Date__c, Account_SID_Status__c, Account__r.Id FROM Account_SID__c WHERE IsDeleted = false AND Account_SID_Status__c = \'ACTIVE\' AND Account__r.Id = \'' + accountId + '\'';
*/
    	return 'SELECT Id, Account__c, Name, Software_MRR__c, Total_MRR__c, New_Business_Opportunity__c, Exception_Opportunity__c, NPC_Date_50__c, Account_SID_Created_Date__c, Account_SID_Status__c, Account__r.Id FROM Account_SID__c WHERE IsDeleted = false';
    }

    public Opportunity o {get;set;}
/* REMOVED LIMITATION TO ONLY SHOW ACCCOUNT SID'S RELATED TO THE OPPORTUNITY
    public String accountID {get; set;}
*/

    public Boolean alreadySet {
    	get { return (this.o.New_Business_Account_SID_Lookup__c != null || this.o.Exception_Account_SID_Lookup__c != null); }
  	}

    // the results from the search. do not init the results or a blank rows show up initially on page load
    public List<AccountSID> searchResults {get;set;}
    public String totalRecordsFound {get;set;}

	// properties holding the selected account SID information
    public String accountSID {get;set;}
    public String recordID {get;set;}
    public Boolean isNewBusiness {get;set;}
    public Map<String, List<Account_SID_SKU__c>> accountSIDSKU {get;set;}

    public String newBusinessRecordID {get;set;}
    public String newBusinessAccountSID {get;set;}

    public String exceptionRecordID {get;set;}
    public String exceptionAccountSID {get;set;}
    public String exceptionAccountSIDReason {get;set;}

//    public List<Account_SID_SKU__c> selectedAccountSIDSKU {get;set;}
    public List<AccountSIDSKU> selectedAccountSIDSKU {get;set;}
    public List<Opp_SID_SKU__c> existingOppSkus {get; set;}
    public Boolean getHasSelectedAccountSIDSKU() { return selectedAccountSIDSKU == null ? false : !selectedAccountSIDSKU.isEmpty(); }

    // the soql without the order and limit
    private String soql {get;set;}
    private String accountId {get; set;}

    public OpportunityAccountSidController() {
    	String oppId = Apexpages.currentPage().getParameters().get('id');
		searchResults = new List<AccountSID>();
    	initializeOppty(oppId);
/* REMOVED LIMITATION TO ONLY SHOW ACCCOUNT SID'S RELATED TO THE OPPORTUNITY
    	if (initializeOppty(oppId)) {
	        if (!alreadySet) {
			    soql = baseQuery();
		        runQuery();
	        } else {
	        	
	        }
    	}
*/
    }

    public OpportunityAccountSidController(ApexPages.StandardController controller) {
        //initialize the standard controller
        this.controller = controller;

        // Need to add all of the fields so that they will be needed from the Opportunity
        List<String> fieldList = new List<String>();
/* REMOVED LIMITATION TO ONLY SHOW ACCCOUNT SID'S RELATED TO THE OPPORTUNITY
        fieldList.add('AccountId');
*/
        fieldList.add('New_Business_Account_SID_Lookup__c');
        fieldList.add('Exception_Account_SID_Lookup__c');
        fieldList.add('Exception_Account_SID_Reason__c');
        if (!Test.isRunningTest()) {
            controller.addFields(fieldList);
        }
        this.o = (Opportunity)controller.getRecord();
        accountId = [SELECT AccountId FROM Opportunity WHERE Id =: this.o.id].AccountId;

        searchResults = new List<AccountSID>();
        accountSIDSKU = new Map<String, List<Account_SID_SKU__c>>();
        
        initializeOppty(this.o);
/* REMOVED LIMITATION TO ONLY SHOW ACCCOUNT SID'S RELATED TO THE OPPORTUNITY
        if (initializeOppty(this.o)) {
			if (!alreadySet) {
		        soql = baseQuery();
		        System.debug('SOQL(' + soql + ')');
		        runQuery();
			}
        }
*/
    }
    
    // Initialize the opportunity and its properties
    // If an error occurs "false" will be returned otherwise "true"
    private Boolean initializeOppty(Opportunity o) {
/* REMOVED LIMITATION TO ONLY SHOW ACCCOUNT SID'S RELATED TO THE OPPORTUNITY
        accountID = o.AccountId;
*/

		newBusinessRecordID = o.New_Business_Account_SID_Lookup__c;
        newBusinessAccountSID = lookupAccountSID(newBusinessRecordID);
        selectedAccountSIDSKU = lookupAccountSIDSKU(newBusinessAccountSID);

		exceptionRecordID = o.Exception_Account_SID_Lookup__c;
		exceptionAccountSID = lookupAccountSID(exceptionRecordID);
		exceptionAccountSIDReason = o.Exception_Account_SID_Reason__c;

		isNewBusiness = (newBusinessRecordID != null && exceptionRecordID == null);
		
		existingOppSkus = [SELECT Account_SID__r.Name, Account_SID__c, Software_MRR__c, Total_MRR__c FROM Opp_SID_SKU__c WHERE Opportunity__c =: o.Id];
		return true;
    }

    // If an error occurs "false" will be returned otherwise "true"
    private Boolean initializeOppty(Id oppId) {
    	List<Opportunity> opp = [ SELECT Id, AccountId, New_Business_Account_SID_Lookup__c, Exception_Account_SID_Lookup__c, Exception_Account_SID_Reason__c FROM Opportunity WHERE Id = :oppId ];
    	if (opp.size() == 0) {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - Opportunity not found having that record ID.'));
    		return false;
    	} else {
    		this.o = opp[0];
	    	return initializeOppty(this.o);
    	}
    }

	// Lookup the Account SID name from the record ID
	private String lookupAccountSID(Id recId) {
		if (recId == null) {
			return null;
		}
		List<Account_SID__c> sid = [ SELECT Id, Name FROM Account_SID__c WHERE Id = :recId ];
    	if (sid.size() == 0) {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - Account SID not found having that record ID.'));
    		return null;
    	} else {
	    	return sid[0].Name;
    	}
	}

	// Lookup the Account SID name from the record ID
	private List<AccountSIDSKU> lookupAccountSIDSKU(String sid) {
		if (sid == null) {
			return null;
		}
//		return [
//			SELECT Id, Name, Account_SID__r.Account_SID__c, MRR__c, Opportunity_Product__r.Name, Type__c
//			FROM Account_SID_SKU__c
//			WHERE Account_SID__r.Account_SID__c = :sid
//		];
		List<AccountSIDSKU> skuList = new List<AccountSIDSKU>();
		for (Account_SID_SKU__c s : [
			SELECT Id, Name, Account_SID__r.Account_SID__c, Three_Months_MRR__c, Opportunity_Product__r.Name, Type__c
			FROM Account_SID_SKU__c
			WHERE Account_SID__r.Account_SID__c = :sid
		]) {
			skuList.add(new AccountSIDSKU(s.Account_SID__r.Account_SID__c, s.Type__c, s.Opportunity_Product__r.Name, s.Three_Months_MRR__c));
		}
		return skuList;
	}
	
    // the text in the search box
    public Boolean accountSIDAssigned {
        get { return ((o != null) && ((o.New_Business_Account_SID_Lookup__c != null) || (o.Exception_Account_SID_Lookup__c != null))); }
        set;
    }
    
    // the text in the search box
    public string searchText {
        get { return (searchText == null) ? '' : searchText; }
        set;
    }
    
    public string sortField {
    	get { return (sortField == null) ? 'Account_SID_Created_Date__c' : sortField; }
    	set;
    }
    
    public string sortDir {
    	get { return (sortDir == null) ? 'desc' : sortDir; }
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
            Set<Id> exsitingId = new Set<Id>();
            for(Opp_SID_SKU__c sku: existingOppSkus){
                exsitingId.add(sku.Account_SID__c);
            }
            List <Account_SID__c> sidResults = Database.query(soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults));
			List <String> ids = new List<String>();
			
	        if (searchResults == null) {
	            searchResults = new List<AccountSID>(); // init the list if it is null
	        } else {
	            searchResults.clear(); // clear out the current results if they exist
	        }
            for (Account_SID__c a : sidResults) {
                AccountSID result = new AccountSID(a);
                result.existed = exsitingId.contains(a.Id);
                result.notSameAccount =  a.Account__c != null && a.Account__c != accountId;
            	searchResults.add(result);
            	ids.add(a.Name);
            }

            if (sidResults.size() == 0) {
                totalRecordsFound = 'No matches';
            } else if (sidResults.size() == 1) {
                totalRecordsFound = '1 match found';
            } else if (sidResults.size() == maxSearchResults) {
                totalRecordsFound = String.valueOf(sidResults.size()) + '+ matches found (showing only ' + String.valueOf(maxSearchResults) + ')';
            } else if (sidResults.size() > 1) {
                totalRecordsFound = String.valueOf(sidResults.size()) + ' matches found';
            }

			// Look up related SKUs for the Account SIDs and add them to the corresponding searchResults SKU list
            accountSIDSKU = new Map<String, List<Account_SID_SKU__c>>();
            for (Account_SID_SKU__c s : [
				SELECT Id, Name, Account_SID__r.Account_SID__c, Three_Months_MRR__c, Opportunity_Product__r.Name, Type__c
				FROM Account_SID_SKU__c
				WHERE Account_SID__r.Account_SID__c IN :ids
			]) {
				System.debug('ADDING: ' + s);

				if (!accountSIDSKU.containsKey(s.Account_SID__r.Account_SID__c))
					accountSIDSKU.put(s.Account_SID__r.Account_SID__c, new List<Account_SID_SKU__c>());

				accountSIDSKU.get(s.Account_SID__r.Account_SID__c).add(s);
/*
            	for (AccountSID a : searchResults) {
	            	a.sku.add(s);
	            }
*/
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
            soql += ' AND Name =:searchText AND Parent_Account_SID__c = null';

        // run the query again
        runQuery();

        return null;
    }
    
    // handle the action of the commandlink
    public PageReference selectAccountSID() {
        System.debug('accountSID: '+accountSID);

		newBusinessRecordID = null;
		newBusinessAccountSID = null;

		exceptionRecordID = null;
		exceptionAccountSID = null;
		exceptionAccountSIDReason = '';

		if (isNewBusiness) {
			newBusinessRecordID = recordID;
			newBusinessAccountSID = accountSID;
		} else {
			exceptionRecordID = recordID;
			exceptionAccountSID = accountSID;
		}

		selectedAccountSIDSKU = getSKUs(o, accountSID);
        save();
        return null;
    }
    
    public PageReference save() {
    	if (!isNewBusiness && String.isBlank(exceptionAccountSIDReason)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An exception reason must be given to select this Account SID.'));
			return null;
    	}
    	Opportunity opp = new Opportunity();
    	opp.Id = this.o.Id;
    	opp.New_Business_Account_SID__c = newBusinessAccountSID;
    	opp.New_Business_Account_SID_Lookup__c = newBusinessRecordID;
    	opp.Exception_Account_SID__c = exceptionAccountSID;
    	opp.Exception_Account_SID_Lookup__c = exceptionRecordID;
    	opp.Exception_Account_SID_Reason__c = exceptionAccountSIDReason;
    	Id accountId = [SELECT AccountId FROM Opportunity WHERE Id =: opp.Id LIMIT 1].AccountId;
    	
    	Account_SID__c sid;
    	
    	if (newBusinessRecordID != null) {
    		List<Account_SID__c> sids = [
				SELECT Id, New_Business_Opportunity__c, Account__c
				FROM Account_SID__c
				WHERE Id = :newBusinessRecordID
				AND New_Business_Opportunity__c = null
			];
    		if (!sids.isEmpty()) {
    			sid = sids[0];
	    		sid.New_Business_Opportunity__c = this.o.Id;
	    		if(sid.Account__c == null) sid.Account__c = accountId;
    		}
    	} else if (exceptionRecordID != null) {
    		List<Account_SID__c> sids = [
				SELECT Id, Exception_Opportunity__c, Account__c
				FROM Account_SID__c
				WHERE Id = :exceptionRecordID
				AND Exception_Opportunity__c = null
			];
    		if (!sids.isEmpty()) {
	    		sid = sids[0];
	    		sid.Exception_Opportunity__c = this.o.Id;
	    		if(sid.Account__c == null) sid.Account__c = accountId;
    		}
    	}
    	String queryString = 'SELECT Id ';
    	
    	for(String fieldStr: oppSKUFieldMap.keySet()){
    	    queryString += ',' + fieldStr.split('-')[0];
    	}
    	
    	queryString += ' FROM Account_SID__c WHERE Id =:newBusinessRecordId';
    	
    	Account_SID__c querySid = Database.query(queryString);
    	
    	Opp_SID_SKU__c sku = new Opp_SID_SKU__c(Opportunity__c = this.o.Id, Account_SID__c = newBusinessRecordId);
    	for(String fieldStr: oppSKUFieldMap.keySet()){
    	    String accSIDField = fieldStr.split('-')[0];
    	    sku.put(oppSKUFieldMap.get(fieldStr), querySid.get(accSIDField));
    	}
    	
    	// Create a savepoint while AccountNumber is null
		Savepoint sp = Database.setSavepoint();
    	
    	try {
    	    insert sku;
    	    //system.assert(false, 'Should not show here');
    		update opp;
    		if (sid != null) {
    			update sid;
    		}
    		
    		List<Product_Schedule__c> schedules = [SELECT MRR__c, Forecast_Amount__c FROM Product_Schedule__c WHERE Forecast_Schedule__r.Opportunity__c =: this.o.Id];
    		
    		for(Product_Schedule__c schedule: schedules){
    		    if(schedule.Forecast_Amount__c != null && schedule.MRR__c != null){
    		        schedule.New_Business_Forecast_Amount__c = schedule.Forecast_Amount__c + schedule.MRR__c;
    		    }
    		}
    		
    		update schedules;
	    	initializeOppty(this.o.Id);
    	} catch (System.DMLException e) {
    		ApexPages.addMessages(e);
    		Database.rollback(sp);
    	}
    	
    	
    	return null;
	}

  // format the soql for display on the visualforce page
  public String debugSoql {
    get { return soql + ' limit 20'; }
    set;
  }
  
  // format the parameters for display on the visualforce page
  public String debugParameters {
    get { return String.join(Apexpages.currentPage().getParameters().values(), ','); }
    set;
  }
  
  public class AccountSID {
  	public Account_SID__c sid {get;set;}
    public String isNewBusiness {get;set;}
    public Boolean existed {get; set;}
    public Boolean notSameAccount {get; set;}
    
	public AccountSID(Account_SID__c a) {
		this.sid = a;
		this.isNewBusiness = 'true'; //(a.NPC_Date_50__c == null && sid.New_Business_Opportunity__c == null) ? 'true' : 'false';
	}
  }
  

  public class AccountSIDSKU {
  	public String sidName {get;set;}
    public String skuType {get;set;}
    public String prodName {get;set;}
    public Decimal MRR {get;set;}
    
	public AccountSIDSKU(String sidName, String skuType, String prodName, Decimal mrr) {
		this.sidName = sidName;
		this.skuType = skuType;
		this.prodName = prodName;
		this.mrr = mrr;
	}
  }

 	public static AccountSID_to_SKU_Config__c config = AccountSID_to_SKU_Config__c.getInstance();

    // Meant for Opportunity After Insert trigger
    public List<AccountSIDSKU> getSKUs(Opportunity opp, String sidId) {

		Map<Id,Opportunity_Product__c> prodMap = new Map<Id,Opportunity_Product__c>([
			SELECT Id, Opportunity__c, Opportunity__r.New_Business_Account_SID_Lookup__c, Product_Name__c
			FROM Opportunity_Product__c
			WHERE Opportunity__c = :opp.Id
		]);

		Account_SID__c sid = getAccountSIDRecords(sidId);
		System.debug('EXISTING ACCOUNT SID RECORD');
        System.debug('  accountSID=' + sid);
        
		// Get related Account SID SKU records, if they exist
		// The map has the key as a combination of "Account_SID__c|Product_Name__c"
		// Query Account_SID_SKU__c records related to the given Account SID IDs.
		System.debug('CUSTOM SETTING CONTENTS FOR AccountSID_to_SKU_Mappings__c');
        Map<String, AccountSID_to_SKU_Mappings__c> settings = new Map<String, AccountSID_to_SKU_Mappings__c>();
        for (AccountSID_to_SKU_Mappings__c setting : AccountSID_to_SKU_Mappings__c.getAll().values()) {
        	if(setting.Year__c == 2018){
        	    settings.put(setting.Product_Name__c, setting);
        	}
        }
        Set<String> settingNames = settings.keySet();

		Map<String,Account_SID_SKU__c> skuMap = new Map<String,Account_SID_SKU__c>();
		if (sid != null) {
			for (Account_SID_SKU__c a : [
				SELECT Id, Account_SID__c, Account_SID__r.Account_SID__c, New_Business_Opportunity__c, Opportunity_Product__c, Opportunity_Product__r.Product_Name__c, Three_Months_MRR__c
				FROM Account_SID_SKU__c
				WHERE Account_SID__c = :sid.Id and Opportunity_Product__r.Product_Name__c IN :settingNames
			]) {
				skuMap.put(skuIndexKey(a.Account_SID__c, a.Opportunity_Product__r.Product_Name__c), a);
			}
		}
		System.debug('sidId = ' + sidId);
		System.debug('skuMap = ' + skuMap);
		
		System.debug('EXISTING ACCOUNT SID SKU RECORDS');
        for (String k : skuMap.keySet()) {
        	System.debug('  key=(' + k + ') accountSIDSKU=' + skuMap.get(k));
        }

		List<AccountSIDSKU> skuList = new List<AccountSIDSKU>();
		for (Opportunity_Product__c prod : prodMap.values()) {

			// Make sure there is a matching Product Name in the custom setting AccountSID_to_SKU_Mappings__c
			if (!settings.containsKey(prod.Product_Name__c)) {
				System.debug('No product name found in custom setting AccountSID_to_SKU_Mappings__c: ' + prod.Product_Name__c);
				continue;
			}

			String fieldName = settings.get(prod.Product_Name__c).Account_SID_API_Name__c;
			String skuKey = skuIndexKey(sid.Id, prod.Product_Name__c);
			Decimal mrr = (Decimal)sid.get(fieldName);
			System.debug('SKU Key Check: ' + skuKey);
			System.debug('SKU Key Map: ' + skuMap);

			if (skuMap.containsKey(skuKey)) {
				// Create new Exception SKU
				AccountSIDSKU sku = new AccountSIDSKU(sid.Account_SID__c, 'Exception', prod.Product_Name__c, mrr);
				System.debug('UPDATING EXISTING ACCOUNT SID SKU: ' + sku);
				skuList.add(sku);
			} else {
			    if (mrr >= config.MRR_Exception__c) {
					AccountSIDSKU sku = new AccountSIDSKU(sid.Account_SID__c, 'Exception', prod.Product_Name__c, mrr);
					System.debug('UPDATING EXISTING ACCOUNT SID SKU: ' + sku);
					skuList.add(sku);
				} else {
				    AccountSIDSKU sku = new AccountSIDSKU(sid.Account_SID__c, 'New Business', prod.Product_Name__c, mrr);
					System.debug('EXISTING ACCOUNT SID SKU DID NOT MEET UPDATE CRITERIA: ' + sku);
    				skuList.add(sku);
				}
			}
		}
		return skuList;
    }
    
    public static Map<String, String> getMRRBase(Id accId, Set<String> productNames){
        Map<String, String> resultMap = new Map<String, String>();
        
        Date limitDate = Date.today().addYears(-1);
        
        List<Opportunity> opps = [SELECT Id, (SELECT Product_Name__c FROM Opportunity_Products__r) FROM Opportunity WHERE AccountId = :accId AND CloseDate >=: limitDate AND StageName = 'Closed Won'];
        
        for(Opportunity opp: opps){
            if(opp.Opportunity_Products__r != null && !opp.Opportunity_Products__r.isEmpty()){
                for(Opportunity_Product__c product: opp.Opportunity_Products__r){
                    if(productNames.contains(product.Product_Name__c)){
                        resultMap.put(product.Product_Name__c, EXISTING_PRODUCT);
                    }
                }
            }
        }
        
        for(String productName: productNames){
            if(!resultMap.containsKey(productName)){
                resultMap.put(productName, NEW_PRODUCT);
            }
        }
        
        return resultMap;
    }
    
	// Query Account_SID__c records for the given IDs.  The field list from the
	// AccountSID_to_SKU_Mappings__c custom setting will be included in the SOQL
	// for the retrieved records.
    public static Account_SID__c getAccountSIDRecords(String sidId){
        // Build a set with all of the fields to query based on the values
        // in the custom setting AccountSID_to_SKU_Mappings__c
        Set<String> uniqueFields = new Set<String> {
			'Id',
			'Account_SID__c',
			'New_Business_Opportunity__c',
			'Software_MRR__c',
			'Total_MRR__c'
		};
        for(AccountSID_to_SKU_Mappings__c setting : AccountSID_to_SKU_Mappings__c.getAll().values()) {
            uniqueFields.add(setting.Account_SID_API_Name__c);
        }

		// Construct the SOQL query
        String fields = String.join(new List<String>(uniqueFields), ', ');
       	String queryString = 'SELECT ' + fields + ' FROM Account_SID__c WHERE Name = :sidId';
        System.debug(queryString);

		List<Account_SID__c> sids = (List<Account_SID__c>)Database.query(queryString);
		return sids.isEmpty() ? null : sids[0];
    }

	public String skuIndexKey(Id accountSID, String productName) {
		String key = accountSID + '-' + productName;
		System.debug('SKU Key: ' + key + ' (accountSID=' + accountSID + ', productName=' + productName + ')');
		return key;
	}
}