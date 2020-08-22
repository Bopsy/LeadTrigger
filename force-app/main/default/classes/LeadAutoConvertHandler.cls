/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           LeadAutoConvertHandler
*
* @description    Handler class for Converting Leads 
* ──────────────────────────────────────────────────────────────────────────────────────────────────
*
**/
public class LeadAutoConvertHandler {
    
    // Lead Status value
    private static String convertedLeadStatus = 'Opportunity';
    // Get all free email doamin into Set
    private static Set<String> freemail = new Set<String>();
    
    // Returns leads that were not converted
    public static Map<Id, Lead> convert(Map<Id, Lead> leads) {
        
        // Create a Set of qualified lead
        Set<Lead> qualifiedLeads = new Set<Lead>();
        // Create a Set of Domains
        Set<String> domainNames = new Set<String>();
        // Declare AccountRTExcludeLst List
        List<String> AccountRTExcludeLst = null;
        // Declare Auto Convert Status Custom setting to null
        Lead_Auto_Convert_Status__c autoConvertSetting = null;
        // Declared Map for storing matching accounts
        Map<String,Email_Domain__c> matchingAccounts = null;
        // LeadStatus to set whenever the leads are converted
        LeadStatus convertStatus;
        // List of Leads to Convert
        List<Database.LeadConvert> leadsToConvert = null; 
        // Profiles to Include
        Set<String> profilesToExclude = new Set<String>{ 'System Administrator' };
        
        // Get All Converted Lead Status
        List<LeadStatus> convertStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true and MasterLabel = :convertedLeadStatus ];
        // Check if Status is greater than 0
        if (convertStatuses.size() != 1) {
            System.debug('===> ERROR: Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"'); 
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"'));
            return null;
        } else {
            convertStatus = convertStatuses[0];
        }
        
        // Generate a map of leads (by email domain) that have qualifying email domain
        for (Lead l : leads.values()) {
            System.debug('===> LEAD NAME(' + l.FirstName + ' ' + l.LastName + ', ' + l.Email + ', ' + l.Preferred_Email__c + ')');
            String domain = l.Email_Domain_Extracted__c;
            // Do not convert the lead if the email domain:
            //   - is empty
            //   - matches a free email domain
            //   - is owned by a queue instead of a user
            System.debug('===> QUALIFY_CHECK(' + domain + ', ' + ', ' + (leads.containsKey(l.Id) ? 'isOwnedByUser' : 'isNotOwnedByUser') + ')');
            system.debug(isFreeMail(domain));
            // Get all free email doamin into Set
            if(!isFreeMail(domain))
            {
               // Qualified leads
               qualifiedLeads.add(l);
               // domain names
               domainNames.add(domain); 
            }
        }

        // Check if qualified leads and domain names are present
        if (qualifiedLeads.isEmpty() || domainNames.isEmpty()) {
            System.debug('===> NO QUALIFYING EMAIL DOMAIN NAMES - SKIPPING LEAD AUTO-CONVERION'); 
            return leads;
        }
        
        
        AccountRTExcludeLst = new List<String>();
        // Lead Auto Convert Custom Setting
        autoConvertSetting = Lead_Auto_Convert_Status__c.getInstance('Auto Convert');
        if (autoConvertSetting != NULL && autoConvertSetting.AccountRTExclude__c != NULL) {
            AccountRTExcludeLst = autoConvertSetting.AccountRTExclude__c.split(',');
        }
       
        // Generate a list of matching accounts having:
        //   - a qualifying email domain name
        //   - not owned by user that has a System Administrator or Maintain profile
        System.debug('===> GETTING LIST OF ACCOUNTS HAVING MATCHING EMAIL DOMAINS');
        // Matching accounts
        matchingAccounts = new Map<String,Email_Domain__c>();
        for (Email_Domain__c d : [
            SELECT Id, Name, Account__r.Id, Account__r.Name, Account__r.OwnerId, Account__r.Owner.Email, Account__r.FY_17_CSM__c, Account__r.FY_17_CSM__r.Email
            FROM Email_Domain__c
            WHERE Name IN :domainNames
            AND Account__r.RecordTypeID NOT IN :AccountRTExcludeLst
            AND Account__r.Owner.Profile.Name NOT IN :profilesToExclude
            AND Approved__c = true
            AND Account__r.Owner.IsActive = true
        ]) {
            matchingAccounts.put(d.Name, d);
        }

        // If no matching accounts found, no leads to convert
        if (matchingAccounts.isEmpty()) {
            System.debug('===> NO MATCHING ACCOUNT - SKIPPING LEAD AUTO-CONVERION'); 
            return leads;
        }

        
        // store the leads to convert
        leadsToConvert = new List<Database.LeadConvert>();

        // Check to see if the lead matches multiple accounts 
        for (Lead l : qualifiedLeads) {
            // get email domain
            String domain = l.Email_Domain_Extracted__c;
            // Check accounts that match email domain
            if (matchingAccounts.containsKey(domain)) {
                Email_Domain__c d = matchingAccounts.get(domain);
 
                // Convert lead
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(l.Id);
                lc.setAccountId(d.Account__r.Id);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                lc.setDoNotCreateOpportunity(true);
                // accumulates leads to convert
                leadsToConvert.add(lc);
            }
        }

        // Convert the leads and associate to the existing Account and suppress the Opportunity creation
        if (!Test.isRunningTest()) {
            //invoke callConvertLeadProcess Method for convert the Qualified Leads into contacts
            executeConvertLeadProcess(leadsToConvert, leads);
        }
        
        System.debug('oh++++++++++# query: '+Limits.getQueries());
        // return leads not qualified
        return leads;
    }

    
    // Returns leads that were not converted
    public static Map<Id,Lead> convertNPCLead(Map<Id,Lead> leads) {

        // LeadStatus to set whenever the leads are converted
        LeadStatus convertStatus;
        // NPC Routing map
        Map<String,String> npcRoutingMap = null;
        // List of Leads to Convert
        List<Database.LeadConvert> leadsToConvert = null; 

        // Get the LeadStatus to set whenever the leads are converted
        List<LeadStatus> convertStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel = :convertedLeadStatus ];
        if (convertStatuses.size() != 1) {
            System.debug('===> ERROR: Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"'); 
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"'));
            return null;
        } else {
            convertStatus = convertStatuses[0];
        }

        // Load the NPC Routing map based on the ISO Country Code
        npcRoutingMap = new Map<String,String>();
        for (NPC_Routing__c n : NPC_Routing__c.getAll().values()) {
            npcRoutingMap.put(n.ISO_Country_Code__c.toUpperCase(), n.User_ID__c);
        }
        // Ensure that the "OTHER" entry exists in the NPC Routing map
        if (!npcRoutingMap.containsKey('OTHER')) {
            System.debug('===> ERROR: NPC Routine map does not contain a "OTHER" entry'); 
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'NPC Routine map does not contain a "OTHER" entry'));
            return null;
        }

        // store the leads to convert
        leadsToConvert = new List<Database.LeadConvert>();
      
        // Check to see if the lead matches multiple accounts
        for (Lead l : leads.values()) {
            // Convert lead
            Database.LeadConvert lc = new Database.LeadConvert();
            String leadSource = l.LeadSource;
            String leadName = (String.isBlank(l.FirstName) ? '' : (l.FirstName + ' ')) + l.LastName;
            String leadDesc = l.Description;
            System.debug('===> LEAD(' + l.Id + ', ' + leadName + ')');
    
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            lc.setDoNotCreateOpportunity(true);
    
            // How to determine the new owner of the converted lead
            String isoCountryCode = String.isBlank(l.ISO_Country_Code__c) ? 'OTHER' : l.ISO_Country_Code__c.toUpperCase();
            String ownerId = npcRoutingMap.containsKey(isoCountryCode) ? npcRoutingMap.get(isoCountryCode) : npcRoutingMap.get('OTHER');
            lc.setOwnerId(ownerId);                    
            // accumulates leads to convert
            leadsToConvert.add(lc);

            }

        if (!Test.isRunningTest()) {
            //invoke callConvertLeadProcess Method for convert the Qualified Leads into contacts
            executeConvertLeadProcess(leadsToConvert, leads);
        }
        // return leads not qualified
        return leads;
    }


    // Given a map of Lead IDs (key) and Contact IDs (value) and a
    // map of Lead IDs (key) and Account IDs (value) update the 
    // Twilio_Usage__c to be related to the specified Contact and Account.
    public static void linkTwilioUsagesToContact(Map<Id,Id> leadToContactMap, Map<Id,Id> leadToAccountMap) {
        System.debug('===> REPARENTING TWILIO USAGE RECORDS(leadToContactMap Count=' + leadToContactMap.size() + ', leadToAccountMap Count=' + leadToAccountMap.size() + ')');
        List<Twilio_Usage__c> usages = new List<Twilio_Usage__c>();
        for (Twilio_Usage__c u : [ SELECT Id, Lead__c, Contact__c, AccountLookup__c FROM Twilio_Usage__c WHERE Lead__c IN :leadToContactMap.keySet() ]) {
            System.debug('===> TWILIO USAGE RECORD(Id=' + u.Id + ', Lead=' + u.Lead__c + ', Contact=' + u.Contact__c + ', Account=' + u.AccountLookup__c + ')');
            System.debug('===> TWILIO USAGE CONTACT CHECK(leadToContactMap Contact=' + leadToContactMap.get(u.Lead__c) + ', Contact=' + u.Contact__c + ')');
            if (leadToContactMap.get(u.Lead__c) != u.Contact__c) {
                u.Contact__c = leadToContactMap.get(u.Lead__c);
                u.AccountLookup__c = leadToAccountMap.get(u.Lead__c);
                u.Lead__c = null;
                System.debug('===> ADDING TWILIO USAGE FOR UPDATE(Id=' + u.Id + ', Lead=' + u.Lead__c + ', Contact=' + u.Contact__c + ', Account=' + u.AccountLookup__c + ')');
                usages.add(u);
            }
        }
        
        if (!usages.isEmpty()) {
            System.debug('===> UPDATING TWILIO USAGES');
            update usages;
        }
    }

    // Given a map of Lead IDs (key) and Contact IDs (value) update the 
    // Zendesk__Zendesk_Ticket__c to be related to the specified Contact. 
    public static void linkZendeskTicketsToContact(Map<Id,Id> leadToContactMap, Map<Id,Id> leadToAccountMap) {
    }

    // Given a map of Lead IDs (key) and Contact IDs (value) update the 
    // FSR__c to be related to the specified Contact. 
    public static void linkFSRToContact(Map<Id,Id> leadToContactMap) {
        System.debug('===> REPARENTING FSR RECORDS(leadToContactMap Count=' + leadToContactMap.size() + ')');
        List<FSR__c> tickets = new List<FSR__c>();
        for (FSR__c t : [ SELECT Id, Lead__c , Contact__c  FROM FSR__c WHERE Lead__c IN :leadToContactMap.keySet() ]) {
            System.debug('===> FSR RECORD(Id=' + t.Id + ', Lead=' + t.Lead__c + ', Contact=' + t.Contact__c + ')');
            System.debug('===> FSR CONTACT CHECK(leadToContactMap Contact=' + leadToContactMap.get(t.Lead__c) + ', Contact=' + t.Contact__c + ')');
            if (leadToContactMap.get(t.Lead__c) != t.Contact__c) {
                t.Contact__c = leadToContactMap.get(t.Lead__c);
                t.Lead__c = null;
                System.debug('===> ADDING FSR FOR UPDATE(Id=' + t.Id + ', Lead=' + t.Lead__c + ', Contact=' + t.Contact__c + ')');
                tickets.add(t);
            }
        }
        
        if (!tickets.isEmpty()) {
            System.debug('===> UPDATING FSRs');
            update tickets;
        }
    }

    /**************************************************************************************
    * @Description  This method is used to execute the lead conversion logic
    * @Param        list<Database.LeadConvert> - list of leads to convert into contacts and associate to Email domain assocaited account    
    * @Return       Void
    **************************************************************************************/
    public static void executeConvertLeadProcess(list<Database.LeadConvert> leadsToConvert, Map<Id, Lead> leads) {
        
        // Check if leads to convert exist  
        /*if(!leadsToConvert.isEmpty()) {
            // Convert the leads
            Database.LeadConvertResult[] lcr = Database.convertLead(leadsToConvert);
            System.debug('===> LEAD CONVERSION ROUTINE COMPLETE');
            // Check for success and failures
            for(Database.LeadConvertResult result : lcr) {
                if (result.isSuccess()) {
                    // remve leads that are converted
                    leads.remove(result.getLeadId());
                } else {
                    System.debug('===> LEAD CONVERSION FAILED');
                    for (Database.Error e : result.getErrors()) {
                        System.debug('===> ERROR: ' + e.getMessage());
                    }
                }
            }    
        }*/
        
        if(!leadsToConvert.isEmpty()){
            for(Integer i = 0; i <= leadsToConvert.size()/100 ; i++){
                list<Database.LeadConvert> tempList = new list<Database.LeadConvert>();
                Integer startIndex = i*100;
                Integer endIndex = ((startIndex+100) < leadsToConvert.size()) ? startIndex+100: leadsToConvert.size();
                for(Integer j=startIndex;j<endIndex;j++){
                    tempList.add(leadsToConvert[j]);
                }
                // Convert the leads
                Database.LeadConvertResult[] lcr = Database.convertLead(tempList);
                // Check for success and failures
                for(Database.LeadConvertResult result : lcr) {
                    if (result.isSuccess()) {
                        // remve leads that are converted
                        leads.remove(result.getLeadId());
                    } else {
                        System.debug('===> LEAD CONVERSION FAILED');
                        for (Database.Error e : result.getErrors()) {
                            System.debug('===> ERROR: ' + e.getMessage());
                        }
                    }
                } 
            }
            System.debug('===> LEAD CONVERSION ROUTINE COMPLETE');
        }
    }
    
    // Given an email & backup email address extract the email domain portion and return it
    // If the email is empty or is free email then use the backup email
    // If the selected email is free email then return an empty domain
    public static String getEmailDomain(String email, String backupEmail) {
        System.debug('===> GET EMAIL DOMAIN(email=' + email + ', backupEmail=' + backupEmail + ')');
        
        if (!String.isBlank(email) && email.contains('@')) {
            String domain = email.split('@', 2)[1].toLowerCase();
            System.debug('===> EMAIL DOMAIN(' + domain + ')');
            if (!isFreeMail(domain)) {
                System.debug('===> GET EMAIL DOMAIN(email=' + email + ', domain=' + domain + ', isNotFreeMail)');
                return domain;
            }
            System.debug('===> GET EMAIL DOMAIN(email=' + email + ', domain=' + domain + ', isFreemail)');
        }
        
        if (!String.isBlank(backupEmail) && backupEmail.contains('@')) {
            String domain = backupEmail.split('@', 2)[1].toLowerCase();
            System.debug('===> EMAIL DOMAIN(' + domain + ')');
            if (!isFreeMail(domain)) {
                System.debug('===> GET EMAIL DOMAIN(backupEmail=' + backupEmail + ', domain=' + domain + ', isNotFreeMail)');
                return domain;
            }
            System.debug('===> GET EMAIL DOMAIN(backupEmail=' + backupEmail + ', domain=' + domain + ', isFreeMail)');
        } 
        
        return '';
    }
    
    // Given an email domain check whether it is a free email domain
    public static Boolean isFreeMail(String emailDomain) {
        // Check f free email is empty
        if(freemail.isEmpty()) {
            for (String s : Free_Email_Domains__c.getAll().keySet()) {
                freemail.add(s.toLowerCase());
            } 
        }
        return freemail.contains(emailDomain.toLowerCase());
    }
}