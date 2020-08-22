/*
 * Copyright (c) 2020. 7Summits Inc.
 */

@isTest
public with sharing class x7s_Adventure_ResponseTest
{

    @isTest
    public static void testPeakReponse(){
        x7s_Adventure_Response response = new x7s_Adventure_Response();

        // Test success flag
        System.assertEquals(response.success,true);

        // Test messages
        response.messages.add(x7s_Adventure_TestConstants.TEST_MESSAGE);
        System.assertEquals(response.messages[0], x7s_Adventure_TestConstants.TEST_MESSAGE);

        // Test object list
        Account account = x7s_Adventure_TestUtils.createTestAccount();
        response.results.add(account);
        System.assertEquals(account,response.results[0]);
    }
}