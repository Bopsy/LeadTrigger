//Created by: Nitish 3/3/2020
//Last Modified: Nitish 3/4/2020
//
//Description: 
//This abstract class is used to define abstract method 
//which overrides by PartnerCertificationTriggerHandler 
//class methods. 
//
//Test class: PartnerCertificationHandlerTest
/**********************************************************/
public class PartnerCertificationHandler {
    
    public static Boolean flag=true;
    public final List<Partner_Certification__c> partnerCertificationList;	//use to store trigger partner certification list
    public final Map<Id,Partner_Certification__c> partnerCertificationOldMap;	//use to store the partner certification old map
    
    //Contructor of the class
    public PartnerCertificationHandler(List<Partner_Certification__c> newList, Map<Id,Partner_Certification__c> oldMap) {
        partnerCertificationList = newList;
        partnerCertificationOldMap = oldMap;
        // check for delete
        if(newList == null) partnerCertificationList = oldMap.values();
        System.debug('partnerCertificationList: '+partnerCertificationList);
    }
    
    //Description: 
    //This method use to Rollup the partnerCertification and
    //updating the account of it.
    public void updateAccountOnPartnerCertification() {
        if(!flag) return;
		try {
       		Set<Id> contactIds = new Set<Id>();
            for(Partner_Certification__c pc: partnerCertificationList){
                if(pc.Contact__c == null) continue;
                contactIds.add(pc.Contact__c);
            }
            if(System.isFuture() || System.isBatch() || System.isQueueable()){
                BuildCertifiedRollup(contactIds);
            }
            else futureBuildCertifiedRollup(contactIds);
            
        }
        catch(Exception e) {
            System.debug('Error in::'+e.getLineNumber()+' and Error is::'+e.getMessage());
        	throw e;
        }
        flag=false;
    }
    
    @testVisible
    @future
    private static void futureBuildCertifiedRollup(Set<Id> contactIds){
        BuildCertifiedRollup(contactIds);
    }
    
    @testVisible
    private static void BuildCertifiedRollup(Set<Id> contactIds){
        
        // retrieve contacts that had partner certification changes and get the accounts
        // they are associated with
        List<Contact> contacts = [Select id,AccountId From Contact Where Id IN :contactIDs];
        Set<Id> accountIds = new Set<Id>();
        for(Contact originalContact: contacts){
            if(originalContact.AccountId != null) accountIds.add(originalContact.AccountId);
        }
        
        // Get the partner certifications for all contacts including those associate with the accounts
        Map<Id,Contact> contactMap = new Map<Id,Contact>([Select id,AccountId From Contact Where AccountId IN :accountIds AND AccountId != null]);
        List<Partner_Certification__c> pcs = [Select id,Contact__c,Training_Track__c From PArtner_Certification__c Where Contact__c IN :contactMap.keySet() AND Certification_Stage__c  = 'Completed'];
        Map<Id,Set<String>> AccountIdToContactIdANDTrainingTrackMap = new Map<Id,Set<String>>();
        for(Partner_Certification__c pc: pcs){
            if(pc.Training_Track__c == null) continue;
            if(!AccountIdToContactIdANDTrainingTrackMap.containsKey(contactMap.get(pc.Contact__c).AccountId)) AccountIdToContactIdANDTrainingTrackMap.put(contactMap.get(pc.Contact__c).AccountId,new Set<String>());
        	AccountIdToContactIdANDTrainingTrackMap.get(contactMap.get(pc.Contact__c).AccountId).add(pc.Contact__c + pc.Training_Track__c);
        }
        
        // update the accounts from mapping
        List<Account> accountsToUpdate = new List<Account>();
        for(Id accountId : accountIds){
            Integer count = 0;
            if(AccountIdToContactIdANDTrainingTrackMap.containsKey(accountId)) count = AccountIdToContactIdANDTrainingTrackMap.get(accountId).size();
            accountsToUpdate.add(new Account(Id=accountId,Build_Certified_Individuals__c=count));
        }
        update accountsToUpdate;
        
        
    }
}