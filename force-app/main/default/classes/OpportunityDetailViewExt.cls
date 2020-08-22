public without sharing class OpportunityDetailViewExt{
    
    
    class Country{
        String name;
        
        public Country(String name){
            this.name = name;
        }
    }
    
    public static List<String> fieldNames = new List<String>{'MSA_Required__c', 'Solution_Review__c', 'Solution_Identified_with_Customer__c', 'POC__c',
                                                             'Technical_Win__c', 'Documented_Decision_Making_Process__c', 'Project_Team_Identified__c',
                                                             'Test_Traffic_Live__c', 'Commercial_Traffic_Live__c', 'Primary_Competitor__c',
                                                             'Do_we_have_a_credible_champion__c','Key_decision_makers_on_board__c',
                                                             'Secondary_Competitor__c', 'Competitive_Takeout__c', 'Competitor_s_Champion_s_Identified__c',
                                                             'ROI_Presented_to_Executive_Buyer__c', 'Customer_risks_for_not_choosing_Twilio__c', 
                                                             'Buying_Process__c', 'Twilio_Resources_Involved__c', 'Contract_Type__c', 
                                                             'Which_Twilio_Execs_aligned_with_Customer__c', 'What_is_the_Business_Case__c', 
                                                             'Agreement_1__c', 'Agreement_2__c', 'Agreement_3__c','Project_Funding__c', 'Is_Budget_Adequate_for_this_Use_Case__c','Meetings_completed_w_key_decision_makers__c'};
                                                             
    public static Set<String> queryFields = new Set<String>{'POC__c', 'Solution_Identified_with_Customer__c', 'Solution_Review__c', 'MSA_Required__c', 'What_are_the_Use_Case_Metrics__c', 'AccountId','Meetings_completed_w_key_decision_makers__c','Criteria_to_Select_Vendor__c', 'Business_Impact__c', 'Personal_Impact__c', 'Customer_risks_for_not_choosing_Twilio__c',
                                                                'Key_decision_makers_on_board__c', 'Executive_Buyer__r.FirstName', 'Executive_Buyer__r.LastName', 'Executive_Buyer__r.Id',
                                                                'How_might_we_quantify_the_risks__c', 'Buying_Process__c', 'ROI_Presented_to_Executive_Buyer__c','ProjectedVolume__c',
                                                                'Description_of_Volume_Estimate__c', 'Solution_Identification_Overview__c', 'Project_Funding__c', 'Is_Budget_Adequate_for_this_Use_Case__c',
                                                                'Technical_Win__c', 'Top_Risks__c', 'Documented_Decision_Making_Process__c', 'Project_Team_Identified__c',
                                                                'Number_of_Technical_Reviews__c', 'Number_of_Customer_Resources_Involved__c', 'To_Whom_was_Sponsor_Letter_Sent__r.LastName',
                                                                'To_Whom_was_Sponsor_Letter_Sent__r.FirstName', 'To_Whom_was_Sponsor_Letter_Sent__r.Id',
                                                                'Test_Traffic_Live__c,Commercial_Traffic_Live__c','Contract_Type__c,Agreement_1__c','Agreement_1_Signer__r.LastName',
                                                                'Agreement_1_Signer__r.FirstName', 'Agreement_1_Signer__r.Id', 'Agreement_2__c,Agreement_2_Signer__r.LastName',
                                                                'Agreement_2_Signer__r.FirstName', 'Agreement_2_Signer__r.Id', 'Agreement_3__c,Agreement_3_Signer__r.LastName',
                                                                'Agreement_3_Signer__r.FirstName', 'Agreement_3_Signer__r.Id', 'Use_Case_Requirements__c', 'Technical_Pain__c',
                                                                'Business_Pain__c','Describe_Existing__c', 'Compelling_Event_Details__c', 'Primary_Competitor__c',
                                                                'Secondary_Competitor__c', 'Competitive_Takeout__c', 'Competitor_s_Champion_s_Identified__c',
                                                                'Technical_Champion__r.LastName', 'Technical_Champion__r.FirstName', 'Technical_Champion__r.Id',
                                                                'Project_Sponsor__r.LastName', 'Project_Sponsor__r.FirstName', 'Project_Sponsor__r.Id',
                                                                'Do_we_have_a_credible_champion__c', 'Customer_s_Executive_Team_Member__r.LastName',
                                                                'Customer_s_Executive_Team_Member__r.FirstName', 'Customer_s_Executive_Team_Member__r.Id',
                                                                'Which_Twilio_Execs_aligned_with_Customer__c', 'Twilio_Resources_Involved__c', 'What_is_the_Business_Case__c',
                                                                'Project_Timeframe__c', 'Decision_Timeline__c', 'Agreement_1_Signature_Due__c', 'Agreement_2_Signature_Due__c',
                                                                'Agreement_3_Signature_Due__c', 'Account.Name'};
     
    public static Map<String, List<String>> fieldNameToValuesMap {
        get{
            if(fieldNameToValuesMap == null){
                fieldNameToValuesMap = new Map<String, List<String>>();
                Map<String, Schema.SObjectField> oppFieldMap = Opportunity.SObjectType.getDescribe().fields.getMap();
                for(String fieldName: fieldNames){
                    List<String> values = new List<String>();
                    List<Schema.PicklistEntry> picklistValues = oppFieldMap.get(fieldName).getDescribe().getPickListValues();
                    
                    for(Schema.PicklistEntry entry: picklistValues){
                        values.add(entry.getValue());
                    }
                    fieldNameToValuesMap.put(fieldName, values);
                }
            }
            return fieldNameToValuesMap;
        }
        private set;
    }
    
    public static String fieldMapString {
        get{
            if(fieldMapString == null){
                fieldMapString = JSON.serialize(fieldNameToValuesMap);
            }
            return fieldMapString;
        }
        private set;
    }
    public static String contacts{
        get{
            if(contacts == null && accountId != null){
                contacts = JSON.serialize([SELECT LastName, FirstName FROM Contact WHERE AccountId =: accountId ORDER BY LastName]);
            }
            return contacts;
        }
    }
    
    public Boolean showPage {get; set;}
    public String countries {get; set;}
    public String countryStates {get; set;}
    
    public OpportunityDetailViewExt(ApexPages.standardController stdCtrl){
        Id recordId = stdCtrl.getId();
        String queryString = 'SELECT ' + getAllFields('Opportunity').get('Opportunity') + ',RecordTypeId FROM Opportunity WHERE Id =: recordId';
        Opportunity opp = (Opportunity) Database.query(queryString);
        accountId = opp.AccountId;
        oppObject = JSON.serialize(opp);
        showPage = false;
        for(MEDDPICC_Setting__c setting: MEDDPICC_Setting__c.getAll().values()){
            if(setting.RecordTypeId__c != null){
                for(String idValue: setting.RecordTypeId__c.split(',')){
                    if(idValue.trim().containsIgnoreCase(opp.RecordTypeId)){
                        showPage = true;
                        break;
                    }
                }
            }
        }
        List<Country> countryList = new List<Country>();
        Set<String> countrySet = new Set<String>{'[Unknown]', 'United States', 'Canada'};
        countryList.add(new Country('United States'));
        countryList.add(new Country('Canada'));
        Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            if(!countrySet.contains(f.getLabel())){
                countryList.add(new Country(f.getLabel()));
                countrySet.add(f.getLabel());
            }
        }
        countries = JSON.serialize(countrySet);
        Map<String, List<String>> countryToStates = new Map<String, List<String>>();
        for(States_Dependent_List__c setting: States_Dependent_List__c.getAll().values()){
            List<String> states = countryToStates.get(setting.Country__c);
            if(states != null){
                states.add(setting.State__c);
            }
            else{
                states = new List<String>{setting.State__c};
                countryToStates.put(setting.Country__c, states);
            }
        }
        for(List<String> states: countryToStates.values()){
            states.sort();
        }
        countryStates = JSON.serialize(countryToStates);
    }
    
    @RemoteAction
    public static Id createContact(String contactString){
        Contact newContact = (Contact) JSON.deserialize(contactString, Contact.class);
        insert newContact;
        return newContact.Id;
    }
    @RemoteAction
    public static void load(){
    }
    @RemoteAction
    public static void saveData(String oppString, Id oppId){
        Opportunity updateOpp = (Opportunity) JSON.deserialize(oppString, Opportunity.class);
        updateOpp.Id = oppId;
        for(String keyString: fieldNames){
            if(updateOpp.get(keyString) != null && String.valueOf(updateOpp.get(keyString)) == 'None'){
                updateOpp.put(keyString, null);
            }
        }
        update updateOpp;
    }
    
    /*@RemoteAction
    public static String getRequeryOpp(Id recordId){
        String queryString = 'SELECT ' + getAllFields('Opportunity').get('Opportunity') + ' FROM Opportunity WHERE Id =: recordId';
        Opportunity opp = (Opportunity) Database.query(queryString);
        oppObject = JSON.serialize(opp);
        return oppObject;
    }*/
    
    public static String oppObject {get; set;}
    public static Id accountId {get; set;}
    
    public static Map<String, String> getAllFields(String sobjectname){
  
    	String allfields='';
  
    	for(String fieldname : queryFields)
      		allfields += fieldname+',';
  
    	allfields = allfields.subString(0,allfields.length()-1);
    
    	return new Map<String, String>{sobjectname => allfields};
  	}
}