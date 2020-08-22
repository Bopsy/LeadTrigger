public class CreditCheckRequestServices {
    
    @TestVisible
    private static Boolean bypassTrigger = false;
    public static void afterInsert(List<Credit_Check__c> records){
        if(bypassTrigger) return;
        submitApprovalRequest(filterRecords(records, new Map<Id, Credit_Check__c>()));
    }
    
    public static void afterUpdate(List<Credit_Check__c> records, Map<Id, Credit_Check__c> oldMap){
        if(bypassTrigger) return;
        submitApprovalRequest(filterRecords(records, oldMap)); 
    }
    
    @TestVisible
    private static List<Credit_Check__c> filterRecords(List<Credit_Check__c> newRecords, Map<Id, Credit_Check__c> oldMap){
        List<Credit_Check__c> result = new List<Credit_Check__c>();
        for(Credit_Check__c rec: newRecords){
            Credit_Check__c oldRec = oldMap.get(rec.Id);
            if((oldRec == null && rec.Is_Submitted__c && rec.Credit_Check_Ready_for_Submission_Box__c) || (rec.Is_Submitted__c && rec.Is_Submitted__c != oldRec.Is_Submitted__c && rec.Credit_Check_Ready_for_Submission_Box__c)){
                result.add(rec);
            }
        } 
        return result;
    }
    
    @TestVisible
    private static void submitApprovalRequest(List<Credit_Check__c> records){
        for(Credit_Check__c request: records){
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitting request for approval - Credit Check Request Trigger');
            req.setObjectId(request.Id);
            req.setSubmitterId(request.ownerId);
            Approval.process(req);
        }
    }
}