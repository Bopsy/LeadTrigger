public class PassLeadToPartnerController {
  public static Set<String> requiredLeadStages = new Set<String>{ 'Sales Qualified', 'Partner Pass - No SQL' };
  public static String partnerOppRecTypeName = 'Partner Opportunity';
  public static String partnerApprovalProcessName = 'Partner_Opportunity_Flow';
  public static String convertedLeadStatus = 'Opportunity';

  public Lead lead { get; set; }
  public ApexPages.StandardController leadController { get; set; }
  public Boolean canPassToPartner { get; set; }
  public Boolean canSave { get; set; }
  public Boolean isSaved { get; set; }

  public List<Lead> partnerAssignments { get; set; }
  public Map<String, User> partnerMap { get; set; }
  public List<SelectOption> partnerOptions { get; set; }
  public List<String> selectedPartners { get; set; }
  public Id partnerOppRecTypeId { get; set; }
  
  public LeadStatus convertStatus { get; set; }
  public List<Opportunity> opportunities { get; set; }
  
  public PassLeadToPartnerController(ApexPages.StandardController controller) {
      leadController = controller;

      canSave = true;
      isSaved = false;
      
      // Need to add all of the fields so that they will be cloned
      List<String> fieldList = new List<String>();
      fieldList.add('FirstName');
      fieldList.add('LastName');
      fieldList.add('Email');
      fieldList.add('Phone');
      fieldList.add('CreatedDate');
      Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('lead').getDescribe().fields.getMap();
	  for (Schema.SObjectField f : fieldMap.values()) {
		  Schema.DescribeFieldResult fd = f.getDescribe();
		  if (fd.isCreateable()) {
		      fieldList.add(fd.getName());
		  }
	  }
      if (!Test.isRunningTest()) {
      	controller.addFields(fieldList);
      }
      lead = (Lead)controller.getRecord();

      canPassToPartner = true;

      // Get the "Partner Opportunity" record type for the new opportunities that will be created during the conversion process
      if (Schema.SObjectType.Opportunity.RecordTypeInfosByName.get(partnerOppRecTypeName) == null) {
          canPassToPartner = false;
		  ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Opportunity record type "' + partnerOppRecTypeName + '" does not exist.  Please contact your Salesforce administrator.'));
	  } else {
	  	  partnerOppRecTypeId = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get(partnerOppRecTypeName).RecordTypeId;

	      if (!requiredLeadStages.contains(lead.Status)) {
	          canPassToPartner = false;
	          ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL,'Lead Status must be "'+ String.join(new List<String>(requiredLeadStages), '" or "') + '".'));
	      }
	  }
	  
	  // Get the LeadStatus to set whenever the leads are converted
	  List<LeadStatus> convertStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel = :convertedLeadStatus ];
	  if (convertStatuses.size() != 1) {
          canPassToPartner = false;
	      ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Lead object does not have a "converted" LeadStatus of "' + convertedLeadStatus + '"'));
	  } else {
	  	  convertStatus = convertStatuses[0];
	  }
	  
	  List<User> users = [ SELECT Id FROM User WHERE Id = :lead.OwnerId ];
	  if (users.isEmpty()) {
          canPassToPartner = false;
	      ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Lead must be owned by a user.  You must specify a user for the Owner field.'));
	  }
	  
	  if (lead.Account_Type__c != 'Partner Account' && String.isNotBlank(lead.Account_Type__c)) {
          canPassToPartner = false;
	      ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Lead cannot be passed to a partner with "Account Type" set to "' + lead.Account_Type__c + '".  You must specify an "Account Type" of "Partner Account" or the "Account Type" must be set to none.'));
	  }
      
      if (canPassToPartner) {
          lead.AutoDeleteAccount__c = true;

	      // Initialize the partner leads for the VF page
	      partnerAssignments = new List<Lead> { copy(lead), copy(lead), copy(lead) };
	      selectedPartners = new List<String> { 'none', 'none', 'none' };
	
	      // Build a map of the partner users for looking up by Id
		  partnerMap = new Map<String, User>();
		  
		  // Build the picklist of partners for the VF page
	      partnerOptions = new List<SelectOption>();
	      partnerOptions.add(new SelectOption('none', '--None--'));
	      for (User u : [SELECT id, Name, Contact.AccountId, PAM__c FROM User WHERE Profile.UserLicense.Name='Partner Community' AND isActive = true ORDER BY Name]) {
	          partnerOptions.add(new SelectOption(u.Id, u.Name));
	          partnerMap.put(u.Id, u);
	      }
      }
  }

  public PageReference save() {
  	if (isSaved) {
  		return null;
  	}

	// Verify that the lead is not being assigned to the same partner more than once
	Set<String> dupCheck = new Set<String>();
	for (String p : selectedPartners) {
		if (p == 'none') continue;
		if (dupCheck.contains(p)) {
	        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL,'Cannot assign the lead to "' + partnerMap.get(p).Name + '" more than once.'));
	        return null;
		}
		dupCheck.add(p);
	}

    // Get all of the cloned leads that do have an Owner specified
    List<Lead> leads = new List<Lead>();
	List<String> partnerUserPAM = new List<String>();
    for (Integer i = 0; i < selectedPartners.size(); i++) {
        System.debug('===========> REVIEWING LEAD OWNER(' + selectedPartners[i] + ')');                  
        if (selectedPartners[i] != 'none') {
            System.debug('===========> ADDING LEAD(' + partnerMap.get(selectedPartners[i]).Name + ')');

            // Set the lead owner
            partnerAssignments[i].OwnerId = selectedPartners[i];
            partnerUserPAM.add(partnerMap.get(selectedPartners[i]).PAM__c);

            leads.add(partnerAssignments[i]);
        }
    }
    
	// Verify that at least one partner assignment was given
    System.debug('===========> NUMBER OF LEADS SPECIFIED(' + leads.size() + ')');                  
    if (leads.isEmpty()) {
        System.debug('===========> NO LEADS SPECIFIED');                  
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'At least one partner must be specified.'));
        return null;
    }
    
    try {
        // Create the records for the lead partner assignments
        insert leads;
        canSave = false;

	    // Create a mapping of PAM to User records to assign to the Opportunity
	    Map<String, User> partnerLeadPAMMap = new Map<String, User>();
	    for (User u : [ SELECT Id, Name FROM User WHERE Name IN :partnerUserPAM ]) {
	    	for (Lead l : leads) {
	   			System.debug('===========> PARTNER LEAD PAM MAP(Lead.Id=' + l.Id + ', Lead.OwnerId.PAM=' + partnerMap.get(l.OwnerId).PAM__c + ', User.Name' + u.Name + ')');
	    		if (partnerMap.get(l.OwnerId).PAM__c == u.Name) {
	    			partnerLeadPAMMap.put(l.Id, u);
	    			System.debug('===========> MATCHED - PARTNER LEAD PAM MAP(Lead.Id=' + l.Id + ', Lead.OwnerId.PAM=' + partnerMap.get(l.OwnerId).PAM__c + ', User.Name' + u.Name + ')');
	    		}
	    	}
	    }
	    
	    lead.AutoDeleteAccount__c = true;
	    update lead;

		// Add the original lead to the beginning of the lead list in order to convert it with the others.
		// The original lead should be the first lead converted in case there is a problem to prevent any others
		// from being converted.
		List<Lead> newLeads = new List<Lead>();
		newLeads.add(lead);
		newLeads.addAll(leads);
		leads = newLeads;

		// Convert the leads and load the resulting Account, Contact, and Opportunity records into the ConvertedLead list
		List<Database.LeadConvertResult> results = new List<Database.LeadConvertResult>();

		List<Account> accounts = new List<Account>();
		List<Id> opportunityId = new List<Id>();
		String contactInfo = (String.isBlank(lead.FirstName) ? 'No First Name' : lead.FirstName)
				+ ', ' + (String.isBlank(lead.LastName) ? 'No Last Name' : lead.LastName)
				+ ', ' + (String.isBlank(lead.Phone) ? 'No Phone' : Lead.Phone)
				+ ', ' + (String.isBlank(lead.Email) ? 'No Email' : Lead.Email);

		String today = Date.today().month() + '/' + Date.today().day() + '/' + Date.today().year();

		// When the SFDC tests are running cannot perform Lead conversion because the
		// box.com managed package will attempt to make a web service callout
		for (Integer i = 0; i < leads.size(); i++) {
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(leads[i].id);
			lc.setConvertedStatus(convertStatus.MasterLabel);
			if (leads[i].Id == lead.Id) {
				// Do not create an Opportunity for the original lead
				lc.setDoNotCreateOpportunity(false);
			} else {
				lc.setOpportunityName((!partnerMap.containsKey(leads[i].OwnerId) ? 'UNKNOWN' : partnerMap.get(leads[i].OwnerId).Name) + ' - ' + (String.isBlank(lead.Name) ? 'UNKNOWN' : lead.Name) + ' - ' + (String.isBlank(lead.Use_Case__c) ? 'UNKNOWN' : lead.Use_Case__c) + ' - ' + (String.isBlank(lead.Solution_Area__c) ? 'UNKNOWN' : lead.Solution_Area__c) + ' - ' + today);
			}
			if (!Test.isRunningTest()) {
				Database.LeadConvertResult lcr = Database.convertLead(lc);
				results.add(lcr);
			}
		}
		
		Map<Id, User> partnerOpptyPAMMap = new Map<Id, User>();
		for (Database.LeadConvertResult r : results) {
			accounts.add(new Account(Id = r.getAccountId()));
			// Skip the original lead
			if (r.getLeadId() != lead.Id) {
				opportunityId.add(r.getOpportunityId());
	  			System.debug('===========> PARTNER LEAD PAM MAP CHECK(Lead.Id=' + r.getLeadId() + ', MapContainsKey=' + partnerLeadPAMMap.containsKey(r.getLeadId()) + ')');
				if (partnerLeadPAMMap.containsKey(r.getLeadId())) {
			    	partnerOpptyPAMMap.put(r.getOpportunityId(), partnerLeadPAMMap.get(r.getLeadId()));
		  			System.debug('===========> MATCHED - PARTNER LEAD PAM MAP CHECK(Lead.Id=' + r.getLeadId() + ', MapContainsKey=' + partnerLeadPAMMap.containsKey(r.getLeadId()) + ')');
				}
			}
		}

		// Set the opportunities' Record Type to "Partner Opportunity" and assign ownership
		// to the partner
		opportunities = [
			SELECT Id, Name, OwnerId, Owner.ContactId, Owner.Contact.Name, Twilio_Partner_Account_Manager__c,
				AccountId, Account.Name, Account.OwnerId, Account.Owner.Name, Account.Partner_Request_Notes_ELOQUA__c
			FROM Opportunity
			WHERE Id IN :opportunityId
		];
		for (Opportunity o : opportunities) {
			o.RecordTypeId = partnerOppRecTypeId;
			o.StageName = 'Qualified';
			o.AccountId = partnerMap.get(o.OwnerId).Contact.AccountId;
			o.Twilio_Partner_Account_Manager__c = (partnerOpptyPAMMap.containsKey(o.Id) ? partnerOpptyPAMMap.get(o.Id).Id : null);
			o.Description = contactInfo;
			
		}
		update opportunities;

		// Now that the ownership of the Opportunity has been changed delete the Account
		// that was created during the Lead conversion process.
		delete accounts;
		

		for (Opportunity o : opportunities) {
			// Create an approval request for the Opportunity
	        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
//	        request.setComments('Submitting request for approval.');
	        request.setObjectId(o.Id);
	        
	        // Submit the record to specific process and skip the criteria evaluation
	        // - ProcessSubmitRequest methods below will be available in Winter'15
	        //request.setProcessDefinitionNameOrId(partnerApprovalProcessName);
	        //request.setSkipEntryCriteria(true);
 
	        // Submit the approval request for the account
	        Approval.ProcessResult result = Approval.process(request);
		                
	        // Verify the result
	        System.assert(result.isSuccess());
		}
		isSaved = true;

//        System.debug('===========> INSERTED LEAD PARTNER ASSIGNMENTS');                  
    } catch (System.DmlException e) {
        System.debug('===========> ERROR INSERTING LEAD PARTNER ASSIGNMENTS');
        String emsg = '';
	    for (Integer i = 0; i < e.getNumDml(); i++) {
	        System.debug('===========> ERROR: ' + e.getDmlMessage(i)); 
	        emsg = emsg + ' ' + e.getDmlMessage(i);
	    }
	    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, emsg));
        canSave = true;
	    return null;
    }

    return null;
  }
  
  private Lead copy(Lead lead) {
    Lead l = lead.clone(false,true,false,false);
    l.Partner_Portal_Lead__c = true;
    l.OwnerId = null;
    l.Partner_Notes__c = '';
    return l;
  }
}