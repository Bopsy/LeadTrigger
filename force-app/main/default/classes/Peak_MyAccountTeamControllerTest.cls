@isTest
public with sharing class Peak_MyAccountTeamControllerTest {
    Public static User testCommunityUser;
    Public static User testStandardUser;

    @isTest
    public static void setupTestData(){
        //Create Test Community User with Contact and Account
        testCommunityUser = Peak_TestUtils.createStandardUser();
        try {
            insert testCommunityUser;
        }catch(Exception e){
            testCommunityUser.ContactId = NULL;
            insert testCommunityUser;
        }

        testStandardUser = Peak_TestUtils.createGuestUser();
        insert testStandardUser;
    }
    @isTest
    public static void getAccountTeam(){
        setupTestData();
        Peak_Response testResponse = new Peak_Response();

        // Run as user without a contact ID
        system.runAs(testStandardUser) {
            testResponse = Peak_MyAccountTeamController.getAccountTeam();
            system.assertEquals(testResponse.messages[0], Label.X7S_No_ContactId);
        }
    }

    @isTest
    public static void testQueryAccountTeams(){

        List<Contact> testContactList = new List<Contact>();
        testContactList.add(Peak_TestUtils.createTestContact());

        Peak_Response peakResponse = Peak_MyAccountTeamController.queryAccountTeams(testContactList);

        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('AccountTeamMember');
        if (targetType != null){
            System.assertEquals(peakResponse.messages.size(), 0);
        } else {
            System.assertEquals(peakResponse.messages.size(), 1);
        }
    }
}