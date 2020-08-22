public class OpportunitySIDSelectorController {
    
    @AuraEnabled 
    public static List<Account_SID__c> getAccountSIDList(String sidID, Id recordId) {
        List<Opp_SID_SKU__c> existSKU = [ Select Account_SID__c
                                          FROM Opp_SID_SKU__c 
                                          WHERE Opportunity__c =: recordId];
        List<ID> existSID = new List<ID>();                                   
        for(Opp_SID_SKU__c sku: existSKU) {
            existSID.add(sku.Account_SID__c);
        }                                  

        List<Account_SID__c > sidLst = [Select  name, Account_SID_Created_Date__c, 
                                        NPC_Date_50__c, Software_MRR__c, Total_MRR__c 
                                     	FROM Account_SID__c  
                                     	WHERE  Account_SID__c =:sidID
                                     	AND id NOT IN :existSID
                                     	] ;
        return sidLst;
    }
    
    @AuraEnabled 
    public static boolean checkAccount(String sidID, Id recordId) {
        
        Opportunity opp = [SELECT id, AccountID FROM Opportunity Where id =: recordId];
        

        List<Account_SID__c > sidLst = [Select  name,Account__r.ID
                                     	FROM Account_SID__c  
                                     	WHERE  Account_SID__c  =:sidID
                                     	];
        if(sidLst == NULL || sidLst.isEmpty()) return false;
        if(sidLst[0].Account__r.ID != NULL && sidLst[0].Account__r.ID != opp.AccountID) return true;
        
        return false;
    }
    
    @AuraEnabled
    public static List<Opp_SID_SKU__c> getExistAccountSIDList(Id recordId) {
        
        List<Opp_SID_SKU__c> sidID = [Select id,Account_SID__c, Account_SID__r.Total_MRR__c,Account_SID__r.Software_MRR__c,
                                      		 Account_SID__r.Name, Software_MRR__c, Total_MRR__c, Account_SID__r.Account_SID_Created_Date__c
                                      FROM Opp_SID_SKU__c WHERE Opportunity__c =: recordId];
        return sidID;
    }
    
    @AuraEnabled
    public static void linkSID(Account_SID__c sid, Id recordId) {
        Opp_SID_SKU__c sku = new Opp_SID_SKU__c(Account_SID__c = sid.ID, Opportunity__c = recordId);
        insert sku;
        Opportunity opp = new Opportunity(id = recordId);
        opp.New_Business_Account_SID_Lookup__c = sid.ID;
        database.update(opp, false);
    }

}