trigger linkTwilioUsageToAccountTrigger on Twilio_Usage__c (before insert, before update) {

    // For each counter, add its accountsid to a set to remove duplicates from our
    // SOQL query later.
    Set<String> accountSids = new Set<String>();
    Set<String> magicUserIds = new Set<String>();
    for (Twilio_Usage__c counterEntry : Trigger.new) {
        accountSids.add(counterEntry.AccountSid__c);
        
        if ( counterEntry.Magic_User_ID__c != null )
            magicUserIds.add(counterEntry.Magic_User_ID__c);
    }

    // SOQL Query on Accounts to map AccountSids to SFDC Account IDs.
    Map<ID, Account> accountLookup = new Map<ID, Account>(
        [select Id, Account_SID__c from Account
         where Account_SID__c in :accountSids ]);
         //or Magic_User_ID__c in :magicUserIds ]);

    Map<String, ID> accountSidLookup = new Map<String, ID>();
    Map<String, ID> magicLookup = new Map<String, ID>();
    for (ID idKey : accountLookup.keyset()) {
        Account a = accountLookup.get(idKey);
        accountSidLookup.put(a.Account_SID__c, a.id);
    }


    // SOQL Query on Contacts to map AccountSids to SFDC Contact IDs.
    Map<ID, Contact> contactLookup = new Map<ID, Contact>(
        [select Id, AccountId, Account_SID__c, Magic_User_ID__c from Contact
         where Account_SID__c in :accountSids
         or Magic_User_ID__c in :magicUserIds ]);

    Map<String, ID> accountSidContactLookup = new Map<String, ID>();
    Map<String, ID> magicIdContactLookup = new Map<String, ID>(); 
    for (ID idKey : contactLookup.keyset()) {
        Contact c = contactLookup.get(idKey);
        accountSidContactLookup.put(c.Account_SID__c, c.id);
        magicIdContactLookup.put(c.Magic_User_ID__c, c.id);
        // Map AccountSids to SFDC Account IDs via Contact.
        accountSidLookup.put(c.Account_SID__c, c.AccountId);
    }


    // SOQL Query on Leads to map AccountSids to SFDC Lead IDs.
    Map<ID, Lead> leadLookup = new Map<ID, Lead>(
        [select Id, Account_SID__c, Magic_User_ID__c from Lead
         where IsConverted=false
         and ( Account_SID__c in :accountSids
         or Magic_User_ID__c in :magicUserIds ) ]);

    Map<String, ID> accountSidLeadLookup = new Map<String, ID>();
    Map<String, ID> magicIdLeadLookup = new Map<String, ID>();
    for (ID idKey : leadLookup.keyset()) {
        Lead l = leadLookup.get(idKey);
        accountSidLeadLookup.put(l.Account_SID__c, l.id);
        magicIdLeadLookup.put(l.Magic_User_ID__c, l.id);
    }

    String prodType = 'Magic Net Billing';

    for(Twilio_Usage__c triggerMember : Trigger.new) {
        
        if (triggerMember.AccountLookup__c == null && accountSidLookup.containsKey(triggerMember.AccountSid__c)) {
            triggerMember.AccountLookup__c = accountSidLookup.get(triggerMember.AccountSid__c); system.debug( accountSidLookup.get(triggerMember.AccountSid__c) );
        }

        Boolean isMagicNetBill = triggerMember.Product__c == prodType;

        Map<String, Id> relevantKey2ContactId = isMagicNetBill ? magicIdContactLookup : accountSidContactLookup;
        Map<String, Id> relevantKey2LeadId = isMagicNetBill ? magicIdLeadLookup : accountSidLeadLookup;

        String usageKey = isMagicNetBill ? 'Magic_User_ID__c' : 'AccountSid__c';

        system.debug( usageKey );
        system.debug( triggerMember.get( usageKey ) );
        system.debug( relevantKey2ContactId );
        system.debug( relevantKey2LeadId );

        if (triggerMember.Contact__c == null && relevantKey2ContactId.containsKey((String)triggerMember.get( usageKey ))) {
            
            triggerMember.Contact__c = relevantKey2ContactId.get((String)triggerMember.get( usageKey ));
            
        } else if (triggerMember.Lead__c == null && relevantKey2LeadId.containsKey((String)triggerMember.get( usageKey ))) {
            
            triggerMember.Lead__c = relevantKey2LeadId.get((String)triggerMember.get( usageKey ));
        }

    }
    TwilloUsageTriggerHandler.updateNPC(Trigger.new);
    TwilloUsageTriggerHandler.updateForcastFields(Trigger.new, trigger.oldMap, false);
}