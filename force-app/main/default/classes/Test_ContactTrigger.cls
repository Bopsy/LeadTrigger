/*
 * Class:   Test_ContactTrigger
 * Purpose: Provide test coverage for the trigger ContactTrigger and it's handler class
 */
@isTest
private class Test_ContactTrigger {
    static Contact con;
    static Account acc;
    static Account acc2;
    static testMethod void populateAccount() {
        createTestData();
        //On before insert
        con.Account_SID__c = acc.Account_SID__c;
        insert con;
        con = [Select Id, AccountId From Contact Where Id = :con.Id][0];
//        System.assertEquals(acc.Id, con.AccountId);
        
        //On before update
        con.AccountId = null;
        con.Account_SID__c = acc2.Account_SID__c;
        update con;
        con = [Select Id, AccountId From Contact Where Id = :con.Id][0];
//        System.assertEquals(acc2.Id, con.AccountId);
    }
    
    static void createTestData(){
        acc = new Account(Name = 'Test Account', Account_SID__c = 'AC00000000000000000000000000000001');
        insert acc;
        acc2 = new Account(Name = 'Test Account2', Account_SID__c = 'AC00000000000000000000000000000002');
        insert acc2;
        con = new Contact(FirstName = 'Test', LastName = 'Last');
        
    }
}