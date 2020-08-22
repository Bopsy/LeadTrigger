global class JIRAWebserviceCalloutSyncFields {
    public class FieldObject{
        public AssigneeObject assignee;
        public String duedate;
        public String created;
        public statusObject status;
        public String summary;
        public String description;
    }
    
    public class JIRAObject{
        public FieldObject fields;
        public String[] errorMessages;
        
         public Opportunity_Milestone__c parseOpportunityMilestone(Id objId){
            Opportunity_Milestone__c result = new Opportunity_Milestone__c(Id = objId);
            if(errorMessages != null && !errorMessages.isEmpty()){
                result.JIRA_Status__c = errorMessages[0];
            }
            else{
                result.JIRA_Subject__c = this.fields.summary == null ? 'No summary' : this.fields.summary;
                result.JIRA_Description__c = this.fields.description == null ? 'No description' : this.fields.description;
                //result.Due_Date__c = Date.valueOf(this.fields.duedate);
                result.JIRA_Due_Date__c = this.fields.duedate == null ? null: Date.valueOf(this.fields.duedate);
                result.JIRA_Created_Date__c = this.fields.created == null ? null: Date.valueof(this.fields.created);
                result.JIRA_Assignee__c = this.fields.assignee == null || this.fields.assignee.displayName == null ? 'Unassgined' : this.fields.assignee.displayName;
                result.JIRA_Status__c = this.fields.status.name;
            }
            return result;
        }
    }
    
    public class AssigneeObject{
        public String name;
        public String emailAddress;
        public String displayName;
    }
    
    public class statusObject{
        public String description;
        public String name;
    }
    
    WebService static void batchSyncfields(String JIRA_Key, Id objId){
        String username = 'svc.sfdc-jira';
        String password = 'aDewdA8BL3gFxXbV';
        String jiraURL = 'https://issues.corp.twilio.com';
        
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        
        Blob headerValue = Blob.valueOf(username+':'+password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type','application/json');
        //req.setTimeout(20000);
        
        String endpoint = jiraURL+'/rest/api/2/issue/'+JIRA_Key;
        
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        
        try {
            //Send endpoint to JIRA
            res = http.send(req);
            Opportunity_Milestone__c obj = parseJIRAResponse(res.getBody(), objId);
            system.debug(obj);
            update obj;
        } catch(System.CalloutException e) {
            System.debug('ERROR:' + e);
            System.debug(res.toString());
        }
    }
    
    @future (callout=true)
    WebService static void syncfields(String JIRA_Key, Id objId) {
        //Modify these variables:
        String username = 'svc.sfdc-jira';
        String password = 'aDewdA8BL3gFxXbV';
        String jiraURL = 'https://issues.corp.twilio.com';
        
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        
        Blob headerValue = Blob.valueOf(username+':'+password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type','application/json');
        //req.setTimeout(20000);
        
        String endpoint = jiraURL+'/rest/api/2/issue/'+JIRA_Key;
        
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        
        try {
            //Send endpoint to JIRA
            res = http.send(req);
            Opportunity_Milestone__c obj = parseJIRAResponse(res.getBody(), objId);
            system.debug(obj);
            update obj;
        } catch(System.CalloutException e) {
            System.debug('ERROR:' + e);
            System.debug(res.toString());
        }
    }
    
    public static Opportunity_Milestone__c parseJIRAResponse(String res, Id objId){
        JIRAObject newParseResult = (JIRAObject) JSON.deserialize(res, JIRAObject.class);
        return newParseResult.parseOpportunityMilestone(objId);
        
    }
}