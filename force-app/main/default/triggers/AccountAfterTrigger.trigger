trigger AccountAfterTrigger on Account (after insert, after update) {
    /*if (Trigger.isUpdate) {

        // When an account's OwnerId changes update its related contacts
        // to be owned by the same user

        // Identify accounts where the OwnerId has changed
        Map<Id,Account> changedAccounts = new Map<Id,Account>();
        for (Account newAccount : Trigger.new) {
            Account oldAccount = Trigger.oldMap.get(newAccount.Id);
            if (newAccount.OwnerId != oldAccount.OwnerId) {
                changedAccounts.put(newAccount.Id, newAccount);
            }
        }

        // Query related contacts for the changed accounts and
        // update contact's OwnerId, if different from the account's
        if(!changedAccounts.isEmpty()){
            List<Contact> updatedContacts = new List<Contact>();
            for (Contact contact : [
                SELECT Id, AccountId, OwnerId
                FROM Contact
                WHERE AccountId IN :changedAccounts.keySet()
            ]) {
                Account account = Trigger.newMap.get(Contact.AccountId);
                if (contact.OwnerId != account.OwnerId) {
                    contact.OwnerId = account.OwnerId;
                    updatedContacts.add(contact);
                }
            }
            
            update updatedContacts;
        }
    }*/
}