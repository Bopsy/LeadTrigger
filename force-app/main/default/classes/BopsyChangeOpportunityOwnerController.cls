public without sharing class BopsyChangeOpportunityOwnerController {
    @testVisible private Opportunity opp;
    
    public BopsyChangeOpportunityOwnerController(ApexPages.StandardController sc) {
        this.opp = (Opportunity)sc.getRecord();
       
    }

    public void changeOwner(){
        profile p = [select id, name from profile where name = 'Partners & Alliances - Sales'];
        ByPassValidationRuleForOpp__c objCustomSetting = ByPassValidationRuleForOpp__c.getInstance(p.id);
        objCustomSetting.ByPassValRule__c = true;
        update objCustomSetting;
        system.debug('update custom setting'+objCustomSetting);        
        update opp;
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm, 'Owner is changed successfully.'));
        objCustomSetting.ByPassValRule__c = false;
        update objCustomSetting;
    }

    @AuraEnabled
    public static List<UserOption> findUser(String searchString){
        
        List<UserOption> userList = new List<UserOption>();

        if(!String.isEmpty(searchString)) {
            String nameLike = '%'+searchString;
            for(User userRec : [SELECT Id, firstname, lastname FROM User WHERE firstname LIKE :nameLike AND isActive=true]) {
                UserOption uo = new UserOption(userRec.firstname+' '+userRec.lastname, userRec.Id);

                userList.add(uo);
            }
        }
        return userList;
    }

    @AuraEnabled
    public static String assign(String userId, String opportunityId){
        Opportunity opp = new Opportunity(Id=opportunityId, OwnerId=userId);

        try {
            update opp;
        } catch(Exception ex) {
            String errorMessage = ex.getMessage();
            return errorMessage;
        }
        return 'success';
    }

    @AuraEnabled
    public static Boolean getProfileInfo() {
        Profile profile = [SELECT Id, Name FROM Profile WHERE Name ='Partners & Alliances - Sales'];
        return profile.Id == UserInfo.getProfileId();
    }

    public class UserOption {
        @AuraEnabled
        public String username;
        @AuraEnabled
        public String userId;

        public UserOption(String username, String userId) {
            this.username = username;
            this.userId = userId;
        }
    }
    
}