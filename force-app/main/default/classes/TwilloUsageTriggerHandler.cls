public without sharing class TwilloUsageTriggerHandler {
	
	//--------------------------------------------------------------------------------------------------------------------
	// Update Forcast lookup fields on usage records
		/*   
		//Populate forecast category
		1. Twilio_usage__c. Current_Month_Forecast__c
		Where twilio_usage_c.usage_date__c = twilio_forecast__c. Usage_Date__c AND
		Twilio_Usage__c. AccountLookup__c.id =
		Twilio_forecast__c.Account__c.id
		
		2. Twilio_usage__c. Last_Month_Forecast__c
		Where twilio_usage_c.usage_date__c = twilio_forecast__c. Usage_Date__c - 1
		Map to the LAST MONTH’S Forecast for that account (Prior to the month of usage)
		 
		3. Twilio_usage__c. X2_Month_Ago_Forecast__c
		Where twilio_usage_c.usage_date__c = twilio_forecast__c. Usage_Date__c - 2
		Map to the 2 MONTH’S Ago Forecast for that account (Prior to the month of usage)
		 
		AND 
		Twilio_Usage__c. AccountLookup__c.id =
		Twilio_forecast__c.Account__c.id
		
		Twilio_usage__c. Twilio_Forecast_3__c
		Map to the Forecast for NEXT MONTH’S (following the month of the usage)
		 
		Where twilio_usage_c.usage_date__c = twilio_forecast__c. Usage_Date__c +1
		AND	Twilio_Usage__c. AccountLookup__c.id = Twilio_forecast__c.Account__c.id   */
	//--------------------------------------------------------------------------------------------------------------------
	public static void updateForcastFields(List<Twilio_Usage__c> lstTwilloUsage, Map<Id, Twilio_Usage__c> oldMap, Boolean forceUpdate) {
		List<Twilio_Usage__c> lstTwilioUsgToUpdt = new List<Twilio_Usage__c> ();
		
		for (Twilio_Usage__c twUsg : lstTwilloUsage) {
			if (forceUpdate || Utility.isNewOrChanged(twUsg, 'Month__c', oldMap) 
				|| Utility.isNewOrChanged(twUsg, 'Year__c', oldMap)
				|| Utility.isNewOrChanged(twUsg, 'Total__c', oldMap)
				|| Utility.isNewOrChanged(twUsg, 'AccountLookup__c', oldMap)) {
				lstTwilioUsgToUpdt.add(twUsg);
			}
		}
		System.debug('=========> # of Usage for update for Forecasts(' + lstTwilioUsgToUpdt.size() + ')');
		updateForeCast(lstTwilioUsgToUpdt);
	}
	
	//--------------------------------------------------------------------------------------------------------------------
	// updates forecast
	//--------------------------------------------------------------------------------------------------------------------
	public static void updateForeCast(List<Twilio_Usage__c> lstTwilioUsgToUpdt) {
		if (lstTwilioUsgToUpdt.size() > 0) {
			Map<String, Twilio_Forecast__c> mapForcast = getTwilioForecast(lstTwilioUsgToUpdt);
 				
			for (Twilio_Usage__c tu : lstTwilioUsgToUpdt) {
				tu.Current_Month_Forecast__c = null;
				tu.Last_Month_Forecast__c = null;
				tu.X2_Month_Ago_Forecast__c = null;
				tu.Twilio_Forecast_3__c = null;
				tu.X2_Month_Ahead_Forecast__c = null;
				
				String currMonth = getKey(tu.AccountLookup__c, tu.Usage_Date__c);
				System.debug('=========> CURRENT MONTH FORECAST KEY(' + currMonth + ')');
				if (mapForcast.containsKey(currMonth)) {
					System.debug('=========> SETTING CURRENT MONTH FORECAST(' + mapForcast.get(currMonth).Id + ')');
					tu.Current_Month_Forecast__c = mapForcast.get(currMonth).Id;
				}
				
				if (tu.Usage_Date__c != null) {
					String twoMonthAgo = getKey(tu.AccountLookup__c, tu.Usage_Date__c.addMonths(-2));
					System.debug('=========> 2 MONTH AGO FORECAST KEY(' + twoMonthAgo + ')');
					if (mapForcast.containsKey(twoMonthAgo)) {
						System.debug('=========> SETTING 2 MONTH AGO FORECAST(' + mapForcast.get(twoMonthAgo).Id + ')');
						tu.X2_Month_Ago_Forecast__c = mapForcast.get(twoMonthAgo).Id;
					} 
	
					String lastMonth = getKey(tu.AccountLookup__c, tu.Usage_Date__c.addMonths(-1));
					System.debug('=========> LAST MONTH FORECAST KEY(' + lastMonth + ')');
					if (mapForcast.containsKey(lastMonth)) {
						System.debug('=========> SETTING LAST MONTH FORECAST(' + mapForcast.get(lastMonth).Id + ')');
						tu.Last_Month_Forecast__c = mapForcast.get(lastMonth).Id;
					} 
	
					String nextMonth = getKey(tu.AccountLookup__c, tu.Usage_Date__c.addMonths(1));
					System.debug('=========> NEXT MONTH FORECAST KEY(' + nextMonth + ')');
					if (mapForcast.containsKey(nextMonth)) {
						System.debug('=========> SETTING NEXT MONTH FORECAST(' + mapForcast.get(nextMonth).Id + ')');
						tu.Twilio_Forecast_3__c = mapForcast.get(nextMonth).Id;
					}

					String twoMonthAhead = getKey(tu.AccountLookup__c, tu.Usage_Date__c.addMonths(2));
					System.debug('=========> 2 MONTH AHEAD FORECAST KEY(' + twoMonthAhead + ')');
					if (mapForcast.containsKey(twoMonthAhead)) {
						System.debug('=========> SETTING 2 MONTH AHEAD FORECAST(' + mapForcast.get(twoMonthAhead).Id + ')');
						tu.X2_Month_Ahead_Forecast__c = mapForcast.get(twoMonthAhead).Id;
					}
				}
			}
		}
	}
	
	//--------------------------------------------------------------------------------------------------------------------
	// Returns a Map<Account + Month + Year, Forecast>
	//--------------------------------------------------------------------------------------------------------------------
//	private static Map<String, Twilio_Forecast__c> getTwilioForecast(Set<Id> accIds, Set<String> years) {
	private static Map<String, Twilio_Forecast__c> getTwilioForecast(List<Twilio_Usage__c> usages) {
		Set<Id> accIds = new Set<Id>();
		Set<String> years = new Set<String>();
		for (Twilio_Usage__c twUsg : usages) {
			accIds.add(twUsg.AccountLookup__c);

			// Get the year for 2 months ago, last, current, and next month
			if (twUsg.Usage_Date__c != null) {
				years.add(String.valueOf(twUsg.Usage_Date__c.addMonths(-2).year()));
				years.add(String.valueOf(twUsg.Usage_Date__c.addMonths(-1).year()));
				years.add(String.valueOf(twUsg.Usage_Date__c.year()));
				years.add(String.valueOf(twUsg.Usage_Date__c.addMonths(1).year()));
				years.add(String.valueOf(twUsg.Usage_Date__c.addMonths(2).year()));
			}
		}
		
		Map<String, Twilio_Forecast__c> mapForecast = new Map<String, Twilio_Forecast__c>();

		for (Twilio_Forecast__c tf : [Select Id, Account__c, Fiscal_Year__c, Fiscal_Month__c 
																	From Twilio_Forecast__c 
																	Where Account__c in :accIds 
																	and Fiscal_Year__c in :years
																	Order by CreatedDate desc]) {
			String key = getKey(tf);
			if (!mapForecast.containsKey(key)) {
				System.debug('=========> GET FORECAST(' + key + ')');
				mapForecast.put(key, tf);
			}
		}
		return mapForecast;
	}

	private static Map<String, Integer> mapMonthStringAndNum = new Map<String, Integer> {
		'January'   => 1, 'February' => 2,  'March'    => 3,  'April'    => 4,
		'May'       => 5, 'June'     => 6,  'July'     => 7,  'August'   => 8,
		'September' => 9, 'October'  => 10, 'November' => 11, 'December' => 12
	};
		
	private static String getKey(Twilio_Forecast__c forecast) {
		return forecast.Account__c + '~' + mapMonthStringAndNum.get(forecast.Fiscal_Month__c) + '~' + forecast.Fiscal_Year__c;
	}

	private static String getKey(String id, Date dt) {
		return id + '~' + dt.month() + '~' + dt.year();
	}

	public static void updateNPC(List<Twilio_Usage__c> usages) {
		if (usages.size() > 0) {
			Set<Id> leadIds = new Set<Id>();
			Set<Id> contactIds = new Set<Id>();
			for (Twilio_Usage__c u : usages) {
				if (u.NPC_Date_Sales__c != null) {
					if (u.Contact__c != null) {
						contactIds.add(u.Contact__c);
					} else if (u.Lead__c != null) {
						leadIds.add(u.Lead__c);
					}
				}
			}
			
			Map<Id,Lead> leads = new Map<Id,Lead>([
				SELECT Id, Owner.Name, NPC_Date__c, NPC_Owner__c,
					Contacted_Time__c, Qualified_Time__c, Non_Eligible_SQL__c
				FROM Lead
				WHERE Id IN :leadIds
				AND NPC_Date__c = null
			]);
			Map<Id,Contact> contacts = new Map<Id,Contact>([
				SELECT Id, Owner.Name, NPC_Date__c, NPC_Owner__c, CreatedDate
				FROM Contact
				WHERE Id IN :contactIds
				AND NPC_Date__c = null
			]);
			
			//List<Contact> contactsToUpdate = new List<Contact>();
			Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
			List<Lead> leadsToUpdate = new List<Lead>();
			
			for (Twilio_Usage__c u : usages) {
				// Attempt to set the NPC_Date from the Contact or Lead if
				// it is not set on the Twilio_Usage__c
				if (u.NPC_Date_Sales__c != null) {
					if (u.Contact__c != null && contacts.containsKey(u.Contact__c)) {
						Contact c = contacts.get(u.Contact__c);
						c.NPC_Date__c = u.NPC_Date_Sales__c;
						c.NPC_Owner__c = c.Owner.Name;
						
						if ( !contactsToUpdate.containsKey( c.Id ) || c.CreatedDate > contactsToUpdate.get( c.Id ).CreatedDate )
							contactsToUpdate.put(c.Id, c);
						
					} else if (u.Lead__c != null && leads.containsKey(u.Lead__c)) {
						Lead l = leads.get(u.Lead__c);
						l.NPC_Date__c = u.NPC_Date_Sales__c;
						l.NPC_Owner__c = (l.Contacted_Time__c == null && u.NPC_Date_Sales__c != null) ? 'Sales Operations' : l.Owner.Name;
						l.Non_Eligible_SQL__c =  (l.Qualified_Time__c > l.NPC_Date__c);
						leadsToUpdate.add(l);
					}
				}
			}
			if (!contactsToUpdate.isEmpty()) {
				update contactsToUpdate.values();
			}
			if (!leadsToUpdate.isEmpty()) {
				update leadsToUpdate;
			}
		}
	}
	
	/************************* 
	 * Added by Ashwani as a part of "Twilio Multi-User Code Update Project v2.1" on 10-Feb-2015
	 * 1. Method : onBeforeInsert
	 * 2. Method : onBeforeUpdate
	 * Methods would be called from Trigger "NimblyLinkUsages"
	**********/
	
	// On Before Insert event
	// @param: Takes Trigger.New list
	public static void onBeforeInsert(List<Twilio_Usage__c> twilioUsages)
	{
		List<Twilio_Usage__c> changedTwUsages = new List<Twilio_Usage__c>();
		
		// Update Twilio Usage onoy if there AccountSid__c is present.
		for(Twilio_Usage__c tw : twilioUsages)
		{
			if(tw.AccountSid__c != null)
			{
				changedTwUsages.add(tw);
			}
		}
		if(changedTwUsages.size()>0)
		{
			UtilityLinkAccountSidToTwilioUsage.LinkAccountSidToTwilioUsage(changedTwUsages );
		}
	}
	
	// On Before Update event
	// @param: Takes Trigger.New list
	// @param: Takes Trigger.New and Trigger.oldMap
	public static void onBeforeUpdate(List<Twilio_Usage__c> newTwilioUsages, Map<Id,Twilio_Usage__c> oldTwilioUsagesMap)
	{
		List<Twilio_Usage__c> changedTwUsages = new List<Twilio_Usage__c>();
		
		// Update Twilio Usage only if there Related_Account_SID__c is changed.
		for(Twilio_Usage__c tw : newTwilioUsages)
		{
			if(tw.AccountSid__c != null &&
			   ((tw.Related_Account_SID__c != oldTwilioUsagesMap.get(tw.id).Related_Account_SID__c ||
			   tw.AccountSID__c != oldTwilioUsagesMap.get(tw.id).AccountSID__c ) || tw.Related_Account_SID__c==null) )
			{
				changedTwUsages.add(tw);
			}
		}
		if(changedTwUsages.size()>0)
		{
			UtilityLinkAccountSidToTwilioUsage.LinkAccountSidToTwilioUsage(changedTwUsages );
		}
	}
}