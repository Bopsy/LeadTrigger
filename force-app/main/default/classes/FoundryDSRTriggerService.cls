/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  FoundryDSRTriggerService
*
* @description 	  Service class for FoundryCampaignMemberBatch and FoundryDSRTrigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui	 <ncui@twilio.com>
* @modifiedBy     Mia Cui    <ncui@twilio.com>
* @version        1.0
* @created        2020-03-10
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		
*
**/
public class FoundryDSRTriggerService {
    /***
     * take out Campaign Member if FoundryDSR Status move from Approved to Decliend/Reviewing/Submitted
     * ***/
    public static void clearCampaignMember(List<Foundry_Deal_Support_Request__c> foundryList, Map<id, Foundry_Deal_Support_Request__c> oldFoundryList) {
        List<Foundry_Deal_Support_Request__c> filterFoundryList = new List<Foundry_Deal_Support_Request__c>();
        for(Foundry_Deal_Support_Request__c foundry : foundryList) {

            if(foundry.Status__c != 'Approved' && oldFoundryList.get(foundry.ID).status__c == 'Approved' && foundry.ContactIDRepo__c != NULL) {
                filterFoundryList.add(foundry);
            }
        }
        if(filterFoundryList.isEmpty()) return;
        
        Set<String> cmToDelete = new Set<String>();
        for(Foundry_Deal_Support_Request__c filterFoundry : filterFoundryList) {
            cmToDelete.addAll(filterFoundry.ContactIDRepo__c.split(','));
        }
        
        List<CampaignMember> del = [SELECT id from CampaignMember WHere Campaign_Member_Unique_Key__c IN: cmToDelete ];
        delete del;
    }
    
    /***
     * Add all contactRole from Foundry DSR's oppty to corresponding campaign as campaign member
     * ***/
    public static void addCampaignMember(List<Foundry_Deal_Support_Request__c> foundryList) {
        //Soql - Get ALL Oppty and its contactRole
        Set<Id> oppIdinScope = new Set<Id>();
        for(Foundry_Deal_Support_Request__c fl: foundryList){
            if(fl.Opportunity__c != null) oppIdinScope.add(fl.Opportunity__c);
        }
        List<Opportunity> oppContact = [select id, (select contactID from OpportunityContactRoles)
                                        from Opportunity 
                                        WHERE id IN :oppIdinScope
                                       ];
        
        //Map oppty to its ContactRole
        //oppty ID ==> List<OpportunityContactRole>
        Map<Id, Set<OpportunityContactRole>> oppContactMap = new Map<Id, Set<OpportunityContactRole>>();
        for(Opportunity opp: oppContact) {
            if(oppContactMap.get(opp.ID) == NULL) oppContactMap.put(opp.ID, new Set<OpportunityContactRole>());
            oppContactMap.get(opp.ID).addALL(opp.OpportunityContactRoles);
        }
        
        
        List<CampaignMember> campaignMemberRet = new List<CampaignMember>();
        for(Foundry_Deal_Support_Request__c foundry: foundryList) {
            String conatctIDRepo = '';
            for(OpportunityContactRole contactRole : oppContactMap.get(foundry.opportunity__c)) {
                
                String uniqueKey = foundry.Campaign__c+'-'+contactRole.contactID;
                conatctIDRepo += uniqueKey + ',';
                
                campaignMemberRet.add(new campaignMember(campaignId=foundry.Campaign__c,
                                                             ContactID = contactRole.contactID,
                                                             Responded_Date__c = foundry.Meeting_Date__c,
                                                             Campaign_Member_Unique_Key__c = uniqueKey));
            }
            foundry.ContactIDRepo__c = conatctIDRepo;
        }
        if(!campaignMemberRet.isEmpty()) {
            upsert campaignMemberRet Campaign_Member_Unique_Key__c;
            update foundryList;
            
        }
    }
}