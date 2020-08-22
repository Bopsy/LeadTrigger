/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           orgApplicationHandler
*
* @description    org Application Trigger Service Class
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui     <ncui@twilio.com>
* @modifiedBy     Mia Cui     <ncui@twilio.com>
* @version        1.0
* @created        2020-01-11
* @modified       2020-01-11
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class orgApplicationHandler {
   
    public static void addCampaignMember(List<org_Application__c> applicationList) {
        List<CampaignMember_orgApplication_Mapping__c> campaignMemberMapping = CampaignMember_orgApplication_Mapping__c.getAll().values();
        
        if(campaignMemberMapping!= NULL && !campaignMemberMapping.isEmpty()) {
            String campaignID = campaignMemberMapping[0].Campaign_ID__c;
            String status = campaignMemberMapping[0].Status__c;
        
            List<CampaignMember> campaignMemberRet = new List<CampaignMember>();
            for(org_Application__c app: applicationList) {
                if(app.Lead__c != NULL) {
                    String uniqueKey = campaignID+'-'+app.lead__c;
                    campaignMemberRet.add(new campaignMember(campaignId=campaignID,
                                                             LeadId = app.lead__c,Status = status,
                                                             Campaign_Member_Updated_Date__c = System.now(),
                                                             Campaign_Member_Unique_Key__c = uniqueKey));
                }
                
                if(app.Contact__c != NULL) {
                    String uniqueKey = campaignID+'-'+app.Contact__c;
                    campaignMemberRet.add(new campaignMember(campaignId=campaignID,Status = status,
                                                             contactID = app.Contact__c, 
                                                             Campaign_Member_Updated_Date__c = System.now(),
                                                             Campaign_Member_Unique_Key__c = uniqueKey));
                }
            }
            if(!campaignMemberRet.isEmpty()) upsert campaignMemberRet Campaign_Member_Unique_Key__c;
        }
    }
}