public with sharing class Peak_JoinCommunityController {

    @AuraEnabled
    public static List<User> getUsersWithPublicPhotos(String desiredResultsCount){
        Integer limitInteger = Integer.valueof(desiredResultsCount); // https://developer.salesforce.com/forums/?id=906F00000005FxqIAE
        List<User> userList = [Select Id,SmallPhotoUrl,FullPhotoUrl,UserPreferencesShowProfilePicToGuestUsers from User where UserPreferencesShowProfilePicToGuestUsers = true limit: limitInteger];

        // If we did not find enough users, just add new blank users to the list to fill the slots
        while (userList.size() < limitInteger){
            User newUser = new User();
            userList.add(newUser);
        }

        return userList;
    }
}