/** * * * * * * * * * * * *
* 
*  Class Name          : AccountTriggerHandler
*  Purpose             : Handler for AccountTrigger
*  Author              : Dhana Prasad
*  Created Date        : 31-Mar-2020
*  Modified By and Date :   
* 
** * * * * * * * * * * * */
public with sharing class AccountTriggerHandler {
    /*
* Method Name : afterUpdate
* Description : works on trigger after update
* Created on and by : 31 -03-2020 Dhana Prasad
* Modified on and by :
*/
    public static void afterUpdate(List<Account> newList, Map<Id,Account> oldMap){
        checkIsPartnerChanged(newList, oldMap);
    }
    /*
* Method Name : checkIsPartnerChanged
* Description : checks if partner is changed nad retrives the latest adventure of account which has same partner type
* Created on and by : 31 -03-2020 Dhana Prasad
* Modified on and by :
*/
    public static void checkIsPartnerChanged(List<Account> newList, Map<Id,Account> oldMap){
        Set<Id> accIdSet = new Set<Id>();
        Map<Id,Id> mapOfAccountIdAndAdventureId = new Map<Id,Id>();
        Map<String,Id> mapOfIdAndPartnerType = new Map<String,Id>();
        for(Account acc: newList){
            if(acc.IsPartner == true && oldMap.get(acc.Id).IsPartner == false && acc.Partner_Type__c != null){
                mapOfIdAndPartnerType.put(acc.Partner_Type__c,acc.Id);
            }
        }
        List<Adventure__c> recentAdventure = null;
        if(mapOfIdAndPartnerType.isEmpty()) return; 
        else{
            recentAdventure =  [SELECT Id, Account__c,Partner_Type__c, CreatedDate  FROM Adventure__c 
                                WHERE Partner_Type__c IN: mapOfIdAndPartnerType.keySet() 
                                AND Template__c =true
                                ORDER BY CreatedDate DESC
                                LIMIT 1]; 
        }
        
        if(recentAdventure !=null){
            for(Adventure__c adventure : recentAdventure){
                mapOfAccountIdAndAdventureId.put(adventure.Id,mapOfIdAndPartnerType.get(adventure.Partner_Type__c));
            }
        }
        system.debug('mapOfAccountIdAndAdventureId'+mapOfAccountIdAndAdventureId);
        if(mapOfAccountIdAndAdventureId.size()>0){
            for(Id advId : mapOfAccountIdAndAdventureId.keySet())
            {
                Id  test =  x7s_Adventure_CloneProjectAssignment.cloneAdventureWithAccount(advId,mapOfAccountIdAndAdventureId.get(advId));
            }
        }
        
    }
    
}