/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  MQLWindowTriggerHandler
*
* @description 	  TriggerHandler for the MQLWindowTrigger.  Contains methods called by the trigger.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-11-05
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*
**/
public without sharing class MQLWindowTriggerHandler {
    public static void deleteDuplicateMQLWindows(List<MQL_Window__c> mqlWindowRecs, Map<Id, MQL_Window__c> oldMap){
        List<MQL_Window__c> mqlWindowRecsForReview = new List<MQL_Window__c>();
        Set<Id> mqlWindowLeadIDs = new Set<Id>();
        Set<Id> mqlWindowContactIds = new Set<Id>();
        
        for(MQL_Window__c mqlWindowRec : mqlWindowRecs){
            MQL_Window__c oldMQLWindowRec = oldMap.get(mqlWindowRec.Id);
            if(mqlWindowRec.MQL_Window_Status__c == 'Open'){
                if(mqlWindowRec.Lead__c != oldMQLWindowRec.Lead__c && mqlWindowRec.Lead__c != null /*&& mqlWindowRec.Lead__c != ''*/){
                    mqlWindowRecsForReview.add(mqlWindowRec);
                    mqlWindowLeadIDs.add(mqlWindowRec.Lead__c);
                } else if(mqlWindowRec.Contact__c != oldMQLWindowRec.Contact__c && mqlWindowRec.Contact__c != null /*&& mqlWindowRec.Contact__c != ''*/){
                    mqlWindowRecsForReview.add(mqlWindowRec);
                    mqlWindowContactIds.add(mqlWindowRec.Contact__c);
                }
            }
        }
        
        if(!mqlWindowRecsForReview.isEmpty()){
            List<MQL_Window__c> mqlWindowsForUpdate = new List<MQL_Window__c>();
            Map<Id, List<MQL_Window__c>> leadMQLWindows = new Map<Id, List<MQL_Window__c>>();
            Map<Id, List<MQL_Window__c>> contactMQLWindows = new Map<Id, List<MQL_Window__c>>();
            List<MQL_Window__c> mqlWindowRecsForQuery = getMQLWindowsForReview(mqlWindowLeadIDs, mqlWindowContactIds);
            
            for(MQL_Window__c mqlWindowRec : mqlWindowRecsForQuery){
                if(mqlWindowRec.Lead__c != null){
                    List<MQL_Window__c> tempLeadMQLWindowList = new List<MQL_Window__c>();
                    if(leadMQLWindows.get(mqlWindowRec.Lead__c) == null){
                        tempLeadMQLWindowList.add(mqlWindowRec);
                        leadMQLWindows.put(mqlWindowRec.Lead__c, tempLeadMQLWindowList);
                    } else {
                        tempLeadMQLWindowList = leadMQLWindows.get(mqlWindowRec.Lead__c);
                        tempLeadMQLWindowList.add(mqlWindowRec);
                        leadMQLWindows.put(mqlWindowRec.Lead__c, tempLeadMQLWindowList);
                    }
                }
                
                //Clear the list if it's populated so that we can process Contacts.
                //if(!tempMQLWindowList.isEmpty()){ tempMQLWindowList.clear(); }
                
                if(mqlWindowRec.Contact__c != null){
                    List<MQL_Window__c> tempContactMQLWindowList = new List<MQL_Window__c>();
                    if(contactMQLWindows.get(mqlWindowRec.Contact__c) == null){
                        tempContactMQLWindowList.add(mqlWindowRec);
                        contactMQLWindows.put(mqlWindowRec.Contact__c, tempContactMQLWindowList);
                    } else {
                        tempContactMQLWindowList = contactMQLWindows.get(mqlWindowRec.Contact__c);
                        tempContactMQLWindowList.add(mqlWindowRec);
                        contactMQLWindows.put(mqlWindowRec.Contact__c, tempContactMQLWindowList);
                    }
                }
            }
            
            //If the leadMQLWindows map has values, then review them.
            if(!leadMQLWindows.isEmpty()){
                for(Id mqlWindowLeadId : leadMQLWindows.keySet()){
                    List<MQL_Window__c> tempMQLWindows = new List<MQL_Window__c>();
                    if(leadMQLWindows.get(mqlWindowLeadId).size() > 1){
                        tempMQLWindows = getMQLWindowsForClose(leadMQLWindows.get(mqlWindowLeadId));
                        mqlWindowsForUpdate.addAll(tempMQLWindows);
                    }
                }
            }
            //If the contactMQLWindows map has values, then review them.
            if(!contactMQLWindows.isEmpty()){
                for(Id mqlWindowContactId : contactMQLWindows.keySet()){
                    List<MQL_Window__c> tempMQLWindows = new List<MQL_Window__c>();
                    if(contactMQLWindows.get(mqlWindowContactId).size() > 1){
                        tempMQLWindows = getMQLWindowsForClose(contactMQLWindows.get(mqlWindowContactId));
                        mqlWindowsForUpdate.addAll(tempMQLWindows);
                    }
                }
            }
            
            if(!mqlWindowsForUpdate.isEmpty()){
                for(MQL_Window__c window : mqlWindowsForUpdate){
                	System.debug('MQL Window Records for Update --> ' + window);    
                }
                
                update mqlWindowsForUpdate;
            }
        }
    }
    
    public static void deleteDuplicateMQLWindows(Map<Id, List<Lead>> leadMap){
        List<MQL_Window__c> mqlWindowsForReview = new List<MQL_Window__c>();
        List<MQL_Window__c> mqlWindowsForUpdate = new List<MQL_Window__c>();
        Map<Id, List<MQL_Window__c>> leadMQLWindows = new Map<Id, List<MQL_Window__c>>();
        mqlWindowsForReview = getMQLWindowsForReview(leadMap.keySet(), null);
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReview){
            //If the leadMQLWindows map has values, then review them.
            List<MQL_Window__c> tempLeadMQLWindowList = new List<MQL_Window__c>();
            if(leadMQLWindows.get(mqlWindowRec.Lead__c) == null){
                tempLeadMQLWindowList.add(mqlWindowRec);
                leadMQLWindows.put(mqlWindowRec.Lead__c, tempLeadMQLWindowList);
            } else {
                tempLeadMQLWindowList = leadMQLWindows.get(mqlWindowRec.Lead__c);
                tempLeadMQLWindowList.add(mqlWindowRec);
                leadMQLWindows.put(mqlWindowRec.Lead__c, tempLeadMQLWindowList);
            }
        }
        
        if(!leadMQLWindows.isEmpty()){
            for(Id mqlWindowLeadId : leadMQLWindows.keySet()){
                List<MQL_Window__c> tempMQLWindows = new List<MQL_Window__c>();
                if(leadMQLWindows.get(mqlWindowLeadId).size() > 1){
                    tempMQLWindows = getMQLWindowsForClose(leadMQLWindows.get(mqlWindowLeadId));
                    mqlWindowsForUpdate.addAll(tempMQLWindows);
                }
            }
        }
        
        if(!mqlWindowsForUpdate.isEmpty()){
            update mqlWindowsForUpdate;
        }
    }
    
    public static void deleteDuplicateMQLWindows(Map<Id, List<Contact>> contactMap){
        List<MQL_Window__c> mqlWindowsForReview = new List<MQL_Window__c>();
        List<MQL_Window__c> mqlWindowsForUpdate = new List<MQL_Window__c>();
        Map<Id, List<MQL_Window__c>> contactMQLWindows = new Map<Id, List<MQL_Window__c>>();
        
        mqlWindowsForReview = getMQLWindowsForReview(null, contactMap.keySet());
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReview){
            //If the contactMQLWindows map has values, then review them.
            List<MQL_Window__c> tempContactMQLWindowList = new List<MQL_Window__c>();
            if(contactMQLWindows.get(mqlWindowRec.Contact__c) == null){
                tempContactMQLWindowList.add(mqlWindowRec);
                contactMQLWindows.put(mqlWindowRec.Contact__c, tempContactMQLWindowList);
            } else {
                tempContactMQLWindowList = contactMQLWindows.get(mqlWindowRec.Contact__c);
                tempContactMQLWindowList.add(mqlWindowRec);
                contactMQLWindows.put(mqlWindowRec.Contact__c, tempContactMQLWindowList);
            }
        }
        if(!contactMQLWindows.isEmpty()){
            for(Id mqlWindowContactId : contactMQLWindows.keySet()){
                List<MQL_Window__c> tempMQLWindows = new List<MQL_Window__c>();
                if(contactMQLWindows.get(mqlWindowContactId).size() > 1){
                    tempMQLWindows = getMQLWindowsForClose(contactMQLWindows.get(mqlWindowContactId));
                    mqlWindowsForUpdate.addAll(tempMQLWindows);
                }
            }
        }
        
        if(!mqlWindowsForUpdate.isEmpty()){
        	update mqlWindowsForUpdate;
        }
    }
    
    private static List<MQL_Window__c> getMQLWindowsForReview(Set<Id> leadIds, Set<Id> contactIds){
        List<MQL_Window__c> mqlWindowRecsForQuery = new List<MQL_Window__c>();
        mqlWindowRecsForQuery = [SELECT Id,
                                        Name,
                                        MQL_Window_Open_Date__c,
                                        Lead__c,
                                        Contact__c
                                 FROM MQL_Window__c 
                                 WHERE MQL_Window_Status__c = 'Open' AND
                                 	(Lead__c IN :leadIds OR Contact__c IN :contactIds)];
        return mqlWindowRecsForQuery;
    }
    
    //This method returns a list of MQL Windows that should be closed.  This method determines which
    //MQL Window records should have MQL Window Status = 'Merged and Closed'.  The record with the 
    //oldest MQL Window Open Date should keep MQL Window Status = 'Open'.
    private static List<MQL_Window__c> getMQLWindowsForClose(List<MQL_Window__c> mqlWindowRecs){
        if(mqlWindowRecs.size() <= 1){ return null; }
        Datetime timeNow = DateTime.now();
        List<MQL_Window__c> mqlWindowsForClose = new List<MQL_Window__c>();
        MQL_Window__c oldestMQLWindow = new MQL_Window__c();
        
        for(MQL_Window__c mqlWindowRec : mqlWindowRecs){
            if(oldestMQLWindow.Id == null/* || oldestMQLWindow.Id == ''*/){
                oldestMQLWindow = mqlWindowRec;
            } else {
                if(oldestMQLWindow.MQL_Window_Open_Date__c <= mqlWindowRec.MQL_Window_Open_Date__c){
                    mqlWindowRec.MQL_Window_Status__c = 'Merged and Closed';
                    mqlWindowRec.MQL_Window_Close_Date__c = timeNow;
                    mqlWindowsForClose.add(mqlWindowRec);
                } else/* if (oldestMQLWindow.MQL_Window_Open_Date__c > mqlWindowRec.MQL_Window_Open_Date__c)*/{
                    oldestMQLWindow.MQL_Window_Status__c = 'Merged and Closed';
                    oldestMQLWindow.MQL_Window_Close_Date__c = timeNow;
                    mqlWindowsForClose.add(oldestMQLWindow);
                    oldestMQLWindow = mqlWindowRec;
                }
            }
        }
        return mqlWindowsForClose;
    }
    
    
}