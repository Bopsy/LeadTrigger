public without sharing class Peak_MyAccountTeamController {

    @AuraEnabled
    public static Peak_Response getAccountTeam() {
        Peak_Response peakResponse = new Peak_Response();

        List<User> currentUser = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];

        // If current user was found WITH a contact ID
        if (!Peak_Utils.isNullOrEmpty(currentUser)) { //&& currentUser[0].ContactId != null) {

            // Get Contact for user, with associated account
            List <Contact> contact = [Select Id, AccountId from Contact where Id = :currentUser[0].ContactId];

            // ... and if user's contact is found...
            if (!Peak_Utils.isNullOrEmpty(contact)) {
                peakResponse = queryAccountTeams(contact);
            }
            else {
                peakResponse.messages.add(Label.X7S_No_ContactId);
            }
        }

        // Flip to unsuccessful if there are any error messages
        if (peakResponse.messages.size() > 0){
            peakResponse.success = false;
        }
        return peakResponse;
    }

    @AuraEnabled
    public static Peak_Response queryAccountTeams(List<Contact> contact){

        Peak_Response peakResponse = new Peak_Response();

        // AND if account teams are enabled
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('AccountTeamMember');
        if (targetType != null){
            // Use database.query in case Account teams are not enabled, otherwise a standard select won't even compile!
            try {
                peakResponse.results =  Database.query('SELECT Id, TeamMemberRole, User.Firstname, User.Lastname,User.Email, User.Phone FROM AccountTeamMember WHERE AccountId = \'' + contact[0].AccountId+'\'');
            } catch (Exception e){
                peakResponse.messages.add(e.getMessage());
            }
        } else {
            peakResponse.messages.add(Label.X7S_Account_Teams_Not_Enabled);
        }
        return peakResponse;
    }
}