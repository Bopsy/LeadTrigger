@isTest
public with sharing class Peak_MyGroupsControllerTest {

    // Note: For Group Membership, ensure that the type of user matches the type of group. Salesforce prevents
    // Internal Chatter Group (No Network Id) <=> Internal User (Has Standard/Internal Profile)
    // Community Chatter Group (Has Network Id) <=> Community User (Has Community/Partner profile)

    @testSetup
    static void testSetup() {
        Contact testContact = Peak_TestUtils.createTestContact();
    }

    @isTest
    public static void testIsNotInGroup() {
        // Create user
        List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];

        User testUser = Peak_TestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        }catch(Exception e){
            testUser.ContactId = NULL;
            insert testUser;
        }

        // Make sure they're not yet in a group
        System.runAs(testUser){
            System.assertEquals(Peak_MyGroupsController.isInAGroup(),false);
        }


        // Insert a collab group - failing only in HGSE environment on DML setup / non setup between CollaborationGroup and User
        /*CollaborationGroup testGroup = Peak_TestUtils.createChatterGroup(Peak_TestConstants.TEST_GROUPNAME,'Public');
        insert testGroup;

        CollaborationGroupMember testGroupMember = Peak_TestUtils.createGroupMembership(testGroup.Id, testUser.Id);
        insert testGroupMember;

        System.runAs(testUser){
            System.assertEquals(Peak_MyGroupsController.isInAGroup(), true);
        }*/


    }

    @isTest
    public static void testGetFeaturedGroup() {

        // Insert a collab group
        CollaborationGroup testGroup = Peak_TestUtils.createChatterGroup(Peak_TestConstants.TEST_GROUPNAME,'Public');
        insert testGroup;

        // Call action and cast result as Collab Group
        Peak_Response peakResponse = Peak_MyGroupsController.getFeaturedGroup(testGroup.Id);
        CollaborationGroup foundGroup = (CollaborationGroup)peakResponse.results[0];

        // Test that the collab group name is accurate
        System.assertEquals(foundGroup.Name,Peak_TestConstants.TEST_GROUPNAME);
    }

    @isTest
    public static void testGetMyGroups() {
        // Create user
        List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];

        User testUser = Peak_TestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        }catch(Exception e){
            testUser.ContactId = NULL;
            insert testUser;
        }

        System.runAs(testUser){
            System.assertEquals(Peak_MyGroupsController.getMyGroups('3').results.size(),0);
        }
    }


    @isTest
    public static void testGetPrefix() {
        system.assert(Peak_MyGroupsController.getSitePrefix() != null);
    }



}