trigger MergeAccountEmailDomains on Account (after delete) {

    // Identify accounts that are being delete as a
    // results of an account merge
    Map<Id,Id> mergedAccountIds = new Map<Id,Id>();
    for (Account a : Trigger.old) {
        if (a.MasterRecordId != a.Id) {
            System.debug('======> ACCOUNT MERGED (' + a.Id + ', ' + a.Name + ')');
            mergedAccountIds.put(a.Id, a.MasterRecordId);
        }
    }
    
    if (!mergedAccountIds.isEmpty()) {
        List<Email_Domain__c> updatedEmailDomains = new List<Email_Domain__c>(); 
        for (Email_Domain__c d : [ SELECT Id, Account__c FROM Email_Domain__c WHERE Account__c IN :mergedAccountIds.keySet() ]) {
            d.Account__c = mergedAccountIds.get(d.Account__c);
            updatedEmailDomains.add(d);
        }
        
        if (!updatedEmailDomains.isEmpty()) {
            update updatedEmailDomains;
        }
    }
}