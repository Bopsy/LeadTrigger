@RestResource(urlMapping='/Inquiry/*')
global with sharing class InquiryWebService {
    @HttpPost
    global static CampaignMember createInquiry(List<Map<string, string>> inquiryObj) {
        List<Inquiry__mdt> inqMdtLst = [SELECT Marketo_Field__c,Salesforce_Field__c FROM Inquiry__mdt];
        
        Map<string,string> fields = new Map<string,string>();
        for(Inquiry__mdt inqMdt : inqMdtLst) {
            fields.put(inqMdt.Marketo_Field__c, inqMdt.Salesforce_Field__c);
        }

        CampaignMember cm;
        string sfdcId;
        string campaignId;

        Map<string,string> inquiryData = new Map<string,string>();
        for(Map<string,string> inqObjFromAPI : inquiryObj) {
            if(inqObjFromAPI.containsKey('Campaign ID')) {
                campaignId = inqObjFromAPI.get('Campaign ID');
            }
            if(inqObjFromAPI.containsKey('SFDC ID')) {
                sfdcId = inqObjFromAPI.get('SFDC ID');
            }
            for(string key : inqObjFromAPI.keySet()) {
                inquiryData.put(key, inqObjFromAPI.get(key));
            }
        }

        if(campaignId == null || campaignId == '') {
            InquiryWebServiceExceptionClass.createInquiryException(null, new InquiryWebServiceExceptionClass.InquiryWebServiceExceptionContainer('Campaign Id value is missing.'));
            return null;
        }
        if(sfdcId == null || sfdcId == '') {
            InquiryWebServiceExceptionClass.createInquiryException(null, new InquiryWebServiceExceptionClass.InquiryWebServiceExceptionContainer('SFDC Id value is missing.'));
            return null;
        }

        try {
            cm = [SELECT Id
                  FROM CampaignMember
                  WHERE CampaignId = :campaignId AND (LeadId = :sfdcId OR ContactId = :sfdcId)];
        } catch(Exception e) {
            InquiryWebServiceExceptionClass.createInquiryException(e, new InquiryWebServiceExceptionClass.InquiryWebServiceExceptionContainer(e.getMessage()));
            return null;
        }

        // Map particular fields with values sent over via Mkto webhook - use the Inquiry Metadata to add in more field references
        User u;
        String userName;
        String userField;
        boolean isInquiry = true;
        for(string fieldName : inquiryData.keySet()) {
            if(fieldName != 'Assign MQL Owner' && fieldName != 'Campaign ID' && fieldName != 'SFDC ID' && fieldName != 'Is Inquiry') {
                cm.put(fields.get(fieldName), inquiryData.get(fieldName));
            } else if(fieldName == 'Assign MQL Owner' && fieldName != 'Campaign ID' && fieldName != 'SFDC ID' && fieldName != 'Is Inquiry') {
                // the following assignments are for finding the MQL owner (see user SOQL query call below)
                userName = inquiryData.get(fieldName);
                userField = fields.get(fieldName);
            } else if(fieldName != 'Assign MQL Owner' && fieldName != 'Campaign ID' && fieldNAme != 'SFDC ID' && fieldName == 'Is Inquiry') {
                if(inquiryData.get(fieldName).toLowerCase() == 'false') {
                    isInquiry = false;
                }
            }
        }
        
        // the following code assigns the MQL owner by first finding if the owner exists, given that the MQL owner name has been provided in the JSON request body
        if(userName != null && userName != '') {
            try {
                u = [
                    SELECT Id
                    FROM User
                    WHERE Name = :userName
                ];
            } catch(Exception e) {
                InquiryWebServiceExceptionClass.createInquiryException(e, new InquiryWebServiceExceptionClass.InquiryWebServiceExceptionContainer(e.getMessage()));
                return null;
            }
            cm.put(userField, u.Id);
        }

        // if the webhook value sent over is true, then create inquiry upon updating Campaign Member.
        if(isInquiry) {
            cm.Campaign_Member_Updated_Date__c = DateTime.now();
        }

		update cm;
        return null;
    }
   
}