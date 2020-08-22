/******************************************
//Created By: Brittany Blecher
//Last Modified by: Gram Bischof {04/17/2020}
//Description: handler class of PassToPartnerTrigger
//TestClass : PassToPartnerTriggerHandlerTest
*******************************************/
public without sharing class PassToPartnerTriggerHandler {
    
    //	public static Set<String> inactiveStatuses = new Set<String> { 'Closed - Won', 'Closed - Lost', 'Declined', 'Closed - Duplicate' };
    public static Set<String> doNotCopyOpportunityFieldsForStatuses = new Set<String> { 'Closed - Won', 'Closed - Lost', 'Declined' };
    public static Set<String> unsetContactForStatuses = new Set<String> { 'Closed - Won', 'Closed - Lost', 'Declined' };
    public static Set<String> unsetMappedFieldsForStatuses = new Set<String> { 'Declined', 'Closed - Lost' };
    public static Boolean runOnce = false;
    
    // Unset the Contact__c field if the Partner_Status__c is set to any of the
    // values in unsetContactForStatuses.
    //
    // Unset the fields specified by the Opportunity_to_PTP_Mappings__c
    // custom setting from the Pass_To_Partner__c.Opportunity__c to the
    // Pass_To_Partner__c record when the Partner_Status__c is set to any of the
    // values in unsetMappedFieldsForStatuses.
    // 
    // Returns a list of Pass_To_Partner__c records that have been updated.
    //
    // It is the responibility of the calling routine to perform the DML update (or insert).
    // This is meant for use by a trigger.
    public static List<Pass_To_Partner__c> unsetFieldsOnEndingStatus(List<Pass_To_Partner__c> ptpList) {
        System.debug('ptpList::'+ptpList);
        System.debug('inside unsetFieldsOnEndingStatus method');
        
        Map<String, Opportunity_to_PTP_Mappings__c> settings = Opportunity_to_PTP_Mappings__c.getAll();
        List<Pass_To_Partner__c> ptpRecordsUpdated = new List<Pass_To_Partner__c>();
        
        for (Pass_to_Partner__c p : ptpList) {
            if (unsetContactForStatuses.contains(p.Partner_Status__c)) {
                p.Contact__c = null;
                
                if (unsetMappedFieldsForStatuses.contains(p.Partner_Status__c)) {
                    for(String key : settings.keySet()) {
                        String ptpFieldName = settings.get(key).PTP_API_Name__c;
                        p.put(ptpFieldName, null);
                    }
                    ptpRecordsUpdated.add(p);
                }
            }
        }
        return ptpRecordsUpdated;
    }
    
    // Copy the fields specified by the Opportunity_to_PTP_Mappings__c custom setting from the
    // Pass_To_Partner__c.Opportunity__c to the Pass_To_Partner__c record whenever the Opportunity
    // is updated.
    //
    // It is the responibility of the calling routine to perform the DML update (or insert).
    // This is meant for use by a trigger.
    public static List<Pass_To_Partner__c> copyFieldsFromOpportunity(Map<Id,Opportunity> oldMap, Map<Id,Opportunity> newMap) {
        
        System.debug('opportunity map::'+oldMap);
        System.debug('inside copyFieldsFromOpportunity method');
        
        List<Pass_To_Partner__c> ptpRecordsUpdated = new List<Pass_To_Partner__c>();
        if(runOnce) return ptpRecordsUpdated;
        Set<Id> oppIds = newMap.keySet();
        String queryString = 'SELECT ' + PassToPartnerTriggerHandler.getPassToPartnerFieldString('Id, Opportunity__c') + ' FROM Pass_To_Partner__c WHERE Opportunity__c IN :oppIds AND Partner_Status__c NOT IN :doNotCopyOpportunityFieldsForStatuses';
        System.debug(queryString);
        Map<Id,Pass_To_Partner__c> ptpMap = new Map<Id,Pass_To_Partner__c>();
        ptpMap.putAll((List<Pass_To_Partner__c>)Database.query(queryString));
        
        for (Pass_To_Partner__c ptp : ptpMap.values()) {
            copyFieldsFromOpportunity(newMap.get(ptp.Opportunity__c), ptp);
            ptpRecordsUpdated.add(ptp);
        }
        runOnce = true;
        return ptpRecordsUpdated;
    }
    
    // Copy the fields specified by the Opportunity_to_PTP_Mappings__c custom setting from the
    // Pass_To_Partner__c.Opportunity__c to the Pass_To_Partner__c record.
    // Copy only occurs if the Pass_To_Partner__c.Opportunity__c is being changed.
    // Returns a list of Pass_To_Partner__c records that have been updated.
    //
    // It is the responibility of the calling routine to perform the DML update (or insert).
    // This is meant for use by a trigger.
    public static List<Pass_To_Partner__c> copyFieldsFromOpportunity(Map<Id,Pass_To_Partner__c> oldMap, Map<Id,Pass_To_Partner__c> newMap) {
        
        System.debug('new pass to partner map::'+newMap);
        System.debug('inside copyFieldsFromOpportunity method');
        
        List<Pass_To_Partner__c> ptpList = new List<Pass_To_Partner__c>();
        for (Pass_To_Partner__c n : newMap.values()) {
            if ((n.Opportunity__c != null) && (n.Opportunity__c != oldMap.get(n.Id).Opportunity__c)) {
                ptpList.add(n);
            }
        }
        return copyFieldsFromOpportunity(ptpList);
    }
    
    // Copy the fields specified by the Opportunity_to_PTP_Mappings__c custom setting from the
    // Pass_To_Partner__c.Opportunity__c to the Pass_To_Partner__c record.
    // Returns a list of Pass_To_Partner__c records that have been updated.
    //
    // It is the responibility of the calling routine to perform the DML update (or insert).
    // For example:
    //     List<Pass_To_Partner__c> ptpUpdatedList = copyFieldsFromOpportunity(ptpList);
    //     if (!ptpUpdatedList.isEmpty())
    //          upsert ptpUpdatedList;
    public static List<Pass_To_Partner__c> copyFieldsFromOpportunity(List<Pass_To_Partner__c> ptpList) {
        
        System.debug('pass to partner lsiut::'+ptpList);
        System.debug('inside copyFieldsFromOpportunity method');
        
        List<Id> oppIds = new List<Id>();
        for (Pass_To_Partner__c ptp : ptpList) {
            if (ptp.Opportunity__c != null) {
                oppIds.add(ptp.Opportunity__c);
            }
        }
        
        List<Pass_To_Partner__c> ptpRecordsUpdated = new List<Pass_To_Partner__c>();
        if (!oppIds.isEmpty()) {
            String queryString = 'SELECT ' + PassToPartnerTriggerHandler.getOpportunityFieldString('Id') + ' FROM Opportunity WHERE Id IN :oppIds';
            System.debug(queryString);
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
            oppMap.putAll((List<Opportunity>)Database.query(queryString));
            
            for (Pass_To_Partner__c ptp : ptpList) {
                copyFieldsFromOpportunity(oppMap.get(ptp.Opportunity__c), ptp);
                ptpRecordsUpdated.add(ptp);
            }
        }
        return ptpRecordsUpdated;
    }
    
    // Copy the fields specified by the Opportunity_to_PTP_Mappings__c custom setting from the
    // given Opportunity record to the given Pass_To_Partner__c record
    public static void copyFieldsFromOpportunity(Opportunity opp, Pass_To_Partner__c ptp){
        
        System.debug('ptp:::::'+ptp);
        System.debug('copyFieldsFromOpportunity');
        
        System.debug('Copying: Opportunity(' + opp.Id + ') > Pass_To_Partner__c(' + ptp.Id + ')');
        Map<String, Opportunity_to_PTP_Mappings__c> settings = Opportunity_to_PTP_Mappings__c.getAll();
        for(String key : settings.keySet()) {
            String ptpFieldName = settings.get(key).PTP_API_Name__c;
            String oppFieldName = settings.get(key).Opportunity_API_Name__c;
            ptp.put(ptpFieldName, opp.get(oppFieldName));
            //            System.debug('Copying: Opportunity.' + oppFieldName + ' > Pass_To_Partner__c.' + ptpFieldName + ' VALUE=' + opp.get(oppFieldName) );
        }
    }
    
    // Generate the SOQL select field list from the Opportunity_to_PTP_Mappings__c custom setting
    // Additional fields can be supplied that will be included in the field list string, but if 
    // there are no additional fields specify an empty/blank string, e.g. ''
    public static String getOpportunityFieldString(String additionalFields){
        
        System.debug('getOpportunityFieldString');
        
        Map<String, Opportunity_to_PTP_Mappings__c> settings = Opportunity_to_PTP_Mappings__c.getAll();
        
        // Make sure no field entered two times.
        Set<String> uniqueFields = new Set<String>();
        if (!String.isBlank(additionalFields)) {
            uniqueFields.add(additionalFields);
        }
        for(String key : settings.keySet()){
            uniqueFields.add(settings.get(key).Opportunity_API_Name__c);
        }
        
        return String.join(new List<String>(uniqueFields), ', ');
    }
    
    // Generate the SOQL select field list from the Opportunity_to_PTP_Mappings__c custom setting
    // Additional fields can be supplied that will be included in the field list string, but if 
    // there are no additional fields specify an empty/blank string, e.g. ''
    public static String getPassToPartnerFieldString(String additionalFields){
        
        System.debug('additionalFields:::::'+additionalFields);
        System.debug('getPassToPartnerFieldString');
        
        
        Map<String, Opportunity_to_PTP_Mappings__c> settings = Opportunity_to_PTP_Mappings__c.getAll();
        
        // Make sure no field entered two times.
        Set<String> uniqueFields = new Set<String>();
        if (!String.isBlank(additionalFields)) {
            uniqueFields.add(additionalFields);
        }
        for(String key : settings.keySet()){
            uniqueFields.add(settings.get(key).PTP_API_Name__c);
        }
        
        return String.join(new List<String>(uniqueFields), ', ');
    }
    
    // Set the Opportunity.Active_Pass_to_Partner__c related Pass_To_Partner__c record (e.g. if
    // Pass_To_Partner__c.Partner_Status__c is active then set, but if not active then unset).
    public static List<Opportunity> setOpportunityActivePassToPartner(Map<Id,Pass_To_Partner__c> ptpMap) {
        
        System.debug('setOppptpMap:::::'+ptpMap);
        System.debug('setOpportunityActivePassToPartner');
        
        Map<Id,Opportunity> updatedOpportunities = new Map<Id,Opportunity>();
        
        // Query Opportunities that can be related to the Pass_To_Partner__c records
        // Check for two situations:
        //    1) Pass_To_Partner__c.Opportunity__c is set
        //    2) Opportunity.Active_Pass_to_Partner__c is set to any of the given Pass_To_Partner__c records
        Map<Id,Pass_To_Partner__c> oppIdToPTPMap = new Map<Id,Pass_To_Partner__c>();
        for (Pass_To_Partner__c p : ptpMap.values()) {
            if (p.Opportunity__c == null) continue;
            System.debug('Checking ' + p.Id + ': ' + p);
            oppIdToPTPMap.put(p.Opportunity__c, p.Record_Lock__c ? null : p);
            System.debug('Setting ' + p.Opportunity__c + ': ' + oppIdToPTPMap.get(p.Opportunity__c));
        }
        
        // Process the Opportunites
        for (Opportunity o : [
            SELECT Id,
            Active_Pass_to_Partner__c,
            Active_Pass_to_Partner__r.Record_Lock__c,
            Active_Pass_to_Partner__r.Partner_Status__c,
            (SELECT Id, Record_Lock__c, Partner_Status__c FROM Pass_to_Partner__r ORDER BY LastModifiedDate DESC)
            FROM Opportunity
            WHERE Id IN :oppIdToPTPMap.keySet()
            OR Active_Pass_to_Partner__c IN :ptpMap.keySet()
            
        ]) {
            System.debug('Processing ' + o.Id + ': ' + o.Active_Pass_to_Partner__c + '/' + o.Active_Pass_to_Partner__r.Record_Lock__c);
            
            // If the Opportunity.Active_Pass_to_Partner__c is set to the Pass_To_Partner__c record
            // and the Pass_To_Partner.Partner_Status__c is inactive then unset Opportunity.Active_Pass_to_Partner__c.
            if (o.Active_Pass_to_Partner__c != null && o.Active_Pass_to_Partner__r.Record_Lock__c || o.Active_Pass_to_Partner__r.Partner_Status__c == 'Disqualified') {
                System.debug('Clearing Opportunity.Active_Pass_to_Partner__c for Id(' + o.Id + ')');
                o.Active_Pass_to_Partner__c = null;
                updatedOpportunities.put(o.Id, o);
            }
            
            // If the Opportunity.Active_Pass_to_Partner__c is not set to the Pass_To_Partner__c record
            // and the Pass_To_Partner.Partner_Status__c is active then set Opportunity.Active_Pass_to_Partner__c.
            if (o.Active_Pass_to_Partner__c == null) {
                System.debug('Checking Opportunity.Active_Pass_to_Partner__c for Opportunity.Id(' + o.Id + ')');
                for (Pass_To_Partner__c p : o.getSObjects('Pass_to_Partner__r')) {
                    System.debug('Pass_To_Partner: ' + p);
                    if (!p.Record_Lock__c && p.Partner_Status__c != 'Disqualified') {
                        System.debug('Setting Opportunity.Active_Pass_to_Partner__c to ' + p.Id + ' for Id(' + o.Id + ')');
                        o.Active_Pass_to_Partner__c = p.Id;
                        updatedOpportunities.put(o.Id, o);
                        break;
                    }
                }
            }
        }
        
        // Update the Opportunities where Active_Pass_To_Partner__c has changed
        Database.SaveResult[] srList = Database.update(updatedOpportunities.values(), false);
        System.debug('PassToPartnerTriggerHandler.setOpportunityActivePassToPartner: Updated ' + updatedOpportunities.size() + ' opportunities');
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            // Operation failed, so get all errors and add error to related records
            if (!sr.isSuccess()) {
                if (oppIdToPTPMap.containsKey(sr.getId())) {
                    for(Database.Error err : sr.getErrors()) {
                        oppIdToPTPMap.get(sr.getId()).addError(err.getMessage());
                        System.debug('PassToPartnerTriggerHandler.setOpportunityActivePassToPartner(): The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Opportunity fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
        
        return new List<Opportunity>(updatedOpportunities.values());
    }
    
    //Description: this method use to create the sharing
    //for the pass to partner with all the community user.
    public static void createSharingForCommunityUser(List<Pass_To_Partner__c> PassToPartnerList) {
        
        try {
            
            System.debug('PassToPartnerList::'+PassToPartnerList);
            Set<Id> accountIds=new Set<Id>();
            Set<Id> ownerIds = new Set<Id>();
            
            for(Pass_To_Partner__c passToPartner:PassToPartnerList) {
            	if(passToPartner.Partner_Account__c != null) accountIds.add(passToPartner.Partner_Account__c);
            	ownerIds.add(passToPartner.OwnerId);
            }
            System.debug('accountIds::'+accountIds);
            
            //all the portal user list
            List<User> userList = [select id,Name,isPortalEnabled,Contact.AccountId from User where isPortalEnabled =true AND isActive=true  AND Contact.AccountId IN :accountIds AND Id NOT IN :ownerIds];
            Map<Id,List<User>> accountIdToUsersMap = new Map<Id,List<User>>();
            for(User partner: userList){
                if(!accountIdToUsersMap.containsKey(partner.Contact.AccountId)) accountIdToUsersMap.put(partner.Contact.AccountId, new List<User>());
            	accountIdToUsersMap.get(partner.Contact.AccountId).add(partner);
            }
            System.debug('userList::'+userList);
            System.debug('accountIdToUsersMap::'+accountIdToUsersMap);
            
            //creating sharing with community user
            List<Pass_to_Partner__share> passToPartnerSharingList=new List<Pass_to_Partner__share>();               
            for(Pass_To_Partner__c passToPartner : PassToPartnerList) {
            	if(!accountIdToUsersMap.containskey(passToPartner.Partner_Account__c)) continue;
                for(User user : accountIdToUsersMap.get(passToPartner.Partner_Account__c) ) {
                	Pass_to_Partner__share passToPartnerShare=new Pass_to_Partner__share();
                	passToPartnerShare.ParentId=passToPartner.Id;
                	passToPartnerShare.AccessLevel='Edit';
                	passToPartnerShare.UserOrGroupId=user.id;
                	passToPartnerSharingList.add(passToPartnerShare);
            	}
            }
                
            System.debug('passToPartnerSharingList::'+passToPartnerSharingList);
            insert passToPartnerSharingList;
        }
        catch(Exception e) {
            System.debug('Exception in::'+e.getLineNumber()+' and Exception is::'+e.getMessage());
            throw e;
        }
    }
}