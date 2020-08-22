public class PassOpptyToPartnerController {
  public static String partnerStageName = 'Qualified';
  public static String partnerOppRecTypeName = 'Partner Opportunity';
  public static String partnerApprovalProcessName = 'Partner_Opportunity_Flow';

  public Account account { get; set; }
  public Contact contact { get; set; }
  public User partner { get; set; }

  public ApexPages.StandardController accountController { get; set; }
  public Boolean canPassToPartner { get; set; }

  public Integer step { get; set; }
  public Boolean getStep1() { return(step == 1); }
  public Boolean getStep2() { return(step == 2); }
  public Boolean getStep3() { return(step == 3); }
  
  public Id partnerOppRecTypeId { get; set; }

  public Opportunity partnerAssignment { get; set; }

  public Map<String, User> partnerMap { get; set; }
  public List<SelectOption> partnerOptions { get; set; }
  public String selectedPartner { get; set; }

  public Map<String, Contact> contactMap { get; set; }
  public List<SelectOption> contactOptions { get; set; }
  public String selectedContact { get; set; }
  
  public LeadStatus convertStatus { get; set; }
  public List<Opportunity> opportunities { get; set; }
  
  public PassOpptyToPartnerController(ApexPages.StandardController controller) {
      accountController = controller;

      List<String> fieldList = new List<String>();
      fieldList.add('Partner_Request_Notes_ELOQUA__c');
      if (!Test.isRunningTest()) {
          accountController.addFields(fieldList);
      }

      account = (Account)controller.getRecord();

      step = 1;
      canPassToPartner = true;

      // Get the "Partner Opportunity" record type for the new opportunities that will be created during the conversion process
      if (Schema.SObjectType.Opportunity.RecordTypeInfosByName.get(partnerOppRecTypeName) == null) {
          canPassToPartner = false;
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Opportunity record type "' + partnerOppRecTypeName + '" does not exist.  Please contact your Salesforce administrator.'));
      } else {
          partnerOppRecTypeId = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get(partnerOppRecTypeName).RecordTypeId;
      }

      List<Contact> contactList = [
      	  SELECT id, Name, FirstName, LastName, Phone, Email
		  FROM Contact
		  WHERE AccountId = :account.Id AND Inactive__c = false AND isDeleted = false
		  ORDER BY Name
	  ];
      if (contactList.isEmpty()) {
          canPassToPartner = false;
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'The account must have at least one contact to create an opportunity for a partner.'));
      }
      
      List<User> partnerList = [
      	  SELECT id, Name, Contact.AccountId
		  FROM User
		  WHERE Profile.UserLicense.Name='Partner Community' AND isActive = true
		  ORDER BY Name
	  ];
      if (partnerList.isEmpty()) {
          canPassToPartner = false;
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'The account must have at least one partner portal user to create an opportunity for a partner.'));
      }          
      
      if (canPassToPartner) {
          // Build a map of the account contacts for looking up by Id
          contactMap = new Map<String, Contact>();
          selectedContact = 'none';
          contact = null;

          // Build the picklist of Account Contacts for the VF page
          contactOptions = new List<SelectOption>();
          contactOptions.add(new SelectOption('none', '--Select a contact--'));
          for (Contact c : contactList) {
              contactOptions.add(new SelectOption(c.Id, c.Name));
              contactMap.put(c.Id, c);
          }

          // Build a map of the partner users for looking up by Id
          partnerMap = new Map<String, User>();
          selectedPartner = 'none';
          partner = null;
          
          // Build the picklist of partners for the VF page
          partnerOptions = new List<SelectOption>();
          partnerOptions.add(new SelectOption('none', '--Select a partner--'));
          for (User u : partnerList) {
              partnerOptions.add(new SelectOption(u.Id, u.Name));
              partnerMap.put(u.Id, u);
          }

          // Initialize the partner leads for the VF page
          partnerAssignment = new Opportunity(
			  AccountId = account.Id,
			  RecordTypeId = partnerOppRecTypeId,
			  StageName = partnerStageName,
			  CloseDate = Date.today()
          );
      }
  }

  public PageReference gotoStep1() {
  	step = 1;
    return null;
  }
  
  public PageReference gotoStep2() {
  	if (selectedContact == 'none') {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'A contact must be selected.'));  		
  	} else {
  		contact = contactMap.get(selectedContact);
	  	step = 2;
  	}
    return null;
  }
  
  public PageReference gotoStep3() {
  	Boolean canContinue = true;

  	if (selectedPartner == 'none') {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'A partner must be selected.'));
        canContinue = false;	
  	}
	
  	if (String.isBlank(partnerAssignment.Use_Case1__c)) {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'A use case must be selected.'));
        canContinue = false;	
  	} else if (String.isBlank(partnerAssignment.Solution_Area__c)) {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'A solution area must be selected.'));
        canContinue = false;	
  	}
  	
	if (canContinue){
  		partner = partnerMap.get(selectedPartner);
	    step = 3;
	    return save();
  	} else {
	    return null;
	}
  }
  
  public PageReference save() {
    try {
		partnerAssignment.Name = account.Name + ' - ' + contact.Name;
		partnerAssignment.AccountId = account.Id;
		partnerAssignment.OwnerId = partner.Id;
		partnerAssignment.Description = (String.isBlank(contact.FirstName) ? 'No First Name' : contact.FirstName)
			+ ', ' + (String.isBlank(contact.LastName) ? 'No Last Name' : contact.LastName)
			+ ', ' + (String.isBlank(contact.Phone) ? 'No Phone' : contact.Phone)
			+ ', ' + (String.isBlank(contact.Email) ? 'No Email' : contact.Email);
		insert partnerAssignment;

		// Create an approval request for the Opportunity
	    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
	    request.setComments('Submitting request for approval.');
	    request.setObjectId(partnerAssignment.Id);
	        
	    // Submit the approval request for the account
	    Approval.ProcessResult result = Approval.process(request);
		                
	    // Verify the result
	    System.assert(result.isSuccess());

        System.debug('===========> SUBMIT OPPORTUNITY FOR PARTNER APPROVALS');                  

		return new PageReference('/'+ partnerAssignment.Id +'/e?retURL=%2F' + partnerAssignment.Id);
    } catch (System.DmlException e) {
        System.debug('===========> ERROR INSERTING OPPORUNTITY PARTNER ASSIGNMENTS');
	    for (Integer i = 0; i < e.getNumDml(); i++) {
	        System.debug('===========> ERROR: ' + e.getDmlMessage(i)); 
	    }
	    return null;
    }
  }  
}