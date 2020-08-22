public without sharing class UseCaseConvertController 
{
    
    ApexPages.standardController msc = null;   
    public static Boolean inConversion = false;
    static public String ConvertedAccountOwnerName = 'Customer Success Team';

    public Opportunity opp {get;set;}
    public Use_Case_Interest__c usecase {get;set;}
    public String selectedStatus {get;set;} 
    public User accountOwner {get;set;}
    public String accountQBName {get; set;}
    public String accountQBsize {get; set;}
    public String accountQBState {get; set;}
    public String accountQBZipCode {get; set;}
    public String accountQBCountry {get; set;}
    
    public String oppOwnerName {get; set;}
    public String oppSpecialistName {get; set;}
    public String oppSize {get; set;}
    public String oppAmount {get; set;}
    public String oppSolution {get; set;}
    public String oppProduct {get; set;}
    public String oppState {get; set;}
    public String oppZipCode {get; set;}
    public String oppCountry {get; set;}
    
    public String AccName {get;set;}
    public String ConName {get;set;}
    public boolean readOnlyFlag{get;set;} 
    public boolean createAcc{get;set;}
    public Id memberId {get; set;}
    public Id accountQBId {get; set;}

    public Id convertedOppId {get;set;}
	public String errorMsg {get; set;}    
    
    // Constructor    
    public UseCaseConvertController(ApexPages.StandardController controller)  
    {         
        List<Use_Case_Interest__c> useCaseList = new List<Use_Case_Interest__c>();
        msc = controller; 
        
        string usecaseId = apexpages.currentpage().getparameters().get('id');
        
        /*/
         * Fetching use case Interest's record. 
        /*/
        if(usecaseId != null)
        {
            String selectString = 'select id, MQL__c, SendGrid_Specialist__c, Account_Quarterback__c, Email__c, contact__r.account.REF_AE_Routing_Tier__c,contact__r.account.FY_17_AE_Owner_Preliminary__c, contact__r.account.FY_17_Key_AE_Account__c, Solution_Sales_Specialist__c, contact__r.account.SFDC_ZipCode__c, contact__r.account.ownerid, contact__r.account.SFDC_State__c, contact__r.account.SFDC_Country__c, contact__r.account.REF_Employee_Size__c, lead__r.REF_Employee_Size__c, lead__r.country,lead__r.City,lead__r.Street,lead__r.PostalCode,lead__r.State,lead__r.isconverted,lead__r.ownerid,ownerid,name, lead__c,contact__r.name,lead__r.Product__c,lead__r.Salutation,lead__r.firstname,lead__r.lastname,lead__r.company,contact__c,contact__r.accountid,contact__r.account.name,account_owner__c';
            selectString += ', ' + getUseCaseFieldString();
            String queryString = selectString + ' from Use_Case_Interest__c where ID =: usecaseId LIMIT 1';
            System.debug(queryString);
            useCaseList = (List<Use_Case_Interest__c>)Database.query(queryString);
        }
        
        if(useCaseList.size() > 0)
        {
            usecase = useCaseList[0];
            opp = new Opportunity();              
            OpportunityRoutingServices.OppWrapper wrapper = new OpportunityRoutingServices.OppWrapper();
            /*/
             * Checking whether useCase record has related contact.
             * If No, putting values to variable for creating new account,contact and opportunity.
             * If Yes, Using the values from contact and converted lead to generate new opportunoity record.
            /*/
            wrapper.amount = usecase.Volume__c;
            wrapper.product = usecase.FY_16_Primary_Product__c;
            wrapper.solutionCategory = usecase.Solution_Category__c;
            if(usecase.Contact__c == null)
            {
                createAcc = true;
                readOnlyFlag = true ;
                AccName = usecase.lead__r.company;       
                String contactname = '';
                
                if(usecase.lead__r.Salutation !=null)
                {
                    contactname = usecase.lead__r.Salutation + ' ';
                }
                if(usecase.lead__r.firstname != null)
                {
                    contactname = usecase.lead__r.firstname + ' ' ; 
                }     
                if(usecase.lead__r.lastname != null)
                {
                    contactname = contactname + usecase.lead__r.lastname;            
                }
                
                conName = contactname;                 
                opp.name = usecase.lead__r.company + ' - ';
                
                if(usecase.lead__r.Product__c != null)
                {
                    opp.name = opp.name + usecase.lead__r.Product__c;
                }
                
                selectedStatus = 'Opportunity';
                wrapper.zipCode = usecase.lead__r.PostalCode;
                wrapper.state = usecase.lead__r.State;
                wrapper.country = usecase.lead__r.country;
                wrapper.employeeSize = usecase.lead__r.REF_Employee_Size__c;
                wrapper.AESwitch = false;
                wrapper.ignoreAE = true;
            } 
            else
            {
                opp.name = usecase.contact__r.account.name ;
                list<lead> parentleadList = [select id,name,product__c from lead where isConverted = true AND ConvertedAccountId = :usecase.contact__r.accountid];
                if(parentleadList.size() > 0 && parentleadList[0].product__c != null)
                {
                    opp.name = opp.name + ' - ' + parentleadList[0].product__c ;
                }
                wrapper.zipCode = usecase.contact__r.account.SFDC_ZipCode__c;
                wrapper.state = usecase.contact__r.account.SFDC_State__c;
                wrapper.country = usecase.contact__r.account.SFDC_Country__c;
                wrapper.employeeSize = usecase.contact__r.account.REF_Employee_Size__c;
                wrapper.AESwitch = usecase.contact__r.account.FY_17_Key_AE_Account__c;
                wrapper.aeOwner = usecase.contact__r.account.ownerId;
                wrapper.aeTier = usecase.contact__r.account.REF_AE_Routing_Tier__c;
                wrapper.ignoreAE = false;
            }

            /*/
             * If the Account Owner is not specified that set it to ConvertedAccountOwner
            /*/
            if (usecase.Account_Owner__c == null) {
                List<User> u = [ SELECT Id, Name FROM User WHERE Name = :ConvertedAccountOwnerName ];
                usecase.Account_Owner__c = (u.size() > 0) ? u[0].Id : '';
            }
            //system.assert(false, wrapper);
            if(createAcc != null){
                OpportunityRoutingServices.OppSettingWrapper resultWrapper = OpportunityRoutingServices.findOppOwner(wrapper);
                if(resultWrapper != null){
                    OpportunityRoutingServices.getRoundRobinOwnerId(resultWrapper);
                    accountQBId = resultWrapper.memberId;
                    useCase.Account_Quarterback__c = resultWrapper.oppOwnerId;
                    useCase.Account_Owner__c = resultWrapper.oppOwnerId;
                    accountQBName = resultWrapper.ownerName;
                    if(accountQBId != null) accountQBName += ' (Round Robin)';
                    accountQBCountry = resultWrapper.country;
                    accountQBState = resultWrapper.state;
                    accountQBZipCode = resultWrapper.zipCode == null ? resultWrapper.zipCodeFloor + ' - ' + resultWrapper.zipCodeCeiling : resultWrapper.zipCode;
                    accountQBsize = wrapper.employeeSize;
                }
            }
            if(usecase.Contact__c == null) wrapper.aeOwner = useCase.Account_Quarterback__c;
            if(useCase.Account_Quarterback__c == null) useCase.Account_Quarterback__c = UserInfo.getUserId();
            OpportunityRoutingServices.OppSettingWrapper oppWrapper = OpportunityRoutingServices.findOppOwner(wrapper);
            OpportunityRoutingServices.OppSettingWrapper specialistWrapper = OpportunityRoutingServices.findSpecialist(wrapper); 
            if(oppWrapper != null){
                OpportunityRoutingServices.getRoundRobinOwnerId(oppWrapper);
                memberId = oppWrapper.memberId;
                if(oppWrapper.oppOwnerId != null)
                    useCase.OwnerId = oppWrapper.oppOwnerId;
                if(specialistWrapper != null){
                    useCase.Solution_Sales_Specialist__c = specialistWrapper.specialistId;
                    oppSpecialistName = specialistWrapper.specialistName;
                }
                oppOwnerName = oppWrapper.ownerName;
                if(memberId != null) oppOwnerName += ' (Round Robin)';
                oppCountry = oppWrapper.country;
                oppState = oppWrapper.state;
                oppZipCode = oppWrapper.zipCode == null ? oppWrapper.zipCodeFloor + ' - ' + oppWrapper.zipCodeCeiling : oppWrapper.zipCode;
                oppSize = wrapper.employeeSize;
                oppProduct = oppWrapper.product;
                oppSolution = oppWrapper.solutionCategory;
                oppAmount = String.valueOf(wrapper.amount);
            }
            if(useCase.Email__c != null){
                String emailDomain = LeadAutoConvertHandler.getEmailDomain(useCase.Email__c, '');
                if(!String.isBlank(emailDomain)){
                    List<Email_Domain__c> domain = [SELECT Account__c, Account__r.Name FROM Email_Domain__c WHERE Unique_Name__c = :emailDomain];
                    if(domain != null && !domain.isEmpty()){
                         opp.AccountId = domain[0].Account__c;
                         createAcc = false;
                    }
                }
            }
        }        
    }
    
    /*/
     * Method to convert Lead To Opportunity from UseCase Record view page.
    /*/
    public PageReference convert() 
    {
        /*if(UserInfo.getUserId() != usecase.ownerid)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Sorry, you can only convert Use Case Interests that you own.')); 
            return null;
        }
        else
        {*/            
            inConversion = true;
            Opportunity convertedOpp = new opportunity(name= opp.name,accountid = opp.accountid);
            Datetime now = Datetime.now();
            if(memberId != null) update new Assignment_Groups__c(Id = memberId, Last_Assignment__c = now, Millisecond__c = now.millisecond());
            if(accountQBId != null && accountQBId != memberId) update new Assignment_Groups__c(Id = accountQBId, Last_Assignment__c = now, Millisecond__c = now.millisecond());
            PageReference oppPage;
            SavePoint sp = Database.setSavePoint();
            Id contactRtId = '01240000000cng1AAA';//[SELECT Id FROM RecordType WHERE SobjectType = 'Use_Case_Interest__c' AND Name = 'Contact' LIMIT 1].Id;
            /*/ 
             * Show error Message if user doesn't select any account record.
             * and doesn't select the flag to create new account.
            /*/
            if(usecase.Contact__c == null && !createAcc && convertedOpp.accountid == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Please select an account'));
                System.debug('UseCaseController.convert(LEAD): Exception Thrown - Please select an account');
                errorMsg = 'No account selected';
                return oppPage;
            }
            
            /*/
             * If use case has realated lead only.
             * Converting Lead To Account,Contact and Opportunity
             * Linking Oppotunity to Use case record. 
            /*/    
            else if(usecase.lead__c != null && (!usecase.lead__r.isconverted ) && usecase.Contact__c == null)
            {   
                Lead updateLead = new Lead(Id = usecase.lead__c, OwnerId = UserInfo.getUserId());
                update updateLead;
                Database.LeadConvert lc = new Database.LeadConvert();
                
                contact convertedCon = new contact();
                account convertedAcc;
                
                if(usecase.lead__r.Salutation !=null)
                {
                    convertedCon.Salutation= usecase.lead__r.Salutation;
                }
                if(usecase.lead__r.firstname != null)
                {
                    convertedCon.FirstName= usecase.lead__r.firstname ; 
                }     
                if(usecase.lead__r.Lastname != null)
                {
                    convertedCon.LastName = usecase.lead__r.lastname;            
                }
                
                if(usecase.lead__r.country!= null)
                {                     
                    convertedCon.MailingCountry= usecase.lead__r.country;                               
                }
                if(usecase.lead__r.city!= null)
                {                     
                    convertedCon.MailingCity= usecase.lead__r.city;                               
                }
                if(usecase.lead__r.Street!= null)
                {                     
                    convertedCon.MailingStreet= usecase.lead__r.Street;                               
                }
                if(usecase.lead__r.State!= null)
                {                     
                    convertedCon.MailingState= usecase.lead__r.State;                               
                }
                if(usecase.lead__r.PostalCode!= null)
                {                     
                    convertedCon.MailingPostalCode= usecase.lead__r.PostalCode;                               
                }
  
                            
                if(createAcc)
                {
                    convertedAcc = new account();
                    convertedAcc.name = usecase.lead__r.company;
                    convertedAcc.Lead_ID_If_Conversion__c = usecase.lead__c;
                    convertedAcc.BillingCountry= usecase.lead__r.country;
                    convertedAcc.BillingCity= usecase.lead__r.City;
                    convertedAcc.BillingStreet= usecase.lead__r.Street;
                    convertedAcc.BillingState= usecase.lead__r.State;
                    convertedAcc.BillingPostalCode= usecase.lead__r.PostalCode;
                    
                    convertedAcc.ShippingCountry= usecase.lead__r.country;
                    convertedAcc.ShippingCity= usecase.lead__r.City;
                    convertedAcc.ShippingStreet= usecase.lead__r.Street;
                    convertedAcc.ShippingState= usecase.lead__r.State;
                    convertedAcc.ShippingPostalCode= usecase.lead__r.PostalCode;
                    System.debug('UseCaseController.convert(LEAD): Create Account - ' + convertedAcc);
                }
                else
                {
                    lc.setAccountId(convertedOpp.accountid);                
                    convertedCon.accountid = convertedOpp.accountid;
                    System.debug('UseCaseController.convert(LEAD): Existing Account - ' + convertedOpp.accountid);
                }
                
                try
                {
                    if(createAcc)
                    {
                        convertedAcc.ownerid = usecase.Account_Owner__c;
                        //convertedAcc.FY_17_AE_Owner_Preliminary__c = usecase.Account_Quarterback__c;
                        insert convertedAcc;
                        System.debug('UseCaseController.convert(LEAD): Insert Account - ' + convertedAcc);
                        lc.setAccountId(convertedAcc.id);                
                        convertedCon.accountid = convertedAcc.id;
                        convertedOpp.accountid = convertedAcc.id;
                    }
                    
                    convertedCon.ownerid = usecase.ownerid;
                    insert convertedCon;
                    System.debug('UseCaseController.convert(LEAD): Insert Coontact - ' + convertedCon);

                    lc.setLeadId(usecase.Lead__c);             
                    lc.setContactId(convertedCon.id);
                    lc.setOpportunityName(convertedOpp.name);  
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
                    lc.setConvertedStatus(convertStatus.MasterLabel);        
                    
                    Database.LeadConvertResult lcr = Database.convertLead(lc);  
                    if(lcr != null && lcr.getopportunityid() !=null )
                    {
                        convertedOppId = lcr.getopportunityid();
                        if(usecase.MQL__c != null) update new FSR__c(Id = usecase.MQL__c, Opportunity__c = convertedOppId);
                        Opportunity oppToupdate = [select id, StageName, Account.OwnerId from Opportunity where id =: lcr.getopportunityid()];

			            // Get the Contact's related Short_Code__c and relate the Opportunity to the Short_Code__c
		                // Relate the Contact's Short_Code__c to the Opportunity
			            System.debug('UseCaseController.convert(LEAD): useCase = ' + useCase);
                		List<Short_Code__c> shortCodes = [ SELECT Id, Name FROM Short_Code__c WHERE Lead__c = :useCase.Lead__c LIMIT 1 ];
			            System.debug('UseCaseController.convert(LEAD): Related Short_Code__c = ' + shortCodes);
                		if (shortCodes.size() > 0) {
			            	oppToupdate.Short_Code__c = shortCodes[0].Id;
		                	shortCodes[0].Opportunity__c = convertedOppId;
			                shortCodes[0].OwnerId = oppToupdate.Account.OwnerId;
			                System.debug('UseCaseController.convert(LEAD): Set Opportunity Short_Code__c = ' + oppToupdate.Short_Code__c);
		                	System.debug('UseCaseController.convert(LEAD): Set Short Code Opportunity__c = '+ shortCodes[0].Opportunity__c);
	                		System.debug('UseCaseController.convert(LEAD): Set Short Code owner as Opportunity Account Owner = '+ shortCodes[0].OwnerId);
	                		update shortCodes[0];
	                		
	                		sendEmailNotification(shortCodes[0]);
		                }
	
                        oppToupdate.Use_Case_Interest__c = usecase.id;
                        mapFields(oppToupdate, usecase);
                        oppToupdate.StageName = 'Incubate'; 
                        oppToupdate.ownerid = usecase.ownerid;
                        oppToupdate.Solution_Sales_Specialist__c = usecase.Solution_Sales_Specialist__c;
                        oppToupdate.SendGrid_Specialist__c = usecase.SendGrid_Specialist__c;
                        update oppToupdate;
                        System.debug('UseCaseController.convert(LEAD): Updated Opportunity - ' + oppToupdate);

                        usecase.opportunity__c = lcr.getopportunityid();    
                        usecase.status__c = 'Converted';
                        usecase.RecordTypeId = contactRtId;
                        oppPage = new pagereference('/'+lcr.getopportunityid());

                        System.debug(usecase);
                        System.debug(convertedCon);
                        System.debug(lcr);
                        syncAllUciContacts(usecase.lead__c, convertedCon.Id);
                    	System.debug('UseCaseController.convert(LEAD): Sync UCI contacts on Lead (' + usecase.lead__c + ') with Contact(' + usecase.Contact__c + ')');
                    }
                    
                    // Update use case interest with Opportunity ID   
                    Id ownerId = [SELECT OwnerId FROM Use_Case_Interest__c WHERE Id = :usecase.Id].OwnerId;
                    usecase.OwnerId = ownerid;
                    update usecase;
                    System.debug('UseCaseController.convert(LEAD): Upsert UseCaseInterest - ' + usecase);
                }
                catch(exception ex)
                {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,ex.getMessage()+ex.getStackTraceString())); 
                    System.debug('UseCaseController.convert(LEAD): Exception Thrown - ' + ex.getMessage());
                    errorMsg = ex.getMessage();
                    oppPage = null;
                    
                }
             } 
             
             /*/
             * If use case has realated Contact only.
             * Creating Opportunity and link it to Use case record.
            /*/
             else if(usecase.Contact__c != null)
             {
                mapFields(convertedOpp, usecase);
				System.debug('UseCaseController.convert(CONTACT): Mapped fields from UseCaseInterest to Opportunity');
                convertedOpp.accountid = usecase.contact__r.accountid;
                convertedOpp.StageName = 'Incubate';
                convertedOpp.Use_Case_Interest__c = usecase.id;
                
                // Get the Contact's related Short_Code__c and relate the Opportunity to the Short_Code__c
                System.debug('UseCaseController.convert(CONTACT): useCase = ' + useCase);
                List<Short_Code__c> shortCodes = [ SELECT Id, Name FROM Short_Code__c WHERE Contact__c = :useCase.Contact__c LIMIT 1 ];
                System.debug('UseCaseController.convert(CONTACT): Related Short_Code__c = ' + shortCodes);
                if (shortCodes.size() > 0) {
	                System.debug('UseCaseController.convert(CONTACT): Set Opportunity Short_Code__c = ' + shortCodes[0].Id);
                	convertedOpp.Short_Code__c = shortCodes[0].Id;
                }
	
                try
                {
                    convertedOpp.ownerid = usecase.ownerid;
                    convertedOpp.Solution_Sales_Specialist__c = usecase.Solution_Sales_Specialist__c;
                    convertedOpp.SendGrid_Specialist__c = usecase.SendGrid_Specialist__c;
                    insert convertedOpp;
					System.debug('UseCaseController.convert(CONTACT): Inserted Opportunity' + convertedOpp);
					convertedOppId = convertedOpp.Id;
					
					usecase.opportunity__c = convertedOpp.id;
                    usecase.status__c = 'Converted';
                    usecase.RecordTypeId = contactRtId;
                    oppPage = new ApexPages.StandardController(convertedOpp).view();
                    
                    Id ownerId = [SELECT OwnerId FROM Use_Case_Interest__c WHERE Id = :usecase.Id].OwnerId;
                    usecase.OwnerId = ownerid;
                    update usecase;  
					System.debug('UseCaseController.convert(CONTACT): Upserted UseCaseInterest - ' + usecase);

                    OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=convertedOpp.Id, ContactId=usecase.Contact__c);
                    ocr.IsPrimary = true;
                    insert ocr;
					System.debug('UseCaseController.convert(CONTACT): Inserted OpportunitContactRole - ' + ocr);

                    if(usecase.lead__c != null){
						System.debug('UseCaseController.convert(CONTACT): Sync UCI contacts on Lead (' + usecase.lead__c + ') with Contact(' + usecase.Contact__c + ')');
                        syncAllUciContacts(usecase.lead__c, usecase.Contact__c);    
                    }
                    
	                // Relate the Contact's Short_Code__c to the Opportunity
	                if (shortCodes.size() > 0) {
	                	shortCodes[0].Opportunity__c = convertedOpp.Id;
		                System.debug('UseCaseController.convert(CONTACT): Set Short Code Opportunity__c = ' + shortCodes[0].Opportunity__c);

						Opportunity o = [ SELECT Id, OwnerId, Account.OwnerId FROM Opportunity WHERE Id = :convertedOpp.Id LIMIT 1];
	                	shortCodes[0].OwnerId = o.OwnerId;
		                System.debug('UseCaseController.convert(CONTACT): Set Short Code owner as Opportunity Account Owner = '+ shortCodes[0].OwnerId);
		                update shortCodes[0];
		                
		                sendEmailNotification(shortCodes[0]);
	                }
	                
                 }
                catch(exception ex)
                {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,ex.getMessage()));
                    System.debug('UseCaseController.convert(CONTACT): Exception Thrown - ' + ex.getMessage());
                    errorMsg = ex.getMessage();
                    oppPage = null;
                }          
             }
             System.debug('UseCaseController.convert(' + (oppPage == null ? 'FAILED' : 'SUCCESS') + '): ' + convertedOpp);
             return oppPage;
        //}
    }

    public String getUseCaseFieldString(){
        String fieldString = '';
        Map<String, Use_Case_Interest_Settings__c> settings = Use_Case_Interest_Settings__c.getAll();
    
        // changed mapping to usecase field from name field in CS
        // Make sure no field entered two times.
        Set<String> uniqueFields = new Set<String>();
        for(String key : settings.keySet()){
            uniqueFields.add(settings.get(key).Use_Case_Interest_Field__c);
        }
        
        for(String key : uniqueFields){
            fieldString += ' ' + key + ',';
        }

        fieldString = fieldString.left(fieldString.length() - 1);
        
        return fieldString;
    }

    public void mapFields(Opportunity oppty, Use_Case_Interest__c useCaseInterest){
        Map<String, Use_Case_Interest_Settings__c> settings = Use_Case_Interest_Settings__c.getAll();
        for(String key : settings.keySet())
        {
            // changed mapping to usecase field from name field in CS
            String fieldName = settings.get(key).Use_Case_Interest_Field__c;
            String opportunityFieldName = settings.get(key).Opportunity_Field__c;
            oppty.put(opportunityFieldName, useCaseInterest.get(fieldName));
        }
    }
    
    public void syncAllUciContacts(Id leadId, Id contactId)
    {
        List<Use_Case_Interest__c> ucis = [SELECT Id FROM Use_Case_Interest__c WHERE Lead__c = :leadId AND Contact__c = null];
        for(Use_Case_Interest__c uci : ucis)
        {
            uci.Contact__c = contactId;
            System.debug(uci);
        }
        update ucis;
    }

    public PageReference cancel()
    {
       return msc.cancel();    
    } 
    
    public void sendEmailNotification(Short_Code__c shortCode) {
		// Configurable variables
        String emailSubject            = 'Email Notification';
        String emailMessage            = 'Short Code has been assigned to you:  ' + shortCode.Name + ' (' + shortCode.Id + ')';
        String emailFromDisplayName    = 'Opportunity Conversion Process';

        // Determine if this is running in a sandbox and setting variables accordingly
        Organization org = [ SELECT Id, IsSandbox FROM Organization LIMIT 1];
        String orgURL     = org.IsSandbox ? 'https://test.salesforce.com' : 'https://login.salesforce.com';
        String emailFrom  = org.IsSandbox ? 'jonathan.f.griggs@gmail.com' : '`s@twilio.com';

    	// Setup a email message list for email notifications
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
    	
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(shortCode.OwnerId);
        email.setReplyTo(emailFrom);
        email.setSenderDisplayName(emailFromDisplayName);
        email.saveAsActivity = false;
        email.setSubject(emailSubject);
        email.setPlainTextBody(emailMessage);
        mailList.add(email);

        // Send out the email notifications in the mail list
        System.debug('Sending email notifications');
        if (!mailList.isEmpty() || Test.isRunningTest()) {
            System.debug('SENDING EMAIL');
            //Messaging.sendEmail(mailList);
        }

    }
}