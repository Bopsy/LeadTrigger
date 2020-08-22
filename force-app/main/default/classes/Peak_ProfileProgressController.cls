public with sharing class Peak_ProfileProgressController {
    /**
    * Builds a SOQL query based on the provided values.
    *
    * @param String objectName - Name of the object to be used in the query.
    * @param String userId - Id of the object to be used in the query.
    * @param List<String> fieldNameList - Names of the fields to be used in the query.
    * @return String - Built query string.
    */
    public static String dynamicQueryBuilder (String objectName, String objectId, List<String> fieldNameList) {
        String dynamicQuery;

        if (!String.isEmpty(objectName) || !String.isBlank(objectName) && !String.isEmpty(objectId) || !String.isBlank(objectId)) {
            dynamicQuery = 'SELECT Id';

            // Add the fields provided
            for (String currentFieldName : fieldNameList) {
                if (!String.isEmpty(currentFieldName) || !String.isBlank(currentFieldName)) {
                    dynamicQuery += ', ' + String.escapeSingleQuotes(currentFieldName);
                }
            }

            dynamicQuery += ' FROM '
                    + String.escapeSingleQuotes(objectName)
                    + ' WHERE Id = \''
                    + String.escapeSingleQuotes(objectId) + '\'';
        }

        return dynamicQuery;
    }
    @AuraEnabled
    public static User getUser(){
        User loggedInUser = [SELECT Id, Name,FirstName, LastName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return loggedInUser;
    }
    @AuraEnabled
    public static User getUserById(String userId, List<String> aboutMeFieldNameList) {
        User user;
        List<User> userList;
        String queryString = dynamicQueryBuilder('User', userId, aboutMeFieldNameList);
        userList = Database.query(queryString);


        user = userList[0];

        return user;
    }
    // Get the site prefix (for displaying links/assets)
    @AuraEnabled
    public static String getSitePrefix(){
        return Peak_Utils.getSitePrefix();
    }
}