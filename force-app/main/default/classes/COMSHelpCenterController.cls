public class COMSHelpCenterController {   
    
    @AuraEnabled
    public static List<String> fetchTypeOfHelp(){
        List<String> theTypeOfHelpList = new List<String>();
        List<COMS_RecordType_Map__mdt> COMSRecTypeList = [SELECT Id, Type_of_Help__c FROM COMS_RecordType_Map__mdt];
        for(COMS_RecordType_Map__mdt theCOMS : COMSRecTypeList){
            theTypeOfHelpList.add(theCOMS.Type_of_Help__c);
        }
        
        return theTypeOfHelpList;
    }
    
    @AuraEnabled
    public static recWrapper fetchRecordTypeOfHelp(String selectedTypeofHelp){
        COMS_RecordType_Map__mdt COMSRecTypeList = [SELECT Id, RecordTypeId__c,Description__c FROM COMS_RecordType_Map__mdt WHERE Type_of_Help__c =: selectedTypeofHelp Limit 1];
        recWrapper therec= new recWrapper();
        therec.recID = COMSRecTypeList.RecordTypeId__c;
        therec.recDescription = COMSRecTypeList.Description__c;
        return therec;  
    }
    
    public class recWrapper{
        @AuraEnabled
        public string recID{get;set;}
        @AuraEnabled
        public string recDescription{get;set;}
    }
    
    @AuraEnabled 
    public static String getPicklistValueBasedonRecordType(String objectAPIName, String fieldAPIName, String recordTypeDevId){
        
        list<PicklistValue> picklistValues = new list<PicklistValue>();
        
        if(recordTypeDevId != null){
            
            String method = 'GET';
            String endpoint = String.format('/services/data/v43.0/ui-api/object-info/{0}/picklist-values/{1}/{2}', new String[]{ objectAPIName, recordTypeDevId, fieldAPIName });
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:UI_API_Named_Credentials'+endPoint);
            request.setMethod(method);
            
            If(!Test.isRunningTest()) {
                HTTPResponse response = (new Http()).send(request);
                
                if(response.getStatusCode() == 200){
                    
                    Map<String,Object> root = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                    if(root.containsKey('values')){ 
                        List<Object> picklistVals = (List<Object>)root.get('values');
                        for(Object picklistVal : picklistVals){
                            Map<String,Object> picklistValMap = (Map<String,Object>) picklistVal;
                            picklistValue pickVal = new picklistValue();
                            pickVal.value = (String) picklistValMap.get('value');
                            pickVal.label = (String) picklistValMap.get('label');
                            picklistValues.add(pickVal);
                        }
                    }
                    
                }
            }
            
            else {
                picklistValue pickVal = new picklistValue();
                pickVal.value = 'test';
                pickVal.label = 'test';
                picklistValues.add(pickVal);
                picklistValue pickVal2 = new picklistValue();
                pickVal2.value = 'test2';
                pickVal2.label = 'test2';
                picklistValues.add(pickVal2);
                picklistValue pickVal3 = new picklistValue();
                pickVal3.value = 'test3';
                pickVal3.label = 'test3';
                picklistValues.add(pickVal3);
            }
            
        }
        return JSON.serialize(picklistValues);
    }
    
    public class PicklistValue{
        public String value {get;set;}
        public String label {get;set;}
    }
    
    @AuraEnabled
    public static String queryAccountName(String sobjectType, Id recordId){
        List< COMS_AccountId_Map__mdt> comsAccountIds = [Select SObjectType__c,Field__c From COMS_AccountId_Map__mdt Where SObjectType__c = :sobjectType];
        System.debug(comsAccountIds);
        if(comsAccountIds.size() != 1 ) return null;
        sObject record = Database.query('Select '+comsAccountIds.get(0).Field__c+' From '+sobjectType+' Where Id =:recordId');
        return (Id)record.get(comsAccountIds.get(0).Field__c);
        
    }
}