public with sharing class AccountReassignmentServices {
    
    @TestVisible
    class UsageOwner{
        Decimal floor;
        Decimal ceiling;
        Id ownerId;
        Id groupId;
        Boolean isGroup;
        
        public UsageOwner(Decimal floor, Decimal ceiling, Id ownerId, Id groupId){
            this.floor = floor;
            this.ceiling = ceiling;
            this.ownerId = ownerId;
            this.groupId = groupId;
            this.isGroup = groupId != null;
        }
        
        public Boolean isOwner(Decimal usage){
            if(usage != null){
                if(usage >= this.floor){
                    if(this.ceiling == null || usage < this.ceiling) return true;
                }
            }
            return false;
        }
    }
    
    static Map<Id, DateTime> userIdToAccountCount {
        get{
            if(userIdToAccountCount == null){
                userIdToAccountCount = new Map<Id, DateTime>();
                List<User> users = [SELECT Id, LastRoundRobinTime__c FROM User WHERE IsActive = true AND Id in (SELECT UserOrGroupId From GroupMember WHERE Group.DeveloperName = 'Account_Round_Robin_Owners') ORDER BY LastRoundRobinTime__c DESC NULLS FIRST];
                //Set<Id> allIds = new Set<Id>();
                //for(User u: users){
                //    allIds.add(u.Id);
                //}
                /*AggregateResult[] groupedAccounts = [SELECT Count(Id), OwnerId FROM Account WHERE OwnerId =: allIds GROUP BY OwnerId ORDER BY Count(Id)];
                
                for(AggregateResult ar: groupedAccounts){
                    userIdToAccountCount.put((Id) ar.get('OwnerId'), Integer.valueOf(ar.get('expr0')));
                }*/
                for(User aUser: users){
                    if(!userIdToAccountCount.containsKey(aUser.Id)){
                        if(aUser.LastRoundRobinTime__c != null){
                            userIdToAccountCount.put(aUser.Id, aUser.LastRoundRobinTime__c);
                        }
                        else{
                            userIdToAccountCount.put(aUser.Id, DateTime.newInstance(2000,1,1,0,0,0));
                        }
                    }
                }
            }
            return userIdToAccountCount;
        }
        set;
    }
    
    @TestVisible
    static Map<String, List<UsageOwner>> locationToUsageOwnerMap{
        get{
            if(locationToUsageOwnerMap == null){
                locationToUsageOwnerMap = new Map<String, List<UsageOwner>>();
                for(Account_Reassignment__c rule: [SELECT Assignment_Group__c, ISO_Country_Code__c, Country__c, State__c, Zip_Code__c, Usage_Ceiling__c, Usage_Floor__c, New_Owner__c FROM Account_Reassignment__c WHERE New_Owner__c != null]){
                    String keyString = rule.Country__c;
                    if(rule.State__c != null) keyString +=  '-' + rule.State__c;
                    String keyString2 = rule.ISO_Country_Code__c;
                    if(rule.Zip_Code__c != null) keyString += '-' + rule.Zip_Code__c;
                    UsageOwner usageOwner = new UsageOwner(rule.Usage_Floor__c, rule.Usage_Ceiling__c, rule.New_Owner__c, rule.Assignment_Group__c);
                    if(locationToUsageOwnerMap.containsKey(keyString)){
                        locationToUsageOwnerMap.get(keyString).add(usageOwner);
                    }
                    else{
                        locationToUsageOwnerMap.put(keyString, new List<UsageOwner>{usageOwner});
                    }
                    if(keyString2 != null){
                        if(locationToUsageOwnerMap.containsKey(keyString2)){
                            locationToUsageOwnerMap.get(keyString2).add(usageOwner);
                        }
                        else{
                            locationToUsageOwnerMap.put(keyString2, new List<UsageOwner>{usageOwner});
                        } 
                    }
                }
            }
            return locationToUsageOwnerMap;
        }
        set;
    }
    
    public static void reassignOwner(List<Account> accounts){
        
        List<Account> updateAccounts = new List<Account>();
        Map<Id, User> updateUsers = new Map<Id, User>();
        Map<Account, Id> accToGroupIdMap = new Map<Account, Id>();
        for(Account acc: accounts){
            String keyString = acc.SFDC_Country__c; 
            if(acc.SFDC_State__c != null) keyString += '-' + acc.SFDC_State__c;
            if(acc.SFDC_ZipCode__c != null) keyString += '-' + acc.SFDC_ZipCode__c;
            List<UsageOwner> usageOwners = locationToUsageOwnerMap.get(keyString);
            List<Decimal> accNumbers = new List<Decimal>{acc.Average_Amortized_Usage_Last_3_Months__c, acc.Total_Amortized_Twilio_Usage_This_Month__c, acc.Total_Amortized_Twilio_Usage_Last_Month__c};
            if(usageOwners != null && !usageOwners.isEmpty()){
                Boolean hasAvailable = false;
                for(Integer i = 0; i < 3; i++){
                    Decimal amount = accNumbers[i];
                       for(Integer j = 0; j <  usageOwners.size(); j++){
                           if(usageOwners[j].isOwner(amount)) {hasAvailable = true; break;}
                       }
                }
                if(!hasAvailable) usageOwners = new List<UsageOwner>();   
            }
            if(usageOwners == null || usageOwners.isEmpty()){
                keyString = acc.SFDC_Country__c + '-' + acc.SFDC_State__c;
                usageOwners = locationToUsageOwnerMap.get(keyString);
                if(usageOwners != null && !usageOwners.isEmpty()){
                    Boolean hasAvailable = false;
                    for(Integer i = 0; i < 3; i++){
                        Decimal amount = accNumbers[i];
                           for(Integer j = 0; j < usageOwners.size(); j++){
                               if(usageOwners[j].isOwner(amount)) {hasAvailable = true; break;}
                           }
                    }
                    if(!hasAvailable) usageOwners = new List<UsageOwner>();   
                }
                if(usageOwners == null || usageOwners.isEmpty()){
                     keyString = acc.SFDC_Country__c;
                     usageOwners = locationToUsageOwnerMap.get(keyString);
                }
            }
            if(usageOwners != null && !usageOwners.isEmpty()){
                Boolean findOwner = false;
                Boolean findGroup = false;
                for(Integer i = 0; i < 3; i++){
                    Decimal amount = accNumbers[i];
                    for(UsageOwner usageOwner: usageOwners){
                        if(usageOwner.isOwner(amount) && usageOwner.isGroup){
                            findGroup = true;
                            accToGroupIdMap.put(acc, usageOwner.groupId);
                            break;
                        }
                        else if(usageOwner.isOwner(amount) && usageOwner.ownerId != null){
                            acc.OwnerId = usageOwner.ownerId;
                            updateAccounts.add(acc);
                            findOwner = true;
                            break;
                        }
                    }
                    if(findOwner || findGroup) break;
                }
                if(!findOwner && !findGroup){
                    if(accNumbers[0] >= 500 || accNumbers[1] >= 500 || accNumbers[2] >= 500){
                        Id newOwnerId = roundRobinOwners();
                        if(newOwnerId != null){
                            updateUsers.put(newOwnerId, new User(Id = newOwnerId, LastRoundRobinTime__c = Datetime.now()));
                            acc.OwnerId = newOwnerId;
                            updateAccounts.add(acc);
                        }
                    }
                }
            }
            else{
                if(accNumbers[0] >= 500 || accNumbers[1] >= 500 || accNumbers[2] >= 500){
                    Id newOwnerId = roundRobinOwners();
                    if(newOwnerId != null){
                        updateUsers.put(newOwnerId, new User(Id = newOwnerId, LastRoundRobinTime__c = Datetime.now()));
                        acc.OwnerId = newOwnerId;
                        updateAccounts.add(acc);
                    }
                }
            }
        }
        system.debug(accToGroupIdMap);
        Map<Id, List<Assignment_Groups__c>> groupIdToMembersMap = new Map<Id, List<Assignment_Groups__c>>();
        Map<Id, Assignment_Groups__c> updateMembersMap = new Map<Id, Assignment_Groups__c>();
        
        if(!accToGroupIdMap.isEmpty()){
            for(Assignment_Group_Name__c assignmentGroup : [SELECT Id, ( SELECT Id, Last_Assignment__c, Millisecond__c, User__c 
                                                                        FROM Assignment_Groups__r
                                                                        WHERE Active__c = 'True' AND User_Active__c = 'True')
                                                           FROM Assignment_Group_Name__c
                                                           WHERE Id =: accToGroupIdMap.values()]){
                
                List<Assignment_Groups__c> sortedMembers = MQLRoundRobinServices.sortMemebersByLastAssignmentTime(assignmentGroup.Assignment_Groups__r);
                groupIdToMembersMap.put(assignmentGroup.Id, sortedMembers);
            }
           
            
            for(Account acc: accToGroupIdMap.keySet()){
                Id groupId = accToGroupIdMap.get(acc);
                if(groupId != null){
                     List<Assignment_Groups__c> members = groupIdToMembersMap.get(groupId);
                     if(!members.isEmpty()){
                        acc.OwnerId = members[0].User__c;
                        Datetime now = Datetime.now();
                        members[0].Last_Assignment__c = now;
                        members[0].Millisecond__c = now.millisecondGMT();
                        Assignment_Groups__c element = members.remove(0);
                        updateMembersMap.put(element.Id, element.clone(true, true, true, true));
                        members.add(element);
                        updateAccounts.add(acc);
                    }
                }
            }
        }
        
        Database.upsert(updateMembersMap.values(), false);
        Database.update(updateAccounts, false);
        Database.update(updateUsers.values(), false);
    }
    
    @TestVisible
    private static Id roundRobinOwners(){
        DateTime min = DateTime.newInstance(2099,1,1,0,0,0);
        Id result = null;
        for(Id userId: userIdToAccountCount.keySet()){
            if(userIdToAccountCount.get(userId) < min){
                result = userId;
                min = userIdToAccountCount.get(userId);
            }
        }
        DateTime resultCount = userIdToAccountCount.get(result);
        if(resultCount != null)
            resultCount = DateTime.now();
        return result;
    }
    
    public static void reassignOwnerAccountSID(List<Account_SID__c> accountSIDs){
        
        
        List<Account> updateAccounts = new List<Account>();
        List<Account> insertAccounts = new List<Account>();
        List<Account_SID__c> updateAccountSIDs = new List<Account_SID__c>();
        List<Contact> updateContacts = new List<Contact>();
        Map<String, Set<Id>> accountSIDEmailDomainMap = new Map<String, Set<Id>>();
        Map<Id, Id> accountSIDOwnerMap = new Map<Id, Id>();
        Map<Id, Id> accountSIDLeadMap = new Map<Id, Id>();
        Map<Id, Id> accountSIDContactMap = new Map<Id, Id>();
        List<Account_SID__c> filteredAccountSIDs = new List<Account_SID__c>();
        Map<Id, Id> accountSIDtoAccountIdMap = new Map<Id, Id>();
        
        for(Account_SID__c accountSID: accountSIDs){
            List<UsageOwner> usageOwners = locationToUsageOwnerMap.get(accountSID.ISO_Country_Code__c);
            Boolean added = false;
            if(accountSID.NPC_Date_5__c != null || accountSID.Twilio_org_Pricing_Model__c == true){
                filteredAccountSIDs.add(accountSID);
                added = true;
            
            }
            if(usageOwners != null){
                List<Decimal> accNumbers = new List<Decimal>{accountSID.Average_Amortized_Usage_Last_3_Months__c, accountSID.Total_Amortized_Twilio_Usage_This_Month__c, accountSID.Total_Amortized_Twilio_Usage_Last_Month__c};
                Boolean findOwner = false;
                for(Integer i = 0; i < accNumbers.size(); i++){
                    Decimal amount = accNumbers[i];
                    for(UsageOwner usageOwner: usageOwners){
                        if(usageOwner.isOwner(amount)){
                            accountSIDOwnerMap.put(accountSID.Id, usageOwner.ownerId);
                            findOwner = true;
                            break;
                        }
                    }
                    if(findOwner) break;
                }
                if(findOwner && !added){
                    filteredAccountSIDs.add(accountSID);
                    added = true;
                }
            }
        }
        
        for(Account_SID__c accountSID: filteredAccountSIDs){
            
            if(accountSID.Lead__c != null){
                accountSIDLeadMap.put(accountSID.Id, accountSID.Lead__c);
            }
            else if(accountSID.Contact__c != null){
                if(accountSID.Contact__r.AccountId != null){
                    accountSID.Account__c = accountSID.Contact__r.AccountId;
                    updateAccountSIDs.add(accountSID);
                }
                else{
                    //create new account and relate contact and accountSID
                    Set<Id> accountSIDids = accountSIDEmailDomainMap.get(accountSID.Email_Domain__c);
                    if(accountSIDids == null) accountSIDids = new Set<Id>();
                    accountSIDids.add(accountSID.Id);
                    if(accountSID.Email_Domain__c != null)
                        accountSIDEmailDomainMap.put(accountSID.Email_Domain__c.toUpperCase(), accountSIDids);
                    accountSIDContactMap.put(accountSID.Id, accountSID.Contact__c);
                    accountSIDtoAccountIdMap.put(accountSID.Id, null);
                }
            }
            else{
                //create new account and relate accountSID
                Set<Id> accountSIDids = accountSIDEmailDomainMap.get(accountSID.Email_Domain__c);
                if(accountSIDids == null) accountSIDids = new Set<Id>();
                accountSIDids.add(accountSID.Id);
                if(accountSID.Email_Domain__c != null) accountSIDEmailDomainMap.put(accountSID.Email_Domain__c.toUpperCase(), accountSIDids);
                accountSIDtoAccountIdMap.put(accountSID.Id, null);
            }
        }
        
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT ISO_Country_Code__c, FirstName, LeadSource, LastName, Description FROM Lead WHERE Id =: accountSIDLeadMap.values()]);
        Set<Id> leadIds = leadMap.keySet().clone();
        if(!leadMap.isEmpty()) LeadAutoConvertHandler.convertNPCLead(leadMap);
        Map<Id, Id> convertedAccountIdMap = new Map<Id, Id>();
        Map<Id, Id> convertedContactIdMap = new Map<Id, Id>();
        for(Lead aLead: [SELECT ConvertedAccountId FROM Lead WHERE Id =: leadIds AND ConvertedAccountId != null]){
            convertedAccountIdMap.put(aLead.Id, aLead.ConvertedAccountId);  
        }
        
        String userIdString = Account_Reassignment_User__c.getOrgDefaults().Current_User_ID__c;
        Id userId = userIdString.split(',')[0];
        
        for(Account acc: [SELECT OwnerId FROM Account WHERE Id =: convertedAccountIdMap.values()]){
            if(acc.OwnerId == userId){
                Id leadId;
                for(Id aLeadId: convertedAccountIdMap.keySet()){
                    if(convertedAccountIdMap.get(aLeadId) == acc.Id){
                        leadId = aLeadId;
                        break;
                    }
                }
                if(leadId != null){
                    Id accountSIDid;
                    for(Id accountSID: accountSIDLeadMap.keySet()){
                        if(accountSIDLeadMap.get(accountSID) == leadId){
                            accountSIDid = accountSID;
                            break;
                        }
                    }
                    if(accountSIDid != null){
                        updateAccountSIDs.add(new Account_SID__c(Id = accountSIDid, Account__c = acc.Id));
                        if(accountSIDOwnerMap.get(accountSIDid) != null){
                            acc.OwnerId = accountSIDOwnerMap.get(accountSIDid);
                            updateAccounts.add(acc);
                        }
                    }
                }
            }
        }
        
        
        for(Email_Domain__c domain: [
            SELECT Name, Account__r.Id
            FROM Email_Domain__c
            WHERE Name IN :accountSIDEmailDomainMap.keySet()
            AND Approved__c = true
            AND Account__r.Owner.IsActive = true
        ]){
             for(Id domainId: accountSIDEmailDomainMap.get(domain.Name.toUpperCase())){
                accountSIDtoAccountIdMap.put(domainId, domain.Account__r.Id);
             }
        }
        
        Map<Id, Account> accountSIDtoAccountMap = new Map<Id, Account>();
        for(Id accountSIDid: accountSIDtoAccountIdMap.keySet()){
            Id accountId = accountSIDtoAccountIdMap.get(accountSIDid);
            if(accountId != null){
                updateAccountSIDs.add(new Account_SID__c(Id = accountSIDid, Account__c = accountId));
            }
            else{
                Account newAcc = new Account(OwnerId = userId, Name = '[Unknown]', NPC_Convert_Date__c = Date.today());
                if(accountSIDOwnerMap.get(accountSIDid) != null){
                    newAcc.OwnerId = accountSIDOwnerMap.get(accountSIDid);
                }
                insertAccounts.add(newAcc);
                accountSIDtoAccountMap.put(accountSIDid, newAcc);
            }
        }
        
        
        Database.insert(insertAccounts, false);
        for(Id accountSIDid: accountSIDtoAccountMap.keySet()){
           if(accountSIDtoAccountMap.get(accountSIDid).Id != null){
              updateAccountSIDs.add(new Account_SID__c(Id = accountSIDid, Account__c = accountSIDtoAccountMap.get(accountSIDid).Id));
           } 
        }
        Database.update(updateAccountSIDs, false);
        Database.update(updateAccounts, false);
        
    }

}