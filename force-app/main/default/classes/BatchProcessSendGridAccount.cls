global class BatchProcessSendGridAccount implements Database.Batchable<SObject>, Schedulable{
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchProcessSendGridAccount());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT SendGrid_Account_Name__c, MRR__c, Account_Owner_Id__c, Billing_State__c, Billing_Zip_Code__c, Employee_Size__c, SendGrid_Billing_Contact_Email__c, SendGrid_Backend_Contact_Email__c, Billing_Country__c, SendGrid_Account_Website__c, Billing_Email_Domain__c, Backend_Email_Domain__c, SendGrid_Account_Country__c  FROM SendGrid_Account__c WHERE Account__c = null AND SendGrid_Account_Name__c != null]);
    }
    
    global void execute(Database.BatchableContext bc, List<SendGrid_Account__c> sgAccounts){
        List<SendGrid_Account__c> contactNotMatchingAccounts = new List<SendGrid_Account__c>();
        List<SendGrid_Account__c> updateAccounts = new List<SendGrid_Account__c>();
        
        
        Set<String> contactEmails = new Set<String>();
        for(SendGrid_Account__c sgAccount: sgAccounts){
            if(sgAccount.SendGrid_Billing_Contact_Email__c != null) contactEmails.add(sgAccount.SendGrid_Billing_Contact_Email__c);
            if(sgAccount.SendGrid_Backend_Contact_Email__c != null) contactEmails.add(sgAccount.SendGrid_Backend_Contact_Email__c);
        }
        
        Map<String, Id> emailAccountIdMap = new Map<String, Id>();
        for(Contact aContact: [SELECT AccountId, Email FROM Contact WHERE Email =: contactEmails]){
            if(aContact.AccountId != null){
                emailAccountIdMap.put(aContact.Email, aContact.AccountId);
            }
        }
        
        
        for(SendGrid_Account__c sgAccount: sgAccounts){
            String email = null;
            if(sgAccount.SendGrid_Billing_Contact_Email__c != null && emailAccountIdMap.get(sgAccount.SendGrid_Billing_Contact_Email__c) != null) email = sgAccount.SendGrid_Billing_Contact_Email__c;
            if(email == null && sgAccount.SendGrid_Backend_Contact_Email__c != null && emailAccountIdMap.get(sgAccount.SendGrid_Backend_Contact_Email__c) != null) email = sgAccount.SendGrid_Backend_Contact_Email__c;
            if(email != null){
                sgAccount.Account__c = emailAccountIdMap.get(email);
                updateAccounts.add(sgAccount);
            }
            else{
                contactNotMatchingAccounts.add(sgAccount);
            }
        }
        
        if(updateAccounts.isEmpty()) contactNotMatchingAccounts = sgAccounts.deepClone(true, true);
        
        
        Set<String> freeDomains = Free_Email_Domains__c.getAll().keySet();
        Set<String> sgDomains = new Set<String>();
        
        for(SendGrid_Account__c sgAccount: contactNotMatchingAccounts){
            if(sgAccount.Billing_Email_Domain__c != null && !freeDomains.contains(sgAccount.Billing_Email_Domain__c)) sgDomains.add(sgAccount.Billing_Email_Domain__c);
            if(sgAccount.Backend_Email_Domain__c != null && !freeDomains.contains(sgAccount.Backend_Email_Domain__c)) sgDomains.add(sgAccount.Backend_Email_Domain__c);
        }
        
        Map<String, Id> emailDomainAccountMap = new Map<String, Id>();
        for(Email_Domain__c emailDomain: [SELECT Account__c, Unique_Name__c FROM Email_Domain__c WHERE Unique_Name__c in: sgDomains]){
            emailDomainAccountMap.put(emailDomain.Unique_Name__c, emailDomain.Account__c);
        }
        
        Map<String, Email_Domain__c> emailDomains = new Map<String, Email_Domain__c>();
        Map<String, Account> sgAccountsMap = new Map<String, Account>();
        for(SendGrid_Account__c sgAccount: contactNotMatchingAccounts){
            String domain = null;
            if(sgAccount.Billing_Email_Domain__c != null && !freeDomains.contains(sgAccount.Billing_Email_Domain__c) && emailDomainAccountMap.get(sgAccount.Billing_Email_Domain__c) != null) domain = sgAccount.Billing_Email_Domain__c;
            if(domain == null && sgAccount.Backend_Email_Domain__c != null && !freeDomains.contains(sgAccount.Backend_Email_Domain__c) && emailDomainAccountMap.get(sgAccount.Backend_Email_Domain__c) != null) domain = sgAccount.Backend_Email_Domain__c;
            if(domain != null && emailDomainAccountMap.get(domain) != null){
                sgAccount.Account__c = emailDomainAccountMap.get(domain);
                updateAccounts.add(sgAccount);
            }
            else if(!freeDomains.contains(sgAccount.Billing_Email_Domain__c) && !freeDomains.contains(sgAccount.Backend_Email_Domain__c)){
                if(sgAccount.Billing_Email_Domain__c != null && !freeDomains.contains(sgAccount.Billing_Email_Domain__c)) domain = sgAccount.Billing_Email_Domain__c;
                if(domain == null && sgAccount.Backend_Email_Domain__c != null && !freeDomains.contains(sgAccount.Backend_Email_Domain__c)) domain = sgAccount.Backend_Email_Domain__c;
                if(domain != null){
                    if(sgAccount.Account_Owner_Id__c != null && sgAccount.Account_Owner_Id__c == 'Integration User') sgAccount.Account_Owner_Id__c = '00540000003cyEk';
                    Account newSGAcc = new Account(OwnerId = sgAccount.Account_Owner_Id__c == null ? '00540000003cyEk' : sgAccount.Account_Owner_Id__c, Name = sgAccount.SendGrid_Account_Name__c, BillingState = sgAccount.Billing_State__c, BillingPostalCode = sgAccount.Billing_Zip_Code__c, Employee_Size__c = sgAccount.Employee_Size__c, BillingCountry = sgAccount.SendGrid_Account_Country__c, Website = sgAccount.SendGrid_Account_Website__c);
                    sgAccountsMap.put(domain, newSGAcc);
                }
            }
            else if(sgAccount.MRR__c > 0){
                if(sgAccount.Account_Owner_Id__c != null && sgAccount.Account_Owner_Id__c == 'Integration User') sgAccount.Account_Owner_Id__c = '00540000003cyEk';
                Account newSGAcc = new Account(OwnerId = sgAccount.Account_Owner_Id__c == null ? '00540000003cyEk' : sgAccount.Account_Owner_Id__c, Name = sgAccount.SendGrid_Account_Name__c, BillingState = sgAccount.Billing_State__c, BillingPostalCode = sgAccount.Billing_Zip_Code__c, Employee_Size__c = sgAccount.Employee_Size__c, BillingCountry = sgAccount.SendGrid_Account_Country__c, Website = sgAccount.SendGrid_Account_Website__c);
                sgAccountsMap.put(sgAccount.Id, newSGAcc);
            }
        }
        
        insert sgAccountsMap.values();
        
        for(SendGrid_Account__c sgAccount: contactNotMatchingAccounts){
            String domain = null;
            if(sgAccount.Billing_Email_Domain__c != null && !freeDomains.contains(sgAccount.Billing_Email_Domain__c)) domain = sgAccount.Billing_Email_Domain__c;
            if(domain == null && sgAccount.Backend_Email_Domain__c != null && !freeDomains.contains(sgAccount.Backend_Email_Domain__c)) domain = sgAccount.Backend_Email_Domain__c;
            if(sgAccountsMap.containsKey(domain) && sgAccountsMap.get(domain) != null && sgAccountsMap.get(domain).Id != null){
                SendGrid_Account__c sgAccountWithNewAccount = new SendGrid_Account__c(Id = sgAccount.Id, Account__c = sgAccountsMap.get(domain).Id);
                updateAccounts.add(sgAccountWithNewAccount);
                if(domain != null && !freeDomains.contains(domain)){
                    Email_Domain__c newEmailDomain = new Email_Domain__c(Account__c = sgAccountsMap.get(domain).Id, Name = domain);
                    emailDomains.put(domain, newEmailDomain);
                }
            }
            else if(sgAccountsMap.get(sgAccount.Id) != null){
                SendGrid_Account__c sgAccountWithNewAccount = new SendGrid_Account__c(Id = sgAccount.Id, Account__c = sgAccountsMap.get(sgAccount.Id).Id);
                updateAccounts.add(sgAccountWithNewAccount);
            }
        }
        
        update updateAccounts;
        insert emailDomains.values();
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}