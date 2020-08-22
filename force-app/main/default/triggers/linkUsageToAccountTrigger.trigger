trigger linkUsageToAccountTrigger on TwilioUsage__c (before insert, before update) {

    // For each counter, add its accountsid to a set to remove duplicates from our
    // SOQL query later.
    Set<String> accountSids = new Set<String>();
    for (TwilioUsage__c counterEntry : Trigger.new) {
        accountSids.add(counterEntry.AccountSid__c);
    }

    // SOQL Query on Accounts to map AccountSids to SFDC Account IDs.
    Map<ID, Account> accountLookup = new Map<ID, Account>(
        [select Id, Account_SID__c from Account
         where Account_SID__c in :accountSids]);

    Map<String, ID> accountSidLookup = new Map<String, ID>();
    for (ID idKey : accountLookup.keyset()) {
        Account a = accountLookup.get(idKey);
        accountSidLookup.put(a.Account_SID__c, a.id);
    }

    for(TwilioUsage__c triggerMember : Trigger.new) {
        if (accountSidLookup.containsKey(triggerMember.AccountSid__c)) {
            triggerMember.AccountLookup__c = accountSidLookup.get(triggerMember.AccountSid__c);
        }
    }
}