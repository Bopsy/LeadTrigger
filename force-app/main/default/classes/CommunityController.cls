public class CommunityController {
    @AuraEnabled
    public static String getBaseUrl() {
        if (Network.getNetworkId() != null) {
            return [SELECT Id, UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()].UrlPathPrefix;
        }
        return '';
    }
    
}