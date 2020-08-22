trigger PartnerDealSubmission on Lead (after update) {
    public static String convertedLeadStatus = 'Opportunity';

	public static String fallbackOwnerName = 'Casey Clegg';

	public static String assignedAccountName = 'Twilio Incoming Partner Deals';
	public static String intialOwnerName = 'Website Inbound Queue';
	public static String partnerOppRecTypeName = 'Deal Reg Opportunity';
	public static String partnerApprovalProcessName = 'Partner_Opportunity_Flow';

	public static String openDealOpportunityStage = 'Use Case Confirmed';
	public static String closedDealOpportunityStage = 'Closed Won';

	public static String ppOpenDealLeadSource = 'PPortal - Open Deal Reg';
	public static String ppClosedDealLeadSource = 'PPortal - Closed Deal Reg';
	public static String wfOpenDealLeadSource = 'WebForm - Open Deal Reg';
	public static String wfClosedDealLeadSource = 'WebForm - Closed Deal Reg';
	
	Id assignedAccountId = null;
	Id partnerOppRecTypeId = null;
	Id fallbackOwnerId = null;
	LeadStatus convertStatus = null;
	Set<String> partnerIds = new Set<String>();
	List<Lead> leads = new List<Lead>();

	Map<Id,Lead> newLead = Trigger.newMap;
	Map<Id,Lead> oldLead = Trigger.oldMap;

	// Only operate on leads that are come from the Web2Lead form from the Partner Portal or Ahoy website.
	for (Id l : newLead.keySet()) {
		// Validate that the lead meets the criteria of a Partner Portal web2lead generate lead.
		System.debug('=========> Lead_Source(' + newLead.get(l).LeadSource + ')');
		System.debug('=========> Lead_State(' + newLead.get(l).Status + ')');
		System.debug('=========> Partner_ID(' + newLead.get(l).Partner_ID__c + ')');
		if ((
				newLead.get(l).LeadSource == ppOpenDealLeadSource || newLead.get(l).LeadSource == ppClosedDealLeadSource
				|| newLead.get(l).LeadSource == wfOpenDealLeadSource || newLead.get(l).LeadSource == wfClosedDealLeadSource
			)
			&& newLead.get(l).Status == 'Open'
			&& !newLead.get(l).isConverted
		) {
			System.debug('=========> Qualifying lead:  Lead(' + l + ')');
			leads.add(newLead.get(l));
			if (String.isNotBlank(newLead.get(l).Partner_ID__c)) {
				partnerIds.add(newLead.get(l).Partner_ID__c);
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
		TriggerUtil.setLeadError(Trigger.new, 'Fallback Owner "' + fallbackOwnerName + '" does not exist.  Please contact your Salesforce administrator.');
		return;
	} else {
		fallbackOwnerId = fuser[0].Id;
	}
	
    // Get the "Partner Opportunity" record type for the new opportunities that will be created during the conversion process
    if (Schema.SObjectType.Opportunity.RecordTypeInfosByName.get(partnerOppRecTypeName) == null) {
		TriggerUtil.setLeadError(Trigger.new, 'Opportunity record type "' + partnerOppRecTypeName + '" does not exist.  Please contact your Salesforce administrator.');
		return;
	} else {
		partnerOppRecTypeId = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get(partnerOppRecTypeName).RecordTypeId;
	}

	// Lookup the assigned account by name.
	// If it does not exist abort the execution of the trigger.
	List<Account> assignedAccounts = [ SELECT Id, Name FROM Account WHERE Name = :assignedAccountName ];
	if (assignedAccounts.isEmpty()) {
		System.debug('=========> ERROR: "' + assignedAccountName + '" account is not found.  PartnerDealSubmission trigger aborting...');
		TriggerUtil.setLeadError(Trigger.new, '"' + assignedAccountName + '" account is not found.  PartnerDealSubmission trigger aborting...');
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
		TriggerUtil.setLeadError(Trigger.new, 'Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"');
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
	//			System.debug('===========> LEAD #' + (i + 1) + ' CONVERTED:' + lcr.isSuccess());
				results.add(lcr);
		}
	}
	
	List<Opportunity> opportunities = new List<Opportunity>();
	for (Database.LeadConvertResult r : results) {
		accounts.add(new Account(Id = r.getAccountId()));

		// Set the opportunities' fields as required
		String ls = newLead.get(r.getLeadId()).LeadSource;
		User u = partnerId2User.get(newLead.get(r.getLeadId()).Partner_ID__c);

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