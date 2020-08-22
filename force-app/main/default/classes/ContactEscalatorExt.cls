public without sharing class ContactEscalatorExt {
    public static Id recordId {get; set;}
    
    public ContactEscalatorExt(ApexPages.standardController stdCtrl){
        recordId = stdCtrl.getId();
    }
    
    public String getAccountList(){
        List<Account> accountList = [SELECT Name, Super_Network_Provider_SID__c, Description, Id, 
                                        (SELECT Name, Title, Email, Id FROM Contacts ORDER BY Name),
                                        (SELECT Id, Provider_SID__c, Notes__c, Account__c, X1st_Contact__c, X1st_Contact__r.Name, X2nd_Contact__c, X2nd_Contact__r.Name, X3rd_Contact__c, X3rd_Contact__r.Name, 
                                         X4th_Contact__c, X4th_Contact__r.Name, X5th_Contact__c, X5th_Contact__r.Name,Type__c FROM Contact_Escalations__r WHERE Account__r.ParentId = null ORDER BY CreatedDate)
                                     FROM Account WHERE Id =: recordId OR ParentId =: recordId OR Parent.ParentId =: recordId];
        return JSON.serialize(accountList);
    }
    
    public String getType(){
        return JSON.serialize(new List<String>{'Commercial', 'Interconnection', 'Messaging Ops', 'Voice Ops'});
    }
    
    @RemoteAction
    public static void saveEscalator(String resultString, String recId){
        List<Contact_Escalation__c> escalations = (List<Contact_Escalation__c>) JSON.deserialize(resultString, List<Contact_Escalation__c>.class);
        List<Contact_Escalation__c> deleteEscalations = [SELECT Id FROM Contact_Escalation__c WHERE Account__c = :recId OR Account__r.ParentId =: recId OR Account__r.Parent.ParentId =: recId];
        
        for(Contact_Escalation__c newRec: escalations){
            for(integer i = deleteEscalations.size() - 1; i >= 0; i--){
                if(newRec.Id == deleteEscalations[i].Id){
                    deleteEscalations.remove(i);
                }
            }
        }
        
        delete deleteEscalations;
        upsert escalations;
    }
}