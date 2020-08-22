//----------------------------------------------------------------------------------------------------------
// Handler class of ContactTrigger 
//----------------------------------------------------------------------------------------------------------
public without sharing class ContactTriggerHandler {
	
	public static user usr;
	static {
		for (User user : [Select Id From User Where Name = 'Sales Operations']) {
			usr = user;
		}
	}

    // Users that are considered API/Eloqua
    public static Set<String> apiUsers = new Set<String> { 'Kevin Eloqua', 'Jonathan Eloqua', 'Brittany Eloqua', 'API-Read Only', 'Eloqua Marketing' };

    // Determine if the current running user is Eloqua
    public static Boolean isRunningAsApiUser() {
        return apiUsers.contains(UserInfo.getName());    	
    }
	
	//----------------------------------------------------------------------------------------------------------
	// On trigger of before insert 
	//----------------------------------------------------------------------------------------------------------
	public static void onBeforeInsert(List<Contact> newList) {
		populateAccount(newList);
	}
	
	//----------------------------------------------------------------------------------------------------------
	// On trigger of before update 
	//----------------------------------------------------------------------------------------------------------
	public static void onBeforeUpdate(List<Contact> newList, Map<Id, Contact> oldMap) {
		List<Contact> lstContactToUpdate = new List<Contact>();
		for(Contact con : newList){
			if(Utility.isNewOrChanged(con, 'Account_SID__c', oldMap)){
				lstContactToUpdate.add(con);
			}
		}
		if(!lstContactToUpdate.isEmpty()){
			populateAccount(lstContactToUpdate);
		}
	}
	
	//----------------------------------------------------------------------------------------------------------
	// Update account on contact
	//----------------------------------------------------------------------------------------------------------
	public static void populateAccount(List<Contact> newList){
		Set<String> accountSIds = new Set<String>();
		for(Contact con : newList){
			if(con.AccountId == null && con.Account_SID__c != null && con.Account_SID__c != ''){
				accountSIds.add(con.Account_SID__c);
			}
		}
		if(!accountSIds.isEmpty()){
			Map<String, Account> mapSidAndAccount = new Map<String, Account>();
			for(Account acc : [Select Id, Account_SID__c From Account Where Account_SID__c IN :accountSIds]){
				mapSidAndAccount.put(acc.Account_SID__c, acc);
			}
			
			List<Account> lstAccToInsert = new List<Account> ();
			for (Contact con : newList) {
				if(con.AccountId == null && con.Account_SID__c != null && con.Account_SID__c != ''){
					String accSID = con.Account_SID__c;
					if (!mapSidAndAccount.containsKey(accSID)) {
						Account acc = new Account();
						acc.Account_SID__c = accSID;
						if (con.Email != null) {
							acc.Name = con.Email.split('@').get(1);
						}
						if (usr != null) {
							acc.OwnerId = usr.Id;
						}
						mapSidAndAccount.put(acc.Account_SID__c, acc);
						lstAccToInsert.add(acc);
					}
				}
			}
			
			if (!lstAccToInsert.isEmpty()) {
				insert lstAccToInsert;
			}
			
			for(Contact con : newList){
				if(con.AccountId == null 
					&& con.Account_SID__c != null 
					&& con.Account_SID__c != '' 
					&& mapSidAndAccount.containsKey(con.Account_SID__c)){
					con.AccountId = mapSidAndAccount.get(con.Account_SID__c).Id;
				}
			}
		}
	}

	public static void partnerPortalShowcaseCreateOpportunity(Boolean isInsert, Map<Id,Contact> newMap, Map<Id, Contact> oldMap) {
        System.debug('Starting Showcase Opportunity Processing');

        // If the current running user is not API/Eloqua (or other test users) then skip this process
        if (!isRunningAsApiUser())  return;
        System.debug('Running as ELOQUA API user: ' + UserInfo.getName());

		// Configurable variables        
        Set<String> leadSourceCriteria = new Set<String> { 'Showcase', 'Twilio.org Showcase' };

        // Only operate on contacts that meet the lead source criteria
        Map<Id,Contact> contacts = new Map<Id,Contact>();
        Set<Id> accountIds = new Set<Id>();
        for (Contact n : newMap.values()) {
            // If Lead_Source_Most_Recent_ELOQUA__c changes to a value in the leadSourceCriteria set,
            // then include for processing.
            Boolean lastLeadSourceCriteriaMet = isInsert ? leadSourceCriteria.contains(n.Lead_Source_Most_Recent_ELOQUA__c) : leadSourceCriteria.contains(n.Lead_Source_Most_Recent_ELOQUA__c) && !leadSourceCriteria.contains(oldMap.get(n.Id).Lead_Source_Most_Recent_ELOQUA__c);
            System.debug('Reviewing - Contact(' + n.Id + ') LeadSource(' + n.LeadSource + ') Lead_Source_Most_Recent_ELOQUA__c(' + n.Lead_Source_Most_Recent_ELOQUA__c + ') Partner_ID(' + n.Partner_ID__c + ')');
            if (lastLeadSourceCriteriaMet && n.Partner_ID__c != null) {
                System.debug('Qualifying contact:  Contact(' + n.Id + ',' + n.Name + ')');
                contacts.put(n.Id, n);
                accountIds.add(n.AccountId);
            }
        }

        // If there are no leads that meet the criteria exit the trigger
        if (contacts.isEmpty()) return;
        
        System.debug('Contacts to be processed: ' + contacts.size());

/* Email notifications disabled until told otherwise
		// Configurable variables        
		String emailFromDisplayName    = 'Twilio Partner Portal Lead Auto-Convert Process';

		// Determine if this is running in a sandbox and setting variables accordingly
        Organization org = [ SELECT Id, IsSandbox FROM Organization LIMIT 1];
        String orgURL     = org.IsSandbox ? 'https://test.salesforce.com' : 'https://login.salesforce.com';
        String emailFrom  = org.IsSandbox ? 'jonathan.f.griggs@gmail.com' : '`s@twilio.com';

		// Setup a email message list for email notifications
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();

        // Map the Partner_ID__c to their User
        Set<String> partnerIds = new Set<String>();
        for (Map<String,String> properties : leadList) {
            partnerIds.add(properties.get('Lead.Partner_ID__c'));
        }

        Map<String,User> partnerIdToUser = new Map<String,User>();
        for (User u : [ SELECT Id, Name, Partner_ID__c FROM User WHERE Partner_ID__c IN :partnerIds ]) {
            System.debug('=========> partnerIdToPAM MAP (USER=' + u.Name + ', PARTNER_ID=' + u.Partner_ID__c + ')');
            partnerIdToUser.put(u.Partner_ID__c, u);
        }
*/

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
        Map<Id,Opportunity> contactIdToOpportunities = new Map<Id,Opportunity>();
        List<Pass_To_Partner__c> passToPartners = new List<Pass_To_Partner__c>();

		// Lookup Account information
		Map<Id,Account> accounts = new Map<Id,Account>([ SELECT Id, Name FROM Account WHERE Id IN :accountIds ]);
		
        for (Contact c : contacts.values()) {
        	String contactName = c.FirstName + ' ' + c.LastName;
            System.debug('Contact(' + c.Id + ', ' + contactName + ')');
            OpportunityRoutingServices.OppSettingWrapper oppWrapper = ppRouting.getOwnerWrapper(c.Account_Quarterback_ID__c, c.MailingCountry, c.MailingState, c.MailingPostalCode, 1, '', c.Showcase_Use_Case__c, c.REF_Showcase_Employee_Size__c);
            Opportunity o = new Opportunity(
            	Name = accounts.get(c.AccountId).Name + ' - ' + c.Lead_Source_Most_Recent_ELOQUA__c,
            	StageName = 'Qualified',
            	//OwnerId = ppRouting.getOwnerId(c.MailingCountryCode, c.MailingStateCode, c.Showcase_Employee_Size__c, c.Showcase_Use_Case__c),
            	OwnerId = oppWrapper.oppOwnerId,
            	Solution_Sales_Specialist__c = oppWrapper.specialistId,
				AccountId = c.AccountId,
            	Qualified_Lead_Source__c = c.Lead_Source_Most_Recent_ELOQUA__c,
            	Use_Case_Category__c = c.Showcase_Use_Case__c,
                Partner_ID__c = c.Partner_ID__c,
                CloseDate = closeDate
            );
            if (useCaseToOppRecTypeMap.containsKey(c.Showcase_Use_Case__c)) {
            	o.RecordTypeId = useCaseToOppRecTypeMap.get(c.Showcase_Use_Case__c);
				System.debug('Setting Opportunity.RecordTypeId to "' + o.RecordTypeId + '"');
            } else {
            	System.debug('Missing Use Case to Opportunity Record Type mapping:  "' + c.Showcase_Use_Case__c + '" does not have a entry in Use_Case_to_Opp_Record_Type__c custom setting.');
				c.addError('Missing Use Case to Opportunity Record Type mapping:  "' + c.Showcase_Use_Case__c + '" does not have a entry in Use_Case_to_Opp_Record_Type__c custom setting.');
            }
            contactIdToOpportunities.put(c.Id, o);
        }

        System.debug('Inserting Opportunity records');
        insert contactIdToOpportunities.values();

		// Create the Opportunity Contact Roles and Pass To Partner records
		List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
		for (Contact c : contacts.values()) {
			// Determine if there is an owner mapping for the Partner ID
			String ownerId;
			String accountId;
			if (partnerPortalMap.containsKey(c.Partner_ID__c) && partnerPortalMap.get(c.Partner_ID__c) != null) {
				ownerId = partnerPortalMap.get(c.Partner_ID__c).User_ID__c;
				accountId = partnerPortalMap.get(c.Partner_ID__c).Account_ID__c;
				System.debug('Using Contact Partner ID for Partner User Map matching "' + c.Partner_ID__c + '": OwnerId(' + ownerId + ')');
			} else {
            	System.debug('No Partner User mapping in PartnerPortalMappings__c found for Partner ID "' + c.Partner_ID__c + '"');
				c.addError('No Partner User mapping in PartnerPortalMappings__c found for Partner ID "' + c.Partner_ID__c + '"');
			}
			
			Id opportunityId;
			if (contactIdToOpportunities.containsKey(c.Id) && contactIdToOpportunities.get(c.Id) != null) {
				opportunityId = contactIdToOpportunities.get(c.Id).Id;
			} else {
            	System.debug('No Opportunity was found for Contact "' + c.Id + '"');
				c.addError('No Opportunity was found for Contact "' + c.Id + '"');
			}
			
			if (ownerId != null && opportunityId != null) {
				opportunityContactRoles.add(new OpportunityContactRole(
					OpportunityId = opportunityId,
					ContactId = c.Id
				));

				passToPartners.add(new Pass_To_Partner__c(
					OwnerId = ownerId,
					Partner_Account__c = accountId,
					Opportunity__c = opportunityId,
					Contact__c = c.Id,
					Partner_Status__c = 'Submitted to Partner'
				));
			}

/* Email notifications disabled until told otherwise
            System.debug('PREPARING EMAIL NOTIFICATIONS');

    		// Determine the new owner of the converted lead
    		Id ownerUserId = properties.get('Opportunity.OwnerId');

            Messaging.SingleEmailMessage mailForOpptyOwner = new Messaging.SingleEmailMessage();
            mailForOpptyOwner.setTargetObjectId(ownerUserId);
            mailForOpptyOwner.setReplyTo(emailFrom);
            mailForOpptyOwner.setSenderDisplayName(emailFromDisplayName);
            mailForOpptyOwner.saveAsActivity = false;
            mailForOpptyOwner.setSubject('Assigned Showcase Opportunity');
            mailForOpptyOwner.setPlainTextBody('New Showcase opportunity has been created and assigned to you:  ' + leadName);
            mailList.add(mailForOpptyOwner);
            
            // Determine the partner user of the converted lead
            User partnerUser = partnerIdToUser.get(properties.get('Lead.Partner_ID__c'));
                
            Messaging.SingleEmailMessage mailForPartner = new Messaging.SingleEmailMessage();
            mailForPartner.setTargetObjectId(partnerUser.Id);
            mailForPartner.setReplyTo(emailFrom);
            mailForPartner.setSenderDisplayName(emailFromDisplayName);
            mailForPartner.saveAsActivity = false;
            mailForPartner.setSubject('Assigned Showcase Opportunity');
            mailForPartner.setPlainTextBody('New Showcase opportunity has been created and assigned to you:  ' + leadName);
            mailList.add(mailForPartner);
*/
        }

        System.debug('Inserting Opportunity Contact Role records');
		insert opportunityContactRoles;        

        System.debug('Inserting Pass To Partner records');
        insert passToPartners;

/* Email notifications disabled until told otherwise
        // Send out the email notifications in the mail list
        System.debug('Sending email notifications');
        if (!mailList.isEmpty() || Test.isRunningTest()) {
            System.debug('SENDING EMAIL');
            Messaging.sendEmail(mailList);
        }
*/

		System.debug('Completed Post-Conversion Processing');
    }
}