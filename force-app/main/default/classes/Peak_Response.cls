// ===================
// Custom Response wrapper
// ===================
public virtual with sharing class Peak_Response {
    @AuraEnabled public Boolean success{get;set;} // success or failure
    @AuraEnabled public List<String> messages{get;set;}  // messages to display
    @AuraEnabled public List<SObject> results{get;set;} // results to iterate over - use this when querying SOjbects directoy
    @AuraEnabled public List<Peak_ContentObject> peakResults{get;set;} // custom results to iterate over - use this when creating a list of custom wrapper classes

    public Peak_Response(){
        success = true;
        messages = new List<String>();
        results = new List<SObject>();
        peakResults = new List<Peak_ContentObject>();
    }
}