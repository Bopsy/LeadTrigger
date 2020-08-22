/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  EmailDomainTriggerHandler
*
* @description 	  Service class that contains the logic related to email domain object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2018-01-25
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class EmailDomainTriggerHandler {
    
    //Class to auto approve email domains. Logical test to see if email domain is created by a user in the blacklist
    public static void autoApproveEmailDomains(List<Email_Domain__c> lstEmailDomains){
        //get profiles and roles from custom setting
        List<Email_Domain_Blacklist__c> lstSettings = Email_Domain_Blacklist__c.getAll().values();
        Set<String> setBlacklist = new Set<String>();
        for(Email_Domain_Blacklist__c objSetting: lstSettings){
            setBlacklist.add(objSetting.name);
        }
        //query profile name
        List<Profile> lstProfiles = [Select Id, name from Profile where id=: userinfo.getProfileId()];
        //query role name
        List<UserRole> lstRoles = [Select Id, name from UserRole where id=: userinfo.getUserRoleId()];
        //check if custom setting doesnot contains current user's profile and role
        system.debug('++test '+setBlacklist);
        if(lstRoles.size()>0){
            if(!setBlacklist.contains(lstProfiles[0].name) && !setBlacklist.contains(lstRoles[0].name)){
                for(Email_Domain__c objEmailDomain: lstEmailDomains){
                    objEmailDomain.Approved__c = true;
                }
            }
        }else if(!setBlacklist.contains(lstProfiles[0].name)){
            for(Email_Domain__c objEmailDomain: lstEmailDomains){
                objEmailDomain.Approved__c = true;
            }
            system.debug('++test1 else '+lstEmailDomains);
        }
    }
}