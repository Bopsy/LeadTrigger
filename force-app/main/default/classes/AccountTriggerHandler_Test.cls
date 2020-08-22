@isTest
public class AccountTriggerHandler_Test {
	@isTest
    public static void test_afterUpdate()
    {
        //Create test adventure
        List<Account> accList  = TestDataFactory.createAccountList(1);
        accList[0].Partner_Type__c ='Technology';
        insert accList;        


        //Create test adventure
        Adventure__c testAdventure = new Adventure__c(Name = x7s_Adventure_CloneTestConstants.TEST_ADVENTURE_NAME, Title__c = x7s_Adventure_CloneTestConstants.TEST_ADVENTURE_NAME,
        Account__c= accList[0].Id,Template__c =x7s_Adventure_CloneTestConstants.TEST_TEMPLATE_NAME ,Partner_Type__c ='Technology');
        insert testAdventure;
        Test.startTest();
        accList[0].IsPartner = true;
        update accList;
        Test.stopTest();
        System.assertEquals(accList[0].IsPartner, true);
        
    }
}