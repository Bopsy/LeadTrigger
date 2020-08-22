@isTest

private class CampaignMemberAutoConvertTest {

    static testmethod void CampaignMemberInsertSuccess() {
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
/*
        User au = new User();
        au.ProfileId = ap.Id;
        au.Username = System.now().getTime() + 'eloqua@test.com';
        au.Alias = 'eloqua';
        au.Email='eloqua@test-12345.com';
        au.EmailEncodingKey='UTF-8';
        au.Firstname='Eloqua';
        au.Lastname='Marketing';
        au.LanguageLocaleKey='en_US';
        au.LocaleSidKey='en_US';
        au.TimeZoneSidKey='America/Chicago';
        insert au;
*/

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
	
	        Campaign c = new Campaign(name='testcampaign');
	        insert c;
	        
	        List<CampaignMember> m = new List<CampaignMember>();
			Integer counter = -10;
			for (Lead x : l) {
				m.add(new CampaignMember(
					CampaignId = c.id,
					LeadId = x.id,
					Status = 'Registered',
					Eloqua_Campaign_Association_Done__c = true,
					Campaign_Member_Updated_Date__c = DateTime.now().addMinutes(counter)
				));
				counter++;
			}
	
	        CampaignMember_to_FSR_Mapping__c cmfsr = new CampaignMember_to_FSR_Mapping__c(
	        	Name = 'Campaign Member Updated Date',
	        	FSR_Field__c = 'Date_Submitted__c',
	        	CampaignMember_Field__c = 'Campaign_Member_Updated_Date__c'
	        );
	        insert cmfsr;
        
            insert m;
        }
        
        Test.startTest();
        Database.executeBatch(new CampaignMemberAutoConvert(), 50);
        Test.stopTest();
    }
}