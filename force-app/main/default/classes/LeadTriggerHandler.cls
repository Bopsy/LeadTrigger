//----------------------------------------------------------------------------------------------------------
// Handler class of LeadTriggerHandler
//----------------------------------------------------------------------------------------------------------
public without sharing class LeadTriggerHandler {

    // Users that are considered API/Eloqua
    public static Set<String> apiUsers = new Set<String> { 'Kevin Eloqua', 'Jonathan Eloqua', 'Brittany Eloqua', 'API-Read Only', 'Eloqua Marketing', 'Davis Dong'};
    public static Boolean runOnce = false;
    public static Boolean autoConvertRunOnce = false;
    // Determine if the current running user is Eloqua
    public static Boolean isRunningAsApiUser() {
        return apiUsers.contains(UserInfo.getName());
    }

    public static Boolean useCaseConverted = false;


    // Sets the Lead owner

    public static void ownerUpdate(Boolean isUpdate, Boolean isInsert, Map<Id,Lead> oldMap, Map<Id,Lead> newMap) {
        /*List<Lead> updateCS = new List<Lead>();
        Map<Id,Lead> leadsEloquaOverrideOwner = new Map<Id,Lead>();
        Map<Id,Lead> leadsTempOwner = new Map<Id,Lead>();

        for (Lead cs : newMap.values()) {
            // Check for ELOQUA Override Owner
            if(!String.isBlank(cs.ELOQUA_Override_Ownership__c)) {
                System.debug('>>>>> Owner ID: '+cs.ownerId+' ELOQUA Owner ID: '+cs.ELOQUA_Override_Ownership__c);
                if(cs.OwnerId != cs.ELOQUA_Override_Ownership__c) {
                    leadsEloquaOverrideOwner.put(cs.id,cs);
                }
            } else {
                // Preserved because this TempOwnerId process is unknown why it was implemented, but will be only
                // performed if the ELOQUA_Override_Ownership__c is not set.
                if(isUpdate) {
                    System.debug('>>>>> Owner ID: '+cs.ownerId+' Temp Owner ID: '+cs.TempOwnerId__c);
                    if(cs.TempOwnerId__c <> null && cs.TempOwnerId__c <> '') {
                        if(cs.OwnerId <> cs.TempOwnerId__c) {
                            leadsTempOwner.put(cs.id,cs);
                        }
                    }
                }
            }
        }

        if (!leadsTempOwner.isEmpty() || !leadsEloquaOverrideOwner.isEmpty()) {

            Set<Id> allLeadIds = new Set<Id>();
            allLeadIds.addAll(leadsTempOwner.keySet());
            allLeadIds.addAll(leadsEloquaOverrideOwner.keySet());
            List<Lead> leadsToUpdate = [ SELECT OwnerId, TempOwnerId__c,ELOQUA_Override_Ownership__c FROM Lead WHERE Id in :allLeadIds ];

            if (!leadsToUpdate.isEmpty()) {
                for (Lead cs : leadsToUpdate) {
                    // Preserved because this TempOwnerId process is unknown why it was implemented, but will be only
                    // performed if the ELOQUA_Override_Ownership__c is not set.
                    if (leadsTempOwner.containsKey(cs.Id)) {
                        cs.OwnerId = leadsTempOwner.get(cs.Id).TempOwnerId__c;
                        cs.TempOwnerId__c = 'SKIP'; //flag to stop infinite loop upon update
                        updateCS.add(cs);
                    }

                    if (leadsEloquaOverrideOwner.containsKey(cs.Id)) {
                        cs.OwnerId = leadsEloquaOverrideOwner.get(cs.Id).ELOQUA_Override_Ownership__c;
                        updateCS.add(cs);
                    }
                }
            }

            //
            //Update last assignment for Assignment Group in batch
            //
            System.debug('>>>>>Update Leads: '+updateCS);
            if (updateCS.size()>0) {
                try {
                    update updateCS;
                } catch (Exception e){

                }
            }
        }*/
    }

    // Performs Lead autoconversion for Partner Portal leads
    public static void partnerPortalAutoConversion(Boolean isUpdate, Boolean isInsert, Map<Id,Lead> oldMap, Map<Id,Lead> newMap) {
        // If the current running user is not API/Eloqua (or other test users) then skip this process
        //if (!isRunningAsApiUser())  return;
        /*UseCaseConvertController.inConversion = true;
        System.debug('Running as ELOQUA API user: ' + UserInfo.getName());

        // Configurable variables
        Set<String> leadSourceCriteria = new Set<String> { 'Showcase', 'Twilio.org Showcase' };
        String convertedLeadStatus     = 'Opportunity';
        String salesOpsName            = 'Sales Operations';

        // Only operate on leads that meet the lead source criteria
        Map<Id,Lead> leads = new Map<Id,Lead>();
        Set<String> leadEmailDomains = new Set<String>();
        for (Lead n : newMap.values()) {
            // Validate that the lead meets the criteria of a Partner Portal lead.
            // If LeadSource matches a value in the leadSourceCriteria set, or if
            // Last_Lead_Source__c change to a matching value in the leadSourceCriteria set
            Boolean lastLeadSourceCriteriaMet = isInsert ? false : leadSourceCriteria.contains(n.Last_Lead_Source__c ) && (n.Last_Lead_Source__c != oldMap.get(n.Id).Last_Lead_Source__c);
            System.debug('Reviewing - Lead(' + n.Id + ') LeadSource(' + n.LeadSource + ') Last_Lead_Source__c(' + n.Last_Lead_Source__c + ') Partner_ID(' + n.Partner_ID__c + ') lastLeadSourceCriteriaMet(' + lastLeadSourceCriteriaMet + ')');
            if (!n.isConverted
                && (leadSourceCriteria.contains(n.LeadSource) || (lastLeadSourceCriteriaMet))
                //&& n.Partner_ID__c != null
            ) {
                System.debug('Qualifying lead:  Lead(' + n.Id + ')');
                leads.put(n.Id, n);
                if (String.isNotBlank(n.Email_Domain_Without_HTTP_lower__c)) {
                    leadEmailDomains.add(n.Email_Domain_Without_HTTP_lower__c);
                    System.debug('Adding email domain: ' + n.Email_Domain_Without_HTTP_lower__c);
                }
            }
        }

        // If there are no leads that meet the criteria exit the trigger
        if (leads.isEmpty()) return;
        System.debug('Leads to be processed: ' + leads.size());

        // Get the LeadStatus to set whenever the leads are converted
        //LeadStatus convertStatus = null;
        //List<LeadStatus> convertStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel = :convertedLeadStatus ];
        //if (convertStatuses.size() != 1) {
        //    System.debug('Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"');
        //    TriggerUtil.setLeadError(newMap.values(), 'Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"');
        //    return;
        //} else {
        //    convertStatus = convertStatuses[0];
        //}

        // Generate a map of matching accounts having:
        //   - a qualifying email domain name
        //   - owned by an active user
        System.debug('GETTING LIST OF ACCOUNTS HAVING MATCHING EMAIL DOMAINS');
        Map<String,Email_Domain__c> matchingAccounts = new Map<String,Email_Domain__c>();
        for (Email_Domain__c d : [
            SELECT Id, Name, Account__r.Id, Account__r.Name, Account__r.OwnerId, Account__r.Owner.Email
            FROM Email_Domain__c
            WHERE Name IN :leadEmailDomains
            AND Approved__c = true
            AND Account__r.Owner.IsActive = true
        ]) {
            matchingAccounts.put(d.Name, d);
            System.debug('Account found having email domain "' + d.Name + '": ID(' + d.Id + ') AccountId(' + d.Account__r.Id + ') + Account(' + d.Account__r.Name +')');
        }

        // Instantiate Partner Portal Routing
        PartnerPortalRouting ppRouting;
        try {
            ppRouting = new PartnerPortalRouting();
            System.debug('Initialized Partner Portal Routing map');
        } catch (PartnerPortalRoutingException ex) {
            System.debug(ex.getMessage());
            TriggerUtil.setLeadError(newMap.values(), ex.getMessage());
            return;
        }

        // Get Sales Operations user to assign new Accounts and Contacts
        //User salesOpsUser;
        //try {
        //    salesOpsUser = [ SELECT Id FROM User WHERE Name = :salesOpsName LIMIT 1 ];
        //} catch (Exception ex) {
        //    System.debug('Unable to access ' + salesOpsName + ' user: ' + ex.getMessage());
        //    TriggerUtil.setLeadError(newMap.values(), ex.getMessage());
        //    return;
        //}

        // Convert the leads and load the resulting Account, Contact, and Opportunity records into the ConvertedLead list
        List<Database.LeadConvertResult> results = new List<Database.LeadConvertResult>();

        // Check to see if the lead matches multiple accounts
        for (Lead l : leads.values()) {
            // Convert lead
            Database.LeadConvert lc = new Database.LeadConvert();
            System.debug('Converting Lead: Id(' + l.Id + ')');

            lc.setLeadId(l.Id);
            lc.setConvertedStatus('Opportunity');
            //lc.setDoNotCreateOpportunity(true);


            // If the email is an existing and approved email domain, add to Account and a Contact will be created
            // Else no existing email domain a new Account and Contact will be created
            if (matchingAccounts.containsKey(l.Email_Domain_Without_HTTP_lower__c)) {
                lc.setAccountId(matchingAccounts.get(l.Email_Domain_Without_HTTP_lower__c).Account__r.Id);
                lc.setOwnerId(matchingAccounts.get(l.Email_Domain_Without_HTTP_lower__c).Account__r.OwnerId);
                System.debug('Associating Lead to Account having email domain "' + l.Email_Domain_Without_HTTP_lower__c + '": AccountId(' + matchingAccounts.get(l.Email_Domain_Without_HTTP_lower__c).Account__r.Id +')');
            } else {
                lc.setOwnerId('00540000002WTJF');
            }

            //if (!Test.isRunningTest()) {
                System.debug('Converting Lead');
                Database.LeadConvertResult lcr = Database.convertLead(lc);

                if (lcr.isSuccess()) {
                    System.debug('Lead Conversion SUCCESSFUL');
                    results.add(lcr);
                } else {
                    System.debug('Lead Conversion FAILED');
                    for (Database.Error e : lcr.getErrors()) {
                        System.debug('ERROR: ' + e.getMessage());
                    }
                }
            //}
        }

        List<Map<String,String>> convertedLeadProperties = new List<Map<String,String>>();
        UseCaseConvertController.inConversion = true;
        runOnce = true;
        for (Database.LeadConvertResult r : results) {
            Lead l = leads.get(r.getLeadId());
            OpportunityRoutingServices.AccountQBWrapper accWrapper = ppRouting.getAccWrapper(l.Country, l.State, l.PostalCode, l.REF_Showcase_Employee_Size__c);
            OpportunityRoutingServices.OppSettingWrapper oppWrapper = ppRouting.getOwnerWrapper(accWrapper.quarterBackId, l.Country, l.State, l.PostalCode, l.Volume__c, l.FY_16_Primary_Product__c, l.Showcase_Use_Case__c, l.REF_Showcase_Employee_Size__c);
            convertedLeadProperties.add(new Map<String,String> {
                'Lead.Name' => (String.isBlank(l.FirstName) ? '' : (l.FirstName + ' ')) + l.LastName,
                'Lead.Description' => l.Description,
                'Lead.Partner_ID__c' => l.Partner_ID__c,
                'Lead.CountryCode' => l.CountryCode,
                'Lead.Showcase_Employee_Size__c' => l.Showcase_Employee_Size__c,
                'Lead.Showcase_Use_Case__c' => l.Showcase_Use_Case__c,
                'Lead.LeadSource' => l.LeadSource,
                //'Opportunity.OwnerId' => ppRouting.getOwnerId(l.CountryCode, l.StateCode, l.Showcase_Employee_Size__c, l.Showcase_Use_Case__c),
                'Opportunity.OwnerId' => oppWrapper.oppOwnerId,
                'Opportunity.Solution_Sales_Specialist__c' => oppWrapper.specialistId,
                'Lead.Id' => r.getLeadId(),
                'Contact.Id' => r.getContactId(),
                'Opportunity.Id' => r.getOpportunityId(),
                'Account.Id' => r.getAccountId(),
                'Account.OwnerId' => accWrapper.quarterBackId
            });
        }
        LeadTriggerHandler.partnerPortalPostAutoConversion(leads, convertedLeadProperties);
        System.debug('Partner Portal Lead Conversion Routine Complete');*/
    }

    public static void partnerPortalPostAutoConversion(Map<Id,Lead> leads, List<Map<String,String>> leadList) {
        /*System.debug('Starting Post-Conversion Processing');

        // Load Partner Portal Mapping to assigned User from the customer setting data where the Partner Id is the key for lookup
        Map<String,PartnerPortalMappings__c> partnerPortalMap = new Map<String,PartnerPortalMappings__c>();
        for (PartnerPortalMappings__c p : PartnerPortalMappings__c.getAll().values()) {
            if (!String.isBlank(p.Partner_ID__c) && !String.isBlank(p.User_ID__c) && !String.isBlank(p.Account_ID__c)) {
                partnerPortalMap.put(p.Partner_ID__c, p);
            }
        }

        // Build a mapping of Use Case to Opportunity Record Types
        Map<String,Id> useCaseToOppRecTypeMap = new Map<String,Id>();
        for (Use_Case_to_Opp_Record_Type__c u : Use_Case_to_Opp_Record_Type__c.getAll().values()) {
            useCaseToOppRecTypeMap.put(u.Use_Case__c, u.Opp_Record_Type_ID__c);
        }

        // Determine that last day in the current fiscal quarter
        Date closeDate = [SELECT EndDate FROM Period WHERE Type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER].EndDate;
        System.debug('Last day of the current fiscal quarter = ' + closeDate);

        // Update the Opportunities and Contacts with additional information
        // Create Pass To Partner records
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Contact> contacts = new List<Contact>();
        List<Pass_To_Partner__c> passToPartners = new List<Pass_To_Partner__c>();
        List<Account> accounts = new List<Account>();

        Map<Id, Id> dealOwnerIdMap = new Map<Id, Id>();

        for (Map<String,String> properties : leadList) {
            String leadName = properties.get('Lead.Name');
            String leadDesc = properties.get('Lead.Description');
            System.debug('LEAD(' + properties.get('Lead.Id') + ', ' + leadName + ')');
            if(properties.get('Account.Id') != null){
                Account acc = new Account(
                    Id = properties.get('Account.Id'),
                    OwnerId = properties.get('Account.OwnerId')
                );
                accounts.add(acc);
            }
            Contact c = new Contact(
                Id = properties.get('Contact.Id'),
                Partner_Id__c = properties.get('Lead.Partner_ID__c')
            );
            contacts.add(c);

            Opportunity o = new Opportunity(
                Id = properties.get('Opportunity.Id'),
                OwnerId = properties.get('Opportunity.OwnerId'),
                Qualified_Lead_Source__c = properties.get('Lead.LeadSource'),
                Partner_ID__c = properties.get('Lead.Partner_ID__c'),
                Use_Case_Category__c = properties.get('Lead.Showcase_Use_Case__c'),
                Prospect_Notes_Showcase__c = properties.get('Lead.Description'),
                CloseDate = closeDate,
                Solution_Sales_Specialist__c = properties.get('Opportunity.Solution_Sales_Specialist__c')
            );

            dealOwnerIdMap.put(properties.get('Opportunity.Id'), properties.get('Account.OwnerId') == null ? properties.get('Opportunity.OwnerId') : properties.get('Account.OwnerId'));
            if (useCaseToOppRecTypeMap.containsKey(properties.get('Lead.Showcase_Use_Case__c'))) {
                o.RecordTypeId = useCaseToOppRecTypeMap.get(properties.get('Lead.Showcase_Use_Case__c'));
                System.debug('Setting Opportunity.RecordTypeId to "' + o.RecordTypeId + '"');
            } else {
                System.debug('Missing Use Case to Opportunity Record Type mapping:  "' + properties.get('Lead.Showcase_Use_Case__c') + '" does not have a entry in Use_Case_to_Opp_Record_Type__c custom setting.');
            }
            opportunities.add(o);

            // Determine if there is an owner mapping for the Partner ID
            String ownerId = UserInfo.getUserId();
            String accountId = [SELECT Contact.AccountId FROM User WHERE Id = :ownerId LIMIT 1].Contact.AccountId;
            if (partnerPortalMap.containsKey(properties.get('Lead.Partner_ID__c')) && partnerPortalMap.get(properties.get('Lead.Partner_ID__c')) != null) {
                ownerId = partnerPortalMap.get(properties.get('Lead.Partner_ID__c')).User_ID__c;
                accountId = partnerPortalMap.get(properties.get('Lead.Partner_ID__c')).Account_ID__c;
                System.debug('Using Lead Partner ID for Partner User Map matching "' + properties.get('Lead.Partner_ID__c') + '": OwnerId(' + ownerId + ')');
            } else {
                System.debug('No Partner User mapping found for Partner ID "' + properties.get('Lead.Partner_ID__c') + '"');
                leads.get(properties.get('Lead.Id')).addError('No Partner User mapping found for Partner ID "' + properties.get('Lead.Partner_ID__c') + '"');
            }

            if (ownerId != null) {
                passToPartners.add(new Pass_To_Partner__c(
                    OwnerId = ownerId,
                    Partner_Account__c = accountId,
                    Opportunity__c = properties.get('Opportunity.Id'),
                    Contact__c = properties.get('Contact.Id'),
                    Partner_Status__c = 'Submitted to Partner'
                ));
            }
        }

        List<Deal__c> deals = new List<Deal__c>();
        if(!dealOwnerIdMap.isEmpty()){
            for(Opportunity opp: [SELECT Id, Deal__c, Deal__r.OwnerId FROM Opportunity WHERE Id =: dealOwnerIdMap.keySet()]){
                Deal__c newDeal = new Deal__c(Id = opp.Deal__c, OwnerId = dealOwnerIdMap.get(opp.Id));
                deals.add(newDeal);
            }
        }
        System.debug('Updating Opportunities, Contacts, and Pass To Partner records');
        update accounts;
        //update deals;
        update opportunities;
        update contacts;
        insert passToPartners;

        System.debug('Completed Post-Conversion Processing');*/
    }


    // Performs Lead autoconversion for Partner Deal Submissions

    public static void partnerDealSubmission(Boolean isUpdate, Boolean isInsert, Map<Id,Lead> oldMap, Map<Id,Lead> newMap) {

        /*// Configurable variables
        Set<String> leadSourceCriteria = new Set<String> { 'Deal Registration', 'Referral' };
        String convertedLeadStatus     = 'Opportunity';
        String salesOpsName            = 'Sales Operations';

        // Only operate on leads that meet the lead source criteria
        Map<Id,Lead> dealRegistrationLeads = new Map<Id,Lead>();
        Map<Id,Lead> referralLeads = new Map<Id,Lead>();
        Set<String> leadEmailDomains = new Set<String>();
        Set<String> leadPartnerIDs = new Set<String>();
        for (Lead n : newMap.values()) {
            // Validate that the lead meets the criteria of a Partner Portal lead.
            // If LeadSource matches a value in the leadSourceCriteria set
            System.debug('Reviewing - Lead(' + n.Id + ') LeadSource(' + n.LeadSource + ') Deal_Type__c(' + n.Deal_Type__c + ') Partner_ID__c(' + n.Partner_ID__c + ')');
            if (!n.isConverted
                && leadSourceCriteria.contains(n.LeadSource)
                //&& n.Partner_ID__c != null
            ) {
                System.debug('Qualifying lead:  Lead(' + n.Id + ')');
                if (n.Deal_Type__c == 'Deal Registration')  dealRegistrationLeads.put(n.Id, n);
                else if (n.Deal_Type__c == 'Referral')      referralLeads.put(n.Id, n);
                else continue;

                //leadPartnerIDs.add(n.Partner_ID__c);

                if (String.isNotBlank(n.Email_Domain_Without_HTTP_lower__c)) {
                    leadEmailDomains.add(n.Email_Domain_Without_HTTP_lower__c);
                    System.debug('Adding email domain: ' + n.Email_Domain_Without_HTTP_lower__c);
                }
            }
        }

        // If there are no leads that meet the criteria exit the trigger
        if (dealRegistrationLeads.isEmpty() && referralLeads.isEmpty()) return;
        System.debug('Deal Registration Leads to be processed: ' + dealRegistrationLeads.size());
        System.debug('Referral Leads to be processed: ' + referralLeads.size());

        // Get the LeadStatus to set whenever the leads are converted
        LeadStatus convertStatus = null;
        List<LeadStatus> convertStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel = :convertedLeadStatus ];
        if (convertStatuses.size() != 1) {
            System.debug('Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"');
            TriggerUtil.setLeadError(newMap.values(), 'Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"');
            return;
        } else {
            convertStatus = convertStatuses[0];
        }

        // Generate a map of matching accounts having:
        //   - a qualifying email domain name
        //   - owned by an active user
        System.debug('GETTING LIST OF ACCOUNTS HAVING MATCHING EMAIL DOMAINS');
        Map<String,Email_Domain__c> matchingAccounts = new Map<String,Email_Domain__c>();
        for (Email_Domain__c d : [
            SELECT Id, Name, Account__r.Id, Account__r.Name, Account__r.OwnerId, Account__r.Owner.Email
            FROM Email_Domain__c
            WHERE Name IN :leadEmailDomains
            AND Approved__c = true
            AND Account__r.Owner.IsActive = true
        ]) {
            matchingAccounts.put(d.Name, d);
            System.debug('Account found having email domain "' + d.Name + '": ID(' + d.Id + ') AccountId(' + d.Account__r.Id + ') Account(' + d.Account__r.Name +')');
        }

        // Generate a map of accounts looked up by Partner ID
        System.debug('GETTING LIST OF ACCOUNTS FOR PARTNERS:  PartnerIDs(' + String.join(new List<String>(leadPartnerIDs), ',')+ ') PartnerID_Count=' + leadPartnerIDs.size());
        Map<String,Account> partnerAccounts = new Map<String,Account>();
        for (Account a : [
            SELECT Id, Name, OwnerId, Owner.Email, Partner_ID__c, Alliance_Owner__c
            FROM Account
            WHERE Partner_ID__c IN :leadPartnerIDs
        ]) {
            partnerAccounts.put(a.Partner_ID__c, a);
            System.debug('Account found having partner ID "' + a.Partner_ID__c + '": ID(' + a.Id + ') Name(' + a.Name +')');
        }

        // Generate a map of accounts looked up by Partner ID
        System.debug('GETTING LIST OF USERS FOR PARTNERS');
        Map<String,User> partnerUsers = new Map<String,User>();
        Id currentUserId = UserInfo.getUserId();
        for (User u : [
            SELECT Id, Name, Email, Partner_ID_Text__c
            FROM User
            WHERE Id IN :currentUserId
        ]) {
            //partnerUsers.put(u.Partner_ID_Text__c, u);
            //System.debug('User found having partner ID "' + u.Partner_ID_Text__c + '": ID(' + u.Id + ') Name(' + u.Name +')');
        }

        // Instantiate Partner Portal Routing
        PartnerPortalRouting ppRouting;
        try {
            ppRouting = new PartnerPortalRouting();
            System.debug('Initialized Partner Portal Routing map');
        } catch (PartnerPortalRoutingException ex) {
            System.debug(ex.getMessage());
            TriggerUtil.setLeadError(newMap.values(), ex.getMessage());
            return;
        }

        // Get Sales Operations user to assign new Accounts and Contacts
        User salesOpsUser;
        try {
            salesOpsUser = [ SELECT Id FROM User WHERE Name = :salesOpsName LIMIT 1 ];
        } catch (Exception ex) {
            System.debug('Unable to access ' + salesOpsName + ' user: ' + ex.getMessage());
            TriggerUtil.setLeadError(newMap.values(), ex.getMessage());
            return;
        }

        // Convert the Deal Registration leads and load the resulting Account, Contact, and Opportunity records into the ConvertedLead list
        List<Database.LeadConvertResult> dealRegistrationResults = new List<Database.LeadConvertResult>();
        UseCaseConvertController.inConversion = true;
        runOnce = true;
        for (Lead l : dealRegistrationLeads.values()) {
            // Convert lead
            Database.LeadConvert lc = new Database.LeadConvert();
            OpportunityRoutingServices.AccountQBWrapper accWrapper = ppRouting.getAccWrapper(l.Country, l.State, l.PostalCode, l.REF_Showcase_Employee_Size__c);
            OpportunityRoutingServices.OppSettingWrapper oppWrapper = ppRouting.getOwnerWrapper(accWrapper.quarterBackId, l.Country, l.State, l.PostalCode, l.Volume__c, l.FY_16_Primary_Product__c, l.Showcase_Use_Case__c, l.REF_Showcase_Employee_Size__c);
            System.debug('Converting Deal Registration Lead: Id(' + l.Id + ')');

            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);

            // If the email is an existing and approved email domain, add to Account and a Contact will be created
            // Else no existing email domain a new Account and Contact will be created
            if (matchingAccounts.containsKey(l.Email_Domain_Without_HTTP_lower__c)) {
                lc.setAccountId(matchingAccounts.get(l.Email_Domain_Without_HTTP_lower__c).Account__r.Id);
                //lc.setOwnerId((partnerAccounts.containsKey(l.Partner_ID__c) && partnerAccounts.get(l.Partner_ID__c).Alliance_Owner__c != null) ? partnerAccounts.get(l.Partner_ID__c).Alliance_Owner__c : salesOpsUser.Id);
                lc.setOwnerId(matchingAccounts.get(l.Email_Domain_Without_HTTP_lower__c).Account__r.OwnerId);
                System.debug('Associating Referral Lead to Account having email domain "' + l.Email_Domain_Without_HTTP_lower__c + '": AccountId(' + matchingAccounts.get(l.Email_Domain_Without_HTTP_lower__c).Account__r.Id +')');
            } else {
                lc.setOwnerId(salesOpsUser.Id);
            }

            //if (!Test.isRunningTest()) {
                System.debug('Converting Deal Registration Lead');
                Database.LeadConvertResult lcr = Database.convertLead(lc);

                if (lcr.isSuccess()) {
                    System.debug('Deal Registration Lead Conversion SUCCESSFUL');
                    dealRegistrationResults.add(lcr);
                } else {
                    System.debug('Deal Registration Lead Conversion FAILED');
                    for (Database.Error e : lcr.getErrors()) {
                        System.debug('ERROR: ' + e.getMessage());
                    }
                }
            //}
        }

        // Convert the Reseller leads and load the resulting Account, Contact, and Opportunity records into the ConvertedLead list
        List<Database.LeadConvertResult> referralResults = new List<Database.LeadConvertResult>();

        for (Lead l : referralLeads.values()) {
            // Convert lead
            OpportunityRoutingServices.AccountQBWrapper accWrapper = ppRouting.getAccWrapper(l.Country, l.State, l.PostalCode, l.REF_Showcase_Employee_Size__c);
            OpportunityRoutingServices.OppSettingWrapper oppWrapper = ppRouting.getOwnerWrapper(accWrapper.quarterBackId, l.Country, l.State, l.PostalCode, l.Volume__c, l.FY_16_Primary_Product__c, l.Showcase_Use_Case__c, l.REF_Showcase_Employee_Size__c);
            Database.LeadConvert lc = new Database.LeadConvert();
            System.debug('Converting Referral Lead: Id(' + l.Id + ')');

            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);

            // If the email is an existing and approved email domain, add to Account and a Contact will be created
            // Else no existing email domain a new Account and Contact will be created
            if (matchingAccounts.containsKey(l.Email_Domain_Without_HTTP_lower__c)) {
                lc.setAccountId(matchingAccounts.get(l.Email_Domain_Without_HTTP_lower__c).Account__r.Id);
                lc.setOwnerId(matchingAccounts.get(l.Email_Domain_Without_HTTP_lower__c).Account__r.OwnerId);
                System.debug('Associating Referral Lead to Account having email domain "' + l.Email_Domain_Without_HTTP_lower__c + '": AccountId(' + matchingAccounts.get(l.Email_Domain_Without_HTTP_lower__c).Account__r.Id +')');
            } else {
                lc.setOwnerId(salesOpsUser.Id);
            }

            //if (!Test.isRunningTest()) {
                System.debug('Converting Referral Lead');
                Database.LeadConvertResult lcr = Database.convertLead(lc);

                if (lcr.isSuccess()) {
                    System.debug('Referral Lead Conversion SUCCESSFUL');
                    referralResults.add(lcr);
                } else {
                    System.debug('Referral Lead Conversion FAILED');
                    for (Database.Error e : lcr.getErrors()) {
                        System.debug('ERROR: ' + e.getMessage());
                    }
                }
            //}
        }

        List<Map<String,String>> convertedLeadProperties = new List<Map<String,String>>();
        for (Database.LeadConvertResult r : dealRegistrationResults) {
            Lead l = dealRegistrationLeads.get(r.getLeadId());
            OpportunityRoutingServices.AccountQBWrapper accWrapper = ppRouting.getAccWrapper(l.Country, l.State, l.PostalCode, l.REF_Showcase_Employee_Size__c);
            OpportunityRoutingServices.OppSettingWrapper oppWrapper = ppRouting.getOwnerWrapper(accWrapper.quarterBackId, l.Country, l.State, l.PostalCode, l.Volume__c, l.FY_16_Primary_Product__c, l.Showcase_Use_Case__c, l.REF_Showcase_Employee_Size__c);
            //String ownerId = partnerAccounts.containsKey(l.Partner_ID__c) ? partnerAccounts.get(l.Partner_ID__c).Alliance_Owner__c : '';
            convertedLeadProperties.add(new Map<String,String> {
                'Lead.Name' => (String.isBlank(l.FirstName) ? '' : (l.FirstName + ' ')) + l.LastName,
                'Lead.Description' => l.Description,
                'Lead.Partner_ID__c' => l.Partner_ID__c,
                'Lead.Showcase_Use_Case__c' => l.Showcase_Use_Case__c,
                'Lead.LeadSource' => l.LeadSource,
                //'Opportunity.OwnerId' => ownerId,
                'Opportunity.OwnerId' => oppWrapper.oppOwnerId,
                'Opportunity.Solution_Sales_Specialist__c' => oppWrapper.specialistId,
                'Opportunity.Qualified_Lead_Source__c' => 'Deal Registration',
                'Opportunity.Lead_Qualified_By__c' => currentUserId,
                'Lead.Id' => r.getLeadId(),
                'Contact.Id' => r.getContactId(),
                'Opportunity.Id' => r.getOpportunityId(),
                'Account.Id' => r.getAccountId(),
                'Account.OwnerId' => accWrapper.quarterBackId
            });
        }

        for (Database.LeadConvertResult r : referralResults) {
            Lead l = referralLeads.get(r.getLeadId());
            OpportunityRoutingServices.AccountQBWrapper accWrapper = ppRouting.getAccWrapper(l.Country, l.State, l.PostalCode, l.REF_Showcase_Employee_Size__c);
            OpportunityRoutingServices.OppSettingWrapper oppWrapper = ppRouting.getOwnerWrapper(accWrapper.quarterBackId, l.Country, l.State, l.PostalCode, l.Volume__c, l.FY_16_Primary_Product__c, l.Showcase_Use_Case__c, l.REF_Showcase_Employee_Size__c);
            convertedLeadProperties.add(new Map<String,String> {
                'Lead.Name' => (String.isBlank(l.FirstName) ? '' : (l.FirstName + ' ')) + l.LastName,
                'Lead.Description' => l.Description,
                'Lead.Partner_ID__c' => l.Partner_ID__c,
                'Lead.Showcase_Use_Case__c' => l.Showcase_Use_Case__c,
                'Lead.LeadSource' => l.LeadSource,
                //'Opportunity.OwnerId' => ppRouting.getOwnerId(l.CountryCode, l.StateCode, l.Showcase_Employee_Size__c, l.Showcase_Use_Case__c),
                'Opportunity.OwnerId' => oppWrapper.oppOwnerId,
                'Opportunity.Solution_Sales_Specialist__c' => oppWrapper.specialistId,
                'Opportunity.Qualified_Lead_Source__c' => 'Referral',
                'Opportunity.Lead_Qualified_By__c' => currentUserId,
                'Lead.Id' => r.getLeadId(),
                'Contact.Id' => r.getContactId(),
                'Opportunity.Id' => r.getOpportunityId(),
                'Account.Id' => r.getAccountId(),
                'Account.OwnerId' => accWrapper.quarterBackId
            });
        }

        Map<Id,Lead> leads = new Map<Id,Lead>();
        leads.putAll(dealRegistrationLeads);
        leads.putAll(referralLeads);

        LeadTriggerHandler.partnerDealSubmissionPostAutoConversion(leads, convertedLeadProperties);
        System.debug('Deal Submission Lead Conversion Routine Complete');*/
    }

    public static void partnerDealSubmissionPostAutoConversion(Map<Id,Lead> leads, List<Map<String,String>> leadList) {
        /*System.debug('Starting Post-Conversion Processing');

        // Load Partner Portal Mapping to assigned User from the customer setting data where the Partner Id is the key for lookup
        Map<String,PartnerPortalMappings__c> partnerPortalMap = new Map<String,PartnerPortalMappings__c>();
        for (PartnerPortalMappings__c p : PartnerPortalMappings__c.getAll().values()) {
            if (!String.isBlank(p.Partner_ID__c) && !String.isBlank(p.User_ID__c) && !String.isBlank(p.Account_ID__c)) {
                partnerPortalMap.put(p.Partner_ID__c, p);
            }
        }

        // Build a mapping of Use Case to Opportunity Record Types
        Map<String,Id> useCaseToOppRecTypeMap = new Map<String,Id>();
        for (Use_Case_to_Opp_Record_Type__c u : Use_Case_to_Opp_Record_Type__c.getAll().values()) {
            useCaseToOppRecTypeMap.put(u.Use_Case__c, u.Opp_Record_Type_ID__c);
        }

        // Determine that last day in the current fiscal quarter
        Date closeDate = [SELECT EndDate FROM Period WHERE Type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER].EndDate;
        System.debug('Last day of the current fiscal quarter = ' + closeDate);

        // Update the Opportunities and Contacts with additional information
        // Create Pass To Partner records
        List<Account> accounts = new List<Account>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Contact> contacts = new List<Contact>();
        List<Pass_To_Partner__c> passToPartners = new List<Pass_To_Partner__c>();
        Map<Id, Id> dealOwnerIdMap = new Map<Id, Id>();

        for (Map<String,String> properties : leadList) {
            String leadName = properties.get('Lead.Name');
            String leadDesc = properties.get('Lead.Description');
            System.debug('LEAD(' + properties.get('Lead.Id') + ', ' + leadName + ')');

            if(properties.get('Account.Id') != null){
                Account acc = new Account(
                    Id = properties.get('Account.Id'),
                    OwnerId = properties.get('Account.OwnerId')
                );
                accounts.add(acc);
            }

            Contact c = new Contact(
                Id = properties.get('Contact.Id'),
                Partner_Id__c = properties.get('Lead.Partner_ID__c')
            );
            contacts.add(c);

            Opportunity o = new Opportunity(
                Id = properties.get('Opportunity.Id'),
                OwnerId = properties.get('Opportunity.OwnerId'),
                Qualified_Lead_Source__c = properties.get('Opportunity.Qualified_Lead_Source__c'),
                Lead_Qualified_By__c = properties.get('Opportunity.Lead_Qualified_By__c'),
                Partner_ID__c = properties.get('Lead.Partner_ID__c'),
                Use_Case_Category__c = properties.get('Lead.Showcase_Use_Case__c'),
                CloseDate = closeDate
            );
            if (useCaseToOppRecTypeMap.containsKey(properties.get('Lead.Showcase_Use_Case__c'))) {
                o.RecordTypeId = useCaseToOppRecTypeMap.get(properties.get('Lead.Showcase_Use_Case__c'));
                System.debug('Setting Opportunity.RecordTypeId to "' + o.RecordTypeId + '"');
            } else {
                System.debug('Missing Use Case to Opportunity Record Type mapping:  "' + properties.get('Lead.Showcase_Use_Case__c') + '" does not have a entry in Use_Case_to_Opp_Record_Type__c custom setting.');
            }
            opportunities.add(o);
            dealOwnerIdMap.put(properties.get('Opportunity.Id'), properties.get('Account.OwnerId') == null ? properties.get('Opportunity.OwnerId') : properties.get('Account.OwnerId'));
            // Determine if there is an owner mapping for the Partner ID
            String ownerId = UserInfo.getUserId();
            String accountId = [SELECT Contact.AccountId FROM User WHERE Id = :ownerId LIMIT 1].Contact.AccountId;
            if (partnerPortalMap.containsKey(properties.get('Lead.Partner_ID__c')) && partnerPortalMap.get(properties.get('Lead.Partner_ID__c')) != null) {
                ownerId = partnerPortalMap.get(properties.get('Lead.Partner_ID__c')).User_ID__c;
                accountId = partnerPortalMap.get(properties.get('Lead.Partner_ID__c')).Account_ID__c;
                System.debug('Using Lead Partner ID for Partner User Map matching "' + properties.get('Lead.Partner_ID__c') + '": OwnerId(' + ownerId + ')');
            } else {
                System.debug('No Partner User mapping found for Partner ID "' + properties.get('Lead.Partner_ID__c') + '"');
            }

            if (ownerId != null) {
                passToPartners.add(new Pass_To_Partner__c(
                    OwnerId = ownerId,
                    Partner_Account__c = accountId,
                    Opportunity__c = properties.get('Opportunity.Id'),
                    Contact__c = properties.get('Contact.Id'),
                    Partner_Status__c = 'Submitted to Partner'
                ));
            }
        }

        List<Deal__c> deals = new List<Deal__c>();
        if(!dealOwnerIdMap.isEmpty()){
            for(Opportunity opp: [SELECT Id, Deal__c, Deal__r.OwnerId FROM Opportunity WHERE Id =: dealOwnerIdMap.keySet()]){
                Deal__c newDeal = new Deal__c(Id = opp.Deal__c, OwnerId = dealOwnerIdMap.get(opp.Id));
                deals.add(newDeal);
            }
        }
        System.debug('Updating Opportunities, Contacts, and Pass To Partner records');
        update accounts;
        //update deals;
        update opportunities;
        update contacts;
        insert passToPartners;

        System.debug('Completed Post-Conversion Processing');*/
    }

/*  ORIGINAL partnerDealSubmission()

    public static void partnerDealSubmission(Boolean isUpdate, Boolean isInsert, Map<Id,Lead> oldMap, Map<Id,Lead> newMap) {
        // If the current running user is not API/Eloqua (or other test users) then skip this process
        if (!isRunningAsApiUser())  return;

        String convertedLeadStatus = 'Opportunity';

        String fallbackOwnerName = 'Casey Clegg';

        String assignedAccountName = 'Twilio Incoming Partner Deals';
        String intialOwnerName = 'Website Inbound Queue';
        String partnerOppRecTypeName = 'Deal Reg Opportunity';
        String partnerApprovalProcessName = 'Partner_Opportunity_Flow';

        String openDealOpportunityStage = 'Use Case Confirmed';
        String closedDealOpportunityStage = 'Closed Won';

        String ppOpenDealLeadSource = 'PPortal - Open Deal Reg';
        String ppClosedDealLeadSource = 'PPortal - Closed Deal Reg';
        String wfOpenDealLeadSource = 'WebForm - Open Deal Reg';
        String wfClosedDealLeadSource = 'WebForm - Closed Deal Reg';

        Id assignedAccountId = null;
        Id partnerOppRecTypeId = null;
        Id fallbackOwnerId = null;
        LeadStatus convertStatus = null;
        Set<String> partnerIds = new Set<String>();
        List<Lead> leads = new List<Lead>();

        // Only operate on leads that are come from the Web2Lead form from the Partner Portal or Ahoy website.
        for (Id l : newMap.keySet()) {
            // Validate that the lead meets the criteria of a Partner Portal web2lead generate lead.
            System.debug('=========> Lead_Source(' + newMap.get(l).LeadSource + ')');
            System.debug('=========> Lead_State(' + newMap.get(l).Status + ')');
            System.debug('=========> Partner_ID(' + newMap.get(l).Partner_ID__c + ')');
            if ((
                    newMap.get(l).LeadSource == ppOpenDealLeadSource || newMap.get(l).LeadSource == ppClosedDealLeadSource
                    || newMap.get(l).LeadSource == wfOpenDealLeadSource || newMap.get(l).LeadSource == wfClosedDealLeadSource
                )
                && newMap.get(l).Status == 'Open'
                && !newMap.get(l).isConverted
            ) {
                System.debug('=========> Qualifying lead:  Lead(' + l + ')');
                leads.add(newMap.get(l));
                if (String.isNotBlank(newMap.get(l).Partner_ID__c)) {
                    partnerIds.add(newMap.get(l).Partner_ID__c);
                }
            }
        }

        // If there are no leads that meet the criteria exit the trigger
        if (leads.isEmpty()) {
            return;
        }

        // Get the fallback owner User Id in case the lead's associated Partner ID or the PAM does not exist
        List<User> fuser = [ SELECT Id FROM User WHERE Name = :fallbackOwnerName ];
        if (fuser.isEmpty()) {
            TriggerUtil.setLeadError(newMap.values(), 'Fallback Owner "' + fallbackOwnerName + '" does not exist.  Please contact your Salesforce administrator.');
            return;
        } else {
            fallbackOwnerId = fuser[0].Id;
        }

        // Get the "Partner Opportunity" record type for the new opportunities that will be created during the conversion process
        if (Schema.SObjectType.Opportunity.RecordTypeInfosByName.get(partnerOppRecTypeName) == null) {
            TriggerUtil.setLeadError(newMap.values(), 'Opportunity record type "' + partnerOppRecTypeName + '" does not exist.  Please contact your Salesforce administrator.');
            return;
        } else {
            partnerOppRecTypeId = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get(partnerOppRecTypeName).RecordTypeId;
        }

        // Lookup the assigned account by name.
        // If it does not exist abort the execution of the trigger.
        List<Account> assignedAccounts = [ SELECT Id, Name FROM Account WHERE Name = :assignedAccountName ];
        if (assignedAccounts.isEmpty()) {
            System.debug('=========> ERROR: "' + assignedAccountName + '" account is not found.  PartnerDealSubmission trigger aborting...');
            TriggerUtil.setLeadError(newMap.values(), '"' + assignedAccountName + '" account is not found.  PartnerDealSubmission trigger aborting...');
            return;
        } else {
            assignedAccountId = assignedAccounts[0].Id;
            System.debug('=========> ' + assignedAccountName + ' Account Found: "' + assignedAccountId);
        }


        // Map the Partner_ID__c to the PAM__c (PAM user's name)
        Map<String,String> partnerId2PamName = new Map<String,String>();
        Map<String,User> partnerId2User = new Map<String,User>();
        for (User u : [ SELECT Id, Name, Partner_ID__c, PAM__c FROM User WHERE Partner_ID__c IN :partnerIds ]) {
            System.debug('=========> partnerId2PAM MAP (USER=' + u.Name + ', PARTNER_ID=' + u.Partner_ID__c + ', PAM=' + u.PAM__c + ')');
            partnerId2User.put(u.Partner_ID__c, u);
            partnerId2PamName.put(u.Partner_ID__c, u.PAM__c);
        }

        // Map the Partner_ID__c to the PAM__c User Id
        Map<String, User> partnerId2PamUser = new Map<String,User>();
        for (User pam : [ SELECT Id, Name FROM User WHERE Name IN :partnerId2PamName.values() ]) {
            for (String p : partnerId2PamName.keySet()) {
                if (partnerId2PamName.get(p) == pam.Name) {
                    partnerId2PamUser.put(p,pam);
                    partnerId2PamName.remove(p);  // Shrink the map since we won't need it after this
                }
            }
        }

        // Display the partner to user mapping for debugging.
        for (String p : partnerId2PamUser.keySet()) {
            System.debug('==============> PartnerId 2 PamUser MAP(PartnerId='+ p + ', PamUser=' + partnerId2PamUser.get(p).Name + '[' + partnerId2PamUser.get(p).Id + '])');
        }

        // Get the LeadStatus to set whenever the leads are converted
        List<LeadStatus> convertStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel = :convertedLeadStatus ];
        if (convertStatuses.size() != 1) {
            System.debug('==============> Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"');
            TriggerUtil.setLeadError(newMap.values(), 'Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"');
            return;
        } else {
              convertStatus = convertStatuses[0];
        }

        // Convert the leads and load the resulting Account, Contact, and Opportunity records into the ConvertedLead list
        List<Database.LeadConvertResult> results = new List<Database.LeadConvertResult>();

        List<Account> accounts = new List<Account>();

        String today = Date.today().month() + '/' + Date.today().day() + '/' + Date.today().year();

        // When the SFDC tests are running cannot perform Lead conversion because the
        // box.com managed package will attempt to make a web service callout
        for (Integer i = 0; i < leads.size(); i++) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leads[i].id);
            lc.setOwnerId(partnerId2PamUser.containsKey(leads[i].Partner_ID__c) ? partnerId2PamUser.get(leads[i].Partner_ID__c).Id : fallbackOwnerId);
            System.debug('==============> Lead.setOwnerId(PartnerId='+ leads[i].Partner_ID__c + ', PamUser=' + (partnerId2PamUser.containsKey(leads[i].Partner_ID__c) ? partnerId2PamUser.get(leads[i].Partner_ID__c).Id : fallbackOwnerId) + '])');
            lc.setConvertedStatus(convertStatus.MasterLabel);

            lc.setOpportunityName((String.isBlank(leads[i].Company) ? 'UNKNOWN' : leads[i].Company) + ' - ' + (!partnerId2User.containsKey(leads[i].Partner_ID__c) ? 'UNKNOWN' : partnerId2User.get(leads[i].Partner_ID__c).Name) + ' - ' + today);

            if (!Test.isRunningTest()) {
                    Database.LeadConvertResult lcr = Database.convertLead(lc);
        //          System.debug('===========> LEAD #' + (i + 1) + ' CONVERTED:' + lcr.isSuccess());
                    results.add(lcr);
            }
        }

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Database.LeadConvertResult r : results) {
            accounts.add(new Account(Id = r.getAccountId()));

            // Set the opportunities' fields as required
            String ls = newMap.get(r.getLeadId()).LeadSource;
            User u = partnerId2User.get(newMap.get(r.getLeadId()).Partner_ID__c);

            opportunities.add(new Opportunity(
                Id = r.getOpportunityId(),
                RecordTypeId = partnerOppRecTypeId,
                StageName = (ls == ppOpenDealLeadSource || ls == wfOpenDealLeadSource) ? openDealOpportunityStage : ((ls == ppClosedDealLeadSource || ls == wfClosedDealLeadSource) ? closedDealOpportunityStage : 'Qualified'),
                AccountId = assignedAccountId,
                CloseDate = Date.today(),
                Partner_ID__c = (u != null) ? u.Partner_ID__c : '',
                Partner_Name__c = (u != null) ? u.Name : ''
            ));
            System.debug('===========> OPPORTUNITY RECTYPE(' + partnerOppRecTypeId + ')');
        }

        update opportunities;

        // Now that the ownership of the Opportunity has been changed delete the Account
        // that was created during the Lead conversion process.
        delete accounts;

        for (Opportunity o : opportunities) {
            // Create an approval request for the Opportunity
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setComments('Submitting request for approval.');
            request.setObjectId(o.Id);

            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(request);

            // Verify the result
            System.assert(result.isSuccess());
        }

    }
*/


    // Performs Lead autoconversion

    public static void autoconvert(Boolean isUpdate, Boolean isInsert, Map<Id,Lead> oldMap, Map<Id,Lead> newMap) {
        Set<String> leadSourcesToExclude  = new Set<String>{
            'Showcase',
            'Twilio.org Showcase',
            'PPortal - Open Deal Reg',
            'PPortal - Closed Deal Reg',
            'WebForm - Open Deal Reg',
            'WebForm - Closed Deal Reg',
            'Deal Registration',
            'Referral',
            'DiscoverOrg'
        };

        Map<Id,Lead> leads = new Map<Id,Lead>();
        
        //get list of status that qualified for auto convert
        Lead_Auto_Convert_Status__c  leadData = Lead_Auto_Convert_Status__c.getInstance('Auto Convert');
        List<String> qualifiedStatus = new List<String>();
        if (leadData != NULL && leadData.Qualified_Status__c != NULL) {
            qualifiedStatus = leadData.Qualified_Status__c.split(',');
        }

        // Get the list of profile IDs that should be excluded from auto-conversion on record update only
        // Query the lead's profile owner ID to determine if it should be excluded
        // If the lead should be exclude remove it from the leadsToProcess
        Set<String> userProfilesToExclude = new Set<String>();
        for (DoNotAutoConvert__c d : DoNotAutoConvert__c.getAll().values()) {
            userProfilesToExclude.add(d.Profile_ID__c);
        }
        

        List<Lead> leadsToProcess = new List<Lead>();
        for (Lead l : [
            SELECT Id, Owner.ProfileId
            FROM Lead
            WHERE Id IN :newMap.keySet()
            AND IsConverted != true
            AND status IN : qualifiedStatus
            AND Owner.Type = 'User'
            AND (NOT (
                Owner.ProfileId IN :userProfilesToExclude
                AND Owner.UserRole.Name LIKE '%Outbound%'
            ))
            FOR UPDATE
        ]) {
            leadsToProcess.add(newMap.get(l.Id));
        }
        if(oldMap == null) oldMap = new Map<Id,Lead>();
        // Process the remain leads
        for(Lead l : leadsToProcess){
            Lead oldLead = oldMap.get(l.Id);
            Lead newLead = newMap.get(l.Id);
            if(!newLead.IsConverted
                && (oldLead == null || !oldLead.IsConverted)
                && !apiUsers.contains(UserInfo.getName())
                && !(String.isBlank(l.Email) && String.isBlank(l.Preferred_Email__c))
                && !leadSourcesToExclude.contains(l.LeadSource)
                && qualifiedStatus.contains(l.Status) //l.Status == 'Open'
            ){
                leads.put(l.Id, l);
            }
        }

        if (!leads.isEmpty()) {
            LeadAutoConvertHandler.convert(leads);
            runOnce = true;
            //autoConvertRunOnce = true;
        }
    }


    // Update child objects from the Lead to the Contact it was converted to.

    public static void reparentChildRecords(Boolean isUpdate, Boolean isInsert, Map<Id,Lead> oldMap, Map<Id,Lead> newMap) {
        Map<Id,Id> leadToContactMap = new Map<Id,Id>();
        Map<Id,Id> leadToAccountMap = new Map<Id,Id>();
        Map<Id,Id> leadToOpportunityMap = new Map<Id, Id>();

        if(isUpdate){
            for(Lead l : newMap.values()){
                if ((l.IsConverted && !oldMap.get(l.Id).IsConverted) || Test.isRunningTest()) {
                    leadToContactMap.put(l.Id, l.ConvertedContactId);
                    leadToAccountMap.put(l.Id, l.ConvertedAccountId);
                    leadToOpportunityMap.put(l.Id, l.ConvertedOpportunityId);
                }
            }
        }
        
        Set<String> emailLists = new Set<String>();
        Map<String, List<Id>> emails = new Map<String, List<Id>>();
        Map<Id, Id> mergeList = new Map<Id, Id>();
        
        for(Contact aContact: [SELECT Email FROM Contact WHERE Id =: leadToContactMap.values()]){
            emailLists.add(aContact.Email);
        }
        
        for(Contact aContact: [SELECT Email FROM Contact WHERE Email =: emailLists]){
            List<Id> contactIds = emails.get(aContact.Email);
            if(contactIds == null || contactIds.isEmpty()){
                contactIds = new List<Id>();
            }
            else{
                if(leadToContactMap.values().contains(aContact.Id)){
                    mergeList.put(aContact.Id, contactIds[0]);
                }
                else{
                    mergeList.put(contactIds[0], aContact.Id);
                }
            }
            contactIds.add(aContact.Id);
            emails.put(aContact.Email, contactIds);
        }
        
        for(Id masterId: mergeList.keySet()){
            database.merge(new Contact(Id = masterId), new Contact(Id = mergeList.get(masterId)), false);
        }

        // Link the child records of the converted Lead to the new Contact
        if (!leadToContactMap.isEmpty() || !leadToAccountMap.isEmpty()) {
            LeadAutoConvertHandler.linkTwilioUsagesToContact(leadToContactMap, leadToAccountMap);
            LeadAutoConvertHandler.linkZendeskTicketsToContact(leadToContactMap, leadToAccountMap);
            LeadAutoConvertHandler.linkFSRToContact(leadToContactMap);
            linkLFFToContact(leadToContactMap); // added on 2nd Feb 2016 by ASH.
        }

        if((!leadToOpportunityMap.isEmpty() || !leadToContactMap.isEmpty() || !leadToAccountMap.isEmpty()) && !useCaseConverted){
            linkUCIToOpportunity(leadToOpportunityMap, leadToContactMap, leadToAccountMap);
        }
    }
     /*
    * Link UCI records of UCI under lead to accounts, contacts and opportunities.
    * added on 26th Sep 2016 by Davis.
    */
    public static void linkUCIToOpportunity(Map<Id, Id> leadToOpportunityMap, Map<Id, Id> leadToContactMap, Map<Id, Id> leadToAccountMap){
        List<Use_Case_Interest__c> uciToUpdate = new List<Use_Case_Interest__c>();
        Set<Id> leadIds = new Set<Id>();

        leadIds.addAll(leadToOpportunityMap.keySet());
        leadIds.addAll(leadToContactMap.keySet());
        leadIds.addAll(leadToAccountMap.keySet());

        List<Opportunity> updateOpps = new List<Opportunity>();
        List<Use_Case_Interest__c> uciList = [SELECT Lead__c FROM Use_Case_Interest__c WHERE Lead__c =: leadIds];
        Id contactRtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Use_Case_Interest__c' AND Name = 'Contact' LIMIT 1].Id;

        Set<Id> oppIds = new Set<Id>();
        for(Use_Case_Interest__c uci: uciList){
            uci.Contact__c = leadToContactMap.get(uci.Lead__c);
            uci.Account__c = leadToAccountMap.get(uci.Lead__c);
            Id oppId = leadToOpportunityMap.get(uci.Lead__c);
            if(oppId != null && !oppIds.contains(oppId)){
                uci.Opportunity__c = oppId;
                updateOpps.add(new Opportunity(Id = oppId, Use_Case_Interest__c = uci.Id));
                oppIds.add(oppId);
            }
            uci.RecordTypeId = contactRtId;
            uci.Lead__c = null;
            uciToUpdate.add(uci);
        }

        update updateOpps;
        update uciToUpdate;

    }
    /*
    * Link LFF records of UCI under lead to contacts.
    * added on 2nd Feb 2016 by ASH.
    */

    public static void linkLFFToContact(Map<Id,Id> leadToContactMap )
    {
        List<Lifecycle_Field_Funnel__c> lFFToUpdate = new List<Lifecycle_Field_Funnel__c>();
        List<Lifecycle_Field_Funnel__c> lFFList = [SELECT id,name,Lead__c,contact__c,Use_Case_Interest__r.lead__c,MQL__r.lead__c,MQL__r.contact__c FROM Lifecycle_Field_Funnel__c where lead__c IN:leadToContactMap.keyset() AND (MQL__c !=NULL OR Use_Case_Interest__c !=NULL)];
        Map<Id,Id> lffWithLead = new Map<Id,Id>();
        for(Lifecycle_Field_Funnel__c lFF : lFFList)
        {
            if(lFF.lead__c == lFF.Use_Case_Interest__r.lead__c || leadToContactMap.get(lFF.lead__c) == lFF.MQL__r.contact__c)
            {
                lffWithLead.put(lFF.id,lFF.Lead__c);
                lFF.contact__c = leadToContactMap.get(lFF.lead__c);
                lFF.lead__c = null;
                lFFToUpdate.add(lFF);
            }
        }

        if(lFFToUpdate.size() > 0)
        {
            try
            {
                update lFFToUpdate ;
            }
            catch( System.DmlException dmlEx )
            {
                for( Integer errorIndex = 0; errorIndex < dmlEx.getNumDml(); errorIndex++ )
                {
                    Id lffId = lFFToUpdate[ dmlEx.getDmlIndex(errorIndex) ].Id;
                    Id relatedErrorId = lffWithLead.get(lffId); // LeadId
                    Trigger.newMap.get( relatedErrorId ).addError( dmlEx.getDmlMessage(errorIndex) );
                }
            }

        }
    }
 
    /*
    * Link AccountSID under lead to contacts on lead conversion.
    * added on 12th Feb 2016 by ASH.
    */
    public static void linkAccountSidToContact(Map<Id,Lead> oldMap , Map<Id,Lead> newMap)
    {
        Map<Id,Id> leadToContactMap = new Map<Id,Id>();
        Map<Id,Id> leadToAccountMap = new Map<Id,Id>();
        for(Lead l : newMap.values())
        {
             if ((l.IsConverted && !oldMap.get(l.Id).IsConverted))
             {
                    leadToContactMap.put(l.Id, l.ConvertedContactId);
                    leadToAccountMap.put(l.Id, l.ConvertedAccountId);
             }
        }
        List<Account_SID__c> accSidList = [SELECT id,name,Lead__c,Account__c,Contact__c FROM Account_SID__c WHERE Lead__c IN:leadToContactMap.keyset()];

        Map<Id,Id> accIdWithLead = new Map<Id,Id>();
        for(Account_SID__c accSID : accSidList)
        {
            accIdWithLead.put(accSID.id,accSID.Lead__c);
            accSID.contact__c = leadToContactMap.get(accSID.lead__c);
            //If accountSid has Account Lookup before, DO NOT Overwrite the account lookup field
            if(accSID.Account__c == null) accSID.Account__c = leadToAccountMap.get(accSID.lead__c);
            accSID.Lead__c = null;
        }

        if(accSidList .size() > 0)
        {
            // Let the AccountSidTrigger know that lead is being converted!
            // Added by Ashwani on 16 Feb 2016. Task #4
            AccountSidTriggerHandler.leadconversion = true;
            try
            {
                update accSidList ;
            }
            catch( System.DmlException dmlEx )
            {
                for( Integer errorIndex = 0; errorIndex < dmlEx.getNumDml(); errorIndex++ )
                {
                    Id accID = accSidList[ dmlEx.getDmlIndex(errorIndex) ].Id;
                    Id relatedErrorId = accIdWithLead.get(accID); // LeadId
                    newMap.get( relatedErrorId ).addError( dmlEx.getDmlMessage(errorIndex) );
                }
            }
        }
    }

}