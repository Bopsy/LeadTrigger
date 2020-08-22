global class OpportunitySnapshot implements Database.Batchable<sObject>, Schedulable{
    // Generate a list of records to batch process
    global Database.QueryLocator start(Database.BatchableContext BC) {
    	//String fields = getOpportunityCriteria();
        //String criteria = getOpportunityCriteria();
    	String fields = String.join(new List<String>(getOpportunityFieldMap().keySet()), ',');
		String criteria = getOpportunityCriteria();
		String soql = 'SELECT ' + (String.isBlank(fields) ? 'Id' : fields) +
			' FROM Opportunity' +
			(String.isBlank(criteria) ? '' : (' WHERE ' + criteria));
		System.debug('OpportunitySnapshot SOQL: ' + soql);
    	return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        System.debug('OpportunitySnapshot: Processing ' + scope.size() + ' records');
		copyRecords((List<Opportunity>)scope);
        deleteSnapshotRecords();
    }
    
    // Actions to perform when batch processing is finished
    global void finish(Database.BatchableContext BC) {
		
    }
    
    // Schedulable Interface Method
    global void execute(SchedulableContext context) {
        Database.executebatch(new OpportunitySnapshot());
        
    }

	// Copy the list of Opportunity records to the Opportunity_Snapshot object
	global void copyRecords(List<Opportunity> opptyList) {
		System.debug('OpportunitySnapshot: Processing ' + opptyList.size() + ' records');
		Map<String,String> fieldMap = getOpportunityFieldMap();
		
		List<Opportunity_Snapshot__c> snapshot = new List<Opportunity_Snapshot__c>();
		for (Opportunity o : opptyList) {
            //Filter AccountID to check if this custom setting is stable.
            if(o.AccountId == null){ continue; }
            
			Opportunity_Snapshot__c s = new Opportunity_Snapshot__c();
			for (String opptyFieldName : fieldMap.keySet()) {
				String snapshotFieldName = fieldMap.get(opptyFieldName);
				s.put(snapshotFieldName, lookup(o, opptyFieldName));
			}
			snapshot.add(s);
		}
		
		System.debug(JSON.serializePretty(snapshot));
		insert snapshot;
	}

	// Returns a SOQL friendly date format to use in where clauses
	// This is used to construct portions of the SOQL where clause where the field type is "Date"
	global String formatDateForSoql(Date d) {
		return DateTime.newInstance(d.year(),d.month(),d.day()).format('yyyy-MM-dd');
	}

	// Build a map of fields for the Opportunity to Opportunity_Snapshot__c
	// This is used to construct a list of field to query from the Opportunity
	// This is used to identify which Opportunity field are mapped to Opportunity_Snapshot__c fields
	global Map<String,String> getOpportunityFieldMap() {
		Map<String,String> fields = new Map<String,String>();
		for (Opportunity_Snapshot_Field_Mappings__c setting : Opportunity_Snapshot_Field_Mappings__c.getAll().values()) {
        	fields.put(setting.Opportunity_API_Name__c, setting.Opportunity_Snapshot_API_Name__c);
        }
		return fields;
	}

	// Get the SOQL criteria that the Opportunity records must meet in order to be included in the snapshot
	// This is used as the SOQL where clause when querying the Opportunity
	global String getOpportunityCriteria() {
		List<String> criteria = new List<String>();
		for (Opportunity_Snapshot_Criteria__c setting : Opportunity_Snapshot_Criteria__c.getAll().values()) {
        	if (setting.Type__c.equalsIgnoreCase('date')) {
	        	
	        	// Add minimum date criteria if set
	        	if (setting.Min_Date__c != null)
	        		criteria.add(setting.Opportunity_API_Name__c + ' >= '+ formatDateForSoql(setting.Min_Date__c) +'');
	        	
	        	// Add maximum date criteria if set
	        	if (setting.Max_Date__c != null)
	        		criteria.add(setting.Opportunity_API_Name__c + ' <= '+ formatDateForSoql(setting.Max_Date__c) +'');

        	} else if (setting.Type__c.equalsIgnoreCase('picklist')) {

        		// Parse this picklist value and reformat for the SOQL where clause
        		List<String> values = new List<String>();
        		for (String v : setting.Value__c.split(';')) values.add(v.trim());
        		criteria.add(setting.Opportunity_API_Name__c + ' IN (\''+ String.join(values, '\',\'') +'\')');

        	} else {
        		System.debug('Opportunity_Snapshot_Criteria__c.Type__c (valid values are "date" and "picklist")');
        	}
        }
		return String.join(criteria, ' AND ');
	}

	// Returns the given object field value for the SOQL queried record
	// Traverses the related sObjects returned by the query to get the field value
	global Object lookup(sObject obj, String fieldName) {
		sObject currentSObject = obj;
		String fieldPath = fieldName;
		
		while (fieldPath.contains('.')) {
			List<String> pathPartList = fieldPath.split ('[.]', 2);
			
			currentSObject = (sObject) currentSObject.getSobject(pathPartList[0]);
			fieldPath = pathPartList[1];
		}
		
		return currentSObject.get(fieldPath);
	}
    
    global void deleteSnapshotRecords(){
        Date filterDate = Date.today().addMonths(-3);
        
        List<Opportunity_Snapshot__c> snapshotsForReview = new List<Opportunity_Snapshot__c>();
        //Query limit is 40k, but DML limit is 10k
        //snapshotsForReview = [SELECT Id FROM Opportunity_Snapshot__c WHERE CreatedDate <= :filterDate LIMIT 40000];
        snapshotsForReview = [SELECT Id FROM Opportunity_Snapshot__c WHERE CreatedDate <= :filterDate LIMIT 8000];
        
        if(!snapshotsForReview.isEmpty()){
            delete snapshotsForReview;
        }
    }
}