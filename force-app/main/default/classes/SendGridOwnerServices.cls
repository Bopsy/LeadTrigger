public without sharing class SendGridOwnerServices {
    public static Map<String, String> territoryToUserMap{
        get{
            if(territoryToUserMap == null){
                territoryToUserMap = new Map<String, String>();
                Map<String, String> territoryToRoleMap = new Map<String, String>();
                for(Account_Quarterback_Routing__c rule: [SELECT SendGrid_User_Role__c, Sales_Team__c FROM Account_Quarterback_Routing__c WHERE SendGrid_Assignment__c = true AND SendGrid_User_Role__c != null]){
                    String uniqueKey = rule.Sales_Team__c;
                    territoryToRoleMap.put(uniqueKey, rule.SendGrid_User_Role__c);
                }
                Map<String, String> roleToUserMap = new Map<String, String>();
                for(User aUser: [SELECT Id, UserRole.Name FROM User WHERE UserRole.Name =: territoryToRoleMap.values()]){
                    roleToUserMap.put(aUser.UserRole.Name, aUser.Id);
                }
                for(String keyString: territoryToRoleMap.keySet()){
                    String roleName = territoryToRoleMap.get(keyString);
                    if(roleName != null) territoryToUserMap.put(keyString, roleToUserMap.get(roleName));
                }
            }
            return territoryToUserMap;
        }
        set;
    }
    
    public static String getSendGridOwner(Account acct){
       String ownerId;
       String keyString = acct.FY_16_Role_Team__c;
       ownerId = territoryToUserMap.get(keyString);
       //TODO: add RoundRobin
       return ownerId;
    }
}