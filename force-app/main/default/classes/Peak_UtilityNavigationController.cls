// ===================
// Peak Utility Navigation controller
// ===================
public with sharing class Peak_UtilityNavigationController {

	// Determine if guest or logged in
    @AuraEnabled
    public Static Boolean isGuestUser() {
        return Peak_Utils.isGuestUser();
    }
}