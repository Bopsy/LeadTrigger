@isTest
public class x7s_UserController_Test {
    @isTest
    static void changeProceedToVerifyTest()
    {
        Test.startTest();
        User testUser = TestDataFactory.createUser();
        insert testUser;
        boolean proceedCheck = null;
        System.runAs(testUser){
             x7s_UserController.changeProceedToVerify(true);
            proceedCheck =  x7s_UserController.getProceedToVerify();
            
        }
        Test.stopTest();
        System.assertEquals(true, proceedCheck);
       
        
    }

}