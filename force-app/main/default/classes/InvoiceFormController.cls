public without sharing class InvoiceFormController {
    
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
    public InvoiceFormController(){
        String recordId = ApexPages.currentPage().getParameters().get('Id');
        isValidRecord = true;
        isSubmitted = false;
        try{
            Credit_Check__c obj = [SELECT Is_Submitted__c FROM Credit_Check__c WHERE Id =:recordId];
            isSubmitted = obj.Is_Submitted__c;
        }
        catch(QueryException e){
            isValidRecord = false;
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
        Credit_Check__c obj = (Credit_Check__c) JSON.deserialize(jsonString, Credit_Check__c.class);
        if(attachmentString != 'null'){
            FileWrapper file = (FileWrapper) JSON.deserialize(attachmentString, FileWrapper.class);
            Attachment attachementFile = new Attachment(parentId = obj.Id, Body = EncodingUtil.base64Decode(file.Body), contentType = file.contentType, Name = file.Name);
            insert attachementFile;
            obj.Has_Attachment__c = true;
        }
        update obj;
        
        if(obj.Organization_admin_email__c != null){
            List<String> toAddresses = obj.Organization_admin_email__c.split(',');
            Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Invoice_Form_Notification' LIMIT 1].Id;
            //Id orgEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'donotreply@twilio.com' LIMIT 1].Id;
            Id contactId = [SELECT Id FROM Contact WHERE Email = 'ddong@twilio.com' LIMIT 1].Id;
            Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
            emailMsg.setTemplateId(templateId);
            emailMsg.setTargetObjectId(contactId);
            emailMsg.setWhatId(obj.Id);
            emailMsg.setToAddresses(toAddresses);
            //emailMsg.setOrgWideEmailAddressId(orgEmailId);
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {emailMsg};
            Messaging.sendEmail(messages);
        }
    }
    
}