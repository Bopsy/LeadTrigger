@isTest
public class UseCaseConvertControllerTest {

	static Profile p;
	static User u;
	
	static Account acc;
	static Contact con;

	static Short_Code__c shortCodeLinkedToContact;

	public static void testSetup() {
	
		p = [Select Id from Profile where name = 'Standard User'];

		// Test Standard User
		u = [SELECT Id FROM USER WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		
		//runAs
		//insert u;
		System.debug('Created test user: ' + u.Id);

		// Custom Settings config for Use Case Interest
		Use_Case_Interest_Settings__c setting = new Use_Case_Interest_Settings__c();
		setting.Name = 'FY_16_Primary_Product__c';
		setting.Opportunity_Field__c = 'FY_16_Primary_Product__c';
		setting.Use_Case_Interest_Field__c = 'FY_16_Primary_Product__c';
		
		Use_Case_Interest_Settings__c setting2 = new Use_Case_Interest_Settings__c();
		setting2.Name = 'Amount';
		setting2.Opportunity_Field__c = 'Amount';
		setting2.Use_Case_Interest_Field__c = 'Volume__c';
        
        Use_Case_Interest_Settings__c setting3 = new Use_Case_Interest_Settings__c();
		setting3.Name = 'Solution Category';
		setting3.Opportunity_Field__c = 'Solution_Category__c';
		setting3.Use_Case_Interest_Field__c = 'Solution_Category__c';
		
        Use_Case_Interest_Settings__c setting4 = new Use_Case_Interest_Settings__c();
		setting4.Name = 'Project Timeframe';
		setting4.Opportunity_Field__c = 'Project_Timeframe__c';
		setting4.Use_Case_Interest_Field__c = 'Project_Timeframe__c';
		
        Use_Case_Interest_Settings__c setting5 = new Use_Case_Interest_Settings__c();
		setting5.Name = 'Launch Date';
		setting5.Opportunity_Field__c = 'Launch_Date__c';
		setting5.Use_Case_Interest_Field__c = 'Project_Timeframe__c';

		insert new List<Use_Case_Interest_Settings__c>{ setting, setting2, setting3, setting4, setting5 };		
		
        Use_Case_Interest_Settings__c setting6 = new Use_Case_Interest_Settings__c();
		setting6.Name = 'CloseDate';
		setting6.Opportunity_Field__c = 'CloseDate';
		setting6.Use_Case_Interest_Field__c = 'Project_Timeframe__c';
		insert setting6;		
		
		acc = new Account(
			Name='ABCDEFG Infotech',
			BillingCity='Fremont',
			BillingPostalCode = '94538',
			BillingState = 'California',
			BillingCountry = 'United States',
			Employee_Size__c = '0-50'
		);
		insert acc;	    
		System.debug('Created test account: ' + acc.Id + ' / ' + acc.Name);
		
		con = new Contact(
			FirstName='Dummy1231',
			LastName='Contact5432',
			AccountId = acc.id,
			Email = 'contact@email12344123.com',
			Title = 'Contact Title',
			Phone = '5123-555-1212'
		);
		insert con;		
		System.debug('Created test contact: ' + con.Id + ' / ' + con.LastName);
		
        shortCodeLinkedToContact = new Short_Code__c(
            Short_Code_App_Sid__c = 'ShortCodeTestContact',
            OwnerUser_Email_Address__c = 'TestCustomer@ShortCodeLinkTestContact.com',
            Application_Status__c = 'Pending Twilio',
            Contact__c = con.Id
        );
        insert shortCodeLinkedToContact;
		
		Opportunity_Routing_Rules__c rule = new Opportunity_Routing_Rules__c(Country__c = 'United States', State__c = 'California', Zip_Code__c = null, Employee_Size__c = '2,501+', Zip_Code_Ceiling__c = '94999', Zip_Code_Floor__c = '94000', Opportunity_Owner__c = u.Id);
		insert rule;
		
		Account_Quarterback_Routing__c rules = new Account_Quarterback_Routing__c(Country__c = 'United States', State__c = 'California', Zip_Code__c = '.*', Employee_Size__c = '2,501+');
		insert rules;
	}

	public static testMethod void convertContactToOpptyFailure() {

		testSetup();
		
		Use_Case_Interest__c usecase1 = new Use_Case_Interest__c();
		usecase1.Contact__c = con.Id;   
		usecase1.Account_Owner__c = u.Id;	
        insert usecase1;
		System.debug('Created test uci: ' + usecase1.Id + ' / Contact = ' + usecase1.Contact__c + ' / Account Owner = ' + usecase1.Account_Owner__c);
		
		apexpages.currentpage().getparameters().put('id',usecase1.id);
		ApexPages.StandardController control1 = new ApexPages.StandardController(usecase1);
		UseCaseConvertController obj1 = new UseCaseConvertController(control1); 
		
		Test.startTest();
		
			PageReference oppPage = obj1.convert();
			System.debug('After Convert uci');
			System.assertEquals(null, oppPage, 'Conversion exception thrown');
			
		Test.stopTest();
		
	}

	public static testMethod void convertLeadToOpptyFailure() {
		
		testSetup();
		
		Lead ld1 = new Lead(
			FirstName='Dummy1',
			LastName='Lead1',
			Company='ABC Infotech',
			Status='Open'
		);
		insert ld1;

        // Should Link to Lead
        Short_Code__c shortCodeLinkedToLead = new Short_Code__c(
            Short_Code_App_Sid__c = 'ShortCodeTestLead',
            OwnerUser_Email_Address__c = 'TestCustomer@ShortCodeLinkTestLead.com',
            Application_Status__c = 'Pending Twilio',
            Lead__c = ld1.Id
        );
        insert shortCodeLinkedToLead;

		Opportunity_Routing_Rules__c rule = new Opportunity_Routing_Rules__c(Amount_Floor__c = 0, Opportunity_Owner__c = u.Id, Solution_Specialist__c = u.Id, Country__c = 'United States', State__c = 'California', Zip_Code__c = '.*', Employee_Size__c = 'Under 1,000', Solution_Category__c = 'Account Security', Product__c = '.*');
		insert rule;
		
		Use_Case_Interest__c usecase2 = new Use_Case_Interest__c();
		usecase2.Lead__c = ld1.Id;	     
		usecase2.Account_Owner__c = u.Id;
		usecase2.FY_16_Primary_Product__c = 'Flex';
		//usecase2.Solution__c = 'Phone Verification';
		//usecase2.Solution_Category__c = 'Account Security';
		insert usecase2;
		
		apexpages.currentpage().getparameters().put('id',usecase2.id);
		ApexPages.StandardController control2 = new ApexPages.StandardController(usecase2);
		UseCaseConvertController obj2 = new UseCaseConvertController(control2);
		
		Test.startTest();
		
			PageReference oppPage = obj2.convert();
			System.debug('After Convert uci');
			System.assertEquals(null, oppPage, 'Conversion exception thrown');

	    Test.stopTest();
	}

	public static testMethod void convertLeadToOpptyNoAccountFailure() {
		
		testSetup();
		
		Lead ld1 = new Lead(
			FirstName='Dummy1',
			LastName='Lead1',
			Company='ABC Infotech',
			Status='Open'
		);
		insert ld1;

        // Should Link to Lead
        Short_Code__c shortCodeLinkedToLead = new Short_Code__c(
            Short_Code_App_Sid__c = 'ShortCodeTestLead',
            OwnerUser_Email_Address__c = 'TestCustomer@ShortCodeLinkTestLead.com',
            Application_Status__c = 'Pending Twilio',
            Lead__c = ld1.Id
        );
        insert shortCodeLinkedToLead;

		Opportunity_Routing_Rules__c rule = new Opportunity_Routing_Rules__c(Amount_Floor__c = 0, Opportunity_Owner__c = u.Id, Solution_Specialist__c = u.Id, Country__c = 'United States', State__c = 'California', Zip_Code__c = '.*', Employee_Size__c = 'Under 1,000', Solution_Category__c = 'Account Security', Product__c = '.*');
		insert rule;
		
		Use_Case_Interest__c usecase2 = new Use_Case_Interest__c();
		usecase2.Lead__c = ld1.Id;	     
		usecase2.Account_Owner__c = u.Id;
		usecase2.FY_16_Primary_Product__c = 'Flex';
		//usecase2.Solution__c = 'Phone Verification';
		//usecase2.Solution_Category__c = 'Account Security';
		insert usecase2;
		
		apexpages.currentpage().getparameters().put('id',usecase2.id);
		ApexPages.StandardController control2 = new ApexPages.StandardController(usecase2);
		UseCaseConvertController obj2 = new UseCaseConvertController(control2);
		
		Test.startTest();
		
			obj2.createAcc = false;
			PageReference oppPage = obj2.convert();
			System.debug('After Convert uci');
			System.assertEquals(null, oppPage, 'Conversion exception thrown');

	    Test.stopTest();
	}

	public static testMethod void convertContactToOpptyWithShortCode() {

		testSetup();
		
		Use_Case_Interest__c usecase1 = new Use_Case_Interest__c();
		usecase1.Contact__c = con.Id;   
		usecase1.Account_Owner__c = u.Id;	
        usecase1.Company_Description__c = 'Company Description';
		usecase1.Project_Timeframe__c = Date.today().addMonths(1);  
		usecase1.Decision_Maker__c = 'Decision Maker';
		usecase1.Inquiry_Type__c = Use_Case_Interest__c.Inquiry_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase1.Qualified_Source__c = Use_Case_Interest__c.Qualified_Source__c.getDescribe().getPicklistValues()[0].getValue();
		usecase1.Traffic_Type__c = Use_Case_Interest__c.Traffic_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase1.Build_or_Buy__c = Use_Case_Interest__c.Build_or_Buy__c.getDescribe().getPicklistValues()[0].getValue();
		usecase1.Volume__c = 1;
		usecase1.Next_Followup_Date__c = Date.today().addMonths(2);
        usecase1.Description_of_Volume_Estimate__c = 'Volumne Estimate';
        usecase1.AVID_Not_Found__c = true;
		insert usecase1;
		System.debug('Created test uci: ' + usecase1.Id + ' / Contact = ' + usecase1.Contact__c + ' / Account Owner = ' + usecase1.Account_Owner__c);
		
		apexpages.currentpage().getparameters().put('id',usecase1.id);
		ApexPages.StandardController control1 = new ApexPages.StandardController(usecase1);
		UseCaseConvertController obj1 = new UseCaseConvertController(control1); 
		
		Test.startTest();
		
			PageReference oppPage = obj1.convert();
			System.debug('After Convert uci');
			System.assertNotEquals(null, oppPage, obj1.errorMsg == null ? 'Unknown error' : obj1.errorMsg);

			PageReference cancelPage = obj1.cancel();
			System.debug('After Cancel uci');
			System.assertNotEquals(null, cancelPage, obj1.errorMsg == null ? 'Unknown error' : obj1.errorMsg);

			System.assertNotEquals(null, obj1.convertedOppId, 'Converted Opportunity is null');

			Opportunity o = [ SELECT Id, Short_Code__c, Account.OwnerId FROM Opportunity WHERE Id = :obj1.convertedOppId LIMIT 1 ];
			Use_Case_Interest__c uc = [ SELECT Id, Opportunity__c, Opportunity__r.Short_Code__c FROM Use_Case_Interest__c WHERE Id = :usecase1.Id LIMIT 1 ];
			Short_Code__c s = [ SELECT Id, Opportunity__c, OwnerId FROM Short_Code__c WHERE Id = :shortCodeLinkedToContact.Id LIMIT 1 ];

			System.assertNotEquals(null, o.Id, 'Converted Opportunity record found');
			System.assertEquals(o.Id, uc.Opportunity__c, 'Use Case Interest related to converted Opportunity');
			System.assertEquals(o.Id, s.Opportunity__c, 'Short Code related to converted Opportunity');
			System.assertEquals(shortCodeLinkedToContact.Id, o.Short_Code__c, 'Converted Opportunity related to Short Code');
			//System.assertEquals(o.Account.OwnerId, s.OwnerId, 'Converted Opportunity Account Owner is same as Short Code Owner');
			
		Test.stopTest();
		
	}
	
	public static testMethod void convertLeadToOpptyWithShortCode() {
		
		testSetup();
		
		Lead ld1 = new Lead(
			FirstName='Dummy1',
			LastName='Lead1',
			Company='ABC Infotech',
			Status='Open',
			Salutation='Mr.',
			Product__c='Authy',
			Title = 'Lead Title',
			Email = 'lead@email.com',
			Phone = '555-555-1212',
			Street = '123 Main St.',
			City = 'San Mateo',
			PostalCode = '94403',
			State = 'California',
			Country = 'United States',
			Employee_Size__c = '0-50'
		);
		insert ld1;

        // Should Link to Lead
        Short_Code__c shortCodeLinkedToLead = new Short_Code__c(
            Short_Code_App_Sid__c = 'ShortCodeTestLead',
            OwnerUser_Email_Address__c = 'TestCustomer@ShortCodeLinkTestLead.com',
            Application_Status__c = 'Pending Twilio',
            Lead__c = ld1.Id
        );
        insert shortCodeLinkedToLead;

		Opportunity_Routing_Rules__c rule = new Opportunity_Routing_Rules__c(Amount_Floor__c = 0, Opportunity_Owner__c = u.Id, Solution_Specialist__c = u.Id, Country__c = 'United States', State__c = 'California', Zip_Code__c = '.*', Employee_Size__c = 'Under 1,000', Solution_Category__c = 'Account Security', Product__c = '.*');
		insert rule;
		
		Use_Case_Interest__c usecase2 = new Use_Case_Interest__c();
		usecase2.Lead__c = ld1.Id;	     
		usecase2.Account_Owner__c = u.Id;
		usecase2.FY_16_Primary_Product__c = 'Flex';
		//usecase2.Solution__c = 'Phone Verification';
		//usecase2.Solution_Category__c = 'Account Security';
        usecase2.Company_Description__c = 'Company Description';
		usecase2.Project_Timeframe__c = Date.today().addMonths(1);  
		usecase2.Decision_Maker__c = 'Decision Maker';
		usecase2.Inquiry_Type__c = Use_Case_Interest__c.Inquiry_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase2.Qualified_Source__c = Use_Case_Interest__c.Qualified_Source__c.getDescribe().getPicklistValues()[0].getValue();
		usecase2.Traffic_Type__c = Use_Case_Interest__c.Traffic_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase2.Build_or_Buy__c = Use_Case_Interest__c.Build_or_Buy__c.getDescribe().getPicklistValues()[0].getValue();
		usecase2.Volume__c = 100;
		usecase2.Next_Followup_Date__c = Date.today().addMonths(2);
        usecase2.Description_of_Volume_Estimate__c = 'Volumne Estimate';
		usecase2.AVID_Not_Found__c = true;
		insert usecase2;
		
		apexpages.currentpage().getparameters().put('id',usecase2.id);
		ApexPages.StandardController control2 = new ApexPages.StandardController(usecase2);
		UseCaseConvertController obj2 = new UseCaseConvertController(control2);
		
		Test.startTest();
		
			PageReference oppPage = obj2.convert();
			System.debug('After Convert uci');
			//System.assertNotEquals(null, oppPage, obj2.errorMsg == null ? 'Unknown error' : obj2.errorMsg);

			PageReference cancelPage = obj2.cancel();
			System.debug('After Cancel uci');
			//System.assertNotEquals(null, cancelPage, obj2.errorMsg == null ? 'Unknown error' : obj2.errorMsg);

			System.assertNotEquals(null, obj2.convertedOppId, 'Converted Opportunity is null');

			Opportunity o = [ SELECT Id, Short_Code__c, Account.OwnerId FROM Opportunity WHERE Id = :obj2.convertedOppId LIMIT 1 ];
			Lead l = [ SELECT Id, ConvertedOpportunityId, IsConverted FROM Lead WHERE Id = :ld1.Id LIMIT 1 ];
			Use_Case_Interest__c uc = [ SELECT Id, Opportunity__c, Opportunity__r.Short_Code__c FROM Use_Case_Interest__c WHERE Id = :usecase2.Id LIMIT 1 ];
			Short_Code__c s = [ SELECT Id, Opportunity__c, OwnerId FROM Short_Code__c WHERE Id = :shortCodeLinkedToLead.Id LIMIT 1 ];

			System.assertNotEquals(null, o.Id, 'Converted Opportunity record found');
			System.assertEquals(true, l.IsConverted, 'Lead marked as converted');
			System.assertEquals(o.Id, l.ConvertedOpportunityId, 'Lead related to converted Opportunity');
			System.assertEquals(o.Id, uc.Opportunity__c, 'Use Case Interest related to converted Opportunity');
			System.assertEquals(o.Id, s.Opportunity__c, 'Short Code related to converted Opportunity');
			System.assertEquals(shortCodeLinkedToLead.Id, o.Short_Code__c, 'Converted Opportunity related to Short Code');
			System.assertEquals(o.Account.OwnerId, s.OwnerId, 'Converted Opportunity Account Owner is same as Short Code Owner');
	    
	    Test.stopTest();
	}
	
	public static testMethod void convertLeadToOpptyBasic() {

		testSetup();

		Use_Case_Interest__c usecase3 = new Use_Case_Interest__c();			   
		usecase3.Account_Owner__c = u.Id;	  
		insert usecase3;
		
		apexpages.currentpage().getparameters().put('id',usecase3.id);
		ApexPages.StandardController control3 = new ApexPages.StandardController(usecase3);
		UseCaseConvertController obj3 = new UseCaseConvertController(control3);
		
		obj3.convert();
		obj3.cancel();			 
	    
		Lead ld2 = new Lead(
			FirstName='Dummy2',
			LastName='Lead2',
			Company='ABC Infotech',
			Title = 'Lead Title',
			Email = 'lead@email.com',
			Phone = '555-555-1212',
			Street = '123 Main St.',
			City = 'San Mateo',
			PostalCode = '94403',
			State = 'California',
			Country = 'United States',
			Employee_Size__c = '0-50'
		);
		insert ld2;
		
		Use_Case_Interest__c usecase4 = new Use_Case_Interest__c();
		usecase4.Lead__c = ld2.Id;	     
		usecase4.Account_Owner__c = u.Id;	  
		usecase4.Company_Description__c = 'Company Description';
		usecase4.Project_Timeframe__c = Date.today().addMonths(1);  
		usecase4.Decision_Maker__c = 'Decision Maker';
		usecase4.Inquiry_Type__c = Use_Case_Interest__c.Inquiry_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Qualified_Source__c = Use_Case_Interest__c.Qualified_Source__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Traffic_Type__c = Use_Case_Interest__c.Traffic_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Build_or_Buy__c = Use_Case_Interest__c.Build_or_Buy__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Volume__c = 100;
		usecase4.Next_Followup_Date__c = Date.today().addMonths(2);
        usecase4.Description_of_Volume_Estimate__c = 'Volumne Estimate';
		usecase4.AVID_Not_Found__c = true;
		insert usecase4;
				
		Database.LeadConvert lc = new database.LeadConvert();
		lc.setLeadId(ld2.id);	   
		LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
		lc.setConvertedStatus(convertStatus.MasterLabel); 
		
		Test.startTest();
			
			Database.LeadConvertResult lcr = Database.convertLead(lc);
		
		Test.stopTest();
		
		System.assert(lcr.isSuccess());	     

    }
    
    static Assignment_Groups__c buildActiveMember(DateTime assignmentTime, Decimal seconds, Id userId, Id groupId){
        return new Assignment_Groups__c(Last_Assignment__c = assignmentTime, Millisecond__c = seconds, User__c = userId, Active__c = 'true', Group_Name__c = groupId);
    }
    
	public static testMethod void convertLeadToOppty() {		 
	    List<User> users = [SELECT Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
	    
	    Assignment_Group_Name__c testGroup1 = new Assignment_Group_Name__c(Name = 'Test Group1');
	    insert testGroup1;
	    
	    Assignment_Groups__c testMember1 = buildActiveMember(Datetime.now(), 100, users[0].Id, testGroup1.Id);
	    insert testMember1;
	    testSetup();
	    
		Lead ld2 = new Lead(
			FirstName='Dummy2',
			LastName='Lead2',
			Company='ABC Infotech',
			Title = 'Lead Title',
			Email = 'lead@email.com',
			Phone = '555-555-1212',
			Street = '123 Main St.',
			City = 'San Mateo',
			PostalCode = '94403',
			State = 'California',
			Country = 'United States',
			Employee_Size__c = '0-50'
		);
		insert ld2;

		// No Short_Code__c record to test whether the converstion is tolerate
		
		Use_Case_Interest__c usecase4 = new Use_Case_Interest__c();
		usecase4.Lead__c = ld2.Id;	     
		usecase4.Account_Owner__c = u.Id;	  
        usecase4.Company_Description__c = 'Company Description';
		usecase4.Project_Timeframe__c = Date.today().addMonths(1);  
		usecase4.Decision_Maker__c = 'Decision Maker';
		usecase4.Inquiry_Type__c = Use_Case_Interest__c.Inquiry_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Qualified_Source__c = Use_Case_Interest__c.Qualified_Source__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Traffic_Type__c = Use_Case_Interest__c.Traffic_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Build_or_Buy__c = Use_Case_Interest__c.Build_or_Buy__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Volume__c = 100;
		usecase4.Next_Followup_Date__c = Date.today().addMonths(2);
        usecase4.Description_of_Volume_Estimate__c = 'Volumne Estimate';
		usecase4.AVID_Not_Found__c = true;
		insert usecase4;
     
		apexpages.currentpage().getparameters().put('id',usecase4.id);
		ApexPages.StandardController control4 = new ApexPages.StandardController(usecase4);
		UseCaseConvertController obj4 = new UseCaseConvertController(control4);
		OpportunityRoutingServices.OppSettingWrapper wrapper = new OpportunityRoutingServices.OppSettingWrapper();
		OpportunityRoutingServices.AccountQBWrapper acWrapper = new OpportunityRoutingServices.AccountQBWrapper();
		wrapper.groupId = testGroup1.id;
		acWrapper.groupId = testGroup1.id;

		Test.startTest();

			PageReference oppPage = obj4.convert();
			System.debug('After Convert uci');
			System.assertNotEquals(null, oppPage, obj4.errorMsg == null ? 'Unknown error' : obj4.errorMsg);

			PageReference cancelPage = obj4.cancel();
			System.debug('After Cancel uci');
			System.assertNotEquals(null, cancelPage, obj4.errorMsg == null ? 'Unknown error' : obj4.errorMsg);

			System.assertNotEquals(null, obj4.convertedOppId, 'Converted Opportunity is null');

			Opportunity o = [ SELECT Id, Short_Code__c FROM Opportunity WHERE Id = :obj4.convertedOppId LIMIT 1 ];
			Lead l = [ SELECT Id, ConvertedOpportunityId, IsConverted FROM Lead WHERE Id = :ld2.Id LIMIT 1 ];
			Use_Case_Interest__c uc = [ SELECT Id, Opportunity__c, Opportunity__r.Short_Code__c FROM Use_Case_Interest__c WHERE Id = :usecase4.Id LIMIT 1 ];

			System.assertNotEquals(null, o.Id, 'Converted Opportunity record found');
			System.assertEquals(true, l.IsConverted, 'Lead marked as converted');
			System.assertEquals(o.Id, l.ConvertedOpportunityId, 'Lead related to converted Opportunity');
			System.assertEquals(o.Id, uc.Opportunity__c, 'Use Case Interest related to converted Opportunity');
			System.assertEquals(null, o.Short_Code__c, 'Converted Opportunity not related to Short Code');

			List<OpportunityRoutingServices.AccountQBWrapper> testWrapper = OpportunityRoutingServices.accountSettings;
			OpportunityRoutingServices.getRoundRobinOwnerId(wrapper);
			OpportunityRoutingServices.getRoundRobinAEOwner(acWrapper);

		Test.stopTest();
    } 

	public static testMethod void convertLeadToOpptyWithExistingAccount() {		 
	    List<User> users = [SELECT Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
	    
	    Assignment_Group_Name__c testGroup1 = new Assignment_Group_Name__c(Name = 'Test Group1');
	    insert testGroup1;
	    
	    Assignment_Groups__c testMember1 = buildActiveMember(Datetime.now(), 100, users[0].Id, testGroup1.Id);
	    insert testMember1;
	    testSetup();
	    
		Lead ld2 = new Lead(
			FirstName='Dummy2',
			LastName='Lead2',
			Company='ABC Infotech',
			Title = 'Lead Title',
			Email = 'lead@email.com',
			Phone = '555-555-1212',
			Street = '123 Main St.',
			City = 'San Mateo',
			PostalCode = '94403',
			State = 'California',
			Country = 'United States',
			Employee_Size__c = '0-50'
		);
		insert ld2;

		// No Short_Code__c record to test whether the converstion is tolerate
		
		Use_Case_Interest__c usecase4 = new Use_Case_Interest__c();
		usecase4.Lead__c = ld2.Id;	     
		usecase4.Account_Owner__c = u.Id;	  
        usecase4.Company_Description__c = 'Company Description';
		usecase4.Project_Timeframe__c = Date.today().addMonths(1);  
		usecase4.Decision_Maker__c = 'Decision Maker';
		usecase4.Inquiry_Type__c = Use_Case_Interest__c.Inquiry_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Qualified_Source__c = Use_Case_Interest__c.Qualified_Source__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Traffic_Type__c = Use_Case_Interest__c.Traffic_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Build_or_Buy__c = Use_Case_Interest__c.Build_or_Buy__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Volume__c = 100;
		usecase4.Next_Followup_Date__c = Date.today().addMonths(2);
        usecase4.Description_of_Volume_Estimate__c = 'Volumne Estimate';
		usecase4.AVID_Not_Found__c = true;
		insert usecase4;
     
		apexpages.currentpage().getparameters().put('id',usecase4.id);
		ApexPages.StandardController control4 = new ApexPages.StandardController(usecase4);
		UseCaseConvertController obj4 = new UseCaseConvertController(control4);
		OpportunityRoutingServices.OppSettingWrapper wrapper = new OpportunityRoutingServices.OppSettingWrapper();
		OpportunityRoutingServices.AccountQBWrapper acWrapper = new OpportunityRoutingServices.AccountQBWrapper();
		wrapper.groupId = testGroup1.id;
		acWrapper.groupId = testGroup1.id;

		Test.startTest();

			obj4.createAcc = true;
			
			PageReference oppPage = obj4.convert();
			System.debug('After Convert uci');
			System.assertNotEquals(null, oppPage, obj4.errorMsg == null ? 'Unknown error' : obj4.errorMsg);

			PageReference cancelPage = obj4.cancel();
			System.debug('After Cancel uci');
			System.assertNotEquals(null, cancelPage, obj4.errorMsg == null ? 'Unknown error' : obj4.errorMsg);

			System.assertNotEquals(null, obj4.convertedOppId, 'Converted Opportunity is null');

			Opportunity o = [ SELECT Id, Short_Code__c FROM Opportunity WHERE Id = :obj4.convertedOppId LIMIT 1 ];
			Lead l = [ SELECT Id, ConvertedOpportunityId, IsConverted FROM Lead WHERE Id = :ld2.Id LIMIT 1 ];
			Use_Case_Interest__c uc = [ SELECT Id, Opportunity__c, Opportunity__r.Short_Code__c FROM Use_Case_Interest__c WHERE Id = :usecase4.Id LIMIT 1 ];

			System.assertNotEquals(null, o.Id, 'Converted Opportunity record found');
			System.assertEquals(true, l.IsConverted, 'Lead marked as converted');
			System.assertEquals(o.Id, l.ConvertedOpportunityId, 'Lead related to converted Opportunity');
			System.assertEquals(o.Id, uc.Opportunity__c, 'Use Case Interest related to converted Opportunity');
			System.assertEquals(null, o.Short_Code__c, 'Converted Opportunity not related to Short Code');

			List<OpportunityRoutingServices.AccountQBWrapper> testWrapper = OpportunityRoutingServices.accountSettings;
			OpportunityRoutingServices.getRoundRobinOwnerId(wrapper);
			OpportunityRoutingServices.getRoundRobinAEOwner(acWrapper);

		Test.stopTest();
    } 

	public static testMethod void propertiesCheck() {		 
	    List<User> users = [SELECT Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
	    
	    Assignment_Group_Name__c testGroup1 = new Assignment_Group_Name__c(Name = 'Test Group1');
	    insert testGroup1;
	    
	    Assignment_Groups__c testMember1 = buildActiveMember(Datetime.now(), 100, users[0].Id, testGroup1.Id);
	    insert testMember1;
	    testSetup();
	    
		Lead ld2 = new Lead(
			FirstName='Dummy2',
			LastName='Lead2',
			Company='ABC Infotech',
			Title = 'Lead Title',
			Email = 'lead@email.com',
			Phone = '555-555-1212',
			Street = '123 Main St.',
			City = 'San Mateo',
			PostalCode = '94403',
			State = 'California',
			Country = 'United States',
			Employee_Size__c = '0-50'
		);
		insert ld2;

		// No Short_Code__c record to test whether the converstion is tolerate
		
		Use_Case_Interest__c usecase4 = new Use_Case_Interest__c();
		usecase4.Lead__c = ld2.Id;	     
		usecase4.Account_Owner__c = u.Id;	  
        usecase4.Company_Description__c = 'Company Description';
		usecase4.Project_Timeframe__c = Date.today().addMonths(1);  
		usecase4.Decision_Maker__c = 'Decision Maker';
		usecase4.Inquiry_Type__c = Use_Case_Interest__c.Inquiry_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Qualified_Source__c = Use_Case_Interest__c.Qualified_Source__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Traffic_Type__c = Use_Case_Interest__c.Traffic_Type__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Build_or_Buy__c = Use_Case_Interest__c.Build_or_Buy__c.getDescribe().getPicklistValues()[0].getValue();
		usecase4.Volume__c = 100;
		usecase4.Next_Followup_Date__c = Date.today().addMonths(2);
        usecase4.Description_of_Volume_Estimate__c = 'Volumne Estimate';
		usecase4.AVID_Not_Found__c = true;
		insert usecase4;
     
		apexpages.currentpage().getparameters().put('id',usecase4.id);
		ApexPages.StandardController control4 = new ApexPages.StandardController(usecase4);
		UseCaseConvertController obj4 = new UseCaseConvertController(control4);
		OpportunityRoutingServices.OppSettingWrapper wrapper = new OpportunityRoutingServices.OppSettingWrapper();
		OpportunityRoutingServices.AccountQBWrapper acWrapper = new OpportunityRoutingServices.AccountQBWrapper();
		wrapper.groupId = testGroup1.id;
		acWrapper.groupId = testGroup1.id;

		Test.startTest();

		obj4.oppSpecialistName = 'SpecialistName';
		obj4.accountOwner = users[0];
		obj4.accountQBName = 'QBName';
		obj4.accountQBsize = '1';
		obj4.accountQBState = 'California';
		obj4.accountQBZipCode = '94403';
		obj4.accountQBCountry = 'United States';

		Test.stopTest();
    } 

}