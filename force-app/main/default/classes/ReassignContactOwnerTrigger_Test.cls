@isTest
public class ReassignContactOwnerTrigger_Test {
	@isTest
    static void testInsert()
    {
        Test.startTest();
        List<Account> accList = TestDataFactory.createAccountList(1);
        insert accList;
        List<Contact> conList =  TestDataFactory.createContactList(1);
        conList[0].AccountId = accList[0].Id;
        insert conList;
        Test.stopTest();
        System.assertEquals(conList[0].OwnerId, accList[0].OwnerId);
    }
    @isTest
    static void testInsert1()
    {
        Test.startTest();
        List<Account> accList = TestDataFactory.createAccountList(1);
        insert accList;
		List<Contact> conList =  TestDataFactory.createContactList(1);
        User partnerUser = [SELECT Id FROM User WHERE id='0051W000005aOPbQAM' LIMIT 1];
        System.runAs(partnerUser){
            
            conList[0].AccountId = '0011W0000255XWkQAM';
            insert conList;
            
        }
        Test.stopTest();
        System.assertEquals(conList[0].OwnerId ==  accList[0].OwnerId,true);
    }
    
}