public with sharing class Peak_MyGroupsController {
    // Determine if user is in a group
    @AuraEnabled
    public static boolean isInAGroup() {
        // Find group membership records for current user
        List<CollaborationGroupMember> groupMembers = [
                select MemberId
                from CollaborationGroupMember
                where MemberId = :UserInfo.getUserId()
        ];

        // Hey, found one, return that we are in a group
        if (groupMembers.size() > 0) {
            return true;
        }
        return false;

    }

    // Get a featured group by ID
    @AuraEnabled
    public static Peak_Response getFeaturedGroup(String groupIdString) {
        Peak_Response response = new Peak_Response();

        if (!String.isEmpty(groupIdString)){
            CollaborationGroup featuredGroup = [
                    select BannerPhotoUrl, Description, FullPhotoUrl, Id, MemberCount, Name, SmallPhotoUrl
                    from CollaborationGroup
                    where Id = :groupIdString
            ];

            if (featuredGroup != null){
                response.results.add(featuredGroup);
            }
        }

        return response;

    }

    // Get My Groups
    @AuraEnabled
    public static Peak_Response getMyGroups(String numResultsString) {
        Peak_Response response = new Peak_Response();
        Integer queryLimit = Integer.valueOf(numResultsString); // https://developer.salesforce.com/forums/?id=906F00000005FxqIAE

        // Get group Ids for current user
        List<Id> groupIds = new List<Id>();
        for (CollaborationGroupMember groupMembership: [select CollaborationGroupId from CollaborationGroupMember where MemberId = :UserInfo.getUserId() and NetworkId != null]){
            groupIds.add(groupMembership.CollaborationGroupId);
        }

        // And now query those groups with the IDs

        List<CollaborationGroup> myGroups = [select BannerPhotoUrl, Description, FullPhotoUrl, Id,MemberCount, Name, SmallPhotoUrl
        from CollaborationGroup
        where Id In :groupIds
        limit :queryLimit];

        response.results = myGroups;

        return response;

    }

    @AuraEnabled
    public static String getSitePrefix(){
        return Peak_Utils.getSitePrefix();
    }
}