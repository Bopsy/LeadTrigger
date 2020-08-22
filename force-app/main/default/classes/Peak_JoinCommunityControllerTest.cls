/**
 * Created by kentheberling on 3/13/17.
 */
@IsTest
private class Peak_JoinCommunityControllerTest {

   @isTest
    public static void testGetUsersWithPublicPhotos() {
        List<User> allUsers = [Select Id, UserPreferencesShowProfilePicToGuestUsers from User where UserPreferencesShowProfilePicToGuestUsers = true limit 5];

        // Mark all users as not allowing guest access to their photo
        for (User thisUser : allUsers){
            thisUser.UserPreferencesShowProfilePicToGuestUsers = false;
        }
        update allUsers;

        // Get User list. This will initially find 0 because there are now no users with public photos. However, the function builds up a list of empty users for us!
        List<User> userList = Peak_JoinCommunityController.getUsersWithPublicPhotos('100');

       system.assertEquals(100,userList.size());
    }

}