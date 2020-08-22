public without sharing class SenderIdFormController {
    
    class Country{
        String name;
        
        public Country(String name){
            this.name = name;
        }
    }
    public class FileWrapper{
        public String Body;
        public String Name;
        public String contentType;
    }
    public Boolean isSubmitted {get; set;}
    public Boolean isValidRecord {get; set;}
    public String countries {get; set;}
    public String countryStates {get; set;}
    public SenderIdFormController(){
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
        countries = JSON.serialize(countryList);
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
    public static void saveRecord(String jsonString, String attachmentString){
        Sender_ID_Application__c obj = (Sender_ID_Application__c) JSON.deserialize(jsonString, Sender_ID_Application__c.class);
        insert obj;
        if(attachmentString != 'null'){
            FileWrapper file = (FileWrapper) JSON.deserialize(attachmentString, FileWrapper.class);
            Attachment attachementFile = new Attachment(parentId = obj.Id, Body = EncodingUtil.base64Decode(file.Body), contentType = file.contentType, Name = file.Name);
            insert attachementFile;
        }
        
    }
    
}