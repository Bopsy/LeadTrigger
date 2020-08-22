@isTest
public class UserTriggerTest {
    
    @isTest(SeeAllData=true)
    public static void testUpdateTOSTest(){
        User u = [select id from User where usertype='PowerPartner' and 
                  isActive=true and accountId != null and Agrees_TOS__c =false limit 1];
        if(u != null){
            system.runAs(u) {
                u.Agrees_TOS__c = true;
                update u;
            }
        }
    }
    
    public static testmethod void testInsertingNewDealReg(){
        
        List<Account> accountList=new List<Account>();
        for(Integer i=1;i<=3;i++)
        {
            Account objAccount = new Account();
            objAccount.name = 'testAccount'+i;
            objAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            accountList.add(objAccount);
        }
        insert accountList;

		for(Account objAccount: accountList) objAccount.IsPartner =true;
        update accountList;
        
        List<Contact> partnerContacts = new List<Contact>();
        Integer numContact = 0;
        for(Account acct: accountList){
            partnerContacts.add(new Contact(AccountId=acct.Id,firstName='Test',lastName='Person'+numContact,Preferred_Email__c=acct.Id + '@testaccount.com'));
        	numContact++;
        }
        insert partnerContacts;
        
        List<User> newPartnerUsers = new List<User>();
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%**Partner Community User Login**%' Limit 1];
        for(Contact newPartner: partnerContacts){
            newPartnerUsers.add( new User(
            Username =System.now().millisecond()+'Bopsy'+newPartner.LastName+'@gmail.com',
            ContactId = newPartner.Id,
            ProfileId = portalProfile.Id,
            Alias = 'test123',
            Email = newPartner.Preferred_Email__c,
            EmailEncodingKey = 'UTF-8',
            LastName = 'McTesty'+newPartner.LastName,
            CommunityNickname = 'test12345'+newPartner.LastName,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        	));
        }
        insert newPartnerUsers;
        
        Map<Id,List<Contact>> accountIdToContactMap = new Map<Id,List<Contact>>();
        for(Contact cont: partnerContacts){
            if(!accountIdToContactMap.containsKey(cont.AccountId)) accountIdToContactMap.put(cont.AccountId,new List<Contact>());
            accountIdToContactMap.get(cont.AccountId).add(cont);
        }
        System.assertEquals(3, accountIdToContactMap.size());
        for(List<Contact> contacts: accountIdToContactMap.values()) System.assertEquals(1,contacts.size());
        
        Map<Id,List<User>> contactIdToUserMap = new Map<Id,List<User>>();
        for(User partner: newPartnerUsers){
            if(!contactIdToUserMap.containsKey(partner.contactId)) contactIdToUserMap.put(partner.contactId,new List<User>());
            contactIdToUserMap.get(partner.contactId).add(partner);
        }
        System.assertEquals(3, contactIdToUserMap.size());
        for(List<User> partners: contactIdToUserMap.values()) System.assertEquals(1,partners.size());
        
        
        
        Map<Id,Pass_to_Partner__c> passToPartnerMap = new Map<Id,Pass_to_Partner__c>();
        
        Test.startTest();
        	List<Pass_to_Partner__c> passToPartnerList = new List<Pass_to_Partner__c>();
            for(Account acct : accountList){
                Pass_to_Partner__c objpassToPartner = new Pass_to_Partner__c();
                objpassToPartner.name = 'test';
                objpassToPartner.Launch_Date__c = date.today();
                objpassToPartner.Partner_Account__c = acct.id;
                objpassToPartner.RecordTypeId = Schema.SObjectType.Pass_to_Partner__c.getRecordTypeInfosByName().get('Deal Registration').getRecordTypeId();
                passToPartnerList.add(objpassToPartner);
            }
            insert passToPartnerList;
        	passToPartnerMap = new Map<Id,Pass_to_Partner__c>(passToPartnerList);
        Test.stopTest();
        
        List<Pass_to_Partner__share> shareRecords = [Select id,UserOrGroupId From Pass_to_Partner__share Where ParentID IN :passToPartnerMap.keySet() AND UserOrGroupId IN :newPartnerUsers];
    	Map<Id,List<Pass_To_Partner__share>> userIdToPartnerMap = new Map<Id,List<Pass_To_Partner__share>>();
        for(Pass_To_Partner__share share: shareRecords){
            if(!userIdToPartnerMap.containsKey(share.UserOrGroupId)) userIdToPartnerMap.put(share.UserOrGroupId, new List<Pass_To_Partner__share>());
            userIdToPartnerMap.get(share.UserOrGroupId).add(share);
        }
        for(Id userId: userIdToPartnerMap.keyset()){
            System.assertEquals(1, userIdToPartnerMap.get(userId).size());
        }
    } 
}