/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  LaunchForecastServices
*
* @description 	  Service class that contains the logic to upsert Launch Plan Forecasts.  
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-09-05
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  2019-09-17 	Fixed a bug due to too many rows returned in the batch.  Line 55.
*
**/
public with sharing class LaunchForecastServices {
    public static void upsertLaunchPlanForecasts(List<Launch_Plan__c> lps){
        Map<String, String> fieldMap = new Map<String, String>();
        Map<Id, List<Forecast_Schedule__c>> fsMap = new Map<Id, List<Forecast_Schedule__c>>();
        Map<String, Id> uniqueIdtoRecIdMap = new Map<String,Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> launchPlanIds = new Set<Id>();
        List<String> fsFieldList = new List<String>();
        List<String> lpfFieldList = new List<String>();
        List<Launch_Plan_Forecast__c> lpfsForUpsert = new List<Launch_Plan_Forecast__c>();
		
        //**
        //Create field mapping of Forecast Schedule to Launch Plan Forecast
        //from a custom setting.
        //**
        fieldMap = getLaunchPlanForecastFieldMap();
        for(String s : fieldMap.keySet()){
            fsFieldList.add(s);
            lpfFieldList.add(fieldMap.get(s));
        }
        
        for(Launch_Plan__c l : lps){
            oppIds.add(l.Opportunity__c);
            launchPlanIds.add(l.Id);
        }
        
        String fsQuery = '';
        fsQuery = getFSQuery(fsFieldList, oppIds);
        for(Forecast_Schedule__c f : Database.query(fsQuery)){
            List<Forecast_Schedule__c> tempFSList = new List<Forecast_Schedule__c>();
            if(fsMap.get(f.Opportunity__c) != null){
                tempFSList = fsMap.get(f.Opportunity__c);
            }
            tempFSList.add(f);
            fsMap.put(f.Opportunity__c, tempFSList);
        }
        
        String lpfQuery = '';
        lpfQuery = getLPFQuery(lpfFieldList, launchPlanIds);
        for(Launch_Plan_Forecast__c lpf : Database.query(lpfQuery)){
            uniqueIdToRecIdMap.put(lpf.Launch_Plan_Forecast_Unique_Id__c, lpf.Id);
        }
        
        //Cycle through Launch Plans and Forecast Schedules to create or update Launch Plan Forecasts.
        for(Launch_Plan__c lp : lps){
            if(fsMap.get(lp.Opportunity__c) == null){
                continue;
            }
            List<Forecast_Schedule__c> tempFSList = new List<Forecast_Schedule__c>();
            tempFSList = fsMap.get(lp.Opportunity__c);
            
            for(Forecast_Schedule__c f : tempFSList){
                String uniqueRecId = '' + lp.Id + f.Id;
                
                //Go through the fieldMap to get the mapped fields from the Forecast Schedule object.
                Launch_Plan_Forecast__c lpf = new Launch_Plan_Forecast__c();
                for(String forecastScheduleFieldName : fieldMap.keySet()){
                    String lpfFieldName = fieldMap.get(forecastScheduleFieldName);
                    lpf.put(lpfFieldName, lookup(f, forecastScheduleFieldName));
                }
                //Put Id if it exists
                if(uniqueIdToRecIdMap.get(uniqueRecId) != null){
                    lpf.Id = uniqueIdToRecIdMap.get(uniqueRecId);
                } else {
                    lpf.Launch_Plan__c = lp.Id;
                	lpf.Forecast_Schedule__c = f.Id;
                }
                
                lpfsForUpsert.add(lpf);
            }
        }
        
        upsert lpfsForUpsert;
    }
	
    //***
	// Build a map of fields for the Forecast Schedule to Launch Plan Forecast
	//***
	private static Map<String,String> getLaunchPlanForecastFieldMap() {
		Map<String,String> fields = new Map<String,String>();
		for (Launch_Plan_Forecast_Mapping__c setting : Launch_Plan_Forecast_Mapping__c.getAll().values()) {
        	fields.put(setting.Source_Field_API_Name__c , setting.Target_Field_API_Name__c);
        }
		return fields;
	}
    
    //***
    // Get the Forecast Schedule records based on the opportunity Ids passed to this method.
    // The fields are based on the list of fields passed to this method.
    //***
    private static String getFSQuery(List<String> fsFields, Set<Id> oppIds){
        String query = '';
        List<Forecast_Schedule__c> fs = new List<Forecast_Schedule__c>();
        List<String> fieldList = new List<String>();
        fieldList.addAll(fsFields);
        fieldList.add('Opportunity__c');
        String fields = string.join(fieldList,',');
		query = 'SELECT ' + fields + ' FROM Forecast_Schedule__c WHERE Opportunity__c IN :oppIds';
		//fs = Database.query(query);
        return query;
    }
    
    //***
    // Get the Launch Plan Forecasts for update.
    //***
    private static String getLPFQuery(List<String> lpfFields, Set<Id> launchPlanIds){
        String query = '';
        List<Launch_Plan_Forecast__c> lpfs = new List<Launch_Plan_Forecast__c>();
        List<String> fieldList = new List<String>();
        fieldList.add('Id');
        fieldList.add('Launch_Plan_Forecast_Unique_Id__c');
        fieldList.addAll(lpfFields);
        String fields = string.join(fieldList,',');
		query = 'SELECT ' + fields + ' FROM Launch_Plan_Forecast__c WHERE Launch_Plan__c IN :launchPlanIds';
        return query;
    }
    
    //***
    // Returns the given object field value for the SOQL queried record
	// Traverses the related sObjects returned by the query to get the field value
	//***
	private static Object lookup(sObject obj, String fieldName) {
		sObject currentSObject = obj;
		String fieldPath = fieldName;
		
		while (fieldPath.contains('.')) {
			List<String> pathPartList = fieldPath.split ('[.]', 2);
			
			currentSObject = (sObject) currentSObject.getSobject(pathPartList[0]);
			fieldPath = pathPartList[1];
		}
		
		return currentSObject.get(fieldPath);
	}
}