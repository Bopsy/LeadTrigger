// ===================
// Featured User Controller
// ===================
public with sharing class Peak_FeaturedUserController {
	
	// Get user ID for a user
	@AuraEnabled
	public static User getUserInformation(Id userId){
		User featuredUser = [Select Id,Name,MediumPhotoUrl from User where Id = :userId];
		return featuredUser;
	}
	// Get the site prefix (for displaying links/assets)
	@AuraEnabled
	public static String getSitePrefix(){
		return Peak_Utils.getSitePrefix();
	}
}