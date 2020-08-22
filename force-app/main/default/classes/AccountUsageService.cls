/******************************************
//Created By: Davis Dong
//Last Modified by: Gram Bischof {02/11/2019}
//Description: This class is aiming to roll up Amortized Usage to Account for current, previous, last 2 and last 3 months
//
*******************************************/
public with sharing class AccountUsageService {
    //Consts of Dates
    public static final Date TODAY = Date.today();
	public static final Integer THIS_YEAR = TODAY.year();
    public static final Integer LAST_YEAR = TODAY.addYears(-1).year();
    
/*    
    public static final Integer THIS_YEAR = TODAY.year();
    public static final Integer THIS_MONTH = TODAY.month();
    public static final Integer PREVIOUS_MONTH = TODAY.addMonths(-1).month();
    public static final Integer PREVIOUS_X2_MONTH = TODAY.addMonths(-2).month();
    public static final Integer PREVIOUS_X3_MONTH = TODAY.addMonths(-3).month();
    //Map valid year to months map, edge case like 2016/1, 2015/12 will be considered in this map 
    public static Map<Integer, Set<Integer>> VALID_YEAR_TO_MONTHS{
        get{
            if(VALID_YEAR_TO_MONTHS == null){
                VALID_YEAR_TO_MONTHS = getValidYearsMap(THIS_MONTH, THIS_YEAR, PREVIOUS_MONTH, PREVIOUS_X2_MONTH, PREVIOUS_X3_MONTH);
            }
            return VALID_YEAR_TO_MONTHS;
        }
    }
    
    @TestVisible
    private static Map<Integer, Set<Integer>> getValidYearsMap(Integer thisMonth, Integer thisYear, Integer previousMonth, Integer previousX2Month, Integer previousX3Month){
        Map<Integer, Set<Integer>> resultMap = new Map<Integer, Set<Integer>>();
        if(thisMonth < 4){
            if(thisMonth == 1){
                resultMap.put(thisYear, new Set<Integer>{thisMonth});
                resultMap.put(thisYear - 1, new Set<Integer>{previousMonth, previousX2Month, previousX3Month});
            }
            else if(thisMonth == 2){
                resultMap.put(thisYear, new Set<Integer>{thisMonth, previousMonth});
                resultMap.put(thisYear - 1, new Set<Integer>{previousX2Month, previousX3Month});
            }
            else if(thisMonth == 3){
                resultMap.put(thisYear, new Set<Integer>{thisMonth, previousMonth, previousX2Month});
                resultMap.put(thisYear - 1, new Set<Integer>{previousX3Month});
            }
        }
        else{
            resultMap.put(thisYear, new Set<Integer>{thisMonth, previousMonth, previousX2Month, previousX3Month});
        }
        return resultMap;
    }

    //Function to roll up Usage to Account
    public static void calculateUsage(List<Account> accounts){
        //There is a case Finance_Amortized_Billings__c = null and Total__c < 0, currently we treat Finance_Amortized_Billings__c = 0
        String queryString = 'SELECT AccountLookup__c, Year__c, Month__c, Finance_Amortized_Billings__c FROM Twilio_Usage__c WHERE AccountLookup__c =: accounts AND Finance_Amortized_Billings__c != 0 AND Finance_Amortized_Billings__c != null';
        Integer thisYear = AccountUsageService.THIS_YEAR;
        Set<Integer> thisYearMonths = AccountUsageService.VALID_YEAR_TO_MONTHS.get(thisYear);
        if(AccountUsageService.VALID_YEAR_TO_MONTHS.size() == 1){
            queryString += ' AND Year__c =: thisYear AND Month__c =: thisYearMonths';
        }
        else{
            Integer lastYear = thisYear - 1;
            Set<Integer> lastYearMonths = AccountUsageService.VALID_YEAR_TO_MONTHS.get(lastYear);
            queryString += ' AND ((Year__c =: thisYear AND Month__c =: thisYearMonths) OR (Year__c =: lastYear AND Month__c =:lastYearMonths))';
        }
        List<Twilio_Usage__c> usages = Database.query(queryString);
        for(Account acc: accounts){
            acc.Total_Amortized_Twilio_Usage_This_Month__c = 0;
            acc.Total_Amortized_Twilio_Usage_Last_Month__c  = 0;
            acc.Total_Amortized_Twilio_Usage_2_Month_Ago__c = 0;
            acc.Total_Amortized_Twilio_Usage_3_Month_Ago__c = 0;
            for(Twilio_Usage__c usage: usages){
                if(usage.AccountLookup__c == acc.Id){
                    if(usage.Month__c == THIS_MONTH) acc.Total_Amortized_Twilio_Usage_This_Month__c += usage.Finance_Amortized_Billings__c;
                    else if(usage.Month__c == PREVIOUS_MONTH) acc.Total_Amortized_Twilio_Usage_Last_Month__c += usage.Finance_Amortized_Billings__c;
                    else if(usage.Month__c == PREVIOUS_X2_MONTH) acc.Total_Amortized_Twilio_Usage_2_Month_Ago__c += usage.Finance_Amortized_Billings__c;
                    else if(usage.Month__c == PREVIOUS_X3_MONTH) acc.Total_Amortized_Twilio_Usage_3_Month_Ago__c += usage.Finance_Amortized_Billings__c;
                }
            }
        }
        
        update accounts;
    }
    
    public static void calculateUsage(List<Account_SID__c> accountSIDs){
        String queryString = 'SELECT Related_Account_SID__c, Year__c, Month__c, Finance_Amortized_Billings__c FROM Twilio_Usage__c WHERE Related_Account_SID__c =: accountSIDs AND Finance_Amortized_Billings__c != 0 AND Finance_Amortized_Billings__c != null';
        Integer thisYear = AccountUsageService.THIS_YEAR;
        Set<Integer> thisYearMonths = AccountUsageService.VALID_YEAR_TO_MONTHS.get(thisYear);
        if(AccountUsageService.VALID_YEAR_TO_MONTHS.size() == 1){
            queryString += ' AND Year__c =: thisYear AND Month__c =: thisYearMonths';
        }
        else{
            Integer lastYear = thisYear - 1;
            Set<Integer> lastYearMonths = AccountUsageService.VALID_YEAR_TO_MONTHS.get(lastYear);
            queryString += ' AND ((Year__c =: thisYear AND Month__c =: thisYearMonths) OR (Year__c =: lastYear AND Month__c =:lastYearMonths))';
        }
        List<Twilio_Usage__c> usages = Database.query(queryString);
        for(Account_SID__c accountSID: accountSIDs){
            accountSID.Total_Amortized_Twilio_Usage_This_Month__c = 0;
            accountSID.Total_Amortized_Twilio_Usage_Last_Month__c  = 0;
            accountSID.Total_Amortized_Twilio_Usage_2_Month_Ago__c = 0;
            accountSID.Total_Amortized_Twilio_Usage_3_Month_Ago__c = 0;
            for(Twilio_Usage__c usage: usages){
                if(usage.Related_Account_SID__c == accountSID.Id){
                    if(usage.Month__c == THIS_MONTH) accountSID.Total_Amortized_Twilio_Usage_This_Month__c += usage.Finance_Amortized_Billings__c;
                    else if(usage.Month__c == PREVIOUS_MONTH) accountSID.Total_Amortized_Twilio_Usage_Last_Month__c += usage.Finance_Amortized_Billings__c;
                    else if(usage.Month__c == PREVIOUS_X2_MONTH) accountSID.Total_Amortized_Twilio_Usage_2_Month_Ago__c += usage.Finance_Amortized_Billings__c;
                    else if(usage.Month__c == PREVIOUS_X3_MONTH) accountSID.Total_Amortized_Twilio_Usage_3_Month_Ago__c += usage.Finance_Amortized_Billings__c;
                }
            }
        }
        
        update accountSids;
    }
*/

	// rollupFields lists the fields in reverse chronological order for each
	// usage total amortized amount.
	//
	// Adding/remove items to/from the mapping adjusts how many months the roll-up
	// processor calculates.
	public static List<String> rollupFields = new List<String> {
		'Total_Amortized_Twilio_Usage_This_Month__c',
		'Total_Amortized_Twilio_Usage_Last_Month__c',
		'Total_Amortized_Twilio_Usage_2_Month_Ago__c',
		'Total_Amortized_Twilio_Usage_3_Month_Ago__c',          
		'Total_Amortized_Twilio_Usage_4_Month_Ago__c',
		'Total_Amortized_Twilio_Usage_5_Month_Ago__c',          
		'Total_Amortized_Twilio_Usage_6_Month_Ago__c',
		'Total_Amortized_Twilio_Usage_7_Month_Ago__c',
		'Total_Amortized_Twilio_Usage_8_Month_Ago__c',          
		'Total_Amortized_Twilio_Usage_9_Month_Ago__c',
		'Total_Amortized_Twilio_Usage_10Month_Ago__c',
		'Total_Amortized_Twilio_Usage_11Month_Ago__c',
		'Total_Amortized_Twilio_Usage_12Month_Ago__c',
		'Total_Amortized_Twilio_Usage_13Month_Ago__c',
        'Total_Amortized_Twilio_Usage_14Month_Ago__c'
	};
    
    //Integer function takes in an Integer month and returns an Integer quarter.
    private static Integer getQuarter(Integer i){
        if(i == 1 || i == 2 || i == 3){
            return 1;
        } else if (i == 4 || i == 5 || i == 6){
            return 2;
        } else if (i == 7 || i == 8 || i == 9){
            return 3;
        } else if (i == 10 || i == 11 || i == 12){
            return 4;
        } 
        return null;
    }
    
    public static Map<String, String> usageToAccountSIDFields {
        get{
           if(usageToAccountSIDFields == null){
              usageToAccountSIDFields = new Map<String, String>();
              for(Usage_To_AccountSID__c setting: Usage_To_AccountSID__c.getAll().values()){
                  usageToAccountSIDFields.put(setting.Usage_Field__c + '-' + setting.Months_Ago__c, setting.AccountSID_Field__c);
              }
           }
           return usageToAccountSIDFields;
        }
        set;
    }
	// The dateToFieldMap() method creates a map that is used to lookup the custom
	// field for the associated year-month combination.
	//
	// The key is in the format of "year-month" where the method fieldMapKey() are
	// used to generate a key in that format.
	//
	// The value is the API name for the corresponding field.
	public static String fieldMapKey(Integer y, Integer m) { return y+'-'+m; }
	public static String fieldMapKey(Date d) { return d.year()+'-'+d.month(); }

	public static Map<String,String> dateToFieldMap() {
		Integer howManyMonthsAgo = rollupFields.size();
		Map<String,String> mapping = new Map<String,String>();
		
		Integer j = howManyMonthsAgo;
		for (Integer i = -howManyMonthsAgo+1; i <= 0; i++) {
			j--;
			mapping.put(fieldMapKey(TODAY.addMonths(i)), rollupFields[j]);
			System.debug(fieldMapKey(TODAY.addMonths(i)) + ' = ' + rollupFields[j]);
		}
		
		System.debug(mapping);
		return mapping;
	}

	// The monthRanges() method creates a map where the key is a year and value is
	// a set of months for that year that are within the desired time range.
	// 
	// The time range is determined from the number items in the of rollupFields list.
    public static Map<Integer,List<Integer>> monthRanges() {
		Integer howManyMonthsAgo = rollupFields.size();
		Map<Integer,List<Integer>> months = new Map<Integer,List<Integer>>();
		
		for (Integer i = -howManyMonthsAgo+1; i <= 0; i++) {
			Integer y = TODAY.addMonths(i).year();
			Integer m = TODAY.addMonths(i).month();
		
			if (!months.containsKey(y)) months.put(y, new List<Integer>());
		
			months.get(y).add(m);
		}
		
		System.debug(months);
		return months;
    }

	// The whereClause() method uses the monthRanges() method to create a SOQL where
	// to query Twilio Usage records that match the years and months.
	// 8-1-18:  Jason added some logic to change the WHERE clause to just use years instead of year and specific months.
    public static String whereClause() {
		Map<Integer,List<Integer>> months = monthRanges();
		
		//List<String> criteria = new List<String>();
        List<String> criteria2 = new List<String>();
		for (Integer y : months.keySet()) {
            //criteria.add('(Year__c = '+ y+' AND Month__c IN ('+ String.join(months.get(y), ',') +'))');
            criteria2.add(String.valueOf(y));
		}
		
		//String whereClause = criteria.IsEmpty() ? '' : ' AND (' + String.join(criteria, ' OR ') + ')';
        String whereClause2 = criteria2.IsEmpty() ? '' : ' AND YEAR__c IN (' + String.join(criteria2, ',') + ')';
		//System.debug(whereClause);
        System.debug(whereClause2);
		//return whereClause;
		return whereClause2;
    }
    
    // Function to roll up Usage monthly amounts to Account
    public static void calculateUsage(List<Account> accounts) {
        //There is a case Finance_Amortized_Billings__c = null and Total__c < 0, currently we treat Finance_Amortized_Billings__c = 0
        String queryString = 'SELECT AccountLookup__c, Year__c, Month__c, Finance_Amortized_Billings__c FROM Twilio_Usage__c WHERE AccountLookup__c = :accounts AND Finance_Amortized_Billings__c != 0 AND Finance_Amortized_Billings__c != null';

        List<Twilio_Usage__c> usages = Database.query(queryString + whereClause());
     
        Map<String,String> fieldMap = dateToFieldMap();
        
        // Process the accounts to calculate their current total amortized amount history
        for(Account acc: accounts) {
            // Zero out the account amount fields
            for (String fieldName : fieldMap.values()) acc.put(fieldName, 0);
        }
        
        Map<Id,Account> accountsMap = new Map<Id,Account>(accounts);   
        
        // Sum the billing amounts for the acccount being processed      
        System.debug('DATA,Account.Id,Usage.Id,Usage.Year__c,Usage.Month__c,Usage.Finance_Amortized_Billings__c,FieldKey,FieldName,SummedAmount');
        
        for(Twilio_Usage__c usage: usages) {
            if(accountsMap.containskey(usage.AccountLookup__c)) {
                if(accountsMap.get(usage.AccountLookup__c).Q1_Revenue_This_Year__c == null) accountsMap.get(usage.AccountLookup__c).Q1_Revenue_This_Year__c = 0;
                if(accountsMap.get(usage.AccountLookup__c).Q2_Revenue_This_Year__c == null) accountsMap.get(usage.AccountLookup__c).Q2_Revenue_This_Year__c = 0;
                if(accountsMap.get(usage.AccountLookup__c).Q3_Revenue_This_Year__c == null) accountsMap.get(usage.AccountLookup__c).Q3_Revenue_This_Year__c = 0;
                if(accountsMap.get(usage.AccountLookup__c).Q4_Revenue_This_Year__c == null) accountsMap.get(usage.AccountLookup__c).Q4_Revenue_This_Year__c = 0;
                if(accountsMap.get(usage.AccountLookup__c).Q1_Revenue_Last_Year__c == null) accountsMap.get(usage.AccountLookup__c).Q1_Revenue_Last_Year__c = 0;
                if(accountsMap.get(usage.AccountLookup__c).Q2_Revenue_Last_Year__c == null) accountsMap.get(usage.AccountLookup__c).Q2_Revenue_Last_Year__c = 0;
                if(accountsMap.get(usage.AccountLookup__c).Q3_Revenue_Last_Year__c == null) accountsMap.get(usage.AccountLookup__c).Q3_Revenue_Last_Year__c = 0;
                if(accountsMap.get(usage.AccountLookup__c).Q4_Revenue_Last_Year__c == null) accountsMap.get(usage.AccountLookup__c).Q4_Revenue_Last_Year__c = 0;
                System.Debug('Usage(' + usage.Id + ') Found for Account(' + accountsMap.get(usage.AccountLookup__c).Id + '): year=' + usage.Year__c + ' month=' + usage.Month__c);
                String fieldKey = fieldMapKey(Integer.valueOf(usage.Year__c), Integer.valueOf(usage.Month__c));
                Integer usageQuarter = getQuarter(Integer.valueOf(usage.Month__c));
                System.debug('FieldKey: ' + fieldKey);
                if (fieldMap.containsKey(fieldKey)) {
                    String k = fieldMap.get(fieldKey);
                    Decimal amount = (Decimal)accountsMap.get(usage.AccountLookup__c).get(k) + usage.Finance_Amortized_Billings__c;
                    accountsMap.get(usage.AccountLookup__c).put(k, amount);
                    System.debug('Setting Account Field: ' + k + ' to ' + amount);
                    System.debug('DATA,' + accountsMap.get(usage.AccountLookup__c).Id + ','+ usage.Id + ',' + usage.Year__c + ',' + usage.Month__c + ',' + ',' + usage.Finance_Amortized_Billings__c + ',' + fieldKey + ',' + k + ',' + amount);
                }
                
                // Sum the billing amounts based on quarter and year
                if(Integer.valueOf(usage.Year__c) == THIS_YEAR){
                    if(usageQuarter == 1){
                        accountsMap.get(usage.AccountLookup__c).Q1_Revenue_This_Year__c += usage.Finance_Amortized_Billings__c;
                    } else if(usageQuarter == 2){
                        accountsMap.get(usage.AccountLookup__c).Q2_Revenue_This_Year__c += usage.Finance_Amortized_Billings__c;
                    } else if(usageQuarter == 3){
                        accountsMap.get(usage.AccountLookup__c).Q3_Revenue_This_Year__c += usage.Finance_Amortized_Billings__c;
                    } else if(usageQuarter == 4){
                        accountsMap.get(usage.AccountLookup__c).Q4_Revenue_This_Year__c += usage.Finance_Amortized_Billings__c;
                    }
                } else if (Integer.valueOf(usage.Year__c) == LAST_YEAR){
                    if(usageQuarter == 1){
                        accountsMap.get(usage.AccountLookup__c).Q1_Revenue_Last_Year__c += usage.Finance_Amortized_Billings__c;
                    } else if(usageQuarter == 2){
                        accountsMap.get(usage.AccountLookup__c).Q2_Revenue_Last_Year__c += usage.Finance_Amortized_Billings__c;
                    } else if(usageQuarter == 3){
                        accountsMap.get(usage.AccountLookup__c).Q3_Revenue_Last_Year__c += usage.Finance_Amortized_Billings__c;
                    } else if(usageQuarter == 4){
                        accountsMap.get(usage.AccountLookup__c).Q4_Revenue_Last_Year__c += usage.Finance_Amortized_Billings__c;
                    }
                }
            }
        }
        
        Database.update(accountsMap.values(), false);
    }


    // Function to roll up Usage monthly amounts to Account
    public static void calculateUsage(List<Account_SID__c> accountSIDs){
        //There is a case Finance_Amortized_Billings__c = null and Total__c < 0, currently we treat Finance_Amortized_Billings__c = 0
        String queryString = 'SELECT Related_Account_SID__c, Year__c, Month__c, Finance_Amortized_Billings__c, Usage_Date__c';
        Set<String> alreadyQueriedFields = new Set<String>();
        Map<String, String> theusageToAccountSIDFields = usageToAccountSIDFields;
        for(String fieldName: theusageToAccountSIDFields.keySet()){
            String usageFieldName = fieldName.split('-')[0];
            if(!alreadyQueriedFields.contains(usageFieldName)){
                queryString += ' ,' + usageFieldName;
                alreadyQueriedFields.add(usageFieldName);
            }
        }

        queryString += ' FROM Twilio_Usage__c WHERE Related_Account_SID__c = :accountSIDs AND Finance_Amortized_Billings__c != 0 AND Finance_Amortized_Billings__c != null';

        List<Twilio_Usage__c> usages = Database.query(queryString + whereClause());
        
        Map<String,String> fieldMap = dateToFieldMap();
        
        // Process the accounts to calculate their current total amortized amount history
        for(Account_SID__c sid: accountSIDs){
            
            // Zero out the account amount fields
            for (String fieldName : fieldMap.values()) sid.put(fieldName, 0);
            for (String fieldName : usageToAccountSIDFields.values()) sid.put(fieldName.split('-')[0], 0);
        }
        Map<Id,Account_SID__c> accountSIDsMap = new Map<Id,Account_SID__c>(accountSIDs);
        // Sum the billing amounts for the account being processed
        
        //System.debug('DATA,Account_SID__c.Id,Usage.Id,Usage.Year__c,Usage.Month__c,Usage.Finance_Amortized_Billings__c,FieldKey,FieldName,SummedAmount');
        
        //System.debug('Account SID id: ' + sid.Id);
        
        for(Twilio_Usage__c usage: usages) {
            if(accountSIDsMap.containskey(usage.Related_Account_SID__c)) {   
                System.Debug('Usage(' + usage.Id + ') Found for AccountSID(' + accountSIDsMap.get(usage.Related_Account_SID__c).Id + '): year=' + usage.Year__c + ' month=' + usage.Month__c);
                String fieldKey = fieldMapKey(Integer.valueOf(usage.Year__c), Integer.valueOf(usage.Month__c));
                System.debug('FieldKey: ' + fieldKey);
                if (fieldMap.containsKey(fieldKey)) {
                    String k = fieldMap.get(fieldKey);
                    Decimal amount = (Decimal)accountSIDsMap.get(usage.Related_Account_SID__c).get(k) + usage.Finance_Amortized_Billings__c;
                    accountSIDsMap.get(usage.Related_Account_SID__c).put(k, amount);
                    System.debug('Setting Account Field: ' + k + ' to ' + amount);
                    System.debug('DATA,' + accountSIDsMap.get(usage.Related_Account_SID__c).Id + ','+ usage.Id + ',' + usage.Year__c + ',' + usage.Month__c + ',' + ',' + usage.Finance_Amortized_Billings__c + ',' + fieldKey + ',' + k + ',' + amount);
                }
                
                Decimal monthDiff = usage.Usage_Date__c.monthsBetween(Date.today());
                system.debug('monthsDiff: ' + monthDiff);
                for(String fieldName: theusageToAccountSIDFields.keySet()){
                    Decimal monthAgo = Decimal.valueOf(fieldName.split('-')[1]);
                    system.debug('monthsAgo: ' + monthAgo);
                    if(monthAgo == monthDiff){
                        String usageFieldName = fieldName.split('-')[0];
                        String accountSidFieldName = theusageToAccountSIDFields.get(fieldName);
                        if(usage.get(usageFieldName) != null && accountSIDsMap.get(usage.Related_Account_SID__c).get(accountSidFieldName) != null){
                            Decimal amount = (Decimal) usage.get(usageFieldName) + (Decimal) accountSIDsMap.get(usage.Related_Account_SID__c).get(accountSidFieldName);
                            accountSIDsMap.get(usage.Related_Account_SID__c).put(accountSidFieldName, amount);
                        }
                    }
                }
            }
        }
        
        Database.update(accountSIDsMap.values(), false);
    }
}