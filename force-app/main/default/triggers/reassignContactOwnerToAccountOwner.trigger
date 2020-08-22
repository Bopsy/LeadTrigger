trigger reassignContactOwnerToAccountOwner on Contact ( before insert, before update ) {
    Trigger_Bypass_Settings__c trigBypass = Trigger_Bypass_Settings__c.getInstance(UserInfo.getUserId());
    if(trigBypass != null){
        if(trigBypass.Contact__c == TRUE){ 
            return; 
        }
    }
    User u = [select Id, username, Role_Team__c from User where Id = :UserInfo.getUserId()];

    if(u.Role_Team__c=='Partners'){
            return; 
    }
          
    List<Id> accountIds = new List<Id>();
    Map<Id, Id> accountOwnerIdMap = new Map<Id, Id>();

    // all the accounts whose owner ids to look up
    for ( Contact c : Trigger.new ) {
        accountIds.add( c.accountId );
    }
    
    // look up each account owner id
    for ( Account acct : [ SELECT id, ownerId FROM account WHERE id IN :accountIds ] ) {
        accountOwnerIdMap.put( acct.id, acct.ownerId );
    }
    
    // change contact owner to its account owner
    for ( Contact c : Trigger.new ) {
        if (accountOwnerIdMap.get( c.accountId ) != null ){
            c.ownerId = accountOwnerIdMap.get( c.accountId );
        }
        else {
            System.debug('Error trying to write ' + c.accountId);
        }
    }
}