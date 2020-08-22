global class OpportunityLeadQualifiedByHandler implements Database.Batchable<sObject>, Schedulable {

    // Generate a list of records to batch process
    global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT Id, Lead_Qualified_By__c, Lead_Qualified_By_Lookup__c FROM Opportunity');
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
    	List<Opportunity> opps = (List<Opportunity>)scope;
        System.debug('OpportunityLeadQualifiedByHandler: Processing ' + opps.size() + ' records');
		process(opps);
		update opps;
    }
    
    // Actions to perform when batch processing is finished
    global void finish(Database.BatchableContext BC) {
    }
    
    // Schedulable Interface Method
    global void execute(SchedulableContext context) {
        Database.executebatch(new OpportunityLeadQualifiedByHandler());
    }

    public static void onBeforeInsert(List<Opportunity> newList) {
        List<Opportunity> oppsToProcess = new List<Opportunity>();

        for (Opportunity n : newList) {
            if (String.isNotBlank(n.Lead_Qualified_By__c))
                oppsToProcess.add(n);
        }
        
        process(oppsToProcess);
    }

    public static void onBeforeUpdate(Map<Id,Opportunity> oldMap, Map<Id,Opportunity> newMap) {
        List<Opportunity> oppsToProcess = new List<Opportunity>();

        for (Opportunity n : newMap.values()) {
            Opportunity o = oldMap.get(n.Id);
            if (n.Lead_Qualified_By__c != o.Lead_Qualified_By__c) {
                // If the Lead Qualified By is unset the unset the Lookup
                if (String.isBlank(n.Lead_Qualified_By__c)) {
                    n.Lead_Qualified_By_Lookup__c = null;
	                System.debug('CLEARING Lead_Qualified_By_Lookup__c: ' + n);
                } else {
                    oppsToProcess.add(n);
                }
            }
        }

        process(oppsToProcess);
    }

	// Give a list of Opporunities it will be lookup the Lead_Qualified_By__c field to
	// find Users that have a corresponding name.  If found, the Lead_Qualified_By_Lookup__c
	// is set accordingly.
    public static void process(List<Opportunity> opps) {
        // Get a list of the Lead Qualified By names
        Set<String> names = new Set<String>();
        for (Opportunity o : opps) {
            names.add(o.Lead_Qualified_By__c);
        }
        
        // Lookup of the Lead Qualified By names from the User object
        Map<String,User> users = new Map<String,User>();
        for (User u : [ SELECT Id, Name FROM User WHERE Name IN :names ]) {
            users.put(u.Name, u);
        }
        
        // For all matching Users update the Lead Qualified By Lookup
        for (Opportunity o : opps) {
            if (users.containsKey(o.Lead_Qualified_By__c)) {
                User u = users.get(o.Lead_Qualified_By__c);
                o.Lead_Qualified_By_Lookup__c  = u.Id;
                //System.debug('UPDATING Lead_Qualified_By_Lookup__c (match found): ' + o);
            } else {
                o.Lead_Qualified_By_Lookup__c  = null;
                //System.debug('CLEARING Lead_Qualified_By_Lookup__c (no match found): ' + o);
            }
        }
    }
}