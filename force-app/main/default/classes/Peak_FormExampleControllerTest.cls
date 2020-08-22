@isTest
public with sharing class Peak_FormExampleControllerTest {

    @isTest
    public static void testHandleResponse(){
        system.assertEquals(Peak_FormExampleController.handleSubmit('Hello').success, false);
        system.assertEquals(Peak_FormExampleController.handleSubmit('asdf').success, false);
    }

}