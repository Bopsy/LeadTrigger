public with sharing class ShortCodeTriggerHandler {
    public static void clearShortCodeOnOpportunity(Boolean isUpdate, Boolean isDelete, List<Short_Code__c> newList, Map<Id,Short_Code__c> oldMap) {
        // Create a set of all Short_Code__c records that need to be cleared
        // when the Opportunity.Short_Code__c no longer points to it
        Set<Id> opportunitiesToClear = new Set<Id>();
        if (isUpdate) {
            for (Short_Code__c n : newList) {
                Short_Code__c o = oldMap.get(n.Id);
                if (n.Opportunity__c == null && o.Opportunity__c != null) {
                    System.debug('UPDATE - ADDING TO opportunitiesToClear: ' + o.Opportunity__c);
                    opportunitiesToClear.add(o.Opportunity__c);
                }
            }       
        } else if (isDelete) {
            for (Short_Code__c o : oldMap.values()) {
                if (o.Opportunity__c != null) {
                    System.debug('DELETE - ADDING TO opportunitiesToClear: ' + o.Opportunity__c);
                    opportunitiesToClear.add(o.Opportunity__c);
                }
            }
        }
        
        if (!opportunitiesToClear.isEmpty()) {
            List<Opportunity> opportunities = [
                SELECT Id, Short_Code__c
                FROM Opportunity
                WHERE Id IN :opportunitiesToClear
            ];
            if (!opportunities.isEmpty()) {
                for (Opportunity o : opportunities) {
                    System.debug('CLEARING Short_Code__c: ' + o.Id);
                    o.Short_Code__c = null;
                }

                System.debug('UPDATE Opportunities: ' + opportunities.size() + ' records');
                update opportunities;
            }
        }
    }

    // This method is meant to be used in Short_Code__c before trigger.
    // Returns list of short codes where updates are performed.
    public static void linkShortCodes(Map<Id,Short_Code__c> oldShortCodes, List<Short_Code__c> newShortCodes) {

        // If no short codes to process the nothing to do
        if (!newShortCodes.isEmpty()) {
    
            Map<Id,String> emailAddresses = new Map<Id,String>();
            for (Short_Code__c sc : newShortCodes) {
                if(sc.OwnerUser_Email_Address__c != null && sc.Application_Status__c != 'Created'){
                    emailAddresses.put(sc.Id, sc.OwnerUser_Email_Address__c);
                }
            }
            System.debug('ShortCodeTriggerHandler.linkShortCodes(EMAIL ADDRESSES): ' + emailAddresses);
            
            if(emailAddresses.isEmpty()) return;
            // Query the Contacts object using Short_Code__c.OwnerUser_Email_Address__c to find a Contact with that Email
            Map<Id,Contact> contacts = new Map<Id,Contact>([
                SELECT Id, AccountId, Email, Account.OwnerId
                FROM Contact
                WHERE Email IN :emailAddresses.values()
            ]);
            System.debug('ShortCodeTriggerHandler.linkShortCodes(CONTACTS): ' + contacts);
            
            Map<Id,Lead> leads = new Map<Id,Lead>([
                SELECT Id, Email
                FROM Lead
                WHERE Email IN :emailAddresses.values()
                AND IsConverted = false
            ]);
            System.debug('ShortCodeTriggerHandler.linkShortCodes(LEADS): ' + leads);
            
            for (Short_Code__c n : newShortCodes) {
                Short_Code__c o = oldShortCodes.get(n.Id);
                if ((o == null && n.Application_Status__c != 'Created') || ( o != null && o.Application_Status__c == 'Created' && n.Application_Status__c != o.Application_Status__c)) {
                    Boolean found = false;
    
                    // If Contact with Contact.Email equal to Short_Code__c.OwnerUser_Email_Address__c found
                    // link Short Code to Contact via Short_Code__c.Contact__c
                    for (Contact c : contacts.values()) {
                        if (c.Email == n.OwnerUser_Email_Address__c) {
                            n.Lead__c = null;
                            n.Contact__c = c.Id;
                            n.Account__c = c.AccountId;
                            n.OwnerId = c.Account.OwnerId;
                            found = true;
                            System.debug('ShortCodeTriggerHandler.linkShortCodes(SHORT_CODE LINKED TO CONTACT): ' + n);
                        }
                    }
    
                    // If no Contact matched then if Lead with Lead.Email equal to Short_Code__c.OwnerUser_Email_Address__c found
                    // link Short Code to Lead via Short_Code__c.Lead__c
                    if (!found) {
                        for (Lead l : leads.values()) {
                            if (l.Email == n.OwnerUser_Email_Address__c) {
                                n.Lead__c = l.Id;
                                System.debug('ShortCodeTriggerHandler.linkShortCodes(SHORT_CODE LINKED TO LEAD): ' + n);
                            }
                        }
                    }
                }
            }
        }
    }

    // When a Lead with MQL converts into Contact and Oppty
    //   - Set Short Code owner == Contact's Account Owner from converted Lead
    public static void setOwnershipToAccountOwner(List<Lead> convertedLeads) {

        // If no short codes to process the nothing to do
        if (!convertedLeads.isEmpty()) {
    
            Map<Id, Lead> leads = new Map<Id, Lead>(convertedLeads);
            System.debug('ShortCodeTriggerHandler.setOwnershipToAccountOwner(LEAD MAP): ' + leads);
            
            Set<Id> contactIds = new Set<Id>();
            for (Lead l : convertedLeads) {
                contactIds.add(l.ConvertedContactId);
            }
            Map<Id,Contact> contacts = new Map<Id,Contact>([ SELECT Id, Account.OwnerId FROM Contact WHERE Id IN :contactIds ]);
            
            // Query the Contacts and Leads via the MQL (FSR__c) object using Short_Code__c.OwnerUser_Email_Address__c
            List<Short_Code__c> shortCodes = [
                SELECT Id, Lead__c, Opportunity__c, Account__c, Contact__c, Contact__r.AccountId, Contact__r.Account.OwnerId FROM Short_Code__c WHERE Lead__c IN :leads.keySet() AND MQL__c != null
            ];
            System.debug('ShortCodeTriggerHandler.setOwnershipToAccountOwner(SHORT CODES): ' + shortCodes);
    
            for (Short_Code__c shortCode : shortCodes) {
                Lead l = leads.get(shortCode.Lead__c);

                shortCode.OwnerId = contacts.get(l.ConvertedContactId).Account.OwnerId;
                shortCode.Opportunity__c = l.ConvertedOpportunityId;
                shortCode.Account__c = l.ConvertedAccountId;
                shortCode.Contact__c = l.ConvertedContactId;

                System.debug('ShortCodeTriggerHandler.setOwnershipToAccountOwner(SHORT CODES): ' + shortCode);
            }
            System.debug('ShortCodeTriggerHandler.setOwnershipToAccountOwner(SHORT CODES UPDATED): ' + shortCodes);
            
            update shortCodes;
        }
    }
    
}