/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_Peak_BaseController
{

    // Get the site prefix (for displaying links/assets)
    @AuraEnabled
    public static String getSitePrefix(){
        return x7s_Adventure_Utils.getSitePrefix();
    }

    // Determine if guest or logged in
    @AuraEnabled
    public Static Boolean isGuestUser() {
        return x7s_Adventure_Utils.isGuestUser();
    }

    // Get current year from server
    @AuraEnabled
    public Static Integer getYear() {
        return x7s_Adventure_Utils.getYear();
    }
}