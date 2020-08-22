//----------------------------------------------------------------------------------------------------------
// Utility class OpportunitySKUHandler
//
//  Entry Criteria:
//    This trigger would fire when an Opportunity's New Business AccountSID gets filled in AND this
//    Opportunity has Forecast Schedules. (Choose AccountSID would be completed by the inline VF page
//    you have implemented before on the Opportunity Detail page).
//
//  Expected Process:
//    When the opportunity is processed in Trigger, we want to grab all Opportunity_Product__c under
//    Opportunity, and create a Junction Object Account_SID_SKU__c between Account SID and Opportunity
//    Products. i.e. This Opportunity has two Products: Programmable Messaging and Support, we suppose
//    we could create two Junction Objects in this process.
//
//    Grab existing field on AccountSID to snapshot on the Junction object. So let us assume we have a
//    custom setting and the data would look like: Product Name: Programmable Messaging; Account SID
//    Field: Programmable_Messaging_MRR__c. In this case,  the MRR__c field on Account_SID_SKU__c for
//    the Programmable Messaging one would grab AccountSID.Programmable_Messaging_MRR__c field.
//
//    Check Duplicate and mark as Exceptional. If we found there is an existing Account_SID_SKU__c with
//    the Same AccountSID and Product already existing in the system (You could design this part in the
//    config like add some Unique String field) AND MRR__c >= 50, we would mark the newly created
//    Account_SID_SKU__c as exceptional (Populate Exceptional Account SID lookup and
//    Exception_Opp_Created_Date__c)
//----------------------------------------------------------------------------------------------------------
public without sharing class OpportunitySKUHandler {
	public static AccountSID_to_SKU_Config__c config = AccountSID_to_SKU_Config__c.getInstance();
	public static Boolean bypassTrigger = false;

    // Meant for Opportunity After Insert trigger
    public static void createSKUs(Map<Id,Opportunity> opptyMap) {
        if(bypassTrigger) return;
        Map<Id,Opportunity> filteredOpps = new Map<Id,Opportunity>();
        for (Opportunity o : opptyMap.values()) {
            if (String.isNotBlank(o.New_Business_Account_SID_Lookup__c))
                filteredOpps.put(o.Id, o);
        }
        
        processOpps(getOppsWithForecastSchedules(filteredOpps));
        //bypassTrigger = true;
    }

    public static void createSKUs(List<Opp_SID_SKU__c> skus){
        if(bypassTrigger) return;
        
        Set<Id> oppIds = new Set<Id>();
        Map<Id, List<Opp_SID_SKU__c>> skuMap = new Map<Id, List<Opp_SID_SKU__c>>();
        
        for(Opp_SID_SKU__c sku: skus){
            oppIds.add(sku.Opportunity__c);
            
            List<Opp_SID_SKU__c> oppSkus = skuMap.get(sku.Opportunity__c);
            if(oppSkus == null) oppSkus = new List<Opp_SID_SKU__c>();
            
            oppSkus.add(sku);
            skuMap.put(sku.Opportunity__c, oppSkus);
        }
        
        
        for(Opportunity opp: [
        	SELECT Id, New_Business_Account_SID_Lookup__c
        	FROM Opportunity
        	WHERE Id IN :oppIds
        	//AND New_Business_Account_SID_Lookup__c != null
        ]){
             Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>();
             
            opptyMap.put(opp.Id, opp);
            processOpps(opptyMap);
        }
    }
    // Meant for Opportunity Product After Insert trigger
    public static void createSKUs(Map<Id,Opportunity_Product__c> opMap) {
        //if(bypassTrigger) return;
        
        
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity_Product__c o : opMap.values()) {
        	oppIds.add(o.Opportunity__c);
        }
        
        Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>([
        	SELECT Id, New_Business_Account_SID_Lookup__c
        	FROM Opportunity
        	WHERE Id IN :oppIds
        	AND New_Business_Account_SID_Lookup__c != null
        ]);

        //system.assert(false, getOppsWithForecastSchedules(opptyMap));

        processOpps(getOppsWithForecastSchedules(opptyMap), opMap);
        //bypassTrigger = true;
    }


    // Return only Opportunities that have related Forecast Schedule records
    public static Map<Id,Opportunity> getOppsWithForecastSchedules(Map<Id,Opportunity> opptyMap) {
		Map<Id,Opportunity> recordMap = new Map<Id,Opportunity>();
		for (AggregateResult r : [
			SELECT Opportunity__c OppId, COUNT(Id) OppCount
			FROM Forecast_Schedule__c
			WHERE Opportunity__c IN :opptyMap.keySet()
			GROUP BY Opportunity__c
			HAVING COUNT(Id) > 0
		]) {
			System.debug(r.get('OppId') + ' : ' + r.get('OppCount'));
			recordMap.put(r.Id, opptyMap.get(r.Id));		
		}
		return opptyMap;
    }


	/*public static void updateAccountSIDonSKU(Map<Id,Opportunity> oppsWithChangedAccountSID) {
		// If no entry in the Opportunity map then nothing to do
		if (oppsWithChangedAccountSID.isEmpty()) return;

		List<Account_SID_SKU__c> skuList = new List<Account_SID_SKU__c>();
		Set<Id> oppIds = oppsWithChangedAccountSID.keySet();

		for (Account_SID_SKU__c sku : [
			SELECT Id, Account_SID__c, New_Business_Opportunity__c
			FROM Account_SID_SKU__c
			WHERE New_Business_Opportunity__c IN :oppIds
				//OR Exception_Opportunity__c IN :oppIds
		]) {
			System.debug('PROCESSING Account_SID_SKU__c: ' + sku);
			if (oppsWithChangedAccountSID.containsKey(sku.New_Business_Opportunity__c)) {
				sku.Account_SID__c = oppsWithChangedAccountSID.get(sku.New_Business_Opportunity__c).New_Business_Account_SID_Lookup__c;
				skuList.add(sku);
				System.debug('UPDATING New_Business_Opportunity__c ON SKU: ' + sku);
			}
			/*if (oppsWithChangedAccountSID.containsKey(sku.Exception_Opportunity__c)) {
				sku.Exception_Account_SID__c = oppsWithChangedAccountSID.get(sku.Exception_Opportunity__c).New_Business_Account_SID_Lookup__c;
				skuList.add(sku);
				System.debug('UPDATING Exception_Account_SID__c ON SKU: ' + sku);
			}*/
	//	}
		
	//	update skuList;
	//}

	public static void processOpps(Map<Id,Opportunity> oppMap) {
		// Get all related Opportunity Products records
		Map<Id,Opportunity_Product__c> prodMap = getOpportunityProductRecords(oppMap.keySet());
		System.debug('EXISTING OPPORTUNITY PRODUCT RECORDS');
        for (String k : prodMap.keySet()) {
        	System.debug('  key=(' + k + ') opportunityProduct=' + prodMap.get(k));
        }

		processOpps(oppMap, prodMap);
	}

	// Process Opportunities having only the given specific related Opportunity_Product__c records
	public static void processOpps(Map<Id,Opportunity> oppMap, Map<Id,Opportunity_Product__c> prodMap) {
		// If no entry in the Opportunity map then nothing to do
        
		if (oppMap.isEmpty()) return;
		
		// Get related Account SID records
		Map<Id,Account_SID__c> sidMap = getNewBusinessAccountSIDRecords(oppMap.values());
		System.debug('EXISTING ACCOUNT SID RECORDS');
        for (String k : sidMap.keySet()) {
        	System.debug('  key=(' + k + ') accountSID=' + sidMap.get(k));
        }

		// Get related Account SID SKU records, if they exist
		// The map has the key as a combination of "Account_SID__c|Product_Name__c"
	    Map<String,Account_SID_SKU__c> skuMap = getAccountSIDSKURecords(sidMap.keySet());
		System.debug('EXISTING ACCOUNT SID SKU RECORDS');
        for (String k : skuMap.keySet()) {
        	System.debug('  key=(' + k + ') accountSIDSKU=' + skuMap.get(k));
        }
        
		// Look for matches between Opportunity_Product__r.Product_Name__c and Account_SID_SKU__r.
		Map<String, AccountSID_to_SKU_Mappings__c> settings = new Map<String, AccountSID_to_SKU_Mappings__c>();//AccountSID_to_SKU_Mappings__c.getAll();
		System.debug('CUSTOM SETTING CONTENTS FOR AccountSID_to_SKU_Mappings__c');
        for (AccountSID_to_SKU_Mappings__c setting : AccountSID_to_SKU_Mappings__c.getAll().values()) {
        	//System.debug('  productName=(' + k + ') accountSIDField=(' + settings.get(k).Account_SID_API_Name__c + ')');
        	if(setting.Year__c == 2018) settings.put(setting.Product_Name__c, setting);
        }
		
		List<Account_SID_SKU__c> skuList = new List<Account_SID_SKU__c>();
		for (Opportunity_Product__c prod : prodMap.values()) {

			// Make sure there was an Opportunity identified, if not skip it
			if (!oppMap.containsKey(prod.Opportunity__c)) {
				System.debug('Opportunity Product not related to Opportunity being updated');
				continue;
			}

			// Make sure there is a matching Product Name in the custom setting AccountSID_to_SKU_Mappings__c
			if (!settings.containsKey(prod.Product_Name__c)) {
				System.debug('No product name found in custom setting AccountSID_to_SKU_Mappings__c: ' + prod.Product_Name__c);
				continue;
			}

			// Get related records
			Opportunity opp = oppMap.get(prod.Opportunity__c);
			
			for(Id sidId: sidMap.keySet()){
			    Account_SID__c sid = sidMap.get(sidId);
			
    			String fieldName = settings.get(prod.Product_Name__c).Account_SID_API_Name__c;
    			String skuKey = skuIndexKey(sid.Id, opp.Id, prod.Product_Name__c);
    			Decimal mrr = (Decimal)sid.get(fieldName);
                Account_SID_SKU__c accSku = skuMap.get(skuKey);
    			if (!skuMap.containsKey(skuKey)) {
    				// Create new Exception SKU
    				Account_SID_SKU__c sku = new Account_SID_SKU__c(
    					Account_SID__c = sid.Id,                          // Had to add because Account_SID__c is a required field
    					//Exception_Account_SID__c = sid.Id,
    					New_Business_Opportunity__c = opp.Id,
    					Opportunity_Product__c = prod.Id,
    					MRR__c = mrr
    					//Type__c = 'Exception'
    				);
    				skuList.add(sku);
    				skuMap.put(skuKey, sku);
    				System.debug('UPDATING EXISTING ACCOUNT SID SKU: ' + sku);
    			}
			}
		}
        
        //system.assert(false, skuList);
		insert skuList;
		bypassTrigger = true;
	}

	// Query Opportunity_Product__c records related to the given Opportunity IDs.
    public static Map<Id,Opportunity_Product__c> getOpportunityProductRecords(Set<Id> oppIds){
		Map<Id,Opportunity_Product__c> prodMap = new Map<Id,Opportunity_Product__c>([
			SELECT Id, Opportunity__c, Opportunity__r.New_Business_Account_SID_Lookup__c, Product_Name__c
			FROM Opportunity_Product__c
			WHERE Opportunity__c IN :oppIds
		]);
		return prodMap;
    }

	// Query Account_SID__c records related to the given Opportunity IDs.  The field list from the
	// AccountSID_to_SKU_Mappings__c custom setting will be included in the SOQL for the retrieved records.
    public static Map<Id,Account_SID__c> getNewBusinessAccountSIDRecords(List<Opportunity> oppList){
        //Map<String, AccountSID_to_SKU_Mappings__c> settings = AccountSID_to_SKU_Mappings__c.getAll();
        Map<String, AccountSID_to_SKU_Mappings__c> settings = new Map<String, AccountSID_to_SKU_Mappings__c>();//AccountSID_to_SKU_Mappings__c.getAll();
		System.debug('CUSTOM SETTING CONTENTS FOR AccountSID_to_SKU_Mappings__c');
        for (AccountSID_to_SKU_Mappings__c setting : AccountSID_to_SKU_Mappings__c.getAll().values()) {
        	//System.debug('  productName=(' + k + ') accountSIDField=(' + settings.get(k).Account_SID_API_Name__c + ')');
        	if(setting.Year__c == 2018){
        	    settings.put(setting.Product_Name__c, setting);
        	}
        }
        // Make sure no field entered two times.
        Set<String> uniqueFields = new Set<String> {
			'Id',
			'New_Business_Opportunity__c'
			//'Exception_Opportunity__c'
		};
        for(String key : settings.keySet()) {
            uniqueFields.add(settings.get(key).Account_SID_API_Name__c);
        }
        String fields = String.join(new List<String>(uniqueFields), ', ');
        
        // Get the list of New Business Account SIDs from the Opportunity Map
        Set<Id> sidIds = new Set<Id>();
        
        
        
        for (Opp_SID_SKU__c o : [SELECT Account_SID__c FROM Opp_SID_SKU__c WHERE Opportunity__c =: oppList]) {
        	sidIds.add(o.Account_SID__c);
        }
        
        
       	String queryString = 'SELECT ' + fields + ' FROM Account_SID__c WHERE Id IN :sidIds';
        System.debug(queryString);

		Map<Id,Account_SID__c> sidMap = new Map<Id,Account_SID__c>();
        sidMap.putAll((List<Account_SID__c>)Database.query(queryString));
        //system.assert(false, sidMap);
        return sidMap;
    }

	// Query Account_SID_SKU__c records related to the given Account SID IDs.
    public static Map<String,Account_SID_SKU__c> getAccountSIDSKURecords(Set<Id> sidIds){
        //Map<String, AccountSID_to_SKU_Mappings__c> settings = AccountSID_to_SKU_Mappings__c.getAll();
        Map<String, AccountSID_to_SKU_Mappings__c> settings = new Map<String, AccountSID_to_SKU_Mappings__c>();//AccountSID_to_SKU_Mappings__c.getAll();
		System.debug('CUSTOM SETTING CONTENTS FOR AccountSID_to_SKU_Mappings__c');
        for (AccountSID_to_SKU_Mappings__c setting : AccountSID_to_SKU_Mappings__c.getAll().values()) {
        	//System.debug('  productName=(' + k + ') accountSIDField=(' + settings.get(k).Account_SID_API_Name__c + ')');
        	if(setting.Year__c == 2018) settings.put(setting.Product_Name__c, setting);
        }
        Set<String> settingNames = settings.keySet();

		Map<String,Account_SID_SKU__c> skuMap = new Map<String,Account_SID_SKU__c>();
		for (Account_SID_SKU__c a : [
			SELECT Id, Account_SID__c, Account_SID_Added_Date__c, New_Business_Opportunity__c, Opportunity_Product__c, Opportunity_Product__r.Product_Name__c, MRR__c
			FROM Account_SID_SKU__c
			WHERE Account_SID__c IN :sidIds and Opportunity_Product__r.Product_Name__c IN :settingNames
		]) {
			skuMap.put(skuIndexKey(a.Account_SID__c, a.New_Business_Opportunity__c, a.Opportunity_Product__r.Product_Name__c), a);
		}
		return skuMap;
    }

	public static String skuIndexKey(Id accountSID, Id oppId, String productName) {
		String key = accountSID + '-' + oppId + '-' + productName;
		System.debug('SKU Key: ' + key + ' (accountSID=' + accountSID + ', productName=' + productName + ')');
		return key;
	}
}