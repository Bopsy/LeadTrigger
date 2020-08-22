// Due to a possible bug in SFDC custom CampaignMemberStatus records
// are not accessible when "@isTest(seeAllData=false).  However, an
// attempt to create the custom records with the same label in the test
// methods will result in a DUPLICATE_VALUE exception.  Therefore, the
// "@isTest(seeAllData=true)" must be used.
@isTest(seeAllData=true) 

private class CampaignMemberTasksTest {

    static testmethod void CampaignMemberTaskInsertSuccess() {
        Profile p = [Select Id from Profile where name = 'Standard User'];
        Profile ap = [Select Id from Profile where name = 'System Administrator'];
        
        User u = new User();
        u.ProfileId = p.Id;
        u.Username = System.now().getTime() + 'test@test.com';
        u.Alias = 'testtest';
        u.Email='test@test-lead-autoconvert-12345.com';
        u.EmailEncodingKey='UTF-8';
        u.Firstname='Test';
        u.Lastname='Test';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.TimeZoneSidKey='America/Chicago';
        insert u;

//
// Changed run as user to be the existing "Sales Operations" user so it would be exempted
// from the following Lead validation rules:
//
//    Consolidated_Last_Lead_Source_Edit_Rules
//    Consolidation_of_LeadSource_Edit_Rules
//    Partner_Pass_No_SQL_required_fields
//
		User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

        System.RunAs(au) {
	        Account a = new Account(
	            Name = 'Test Account',
	            OwnerId = u.Id,
	            Employee_Size__c = '0 - 50',
	            Website = 'http://www.checkboxtest.com'
	        );
	        insert a;
	
	        List<Lead> l = new List<Lead>();
	        l.add(new Lead(
	            LastName = 'Test Lead',
	            Company = 'Test Company',
	            Email = 'test12345@checkboxtest.comm',
	            LeadSource = 'Full Service Request',
	            Status = 'Open',
	            OwnerId = u.Id
	        ));
	        l.add(new Lead(
	            LastName = 'Test Lead',
	            Company = 'Test Company',
	            Email = 'test12345@checkboxtest.com',
	            LeadSource = 'Not Full Service Request',
	            Status = 'Open',
	            OwnerId = u.Id
	        ));
	        
	        // No match 
	        l.add(new Lead(
	            LastName = 'Test Lead',
	            Company = 'Test Company',
	            Email = 'test12345@test-lead-autoconvert-67890.com',
	            LeadSource = 'Not Full Service Request',
	            Status = 'Open',
	            OwnerId = u.Id
	        ));
	        insert l;
	
	        Campaign c = new Campaign(
	        	Name = 'testcampaign',
				Create_Task_for_Opened_Email__c = true,
				Create_Task_for_Clicked_Email__c = true,
				Task_Subject_Line__c = 'Test Subject Line',
				Task_Call_Script__c = 'Test Task Call Script'
			);
	        insert c;
	        
	//        List<CampaignMemberStatus> cms = new List<CampaignMemberStatus>();
	//        cms.add(new CampaignMemberStatus(CampaignId=c.Id, HasResponded=true, Label='Opened Email', SortOrder=2));
	//		cms.add(new CampaignMemberStatus(CampaignId=c.Id, HasResponded=true, Label='Clicked Email', SortOrder=3));
	//		insert cms;
	        
	        List<CampaignMember> m = new List<CampaignMember>();
	        for (Lead x : l) {
	            m.add(new CampaignMember(
	                CampaignId = c.id,
	                LeadId = x.id,
	                Status = 'Clicked Email'
	            ));
	        }
	
	        Test.startTest();
	        insert m;
	        Test.stopTest();
        }
    }

    static testmethod void CampaignMemberTaskUpdateSuccess() {
        Profile p = [Select Id from Profile where name = 'Standard User'];
        Profile ap = [Select Id from Profile where name = 'System Administrator'];
        
        User u = new User();
        u.ProfileId = p.Id;
        u.Username = System.now().getTime() + 'test@test.com';
        u.Alias = 'testtest';
        u.Email='test@test-lead-autoconvert-12345.com';
        u.EmailEncodingKey='UTF-8';
        u.Firstname='Test';
        u.Lastname='Test';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.TimeZoneSidKey='America/Chicago';
        insert u;

//
// Changed run as user to be the existing "Sales Operations" user so it would be exempted
// from the following Lead validation rules:
//
//    Consolidated_Last_Lead_Source_Edit_Rules
//    Consolidation_of_LeadSource_Edit_Rules
//    Partner_Pass_No_SQL_required_fields
//
		User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

        System.RunAs(au) {
	        Account a = new Account(
	            Name = 'Test Account',
	            OwnerId = u.Id,
	            Employee_Size__c = '0 - 50',
	            Website = 'http://www.checkboxtest.com'
	        );
	        insert a;
	
	        List<Lead> l = new List<Lead>();
	        l.add(new Lead(
	            LastName = 'Test Lead',
	            Company = 'Test Company',
	            Email = 'test12345@checkboxtest.comm',
	            LeadSource = 'Full Service Request',
	            Status = 'Open',
	            OwnerId = u.Id
	        ));
	        l.add(new Lead(
	            LastName = 'Test Lead',
	            Company = 'Test Company',
	            Email = 'test12345@checkboxtest.com',
	            LeadSource = 'Not Full Service Request',
	            Status = 'Open',
	            OwnerId = u.Id
	        ));
	        
	        // No match 
	        l.add(new Lead(
	            LastName = 'Test Lead',
	            Company = 'Test Company',
	            Email = 'test12345@test-lead-autoconvert-67890.com',
	            LeadSource = 'Not Full Service Request',
	            Status = 'Open',
	            OwnerId = u.Id
	        ));
	        insert l;
	
	        Campaign c = new Campaign(
	        	Name = 'testcampaign',
				Create_Task_for_Opened_Email__c = true,
				Create_Task_for_Clicked_Email__c = true,
				Task_Subject_Line__c = 'Test Subject Line',
				Task_Call_Script__c = 'Test Task Call Script'
			);
	        insert c;
	        
	//        List<CampaignMemberStatus> cms = new List<CampaignMemberStatus>();
	//        cms.add(new CampaignMemberStatus(CampaignId=c.Id, HasResponded=true, Label='Opened Email', SortOrder=2));
	//		cms.add(new CampaignMemberStatus(CampaignId=c.Id, HasResponded=true, Label='Clicked Email', SortOrder=3));
	//		insert cms;
	        
	        List<CampaignMember> m = new List<CampaignMember>();
	        for (Lead x : l) {
	            m.add(new CampaignMember(
	                CampaignId = c.id,
	                LeadId = x.id,
	                Status = 'Registered'
	            ));
	        }
	
	        insert m;
	        
	        Test.startTest();
	        for (CampaignMember x : m) {
	            x.Status = 'Clicked Email';
	        }
	        update m;
	        Test.stopTest();
        }
    }
}