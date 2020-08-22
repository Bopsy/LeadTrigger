/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           UserPermissionAutoService
*
* @description    Lead Trigger Handler Service
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui     <ncui@twilio.com>
* @modifiedBy     Mia Cui     <ncui@twilio.com>
* @version        1.0
* @created        2019-08-09
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/

public class LeadTriggerHandlerService {
    //When the email field has the domain that existed in FREE_EMAIL_DOMAIN custom setting list
    //then leave Website field as BLANK.
    //When the email field has the domain that NOT existed in FREE_EMAIL_DOMAIN custom setting list
    //then populate website field with email domain.
    public static void websiteFieldUpdate(Map<Id,Lead> oldMap, List<Lead> leads) {
		List<Lead> filterLeads = new List<Lead>();
        
        for (Lead newLead : leads) {
            Lead oldLead = oldMap.get(newLead.id);
            if (oldLead == NULL || newLead.Email != oldLead.Email) filterLeads.add(newLead);
        }
        if(filterLeads.size() == 0) return;
        //list of free email domain(fed) contained in custom setting
        Map<String, Free_Email_Domains__c> freeEmailDomainsList = Free_Email_Domains__c.getall();
        
        for (Lead lead : filterLeads) { 
            String emailDomain;
            if (lead.email != NULL) {               
                String regex = '^[\\w-_\\.+]*[\\w-_\\.]\\@([\\w]+\\.)+[\\w]+[\\w]$';
                Pattern MyPattern = Pattern.compile(regex);
                Matcher MyMatcher = MyPattern.matcher(lead.email);
                
                if(MyMatcher.matches()) {
                    emailDomain = lead.email.split('@')[1];
                    if (freeEmailDomainsList == NULL || freeEmailDomainsList.get(emailDomain) == NULL) {
                        lead.website = lead.Email_Domain__c;
                    } else {
                        lead.website = NULL; 
                    }
                }
            }
        }
    }

}