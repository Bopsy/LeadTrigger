public class UserTriggerHandler {
    
    public static void afterUpdate( Map<Id,User> newList , Map<Id,User> oldList){
        List<Account> lAccounts = new List<Account>();
        for (Id uId : newList.keySet()){
            
            if( oldList.get( uId ).Agrees_TOS__c != newList.get( UId ).Agrees_TOS__c
               && newList.get( UId ).Agrees_TOS__c == true){
                   
                   Account a = new Account(id=newList.get( UId ).AccountId, Agrees_TOS__c =true,    
                                           Datetime_Partner_TOS_Signed__c = newList.get( uId ).Datetime_Partner_TOS_Signed__c);
                   lAccounts.add(a);
               }
        }
        if(!lAccounts.isEmpty() && lAccounts.size() > 0){
            update lAccounts;
        }
    }
    
    private without sharing class PullDealRegRecords{
        
        public Map<Id,list<Pass_to_Partner__c>> pullDealRegFromAccount(Set<ID> AccountIds){
            Map<Id,list<Pass_to_Partner__c>> accountIdToListDealReg = new Map<Id,list<Pass_to_Partner__c>>();
            List <Pass_to_Partner__c> passtoPartnerList = [select id,Partner_Account__c from Pass_to_Partner__c where Partner_Account__c IN : AccountIds];
            for(Pass_to_Partner__c dealreg : passtoPartnerList){
                if(dealreg.Partner_Account__c == null) continue;
                if(!accountIdToListDealReg.containsKey(dealreg.Partner_Account__c)) accountIdToListDealReg.put(dealreg.Partner_Account__c, new List<Pass_to_Partner__c>());
                accountIdToListDealReg.get(dealreg.Partner_Account__c).add(dealreg);
            }
            return accountIdToListDealReg;
        }
    }
    
    //Description: this method use to create the sharing
    //for the pass to partner with newly created community user.
    
    Public static void sharepassToPartner(List<User> userList){
    	set <id> userIDSet = new set <id>();
    	for(user objUser : userList){
        	if(objUser.ContactId !=null){
            	userIDSet.add(objUser.id);                
            }            
        }
        futuresharepassToPartner(userIdSet);  
    }
    
    @future
    public static void futuresharepassToPartner(Set<Id> userIds){
        try{
            
            System.debug('trigger userList:::'+userIds);
            
            
            Map<Id,List<User>> accountIdToUserMap = new Map<Id,List<User>>();
            List <User> userNewList = new List <User>();
            userNewList = [select contact.accountid, id from  user where id in : userIds and contact.accountid !=null];
            system.debug('userNewList'+userNewList);
            
            set <id> accountIDSet = new set <id>();
            for(user objUser : userNewList){
                if(objUser.contact.accountid == null) continue;
                if(!accountIdToUserMap.containsKey(objUser.contact.accountid)) accountIdToUserMap.put(objUser.contact.accountid, new List<User>());
                accountIdToUserMap.get(objUser.contact.accountid).add(objUser);
            }
            system.debug('accountIDSet---'+accountIdToUserMap.keySet());
            
            PullDealRegRecords dealRegClass = new PullDealRegRecords();
            Map<Id,List<Pass_to_Partner__c>> accountToListDealReg = dealRegClass.pullDealRegFromAccount(accountIdToUserMap.keySet());
            system.debug('accountToListDealReg'+accountToListDealReg);
            
            List<Pass_to_Partner__share> passToPartnerSharingList=new List<Pass_to_Partner__share>();
            
            for(ID accountId : accountToListDealReg.keySet()){           
                for(Pass_To_Partner__c passToPartner : accountToListDealReg.get(accountId)) {                
                    for(User user:accountIdToUserMap.get(accountId)) {
                    	Pass_to_Partner__share passToPartnerShare=new Pass_to_Partner__share();                    
                        passToPartnerShare.ParentId=passToPartner.Id;
                        passToPartnerShare.AccessLevel='Edit';
                        passToPartnerShare.UserOrGroupId=user.id;                    
                        passToPartnerSharingList.add(passToPartnerShare);
                    }
                }           
            }
            insert passToPartnerSharingList;
            system.debug('passToPartnerSharingList----'+passToPartnerSharingList);
            
        }catch(Exception e){
            system.debug('Error---------'+e.getMessage() + 'at line number--------'+e.getLineNumber());
            throw e;
        }
    } 
}