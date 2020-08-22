/******************************************
//Created By: Gram Bischof
//Last Modified by: Gram bischof {13/02/2020}
//Test Class : LeadLookupControllerTest.apxc
//
*******************************************/
public class LeadLookupController {
    @AuraEnabled public String theContactId {get;set;}
    @AuraEnabled
    public static String getLeadStatus(String RecordId) {
        Lead theLead = [SELECT Name, Email_Domain__c, Status, Email FROM Lead WHERE Id =: RecordId];
        if(theLead!=null){
            return theLead.Status;
        }
        return null;
    }
    
    @AuraEnabled
    public static List<Contact> getContactVal(String RecordId) {
        Lead theLead = [SELECT Name, Email_Domain__c, Email FROM Lead WHERE Id =: RecordId];
        
        list<Contact> theContactlist = [SELECT Id, Name, Email FROM Contact WHERE Email =: theLead.Email limit 1];
        if(theContactlist.size() > 0){
            return theContactlist;
        }
        return null;
    }
    
    
    @AuraEnabled
    public static List<Account> getAccntApprove(String RecordId) {
        List<Account> theAccountList ;
        Lead theLead = [SELECT Name, Email_Domain__c FROM Lead WHERE Id =: RecordId];
        list<Email_Domain__c> theEmailDomain = [SELECT Id, Name, Account__c, Account__r.Name, Approved__c FROM Email_Domain__c Where Name =: theLead.Email_Domain__c AND Approved__c = true];
        if(theEmailDomain.size() > 0){
            theAccountList = [SELECT Id , Name FROM Account WHERE Id=: theEmailDomain[0].Account__r.Id];
            return theAccountList;
        }
        return theAccountList;
    }
    
    @AuraEnabled
    public static List<String> getselectOptions() {
        List<String> lstndustry = new List<String>();
        List<LeadStatus> lstConvertedStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true];
        if(lstConvertedStatus !=null && lstConvertedStatus.size() > 0) {
            for(LeadStatus ls : lstConvertedStatus) {
                lstndustry.add(ls.MasterLabel);
            }
        }
        return lstndustry;
    }  
    
    @AuraEnabled
    public static List<String> getContacttypelist() {
        List<String> thereturnconlist = new List<String>();
        Schema.DescribeFieldResult fieldResult = Contact.Contact_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry s:ple){                
            thereturnconlist.add(s.getLabel());                
        } 
        return thereturnconlist;
    }  
    
    @AuraEnabled
    public static Account InsertAccntData(String AcntName, String recordtype) {
        Account theAccountObj;
        try{
            theAccountObj = new Account();
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordtype).getRecordTypeId();
            theAccountObj.Name = AcntName;
            theAccountObj.RecordTypeId = devRecordTypeId;
            insert theAccountObj;
        }
        catch(Exception e){
            return null;
        }
        return theAccountObj;     
    }
    
    @AuraEnabled
    public static Contact InsertContData(Contact theContactObj, Account Accountid) {
        try{
            theContactObj.AccountId = String.valueOf(Accountid.Id);
            insert theContactObj;
        }
        catch(Exception e){
            system.debug('e'+e);
            return null;
        }
        return theContactObj;     
    }
    
    @AuraEnabled
    public static List <account> fetchAccount(String searchKeyWord, String RecordId) {
        
        String searchKey = searchKeyWord + '%';
        List <Account> returnList = new List <Account> ();
        List <Account> lstOfAccount = new List<Account> ();
        Profile theProfileId = [Select Id, Name FROM Profile WHERE Name =: '**Global AM'];
        List<User> theUserId = [SELECT Id, ProfileId FROM User WHERE Id =: UserInfo.getUserId() AND ProfileId =: theProfileId.Id];
        
        Lead theLead = [SELECT Name, Email_Domain__c FROM Lead WHERE Id =: RecordId];
        list<Email_Domain__c> theEmailDomain = [SELECT Id, Name, Account__c, Account__r.Name FROM Email_Domain__c Where Name =: theLead.Email_Domain__c];
        
        if(theUserId.size() > 0) {
            lstOfAccount = [SELECT Id, Name FROM Account WHERE Name LIKE: searchKey AND OwnerId =: theUserId[0].Id order by createdDate DESC limit 5];  
        }
        else if(theEmailDomain.size() > 0){
            lstOfAccount = [SELECT Id , Name FROM Account WHERE Name LIKE: searchKey AND Id=: theEmailDomain[0].Account__r.Id order by createdDate DESC limit 5];
        }
        else{
            lstOfAccount = [SELECT Id, Name FROM account WHERE Name LIKE: searchKey AND RecordType.Name IN ('FY 16 Account Record Type', 'Partner') order by createdDate DESC limit 5];
        }
        for (Account acc: lstOfAccount) {
            returnList.add(acc);
        }
        return returnList;
    }
    
    @AuraEnabled
    public static List <contact> fetchContact(String searchKeyWord , String selectedAcnt) {
        String searchKey = searchKeyWord + '%';
        List <contact> returnList = new List <contact> ();
        List <contact> lstOfcontact = [SELECT Id, Name FROM contact WHERE Name LIKE: searchKey AND AccountId =: selectedAcnt limit 5];
        for (contact con: lstOfcontact) {
            returnList.add(con);
        }
        return returnList;
    }
    
    @AuraEnabled
    public static LeadLookupController ConvertLead(String recordId , String selectedCont , String selectedAcnt , String leadstatus) {
        
        /* if(String.isBlank(selectedCont) || (selectedCont == null || selectedCont == '')){
			AuraHandledException e = new AuraHandledException('Lead cannot be converted');
			e.setMessage('Lead cannot be converted');
			throw e;  
			}else{*/
        Lead theLeadConvert = [SELECT Id, Name FROM Lead WHERE Id =: recordId];
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(theLeadConvert.id);
        if(String.isNotEmpty(selectedCont)){
            lc.setContactId(selectedCont); 
        }
        lc.setAccountId(selectedAcnt);
        //LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(leadstatus);
        Database.LeadConvertResult lcr = Database.convertLead(lc); 
        system.debug('lcr==>'+lcr);
        LeadLookupController theLeadLookup = new LeadLookupController();
        theLeadLookup.theContactId = lcr.getContactId();
        system.debug('theLeadLookup=>'+theLeadLookup);
        return theLeadLookup;
        //  }
    }
}