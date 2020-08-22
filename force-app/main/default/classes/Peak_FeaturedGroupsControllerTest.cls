@isTest
public with sharing class Peak_FeaturedGroupsControllerTest {

    // Note: For Group Membership, ensure that the type of user matches the type of group. Salesforce prevents
    // Internal Chatter Group (No Network Id) <=> Internal User (Has Standard/Internal Profile)
    // Community Chatter Group (Has Network Id) <=> Community User (Has Community/Partner profile)


    @isTest
    public static void testGetFeaturedGroups() {

        // Insert a collab group
        CollaborationGroup testGroup = Peak_TestUtils.createChatterGroup(Peak_TestConstants.TEST_GROUPNAME,'Public');
        insert testGroup;


        // Call action and cast result as Collab Group
        Peak_Response peakResponse = Peak_FeaturedGroupsController.getFeaturedGroups((String)testGroup.Id);
        CollaborationGroup foundGroup = (CollaborationGroup)peakResponse.results[0];

        // Test that the collab group name is accurate
        System.assertEquals(foundGroup.Name,Peak_TestConstants.TEST_GROUPNAME);
    }


    @isTest
    public static void testGetPrefix() {
        system.assert(Peak_FeaturedGroupsController.getSitePrefix() != null);
    }



}