public with sharing class OpportunitySCSelectorController {
    
    @AuraEnabled 
    public static Boolean checkSID(String scID, Id recordId) {
        Opportunity opp = [SELECT AccountID FROM Opportunity Where id =: recordId LIMIT 1];
        List<Account_SID__c> sidLst = [Select Account__c From Account_SID__c where Account_SID__c =: scID];
        if(!sidLst.isEmpty() && sidLst[0].Account__c != opp.AccountID) return true;
        return false;
    }
     
    @AuraEnabled 
    public static List<Short_Code__c> getShortCodeList(String scID, Id recordId) {
		Opportunity opp = [SELECT AccountID FROM Opportunity Where id =: recordId LIMIT 1];
        List<String> sidStringLst = new List<String>();
        if(opp.AccountID != NULL){
            List<Account_SID__c> sidLst = [Select Account_SID__c From Account_SID__c where Account__c =: opp.AccountID];
            for(Account_SID__c sid: sidLst) {
                sidStringLst.add(sid.Account_SID__c);
            }
        }
        
        List<Short_Code__c> scLst = [Select id, Account_SID__c, Application_Submitted_Date__c,Application_Created_Date__c,
                                     		OwnerUser_Email_Address__c, name, Owner.Name, Account__c, Application_Status__c 
                                     FROM Short_Code__c 
                                     WHERE  (Name =:scId OR Account_SID__c =:scId OR OwnerUser_Email_Address__c =:scId)
                                     AND Opportunity__c !=: recordId
                                     AND Account_SID__c IN:sidStringLst] ;
        
        
        return scLst;
    }
    
    @AuraEnabled
    public static List<Short_Code__c> getExistShortCodeList(Id recordId) {

        List<Short_Code__c> scLst = [Select id, Account_SID__c, Application_Submitted_Date__c,Application_Created_Date__c,
                                     		OwnerUser_Email_Address__c, Opportunity__c, name, Owner.Name, Application_Status__c 
                                     FROM Short_Code__c WHERE Opportunity__c =: recordId];
        return scLst;
    }
    
    @AuraEnabled
    public static void linkOppty(Short_Code__c sc, Id recordId) {
        sc.Opportunity__c = recordId;
        Opportunity oppty = new Opportunity(Id = recordId);
        oppty.Short_Code__c = sc.Id;
        database.update(sc,false);
        database.update(oppty,false);
    }
}