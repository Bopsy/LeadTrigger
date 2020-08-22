public with sharing class Peak_FeaturedGroupsController {

    // Get a featured group by ID
    @AuraEnabled
    public static Peak_Response getFeaturedGroups(String groupIdsString) {
        Peak_Response response = new Peak_Response();

        List<String> idsList = groupIdsString.split(',');

        if (!Peak_Utils.isNullOrEmpty(idsList)){
            List<CollaborationGroup> featuredGroups = [
                    select BannerPhotoUrl, Description, FullPhotoUrl, Id, MemberCount, Name, SmallPhotoUrl
                    from CollaborationGroup
                    where Id in :idsList
            ];

            if (!Peak_Utils.isNullOrEmpty(featuredGroups)){
                response.results = featuredGroups;
            }
        }

        return response;

    }


    @AuraEnabled
    public static String getSitePrefix(){
        return Peak_Utils.getSitePrefix();
    }
}