public without sharing class PersonMergeServices {
    
    public static void afterDelete(List<Contact> oldRec){
        
        Map<Id, List<Contact>> queryContactMaps = new Map<Id, List<Contact>>();
        
        for(Contact oldContact: oldRec){
            if(oldContact.MasterRecordId != null){
                List<Contact> contacts = queryContactMaps.get(oldContact.MasterRecordId);
                if(contacts == null) contacts = new List<Contact>();
                contacts.add(oldContact);
                queryContactMaps.put(oldContact.MasterRecordId, contacts);
            }
        }
        
        if(queryContactMaps.isEmpty()) return;
        Map<Id, Decimal> profileScoreMap = new Map<Id, Decimal>();
        Map<Id, Decimal> engagementScoreMap = new Map<Id, Decimal>();
        
        for(Contact aContact: [SELECT Profile_Score__c, Engagement_Score__c FROM Contact WHERE Id =: queryContactMaps.keySet()]){
            profileScoreMap.put(aContact.Id, aContact.Profile_Score__c);
            engagementScoreMap.put(aContact.Id, aContact.Engagement_Score__c);
        }
        
        Map<Id, Decimal> updateContacts = new  Map<Id, Decimal>();
        Map<Id, Decimal> updateEContacts = new  Map<Id, Decimal>();
        
        for(Id masterRecId: queryContactMaps.keySet()){
            Decimal maxScore = profileScoreMap.get(masterRecId) == null ? -1 : profileScoreMap.get(masterRecId);
            Decimal sumScore = engagementScoreMap.get(masterRecId) == null ? 0: engagementScoreMap.get(masterRecId);
            Contact updateContact = new Contact(Id = masterRecId);
            for(Contact aContact: queryContactMaps.get(masterRecId)){
                if(aContact.Profile_Score__c != null && maxScore < aContact.Profile_Score__c){
                    updateContact.Profile_Score__c = aContact.Profile_Score__c;
                    maxScore = aContact.Profile_Score__c;
                }
                if(aContact.Engagement_Score__c != null){
                    sumScore += aContact.Engagement_Score__c;
                }
            }
            if(maxScore != -1) updateContacts.put(updateContact.Id, maxScore);
            if(sumScore != 0) updateEContacts.put(updateContact.Id, sumScore);
        }
        
        updateProfileScoreOnContacts(updateContacts, updateEContacts);
        
        //Jason added 11-11-19 for MQL Window Test
        MQLWindowTriggerHandler.deleteDuplicateMQLWindows(queryContactMaps);
    }
    
    public static void afterDelete(List<Lead> oldRec){
        
        Map<Id, List<Lead>> queryLeadMaps = new Map<Id, List<Lead>>();
        
        for(Lead oldLead: oldRec){
            if(oldLead.MasterRecordId != null){
                List<Lead> leads = queryLeadMaps.get(oldLead.MasterRecordId);
                if(leads == null) leads = new List<Lead>();
                leads.add(oldLead);
                queryLeadMaps.put(oldLead.MasterRecordId, leads);
            }
        }
        
        if(queryLeadMaps.isEmpty()) return;
        Map<Id, Decimal> profileScoreMap = new Map<Id, Decimal>();
        Map<Id, Decimal> engagementScoreMap = new Map<Id, Decimal>();
        
        for(Lead aLead: [SELECT Profile_Score__c, Engagement_Score__c FROM Lead WHERE Id =: queryLeadMaps.keySet()]){
            profileScoreMap.put(aLead.Id, aLead.Profile_Score__c);
            engagementScoreMap.put(aLead.Id, aLead.Engagement_Score__c);
        }
        
        Map<Id, Decimal> updateLeads = new Map<Id, Decimal>();
        Map<Id, Decimal> updateELeads = new Map<Id, Decimal>();
        
        for(Id masterRecId: queryLeadMaps.keySet()){
            Decimal maxScore = profileScoreMap.get(masterRecId) == null ? -1 : profileScoreMap.get(masterRecId);
            Decimal sumScore = engagementScoreMap.get(masterRecId) == null ? 0 : engagementScoreMap.get(masterRecId);
            Lead updateLead = new Lead(Id = masterRecId);
            for(Lead aLead: queryLeadMaps.get(masterRecId)){
                if(aLead.Profile_Score__c != null && maxScore < aLead.Profile_Score__c){
                    updateLead.Profile_Score__c = aLead.Profile_Score__c;
                    maxScore = aLead.Profile_Score__c;
                }
                if(aLead.Engagement_Score__c != null){
                    sumScore += aLead.Engagement_Score__c;
                }
            }
            if(maxScore != -1) updateLeads.put(updateLead.Id, maxScore);
            if(sumScore != 0) updateELeads.put(updateLead.Id, sumScore);
        }
        
        updateProfileScoreOnLeads(updateLeads, updateELeads);
        
        //Jason added 11-11-19 for MQL Window Test
        MQLWindowTriggerHandler.deleteDuplicateMQLWindows(queryLeadMaps);
    }
    
    @future
    public static void updateProfileScoreOnContacts(Map<Id, Decimal> contactMap, Map<Id, Decimal> contactEMap){
        List<Contact> updateContacts = new List<Contact>();
        for(Id contactId: contactMap.keySet()){
            updateContacts.add(new Contact(Id = contactId, Profile_Score__c = contactMap.get(contactId), Engagement_Score__c = contactEMap.get(contactId)));
        }
        
        update updateContacts;
    }
    
    @future
    public static void updateProfileScoreOnLeads(Map<Id, Decimal> leadMap, Map<Id, Decimal> leadEMap){
        List<Lead> updateLeads = new List<Lead>();
        for(Id leadId: leadMap.keySet()){
            updateLeads.add(new Lead(Id = leadId, Profile_Score__c = leadMap.get(leadId), Engagement_Score__c = leadEMap.get(leadId)));
        }
        update updateLeads;
    }
    
    /*@future
    public static void updateMQLWindows(List<MQL_Window__c> mqlWindowRecs){
        if(!mqlWindowRecs.isEmpty()){
        	update mqlWindowRecs;    
        }
    }*/
}