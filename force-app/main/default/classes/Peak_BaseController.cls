public with sharing class Peak_BaseController {

    // Get the site prefix (for displaying links/assets)
    @AuraEnabled
    public static String getSitePrefix(){
        return Peak_Utils.getSitePrefix();
    }

    // Determine if guest or logged in
    @AuraEnabled
    public Static Boolean isGuestUser() {
        return Peak_Utils.isGuestUser();
    }
}