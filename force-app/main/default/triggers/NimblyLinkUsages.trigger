trigger NimblyLinkUsages on Twilio_Usage__c (before insert, before update) {

/*
******************

This commented fetaure is replaced with new code.
Commented by Ashwani

*******************

    Set<String> usgOwnerUserIds = new Set<String>();
    Map<String, Contact> fy15IdContactId = new Map<String, Contact>();
    Map<String, ID> fy15IdLeadId = new Map<String, ID>();

    // Collecting the Twilio Usage "Owner User ID" values
    for ( Twilio_Usage__c usg : Trigger.new ) {
        
        if ( usg.Owner_User_Id__c != null )
            usgOwnerUserIds.add( usg.Owner_User_ID__c );
    }
    
    // Querying for pre-existing Contacts with an FY15 User Id matching any Owner User ID from above
    // and populating a map for easy retrieval by FY15 User ID
    for ( Contact con : [ SELECT Id, AccountId, Account_SID__c, Magic_User_ID__c, FY15_User_ID__c
                          FROM Contact WHERE FY15_User_ID__c in :usgOwnerUserIds ] ) {
                            
        fy15IdContactId.put( con.FY15_User_ID__c, con );           
    }

    // Querying for pre-existing Leads with an FY15 User Id matching any Owner User ID from above
    // and populating a map for easy retrieval by FY15 User ID
    for ( Lead ld : [ SELECT Id, Account_SID__c, Magic_User_ID__c, FY15_User_ID__c
                      FROM Lead WHERE IsConverted = false AND FY15_User_ID__c in :usgOwnerUserIds ] ) {
                            
        fy15IdLeadId.put( ld.FY15_User_ID__c, ld.id );                
    }
    
    for( Twilio_Usage__c usg2fix : Trigger.new ) {

        // If a Contact match is found and we HAVEN'T set the Contact lookup on the Usage yet...
        if ( usg2fix.Contact__c == null && fy15IdContactId.containsKey( usg2fix.Owner_User_ID__c ) ) {
            
            // Then set it and populate the Account lookup as per the Contact's Account as well
            Contact con4fy15Id = fy15IdContactId.get( usg2fix.Owner_User_ID__c );
            usg2fix.Contact__c = con4fy15Id.Id;
            usg2fix.AccountLookup__c = con4fy15Id.AccountId;
        
        // If no Contact, yet a Lead match is found and we HAVEN'T set the lookup on the Usage yet...
        } else if ( usg2fix.Lead__c == null && fy15IdLeadId.containsKey( usg2fix.Owner_User_ID__c ) ) {
            
            // Then set it to the appropriate Lead
            usg2fix.Lead__c = fy15IdLeadId.get( usg2fix.Owner_User_ID__c );
        }

    }
 */ 
    /***
     * Conditons added by Ashwani on 10-02-2016
     * Replacement of Owner_User_ID__c field logic.
     * Part of ""Twilio Multi-User Code Update Project v2.1"
     * Method: TwilloUsageTriggerHandler.onBeforeInsert(Trigger.new);
     * Method: TwilloUsageTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    **/ 
    //Commented as business don't need it fire as trigger.
    // Commented by Ashwani
    /*
    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {
            TwilloUsageTriggerHandler.onBeforeInsert(Trigger.new);
        } 
        else if(Trigger.isUpdate)
        {
            TwilloUsageTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    */
    
    // Try catch block added by Ashwani over two statements. These are causing error.
    // Remove try catch once it is fixed by owner of these methods.
    try
    {
        TwilloUsageTriggerHandler.updateNPC(Trigger.new);
        TwilloUsageTriggerHandler.updateForcastFields(Trigger.new, Trigger.isUpdate? trigger.oldMap : null, false);
    }
    catch(Exception ex)
    {
        System.debug(' ==> This peice of code has known excpetion '+ex.getMessage());
    }
}