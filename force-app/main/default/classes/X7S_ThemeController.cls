global with sharing class X7S_ThemeController {
    /*
    @Name		  :  getSiteName
    @Description  :  Method to fetch the Network Name (Community Name) of the user's community so we can use it in our theme.
    */
    @AuraEnabled
    global static String getSiteName() {
        String networkId = System.Network.getNetworkId();

        if (String.isNotBlank(networkId))
        {
            Network communityNetwork = [ SELECT Id, Name FROM Network WHERE ID = :networkId ]; return communityNetwork != null ? communityNetwork.Name : '';
        }

        return '';
    }
}