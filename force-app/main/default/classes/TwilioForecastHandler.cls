public without sharing class TwilioForecastHandler {
    final public static Integer defaultProjectGrowthRate = 106;
    final public static Map<Integer, String> monthNumToStrLookup = new Map<Integer, String>{
		 1 => 'January',  2 => 'February',  3 => 'March',
		 4 => 'April',    5 => 'May',       6 => 'June',
		 7 => 'July',     8 => 'August',    9 => 'September',
		10 => 'October', 11 => 'November', 12 => 'December'
	};
    final public static Map<String, Integer> monthStrToNumLookup = new Map<String, Integer>{
		'January' => 1,  'February' => 2,  'March'     => 3,
		'April'   => 4,  'May'      => 5,  'June'      => 6,
		'July'    => 7,  'August'   => 8,  'September' => 9,
		'October' => 10, 'November' => 11, 'December'  => 12
	};
    final public static Map<Integer, String> monthNumToQtrLookup = new Map<Integer, String>{
		 1 => 'Q1',  2 => 'Q1',  3 => 'Q1',
		 4 => 'Q2',  5 => 'Q2',  6 => 'Q2',
		 7 => 'Q3',  8 => 'Q3',  9 => 'Q3',
		10 => 'Q4', 11 => 'Q4', 12 => 'Q4'
	};

	final public static Set<String> amortizedProducts = new Set<String> { 'Net Billings', 'Net Billings Twilio-Only', 'Total Sales (Amortized)' };

    public static void initializeForecast(List<Account> accounts, String year) {
		// Check for Accounts that already have forecast records for the specified year
		Set<Id> accountIds = new Set<Id>();
        for (Account a : accounts) {
        	if (!accountIds.contains(a.Id)) {
        		accountIds.add(a.Id);
        	}
        }

		AggregateResult[] groupedResults = [
			SELECT Account__c, Account__r.Name, COUNT(Id)
			FROM Twilio_Forecast__c
			WHERE Account__c IN :accountIds AND Fiscal_Year__c = :year
			GROUP BY Account__c, Account__r.Name
		];		
		
		Map<Id,Integer> accountForecastCounts = new Map<Id,Integer>();
		for (AggregateResult ar : groupedResults)  {
			accountForecastCounts.put((Id) ar.get('Account__c'), (Integer) ar.get('expr0'));
		}
		
		for (Id k : accountForecastCounts.keySet())  {
			System.debug('====> Account ID/Record Count(' + k + ' / ' + accountForecastCounts.get(k) + ')');
		}

        
  		//	Create the forecast records for each Account
        List<Twilio_Forecast__c> forecasts = new List<Twilio_Forecast__c>();
        
  		for (Account a : accounts) {
  			if (accountForecastCounts.containsKey(a.Id)) {
  				System.debug('SKIPPING: Account ('+ a.Id +' / ' + a.Name + ') already has forecast records for ' + year);
  			} else {
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q1', Fiscal_Month__c = 'January',   Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q1', Fiscal_Month__c = 'February',  Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q1', Fiscal_Month__c = 'March',     Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q2', Fiscal_Month__c = 'April',     Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q2', Fiscal_Month__c = 'May',       Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q2', Fiscal_Month__c = 'June',      Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q3', Fiscal_Month__c = 'July',      Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q3', Fiscal_Month__c = 'August',    Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q3', Fiscal_Month__c = 'September', Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q4', Fiscal_Month__c = 'October',   Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q4', Fiscal_Month__c = 'November',  Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  				forecasts.add(new Twilio_Forecast__c(Name = 'Q4', Fiscal_Month__c = 'December',  Projected_Growth_Rate__c = defaultProjectGrowthRate, Fiscal_Year__c = year, Account__c = a.Id ));
  			}
  		}      
        
        if (forecasts.size() > 0) {
            insert forecasts;
        }
    }
    
    public static void  mergeForecasts(List<Id> mergedAccountIds) {
    	List<Twilio_Forecast__c> forecasts = [
			SELECT Id, Name, Account__c, Account__r.Name, Account__r.Owner.Name,
				Rep_Override__c, Fiscal_Month__c, Fiscal_Year__c
			FROM Twilio_Forecast__c
			WHERE Account__c IN :mergedAccountIds
			ORDER BY Account__c, Fiscal_Year__c, Name, Fiscal_Month__c
		];
    	
    	List<Id> forecastIds = new List<Id>();
    	Set<Twilio_Forecast__c> forecastsToDelete = new Set<Twilio_Forecast__c>();
    	Set<Twilio_Forecast__c> forecastsToReconcile = new Set<Twilio_Forecast__c>();
    	for (Twilio_Forecast__c f1 : forecasts) {
    		forecastIds.add(f1.Id);
    		for (Twilio_Forecast__c f2 : forecasts) {
    			// If the forecast is being analyzed with itself go to the next one 
    			if (f1.Id == f2.Id) {
    				continue;
    			}
    			
    			if (f1.Account__c == f2.Account__c
					&& f1.Fiscal_Month__c == f2.Fiscal_Month__c
					&& f1.Fiscal_Year__c == f2.Fiscal_Year__c
				) {
					System.debug('=====> FORECAST 1 UNDER REVIEW(' + f1.Id + ', Account=' + f1.Account__c + ', RepOverride=' + f1.Rep_Override__c + ', ' + f1.Fiscal_Month__c + '/' + f1.Fiscal_Year__c + ')');
					System.debug('=====> FORECAST 2 UNDER REVIEW(' + f2.Id + ', Account=' + f2.Account__c + ', RepOverride=' + f2.Rep_Override__c + ', ' + f2.Fiscal_Month__c + '/' + f2.Fiscal_Year__c + ')');

					if ((f1.Rep_Override__c == f2.Rep_Override__c)
						|| (
							(f1.Rep_Override__c == 0 || f1.Rep_Override__c == null) &&
							(f2.Rep_Override__c == 0 || f2.Rep_Override__c == null)
						)) {
						System.debug('=====> REP OVERRIDE EQUAL(' + f1.Id + ' : ' + f2.Id + ')');

						// Delete f2 as long as f1 isn't already targeted for deletion
						if (!forecastsToDelete.contains(f1) && !forecastsToDelete.contains(f2)) {
							System.debug('=====> ADDING FORECAST FOR REMOVAL(' + f2.Id + ', Account=' + f2.Account__c + ', RepOverride=' + f2.Rep_Override__c + ', ' + f2.Fiscal_Month__c + '/' + f2.Fiscal_Year__c + ')');
							forecastsToDelete.add(f2);
						}
					} else if (f1.Rep_Override__c > 0 && f2.Rep_Override__c == 0) {
						System.debug('=====> REP OVERRIDE NOT EQUAL(' + f1.Id + ':' + f1.Rep_Override__c + ', ' + f2.Id + ':' + f2.Rep_Override__c + ')');

						// Delete f2 as long as f1 isn't already targeted for deletion
						if (!forecastsToDelete.contains(f1)) {
							System.debug('=====> ADDING FORECAST FOR REMOVAL(' + f2.Id + ', Account=' + f2.Account__c + ', RepOverride=' + f2.Rep_Override__c + ', ' + f2.Fiscal_Month__c + '/' + f2.Fiscal_Year__c + ')');
							forecastsToDelete.add(f2);
						}
					} else if (f1.Rep_Override__c == 0 && f2.Rep_Override__c > 0) {
						System.debug('=====> REP OVERRIDE NOT EQUAL(' + f1.Id + ':' + f1.Rep_Override__c + ', ' + f2.Id + ':' + f2.Rep_Override__c + ')');

						// Delete f1 as long as f2 isn't already targeted for deletion
						if (!forecastsToDelete.contains(f2)) {
							System.debug('=====> ADDING FORECAST FOR REMOVAL(' + f1.Id + ', Account=' + f1.Account__c + ', RepOverride=' + f1.Rep_Override__c + ', ' + f1.Fiscal_Month__c + '/' + f1.Fiscal_Year__c + ')');
							forecastsToDelete.add(f1);
						}
					} else {
						System.debug('=====> REP OVERRIDE NOT EQUAL(' + f1.Id + ':' + f1.Rep_Override__c + ', ' + f2.Id + ':' + f2.Rep_Override__c + ')');

						// Email for manual reconcilation of f1 & f2
						System.debug('=====> ADDING FORECAST FOR MANUAL RECONCILATION(' + f1.Id + ', Account=' + f1.Account__c + ', RepOverride=' + f1.Rep_Override__c + ', ' + f1.Fiscal_Month__c + '/' + f1.Fiscal_Year__c + ')');
						System.debug('=====> ADDING FORECAST FOR MANUAL RECONCILATION(' + f2.Id + ', Account=' + f2.Account__c + ', RepOverride=' + f2.Rep_Override__c + ', ' + f2.Fiscal_Month__c + '/' + f2.Fiscal_Year__c + ')');
						forecastsToReconcile.add(f1);
						forecastsToReconcile.add(f2);
					}
    			}
    		}
    	}
    	
    	if (!forecastsToDelete.isEmpty()) {
    		delete new List<Twilio_Forecast__c>(forecastsToDelete);
    	}
    	
    	if (!forecastsToReconcile.isEmpty()) {
    		Organization org = [ SELECT Id, IsSandbox FROM Organization LIMIT 1];

			String orgURL = org.IsSandbox ? 'https://test.salesforce.com' : 'https://login.salesforce.com';
			String[] mergeAdminEmail = org.IsSandbox ? new String[] {'jonathan.f.griggs@gmail.com', 'jbauch@twilio.com'} : new String[] {'salesops@twilio.com'};
			String mergeEmailFrom = org.IsSandbox ? 'jonathan.f.griggs@gmail.com' : 'salesops@twilio.com';
		
		    String mergeEmailFromDisplayName = 'Twilio Account Merge Conflict';
		    String mergeEmailSubject = 'Twilio Account Merge:  Forecast Conflict Report';
    		
    		// Send email with listing
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			//mail.setToAddresses(new String[] { a.Owner.Email });
			mail.setToAddresses(mergeAdminEmail);
			mail.setReplyTo(mergeEmailFrom);
			mail.setSenderDisplayName(mergeEmailFromDisplayName);
			mail.setSubject(mergeEmailSubject);
			
			String message = 'The following forecasts could not automatically be merged and will need to be manually reconciled.\n\n';
			
			Id currentAccountId;
			for (Twilio_Forecast__c f : forecastsToReconcile) {
				System.debug('====> FORECAST TO RECONCILE(' + f.Id + ', ' + f.Fiscal_Month__c + '/' + f.Fiscal_Year__c + ')');
				if (currentAccountId != f.Account__c) {
					message += '\nACCOUNT: ' + f.Account__r.Name + ' / ' + f.Account__r.Owner.Name + ' (' + orgURL + '/' + f.Account__c + ')\n';
					currentAccountId = f.Account__c;
				}
				String name = String.isBlank(f.name) ? '-' : f.name;
				String month = String.isBlank(f.Fiscal_Month__c) ? '-' : f.Fiscal_Month__c;
				String year = String.isBlank(f.Fiscal_Year__c) ? '-' : f.Fiscal_Year__c;
				
				String repoverride = (f.Rep_Override__c == null) ? '-' : String.format(f.Rep_Override__c.format(), new String[]{'0','number','###,###,##0.00'});
				message += '      ' + name + ' - ' + month + '/' + year + ' - $' + repoverride + ' (' + orgURL + '/' + f.Id + ')\n';
			}
			
			mail.setPlainTextBody(message);

			List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
			mailList.add(mail);
			Messaging.sendEmail(mailList);
    	}

		// Recalculate the forecast totals
   		futureCalculateForecastUsage(mergedAccountIds);
    }
    
    @future public static void futureCalculateForecastUsage(List<Id> accountIds) {
		Map<Id,Twilio_Usage__c> usages = new Map<Id,Twilio_Usage__c>([
			SELECT Id, Product__c, AccountLookup__c, Year__c, Month__c, Lead__c,
			Current_Month_Forecast__c, Last_Month_Forecast__c, X2_Month_Ago_Forecast__c,
			Twilio_Forecast_3__c, X2_Month_Ahead_Forecast__c,
			Fiscal_Year__c, Usage_Date__c
			FROM Twilio_Usage__c
			WHERE AccountLookup__c IN :accountIds
		]);
		TwilloUsageTriggerHandler.updateForcastFields(usages.values(), usages, true);
		calculateForecastUsage(usages.values());
	}
	public static void calculateForecastUsage(List<Twilio_Usage__c> usages) {
	
	  // Get Current and Next (Twilio_Forecast_3__c) forecasts that need to be updated
	  Set<Id> current_month_forecasts = new Set<Id>();
	  Set<Id> next_month_forecasts = new Set<Id>();
	  Set<Id> two_month_ahead_forecasts = new Set<Id>();
	  Set<Id> leadIds = new Set<Id>();
	  for (Twilio_Usage__c u : usages) {
	    if (amortizedProducts.contains(u.Product__c)) {
	      System.debug('====> ADDING USAGE INFO (' + u.Id + ', ' + u.AccountLookup__c + ', ' + u.Year__c + ', ' + u.Month__c + ')');

	      if (u.Current_Month_Forecast__c != null)
	      	current_month_forecasts.add(u.Current_Month_Forecast__c);
	      if (u.Twilio_Forecast_3__c != null)
		    next_month_forecasts.add(u.Twilio_Forecast_3__c);
	      if (u.X2_Month_Ahead_Forecast__c != null)
		    two_month_ahead_forecasts.add(u.X2_Month_Ahead_Forecast__c);
	      if (u.Lead__c != null)
	      	leadIds.add(u.Lead__c);
	     }
	  }
	
	  // Get the forecasts for the current and next that will be updated
	  Set<Id> all_forecasts = new Set<Id>();
	  all_forecasts.addAll(current_month_forecasts);
	  all_forecasts.addAll(next_month_forecasts);
	  all_forecasts.addAll(two_month_ahead_forecasts);
	  Map<Id, Twilio_Forecast__c> forecasts = new Map<Id, Twilio_Forecast__c>([
	    SELECT Id, Current_Month_Usage__c, Last_Month_Usage__c, X2_Month_Ago_Usage__c, Account__c, Fiscal_Year__c, Fiscal_Month__c
	    FROM Twilio_Forecast__c
	    WHERE Id IN :all_forecasts
	  ]);
	
	  // Get all of the usages for the forecasts
	  List<Twilio_Usage__c> all_usages = [
	    SELECT Id, Current_Month_Forecast__c, Twilio_Forecast_3__c, X2_Month_Ahead_Forecast__c, Total__c, AccountLookup__c
	    FROM Twilio_Usage__c
	    WHERE Current_Month_Forecast__c IN :current_month_forecasts
	    AND Product__c IN :amortizedProducts
	  ];

	  // Reset the respective forecasts usage to zero
	  for (Id i : current_month_forecasts) {
	    Twilio_Forecast__c f = forecasts.get(i);
	    f.Current_Month_Usage__c = 0;
	    forecasts.put(i, f);
	  }
	  for (Id i : next_month_forecasts) {
	    Twilio_Forecast__c f = forecasts.get(i);
	    f.Last_Month_Usage__c = 0;
	    forecasts.put(i, f);
	  }
	
	  for (Id i : two_month_ahead_forecasts) {
	    Twilio_Forecast__c f = forecasts.get(i);
	    f.X2_Month_Ago_Usage__c = 0;
	    forecasts.put(i, f);
	  }
	
	  // Calculate the current month usage and update the current month's Current Month Usage and next month's Last Month Usage
	  for (Twilio_Usage__c u : all_usages) {
	    Twilio_Forecast__c c = forecasts.get(u.Current_Month_Forecast__c);
		if (c != null) {
//		    System.debug('====> UPDATING CURRENT FORECAST CURRENT USAGE (' + u.Id + ', ' + c.Id + ', ' + c.Current_Month_Usage__c + ' + ' + u.Total__c + ' = ' + (c.Current_Month_Usage__c + u.Total__c) + ')');
		    c.Current_Month_Usage__c += u.Total__c;
		    forecasts.put(u.Current_Month_Forecast__c, c);
	    }
	
		Twilio_Forecast__c l = forecasts.get(u.Twilio_Forecast_3__c);
		if (l != null && c != null) {
//	    	System.debug('====> UPDATING NEXT FORECAST LAST USAGE (' + u.Id + ', ' + l.Id + ', ' + l.Last_Month_Usage__c + ' + ' + u.Total__c + ' = ' + (l.Last_Month_Usage__c + u.Total__c) + ')');
	    	l.Last_Month_Usage__c = c.Current_Month_Usage__c;
		    forecasts.put(u.Twilio_Forecast_3__c, l);
		}

		Twilio_Forecast__c l2 = forecasts.get(u.X2_Month_Ahead_Forecast__c);
		if (l2 != null && c != null) {
//	    	System.debug('====> UPDATING TWO FORECAST AHEAD TWO MONTH AGO USAGE (' + u.Id + ', ' + l2.Id + ', ' + l2.X2_Month_Ago_Usage__c + ' + ' + u.Total__c + ' = ' + (l2.X2_Month_Ago_Usage__c + u.Total__c) + ')');
	    	l2.X2_Month_Ago_Usage__c = c.Current_Month_Usage__c;
		    forecasts.put(u.X2_Month_Ahead_Forecast__c, l2);
		}
	  }

	  update forecasts.values();
	  updateAccountMonthlyRollup(forecasts.values());
	  updateLeadMonthlyRollup(leadIds, '', '');
	}
	
	// Update the Account's this & last month usage totals
	public static void updateAccountMonthlyRollup(List<Twilio_Forecast__c> forecasts) {
      Datetime now = Datetime.now();
	  String current_months_year = String.valueOf(now.year());
	  String current_months_month = now.format('MMMMM'); 

	  Map<Id, Account> accounts = new Map<Id, Account>();

      for (Twilio_Forecast__c f : forecasts) {
      	if (f.Fiscal_Year__c == current_months_year && f.Fiscal_Month__c == current_months_month) {
	      	accounts.put(f.Account__c, new Account(
	      		Id = f.Account__c,
				Total_Amortized_Twilio_Usage_This_Month__c = f.Current_Month_Usage__c,
				Total_Amortized_Twilio_Usage_Last_Month__c = f.Last_Month_Usage__c,
				Total_Amortized_Twilio_Usage_2_Month_Ago__c = f.X2_Month_Ago_Usage__c
			));
      	}
      }

	  if (!accounts.isEmpty()) {
	  	update accounts.values();
	  	updateMonthlyTrend(accounts.keySet(), current_months_year);
	  }
	}
	
	public static void updateAccountMonthlyRollup(Set<Id> accountIds, String current_months_month, String current_months_year) {
	  if (accountIds.isEmpty()) {
	  	return;
	  }

      Datetime now = Datetime.now();
	  current_months_year = String.isBlank(current_months_year) ? String.valueOf(now.year()) : current_months_year;
	  current_months_month = String.isBlank(current_months_month) ? now.format('MMMMM') : current_months_month; 
	  Map<Id, Account> accountMap = new Map<Id, Account>();

	  // Initialize the account usage totals to zero
	  for (Id i : accountIds) {
	  	accountMap.put(i, new Account(
      		Id = i,
			Total_Amortized_Twilio_Usage_This_Month__c = 0,
			Total_Amortized_Twilio_Usage_Last_Month__c = 0,
			Total_Amortized_Twilio_Usage_2_Month_Ago__c = 0
		));
	  }

	  // For accounts that have forcasts update usage totals
      for (Twilio_Forecast__c f : [ 
      	SELECT Id, Account__c, Current_Month_Usage__c, Last_Month_Usage__c, X2_Month_Ago_Usage__c
		FROM Twilio_Forecast__c
		WHERE Fiscal_Year__c = :current_months_year
		AND Fiscal_Month__c = :current_months_month
		AND Account__c IN :accountMap.keySet()
		]) {
  	  	accountMap.put(f.Account__c, new Account(
      		Id = f.Account__c,
			Total_Amortized_Twilio_Usage_This_Month__c = f.Current_Month_Usage__c,
			Total_Amortized_Twilio_Usage_Last_Month__c = f.Last_Month_Usage__c,
			Total_Amortized_Twilio_Usage_2_Month_Ago__c = f.X2_Month_Ago_Usage__c
		));
      }
      
	  if (!accountMap.isEmpty()) {
	  	update accountMap.values();
	  }

	  updateMonthlyTrend(accountIds, current_months_year);
	}

    // Update the Lead's this & last month usage totals
	public static void updateLeadMonthlyRollup(Set<Id> leadIds, String current_months_month, String current_months_year) {
	  if (leadIds.isEmpty()) {
	  	return;
	  }

      Datetime now = Datetime.now();
	  current_months_year = String.isBlank(current_months_year) ? String.valueOf(now.year()) : current_months_year;
	  current_months_month = String.isBlank(current_months_month) ? now.format('MMMMM') : current_months_month; 

	  String last_months_year = String.valueOf(now.addMonths(-1).year());
	  String last_months_month = now.addMonths(-1).format('MMMMM'); 

	  String x2_months_ago_year = String.valueOf(now.addMonths(-2).year());
	  String x2_months_ago_month = now.addMonths(-2).format('MMMMM'); 

	  List<Twilio_Usage__c> usages = [
	    SELECT Id, Fiscal_Year__c, Calendar_Month__c, Total__c, Lead__c,
	    	Lead__r.Total_Amortized_Twilio_Usage_This_Month__c,
			Lead__r.Total_Amortized_Twilio_Usage_Last_Mont__c,
			Lead__r.Total_Amortized_Twilio_Usage_2_Month_Ago__c
	    FROM Twilio_Usage__c
	    WHERE Lead__c IN :leadIds
	    AND Product__c IN :amortizedProducts
	    AND Lead__r.IsConverted = false
	    AND (
	    	(Fiscal_Year__c = :current_months_year AND Calendar_Month__c = :current_months_month)
	    	OR (Fiscal_Year__c = :last_months_year AND Calendar_Month__c = :last_months_month)
	    	OR (Fiscal_Year__c = :x2_months_ago_year AND Calendar_Month__c = :x2_months_ago_month)
	    )
	  ];

	  // Initialize the Lead's this and last month's totals
	  Map<Id, Lead> leads = new Map<Id, Lead>();
	  Map<Id, Decimal> leadTotalUsageThisMonth = new Map<Id, Decimal>();
	  Map<Id, Decimal> leadTotalUsageLastMonth = new Map<Id, Decimal>();
	  Map<Id, Decimal> leadTotalUsage2MonthAgo = new Map<Id, Decimal>();
	  for (Twilio_Usage__c u : usages) {
      	leads.put(u.Lead__c, new Lead(
      		Id = u.Lead__c,
			Total_Amortized_Twilio_Usage_This_Month__c = 0,
			Total_Amortized_Twilio_Usage_Last_Mont__c = 0,
			Total_Amortized_Twilio_Usage_2_Month_Ago__c = 0
		));
		leadTotalUsageThisMonth.put(u.Lead__c, u.Lead__r.Total_Amortized_Twilio_Usage_This_Month__c);
		leadTotalUsageLastMonth.put(u.Lead__c, u.Lead__r.Total_Amortized_Twilio_Usage_Last_Mont__c);
		leadTotalUsage2MonthAgo.put(u.Lead__c, u.Lead__r.Total_Amortized_Twilio_Usage_2_Month_Ago__c);
	  }

	  for (Twilio_Usage__c u : usages) {
	    if (u.Lead__c != null) {
			if (u.Fiscal_Year__c == current_months_year && u.Calendar_Month__c == current_months_month) {
				Lead lead = leads.get(u.Lead__c);
				lead.Total_Amortized_Twilio_Usage_This_Month__c += u.Total__c;
				leads.put(u.Lead__c, lead);
			}
			if (u.Fiscal_Year__c == last_months_year && u.Calendar_Month__c == last_months_month) {
				Lead lead = leads.get(u.Lead__c);
				lead.Total_Amortized_Twilio_Usage_Last_Mont__c += u.Total__c;
				leads.put(u.Lead__c, lead);
			}
			if (u.Fiscal_Year__c == x2_months_ago_year && u.Calendar_Month__c == x2_months_ago_month) {
				Lead lead = leads.get(u.Lead__c);
				lead.Total_Amortized_Twilio_Usage_2_Month_Ago__c += u.Total__c;
				leads.put(u.Lead__c, lead);
			}
	    }
	  }
	  
	  if (!leads.isEmpty()) {
		  // Check to see if the leads' totals have change and if so only update those
		  List<Lead> leadsToUpdate = new List<Lead>();
		  for (Lead l : leads.values()) {
		  	if (l.Total_Amortized_Twilio_Usage_This_Month__c != leadTotalUsageThisMonth.get(l.Id)
		  		|| l.Total_Amortized_Twilio_Usage_Last_Mont__c != leadTotalUsageLastMonth.get(l.Id)
		  		|| l.Total_Amortized_Twilio_Usage_2_Month_Ago__c != leadTotalUsage2MonthAgo.get(l.Id)
		  	) {
		  		leadsToUpdate.add(l);
		  	}
		  	
		  }
		  
		  if (!leadsToUpdate.isEmpty()) {
		  	update leadsToUpdate;
		  }
	  }
	}
	
    // Update the Lead's this & last month usage totals
	public static void updateMonthlyTrend(Set<Id> accountIds, String year) {

		// If no account Ids are given then nothing to do
		if (accountIds.isEmpty()) {
			return;
		}

		// Get the last and next years relative to the specified year
		// If the specified year is blank then use the current year
		Set<String> years = new Set<String>();
		if (String.isBlank(year)) {
			Datetime now = Datetime.now();
			years.add(String.valueOf(now.year()));					// current year
			years.add(String.valueOf(now.addMonths(-1).year()));	// last year
			years.add(String.valueOf(now.addMonths(1).year()));		// next year
		} else {
			years.add(year);										// specified year
			years.add(String.valueOf(Integer.valueOf(year) - 1));	// last year
			years.add(String.valueOf(Integer.valueOf(year) + 1));	// next year
		}

		// Build a Map of Lists where the Map Key is the Account ID and the 
		// List is the chronologically ordered Twilio Forecast records
		Map<Id, List<Twilio_Forecast__c>> tfMap = new Map<Id, List<Twilio_Forecast__c>>();
		for (Twilio_Forecast__c tf : [ 
			SELECT Id, Account__c, Fiscal_Year__c, Fiscal_Month__c,Trend_NEW__c, Projected_Growth_Rate__c, Last_Month_Usage__c
			FROM Twilio_Forecast__c 
			WHERE Account__c in :accountIds 
			AND Fiscal_Year__c in :years
			ORDER BY Account__c, CreatedDate desc
		]) {
			if (tfMap.containsKey(tf.Account__c)) {
				List<Twilio_Forecast__c> l = tfMap.get(tf.Account__c);
				l.add(tf);
				tfMap.put(tf.Account__c, l); 
			} else {
				tfMap.put(tf.Account__c, new List<Twilio_Forecast__c> { tf }); 
			}
			System.debug('FORECAST(' + tf.Id + ', ' + tf.Fiscal_Month__c + '/' + tf.Fiscal_Year__c + ')');
		}
		
		// Calculate the account forecast trends
		List<Twilio_Forecast__c> forecastsToUpdate = new List<Twilio_Forecast__c>();
		for (List<Twilio_Forecast__c> tflist : tfMap.values()) {
			Twilio_Forecast__c lastForecast = null;
			for (Twilio_Forecast__c tf : tflist) {

				// If the last month usage is NOT NULL then use it for the trend calculation
				if (tf.Last_Month_Usage__c != null) {
					Decimal rate = (tf.Projected_Growth_Rate__c != null) ? (tf.Projected_Growth_Rate__c / 100) : 1;
					tf.Trend_NEW__c = tf.Last_Month_Usage__c * rate;
					forecastsToUpdate.add(tf);
					System.debug('UPDATE FORECAST - BASED ON CURRENT USAGE(' + tf.Id + ', ' + tf.Fiscal_Month__c + '/' + tf.Fiscal_Year__c + ', ' + tf.Trend_NEW__c + '[' + tf.Last_Month_Usage__c + ' * ' + rate + '])');

				// If the last month usage is NULL then use last month's trend for this month's trend calculation
				} else if (lastForecast != null && lastForecast.Trend_NEW__c != null) {
					Decimal rate = (tf.Projected_Growth_Rate__c != null) ? (tf.Projected_Growth_Rate__c / 100) : 1;
					tf.Trend_NEW__c = lastForecast.Trend_NEW__c * rate;
					forecastsToUpdate.add(tf);
					System.debug('UPDATE FORECAST - BASED ON LAST MONTH TREND(' + tf.Id + ', ' + tf.Fiscal_Month__c + '/' + tf.Fiscal_Year__c + ', ' + tf.Trend_NEW__c + '[' + lastForecast.Trend_NEW__c + ' * ' + rate + '])');

				// If the last month usage and last month's trend are NULL there is not enough info for the trend calculation
				} else {
					System.debug('NO UPDATE FOR FORECAST(' + tf.Id + ', ' + tf.Fiscal_Month__c + '/' + tf.Fiscal_Year__c +')');
				}

				lastForecast = tf; 
			}
		}
		
		if (!forecastsToUpdate.isEmpty()) {
			update forecastsToUpdate;
		}
	}	
}