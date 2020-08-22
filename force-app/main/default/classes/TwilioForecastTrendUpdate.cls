// To execute the batch process run:
//    
//    Database.executeBatch(new TwilioForecastTrendUpdate(), 200);
//
global class TwilioForecastTrendUpdate implements Database.Batchable<sObject> {

	public Set<Id> accountIds;  
	public String year;

	global TwilioForecastTrendUpdate (){
		this.accountIds = new Set<Id>();
	}

	global TwilioForecastTrendUpdate (String year){
		this.accountIds = new Set<Id>();
		this.year = year;
	}

	global TwilioForecastTrendUpdate (Set<Id> accountIds){
		this.accountIds = accountIds;
	}

	global TwilioForecastTrendUpdate (Set<Id> accountIds, String year){
		this.accountIds = accountIds;
		this.year = year;
	}

    global Database.querylocator start(Database.BatchableContext BC){
    	if (accountIds.isEmpty()) {
	        return Database.getQueryLocator([ SELECT Id FROM Account ]);
    	} else {
    		return Database.getQueryLocator([ SELECT Id FROM Account WHERE Id IN :accountIds ]);
    	}
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
    	Set<Id> accIds = new Set<Id>();
        for(sObject s : scope){
            Account a = (Account)s;
            accIds.add(a.Id);
        }

        if (!accIds.isEmpty()) {
			TwilioForecastHandler.updateMonthlyTrend(accIds, year);
        }
    }

    global void finish(Database.BatchableContext BC){}
}