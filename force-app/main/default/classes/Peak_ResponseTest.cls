@isTest
public with sharing class Peak_ResponseTest {

    @isTest
    public static void testPeakReponse(){
        Peak_Response response = new Peak_Response();

        // Test success flag
        System.assertEquals(response.success,true);

        // Test messages
        response.messages.add(Peak_TestConstants.TEST_MESSAGE);
        System.assertEquals(response.messages[0],Peak_TestConstants.TEST_MESSAGE);

        // Test object list
        Account account = Peak_TestUtils.createTestAccount();
        response.results.add(account);
        System.assertEquals(account,response.results[0]);
    }
}