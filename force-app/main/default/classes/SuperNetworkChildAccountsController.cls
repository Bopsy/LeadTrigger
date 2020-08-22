public without sharing class SuperNetworkChildAccountsController {
     
     public List<Account> childAccounts {get;set;}
     
     public SuperNetworkChildAccountsController(ApexPages.StandardController controller) {
        childAccounts = [SELECT Name, Super_Network_Group_Id__c, Super_Network_Account_Status__c, Super_Network_Provider_SID__c FROM Account WHERE ParentId = :controller.getRecord().Id];
     }
}