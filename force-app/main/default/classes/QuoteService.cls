global class QuoteService {
	// If the copyQuoteFieldsToAgreement() is called from a trigger on the Quote object
	// under analysis "requeryQuote" can be set to "false" to skip performing
	// an unnecessary SOQL query.  However, if an error is received stating that
	// a field was not in the SOQL that was accessed leave the setting at its default, "true".
    public static Boolean requeryQuote = true;

    public static Map<String,Quote_to_Agreement_Mapping__c> fieldMapForQuote = Quote_to_Agreement_Mapping__c.getAll();
    public static Map<String,QuoteBI_to_SingleBIDiscounts_Mapping__c> fieldMapForBI = QuoteBI_to_SingleBIDiscounts_Mapping__c.getAll();
    public static Schema.RecordTypeInfo orderFormRecType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Order Form');    
    
    public static void upsertOpportunityProductsFromQuote(List<Quote_BI__c> quoteBIs, Id oppId, Boolean overrideAmount){
        
        List<Quote_BI__c> bis = [SELECT SFDC_Product__c, Flat_Price__c, Volume__c, Quote__r.Term_Range__c FROM Quote_BI__c WHERE Id =: quoteBIs];
        
        Opportunity opp = [SELECT Id, Contract_Terms_Months__c, Launch_Date__c, (SELECT Product_Name__c FROM Opportunity_Products__r) FROM Opportunity WHERE Id =: oppId LIMIT 1];
        
        Map<String, Decimal> productsToAmountMap = new Map<String, Decimal>();
        Decimal quoteMonths;
        
        for(Quote_BI__c bi: bis){
            quoteMonths = Decimal.valueOf(bi.Quote__r.Term_Range__c);
            if(bi.SFDC_Product__c != null && bi.Flat_Price__c != null){
                Decimal quantity = productsToAmountMap.get(bi.SFDC_Product__c);
                if(productsToAmountMap.containsKey(bi.SFDC_Product__c)){
                    quantity += bi.Flat_Price__c * bi.Volume__c * quoteMonths;
                }
                else{
                    quantity = bi.Flat_Price__c * bi.Volume__c * quoteMonths;
                }
                productsToAmountMap.put(bi.SFDC_Product__c, quantity);
            }
        }
        
        List<Opportunity_Product__c> products = new List<Opportunity_Product__c>();
        Map<String, Id> productToIdMap = new Map<String, Id>();
        
        for(Opportunity_Product__c product: opp.Opportunity_Products__r){
            productToIdMap.put(product.Product_Name__c, product.Id);
        }
        
        for(String productName: productsToAmountMap.keySet()){
            Opportunity_Product__c product = new Opportunity_Product__c(Opportunity__c = oppId, Id = productToIdMap.get(productName), Product_Name__c = productName);
            Decimal quantity = productsToAmountMap.get(productName);
            if(quantity != null){
                product.Quote_Amount__c = quantity;
                if(overrideAmount || product.Id == null) product.Amount__c = quantity;
            }
            if(product.Id == null){
                product.Name = productName;
                product.Launch_Date__c = opp.Launch_Date__c;
                product.Contract_Terms_Months__c = opp.Contract_Terms_Months__c;
            }
            products.add(product);
        }
        
        upsert products;
        if(!overrideAmount) return;
        Map<Id, Boolean> productOverrideMap = new Map<Id, Boolean>();
        
        for(Opportunity_Product__c product: products){
            productOverrideMap.put(product.Id, true);
        }
        
        List<Product_Schedule__c> productSchedules = new List<Product_Schedule__c>();
        products = [SELECT Amount__c, (SELECT Start_Date__c, Forecast_Amount__c, Forecast_Schedule__c FROM Product_Schedules__r) FROM Opportunity_Product__c WHERE Opportunity__c =:opp.Id];
        for(Opportunity_Product__c prod: products){
            if(prod.Product_Schedules__r == null || prod.Product_Schedules__r.isEmpty() || productOverrideMap.get(prod.Id) != null){
                Date startDate = opp.Launch_Date__c.toStartOfMonth();
                Integer sumUp = Integer.valueOf(prod.Amount__c / quoteMonths);
                Integer modNumber = Math.mod(Integer.valueOf(prod.Amount__c), Integer.valueOf(quoteMonths));
                for(Integer i = 0; i < quoteMonths; i++){
                    Integer addNumber = modNumber > 0 ? 1 : 0;
                    productSchedules.add(new Product_Schedule__c(Opportunity_Product__c = prod.Id, Forecast_Amount__c = sumUp + addNumber, Start_Date__c = startDate));
                    modNumber--;
                    startDate = startDate.addMonths(1);
                }
            }
            else{
                productSchedules.addAll(prod.Product_Schedules__r);
            }
        }
        String scheduleString = JSON.serialize(productSchedules);
        
        String productString = JSON.serialize(products);
        List<String> subProducts = new List<String>();
        for(Twilio_Sub_Product__c subProd: [SELECT Name FROM Twilio_Sub_Product__c WHERE Twilio_Product__c =: products]){
            subProducts.add(subProd.Name);
        }
        OppProductForecastExt.saveForecasts(scheduleString, productString, JSON.serialize(subProducts), opp.Id);
    }
    
    global static void createAgreementsFromQuotes(List<Quote> quoteList) {
    	System.debug('Creating Agreements for Quote List');

    	quoteList = getQuotes(quoteList);
    	System.debug('Quotes: ' + quoteList);
    	
    	// Create a map indexing the Quotes by their related Opportunity Id
		Map<Id,Quote> quoteIndex = new Map<Id,Quote>(quoteList);

		List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
		
		for (Quote q : quoteList) {
			Apttus__APTS_Agreement__c a = new Apttus__APTS_Agreement__c(
				RecordTypeId = orderFormRecType.getRecordTypeId(),
				Quote__c = q.id,
				Apttus__Account__c = q.AccountId,
	            Apttus__Related_Opportunity__c = q.OpportunityId,
	            Related_Opportunity_APTS__c = q.OpportunityId
			);
			copyQuoteFieldsToAgreement(q, a);
			agreementList.add(a);
		}

		insert agreementList;
		
		createSingleBIDiscounts(agreementList);
    }

    global static void copyQuoteFieldsToAgreement(List<Quote> quoteList) {
    	System.debug('Copying Quote List');

    	quoteList = getQuotes(quoteList);
    	System.debug('Quotes: ' + quoteList);
    	
    	// Create a map indexing the Quotes by their related Opportunity Id
		Map<Id,Quote> quoteIndex = new Map<Id,Quote>(quoteList);

		List<Apttus__APTS_Agreement__c> agreementList = getAgreementsByQuoteIds(quoteIndex.keySet());
    	System.debug('Agreements: ' + agreementList);

		for (Apttus__APTS_Agreement__c a : agreementList)
			copyQuoteFieldsToAgreement(quoteIndex.get(a.Quote__c), a);

		update agreementList;
    }

    global static void createSingleBIDiscounts(List<Apttus__APTS_Agreement__c> agreementList) {
    	System.debug('Creating Single BI Discounts');

		// Get a list of the related Quotes for the Agreements
    	Map<Id,Apttus__APTS_Agreement__c> agreementIndex = new Map<Id,Apttus__APTS_Agreement__c>();
    	for (Apttus__APTS_Agreement__c a : agreementList)
    		agreementIndex.put(a.Quote__c, a);
    	System.debug('Agreement Index: ' + agreementIndex);
    	
		List<Quote_BI__c> quoteBIList = getQuoteBIsByQuoteIds(agreementIndex.keySet());
    	System.debug('Quote BIs: ' + quoteBIList);
        /*Get Approval List for each BI:
          AUTO_APPROVAL - DO NOT NEED SET ANYTHING
          MANAGER_APPROVAL - Needs_Approval_Number__c = 1, Needs_Manager_Approval__c = true
          DD_APPROVAL - Needs_Approval_Number__c = 1, Needs_Manager_Approval__c = false
        */
        Map<Id, String> biApprovalMap = QuoteBIPickerCtrl.checkApproval(quoteBiList);
		List<Single_BI_Discount__c> singleBIDiscountList = new List<Single_BI_Discount__c>();
		for (Quote_BI__c q : quoteBIList) {
			Apttus__APTS_Agreement__c a = agreementIndex.get(q.Quote__c);
			Single_BI_Discount__c sbid = new Single_BI_Discount__c(
				Agreement__c = a.Id,
				Quote_BI__c = q.Id,
				//For now let us just do flat price
				Discount_Type__c = 'Flat'
			);
			String approvalString = biApprovalMap.get(q.Id);
			if(approvalString == QuoteBIPickerCtrl.NEED_DD_APPROVAL){
			    sbid.Needs_Approval_Number__c = 1;
			    sbid.Needs_Manager_Approval__c = false;
			}
			else if(approvalString == QuoteBIPickerCtrl.NEED_MANAGER_APPROVAL){
			    sbid.Needs_Approval_Number__c = 1;
			    sbid.Needs_Manager_Approval__c = true;
			}
			copyQuoteBIFieldsToSingleBIDiscount(q, sbid);
			singleBIDiscountList.add(sbid);
		}

		insert singleBIDiscountList;
    }

    // This methods copies the fields from the Quote record to the Apttus__APTS_Agreement__c record
    // as defined in the Quote_to_Agreement_Mapping__c custom setting.
    global static void copyQuoteFieldsToAgreement(Quote q, Apttus__APTS_Agreement__c a){
        System.debug('Copying: Quote(' + q.Id + ') > Apttus__APTS_Agreement__c(' + a.Id + ')');
        for(Quote_to_Agreement_Mapping__c mapping : fieldMapForQuote.values()) {
            String quoteFieldName = mapping.Quote_API_Field_Name__c;
            String agreementFieldName = mapping.Agreement_API_Field_Name__c;
            a.put(agreementFieldName, q.get(quoteFieldName));
            System.debug('Copying: Quote.' + quoteFieldName + ' > Apttus__APTS_Agreement__c.' + agreementFieldName + ' VALUE=' + q.get(quoteFieldName) );
        }
    }

    // This methods copies the fields from the Quote_BI__c record to the Single_BI_Discount__c record
    // as defined in the QuoteBI_to_SingleBIDiscounts_Mapping__c custom setting.
    global static void copyQuoteBIFieldsToSingleBIDiscount(Quote_BI__c qbi, Single_BI_Discount__c sbid){
        System.debug('Copying: Quote_BI__c(' + qbi.Id + ') > Single_BI_Discount__c(' + sbid.Id + ')');
        for(QuoteBI_to_SingleBIDiscounts_Mapping__c mapping : fieldMapForBI.values()) {
            String qbiFieldName = mapping.QuoteBI_API_Field_Name__c;
            String sbidFieldName = mapping.SingleBIDiscount_API_Field_Name__c;
            sbid.put(sbidFieldName, qbi.get(qbiFieldName));
            System.debug('Copying: Quote_BI__c.' + qbiFieldName + ' > Single_BI_Discount__c.' + sbidFieldName + ' VALUE=' + qbi.get(qbiFieldName) );
        }
    }

	// These methods query the corresponding object so that the fields in the Quote_to_Agreement_Mapping__c
	// custom setting are returned.
    private static List<Quote> getQuotes(List<Quote> quoteList){
		// Get requery Quotes if requeryQuotes = true
    	if (requeryQuote) {
    		System.debug('QuoteService.requeryQuote set to false: returning requeried quoteList');
 
    		// Get the list of Quote Ids to requery
    		Set<Id> ids = new Set<Id>();
    		for (Quote q : quoteList)
    			ids.add(q.Id);
    			
			// Create the SOQL and execute the query
	        String queryString = 'SELECT ' + getQuoteFieldString('AccountId, OpportunityId') + ' FROM Quote WHERE Id IN :ids';
	        System.debug(queryString);
    		quoteList = (List<Quote>)Database.query(queryString);
    	} else {
    		System.debug('QuoteService.requeryQuote set to false: returning quoteList that was given');
    	}  	

    	return quoteList;
    }
	
	private static List<Apttus__APTS_Agreement__c> getAgreementsByQuoteIds(Set<Id> quoteIds){
		// Create the SOQL and execute the query
        String queryString = 'SELECT ' + getAgreementFieldString('Quote__c') + ' FROM Apttus__APTS_Agreement__c WHERE Quote__c IN :quoteIds';
        System.debug(queryString);
		List<Apttus__APTS_Agreement__c> agreementList = (List<Apttus__APTS_Agreement__c>)Database.query(queryString);

		return agreementList;
	}

	private static List<Quote_BI__c> getQuoteBIsByQuoteIds(Set<Id> quoteIds){
		// Create the SOQL and execute the query
        String queryString = 'SELECT ' + getQuoteBIFieldString('Quote__c') + ' FROM Quote_BI__c WHERE Quote__c IN :quoteIds';
        System.debug(queryString);
		List<Quote_BI__c> quoteBIList = (List<Quote_BI__c>)Database.query(queryString);

		return quoteBIList;
	}

	// These methods generate the comma-separate field names used in SOQL.
    // The field list is generated from the Quote_to_Agreement_Mapping__c custom setting.
    // Additional fields can be supplied that will be included in the field list string, but if 
    // there are no additional fields specify an empty/blank string, e.g. ''
    private static String getQuoteFieldString(String additionalFields){
        // Make sure no field entered two times.
        Set<String> uniqueFields = new Set<String>();
        if (!String.isBlank(additionalFields))
            uniqueFields.add(additionalFields);

		// Add the list of fields in the custom setting Quote_API_Field_Name__c
        for(Quote_to_Agreement_Mapping__c mapping : fieldMapForQuote.values())
            uniqueFields.add(mapping.Quote_API_Field_Name__c);
        
        return String.join(new List<String>(uniqueFields), ', ');
    }

    private static String getAgreementFieldString(String additionalFields){
        // Make sure no field entered two times.
        Set<String> uniqueFields = new Set<String>();
        if (!String.isBlank(additionalFields))
            uniqueFields.add(additionalFields);

		// Add the list of fields in the custom setting Quote_API_Field_Name__c
        for(Quote_to_Agreement_Mapping__c mapping : fieldMapForQuote.values())
            uniqueFields.add(mapping.Agreement_API_Field_Name__c);            
        
        return String.join(new List<String>(uniqueFields), ', ');
    }

    private static String getQuoteBIFieldString(String additionalFields){
        // Make sure no field entered two times.
        Set<String> uniqueFields = new Set<String>();
        if (!String.isBlank(additionalFields))
            uniqueFields.add(additionalFields);

		// Add the list of fields in the custom setting Quote_API_Field_Name__c
        for(QuoteBI_to_SingleBIDiscounts_Mapping__c mapping : fieldMapForBI.values())
            uniqueFields.add(mapping.QuoteBI_API_Field_Name__c);            
        
        return String.join(new List<String>(uniqueFields), ', ');
    }
}