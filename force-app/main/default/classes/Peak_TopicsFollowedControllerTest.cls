@isTest
public class Peak_TopicsFollowedControllerTest {

    public static User testUser;

    @isTest
    public static void testGetMyFollowedTopics(){
        setupData();

        Topic newTopic = new Topic(Name='Test Topic');
        insert newTopic;

        Test.startTest();

        List<Topic> followedTopics = new List<Topic>();
        System.runAs(testUser) {
            followedTopics = Peak_TopicsFollowedController.getMyFollowedTopics(null);
            System.assertEquals(0, followedTopics.size());
        }

        EntitySubscription newSub = new EntitySubscription(
                ParentId=newTopic.Id,
                SubscriberId=testUser.Id
        );
        insert newSub;

        System.runAs(testUser){
            followedTopics = Peak_TopicsFollowedController.getMyFollowedTopics(null);
            System.assertEquals(1, followedTopics.size());
        }

        Test.stopTest();
    }

    public static void setupData(){
        testUser = Peak_TestUtils.createGuestUser();
        insert testUser;
    }

}