@isTest

private class LeadAutoConvertTest {
    static testmethod void NoMatchingAccounts() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;
		
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;
        
        Profile p = [Select Id from Profile where name = 'Standard User'];
        
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
            List<Lead> l = new List<Lead>();
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@test-lead-autoconvert-12345.com',
                LeadSource = 'Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@test-lead-autoconvert-12345.com',
                LeadSource = 'Not Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            
            Test.startTest();
            insert l;
            Test.stopTest();
        }
    }
    
    static testmethod void InsertSuccess() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;

        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;
        
        Profile p = [Select Id from Profile where name = 'Standard User'];
        
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
                Website = 'http://www.test-lead-autoconvert-12345.com'
            );
            insert a;
            
            Email_Domain__c e = new Email_Domain__c(
                Name = 'test-lead-autoconvert-12345.com',
                Account__c = a.Id,
                Approved__c = true
            );
            insert e;
    
            List<Lead> l = new List<Lead>();
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@test-lead-autoconvert-12345.com',
                LeadSource = 'Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@test-lead-autoconvert-12345.com',
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
    
            Test.startTest();
            insert l;
            Test.stopTest();
        }
    }

    static testmethod void UpdateSuccess() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;
        
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;

        Profile p = [Select Id from Profile where name = 'Standard User'];
        
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
                Website = 'http://www.test-lead-autoconvert-12345.com'
            );
            insert a;
    
            Email_Domain__c e = new Email_Domain__c(
                Name = 'test-lead-autoconvert-12345.com',
                Account__c = a.Id,
                Approved__c = true
            );
            insert e;
    
            List<Lead> l = new List<Lead>();
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                LeadSource = 'Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                LeadSource = 'Not Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            insert l;
    
            List<Twilio_Usage__c> tu = new List<Twilio_Usage__c>();
            tu.add(new Twilio_Usage__c(
                AccountSid__c='somesidstuff5weewfgwde5645egr',
                CounterKey__c='test1234567890',
                Year__c=2015, Month__c=12, Product__c='hello',
                Total__c=12.34, Volume__c=44, Currency__c='USD',
                Lead__c = l[0].Id
            ));
            insert tu;
            
            l[0].Email = 'test12345@test-lead-autoconvert-12345.com';
            l[1].Email = 'test12345@test-lead-autoconvert-12345.com';
                  
            Test.startTest();
            update l;
            Test.stopTest();
        }
    }
    
    /*
     * Added by Ashwani for LFF requirment
    */
    static testmethod void UpdateLFF() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;
        
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;

        Profile p = [Select Id from Profile where name = 'Standard User'];
        
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

		/*
		// Changed run as user to be the existing "Sales Operations" user so it would be exempted
		// from the following Lead validation rules:
		//
		//    Consolidated_Last_Lead_Source_Edit_Rules
		//    Consolidation_of_LeadSource_Edit_Rules
		//    Partner_Pass_No_SQL_required_fields
		*/
        User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

        System.RunAs(au) {
            Account a = new Account(
                Name = 'Test Account',
                OwnerId = u.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.test-lead-autoconvert-12345.com'
            );
            insert a;
    
            Email_Domain__c e = new Email_Domain__c(
                Name = 'test-lead-autoconvert-12345.com',
                Account__c = a.Id,
                Approved__c = true
            );
            insert e;
    
            List<Lead> l = new List<Lead>();
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                LeadSource = 'Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                LeadSource = 'Not Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            insert l;
    
            List<Use_Case_Interest__c> uCI = new List<Use_Case_Interest__c>();
            uCI.add(new Use_Case_Interest__c(
                Lead__c = l[0].Id,FY_16_Primary_Product__c = 'Programmable Authentication (Authy)',
                FY_16_Use_Case__c = 'Account Verification'
            ));
            insert uCI;
            
            FSR__c fSRRecord= new FSR__c ();
            fSRRecord.name = 'testFSR2ld@test.com'; 
            fSRRecord.FSR_Key__c = 'testFSR2ld@test.com'; 
            fSRRecord.Lead__c = l[0].Id;
            insert fSRRecord;

            
            Lifecycle_Field_Funnel__c newLFF = new Lifecycle_Field_Funnel__c ();
            newLFF.Lead__c = l[0].Id;
            newLFF.Use_Case_Interest__c = uCI[0].id; 
            insert newLFF;  
            
            Lifecycle_Field_Funnel__c newLFF2 = new Lifecycle_Field_Funnel__c ();
            newLFF2.Lead__c = l[0].Id;
            newLFF2.Use_Case_Interest__c = uCI[0].id; 
            newLFF2.MQL__c = fSRRecord.id; 
            insert newLFF2; 

            
            l[0].Email = 'test12345@test-lead-autoconvert-12345.com';
            l[1].Email = 'test12345@test-lead-autoconvert-12345.com';
                  
            Test.startTest();
            update l;
            Test.stopTest();
        }
    }
    
    /*
     * Added by Ashwani for MULTI USER requirment TASK #4
    */
    static testmethod void UpdateAccountSidonLeadConverison() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;
        
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;

        Profile p = [Select Id from Profile where name = 'System Administrator'];
        
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

		/*
		// Changed run as user to be the existing "Sales Operations" user so it would be exempted
		// from the following Lead validation rules:
		//
		//    Consolidated_Last_Lead_Source_Edit_Rules
		//    Consolidation_of_LeadSource_Edit_Rules
		//    Partner_Pass_No_SQL_required_fields
		*/
        User au = [ SELECT Id FROM User WHERE id =:u.id LIMIT 1 ];

        System.RunAs(au) {
            Account a = new Account(
                Name = 'Test Account',
                OwnerId = u.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.test-lead-autoconvert-12345.com'
            );
            insert a;
    
            Email_Domain__c e = new Email_Domain__c(
                Name = 'test-lead-autoconvert-12345.com',
                Account__c = a.Id,
                Approved__c = true
            );
            insert e;
    
            List<Lead> l = new List<Lead>();
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                //LeadSource = 'Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            insert l;
            
            List<Account_SID__c> SIDlist = new list<Account_SID__c>();
	    	List<Twilio_Usage__c> twlist = new list<Twilio_Usage__c>();
    
            for(integer i=0; i<l.size(); i++)
		    {    
		        Account_SID__c aSID = new Account_SID__c();
		        aSID.name = 'SID'+i;
		        aSID.Lead__c = l[i].ID;
		        aSID.OwnerUser_SID__c = '1234567'+i;
		        aSID.Account_SID__c = '1234567SID'+i;
		        aSID.OwnerUser_Email_Address__c = 'cont'+i+'@xyz.com';
		        SIDlist.add(aSID);     
		    } 
		    insert SIDlist;
		    
		    System.debug(' ====> SID '+SIDlist);
		     
		    for(integer i=0; i<SIDlist.size(); i++)
		    {
		    	Twilio_Usage__c t = new Twilio_Usage__c(Related_Account_Sid__c=SIDlist[i].id,CounterKey__c='test'+i, Year__c=2014, Month__c=12, Product__c='hello'+i, AccountSid__c='1234567SID'+i, Total__c=12.34, Volume__c=44, Currency__c='USD');
				twlist.add(t);
		    }
		    // Insert usage
	       	insert twlist;

            
            l[0].Email = 'test12345@test-lead-autoconvert-12345.com';
                  
           Test.startTest();			
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(l[0].id);
			
			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);
			
			Database.LeadConvertResult lcr = Database.convertLead(lc);
			System.assert(lcr.isSuccess());
           Test.stopTest();
            
            for(Lead leadRec : [SELECT isConverted FROM Lead WHERE Id=: l[0].id])
            {
            	System.assertEquals(leadRec.isConverted,true);
            }
            
            for(Account_SID__c aSIDrec : [SELECT Account__c, Contact__c, Lead__c FROM Account_SID__c])
            {
            	//System.assertNotEquals(aSIDrec.Account__c,null);
            	System.assertNotEquals(aSIDrec.Contact__c,null);
            	System.assertEquals(aSIDrec.Lead__c,null);
            }
        }
    }

    static testmethod void CampaignMemberInsertSuccess() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;
        
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;

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
    
            Email_Domain__c e = new Email_Domain__c(
                Name = 'checkboxtest.com',
                Account__c = a.Id,
                Approved__c = true
            );
            insert e;
    
            List<Lead> l = new List<Lead>();
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@checkboxtest.com',
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
                name = 'testcampaign',
                Type = 'Full Service Request'
            );
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
            
            Test.startTest();
            insert m;
            Test.stopTest();
        }
    }

    static testmethod void CampaignMemberUpdateSuccess() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;
        
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;

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
    
            Email_Domain__c e = new Email_Domain__c(
                Name = 'checkboxtest.com',
                Account__c = a.Id,
                Approved__c = true
            );
            insert e;
            
            List<Lead> l = new List<Lead>();
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@checkboxtest.com',
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
                name = 'testcampaign',
                Type = 'Full Service Request'
            );
            insert c;
            
            List<CampaignMember> m = new List<CampaignMember>();
            Integer counter = -10;
            for (Lead x : l) {
                m.add(new CampaignMember(
                    CampaignId = c.id,
                    LeadId = x.id,
                    Status = 'Registered',
                    Eloqua_Campaign_Association_Done__c = false,
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
                    
            Test.startTest();
            insert m;
            for (CampaignMember x : m) {
                x.Eloqua_Campaign_Association_Done__c = true;
            }
            update m;
            Test.stopTest();
        }
    }
    
    static testmethod void LinkToContact() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;
        
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;

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
            List<Account> a = new List<Account>();
            a.add(new Account(
                Name = 'Test Account1',
                OwnerId = u.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.checkboxtest1.com'
            ));
            a.add(new Account(
                Name = 'Test Account2',
                OwnerId = u.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.checkboxtest2.com'
            ));
            insert a;
    
            Email_Domain__c e = new Email_Domain__c(
                Name = 'checkboxtest.com',
                Account__c = a[0].Id,
                Approved__c = true
            );
            insert e;
            
            List<Contact> c = new List<Contact>();
            c.add(new Contact(
                LastName = 'Test Contact',
                Email = 'test12345@checkboxtest.com',
                OwnerId = u.Id
            ));
            c.add(new Contact(
                LastName = 'Test Contact',
                Email = 'test12345@checkboxtest.com',
                OwnerId = u.Id
            ));
            insert c;
            
            List<Lead> l = new List<Lead>();
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@checkboxtest.com',
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
            insert l;
            
            List<Twilio_Usage__c> t = new List<Twilio_Usage__c>();
            t.add(new Twilio_Usage__c(
                CounterKey__c = 'ckey1',
                Year__c = 2014,
                Month__c = 12,
                Product__c = 'hello',
                AccountSid__c = 'asid1',
                Lead__c = l[0].Id,
                Total__c = 12.34,
                Volume__c = 44,
                Currency__c = 'USD'
            ));
            t.add(new Twilio_Usage__c(
                CounterKey__c = 'ckey2',
                Year__c = 2014,
                Month__c = 12,
                Product__c = 'hello',
                AccountSid__c = 'asid2',
                Lead__c = l[1].Id,
                Total__c = 12.34,
                Volume__c = 44,
                Currency__c = 'USD'
            ));
            insert t;
    
            Map<Id,Id> leadToContactMap = new Map<Id,Id>();
            leadToContactMap.put(l[0].Id, c[0].Id);
            leadToContactMap.put(l[1].Id, c[1].Id);
            
            Map<Id,Id> leadToAccountMap = new Map<Id,Id>();
            leadToAccountMap.put(l[0].Id, a[0].Id);
            leadToAccountMap.put(l[1].Id, a[1].Id);
            
            Test.startTest();
            LeadAutoConvertHandler.linkTwilioUsagesToContact(leadToContactMap, leadToAccountMap);
            LeadAutoConvertHandler.linkZendeskTicketsToContact(leadToContactMap, leadToAccountMap);
            Test.stopTest();
        }
    }  

    static testmethod void ConvertNPCLead() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;
        
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;

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
            List<Account> a = new List<Account>();
            a.add(new Account(
                Name = 'Test Account1',
                OwnerId = u.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.checkboxtest.com'
            ));
            a.add(new Account(
                Name = 'Test Account2',
                OwnerId = u.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.checkboxtest1.com'
            ));
            insert a;
    
            Email_Domain__c e = new Email_Domain__c(
                Name = 'checkboxtest.com',
                Account__c = a[0].Id,
                Approved__c = true
            );
            insert e;
            
            List<Lead> l = new List<Lead>();
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@checkboxtest.com',
                LeadSource = 'Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@npctest.com',
                LeadSource = 'Full Service Request',
                Status = 'Open',
                ISO_Country_Code__c = 'EMEA',
                NPC_Date_5__c = Date.today(),
                OwnerId = u.Id
            ));
            l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'test12345@npctest.com',
                LeadSource = 'Full Service Request',
                Status = 'Open',
                ISO_Country_Code__c = 'APAC',
                NPC_Date_5__c = Date.today(),
                OwnerId = u.Id
            ));
            insert l;
    
            Map<Id,Lead> npcLeadMap = new Map<Id,Lead>();
            for (Lead x : l) { npcLeadMap.put(x.Id, x);}
            
            List<NPC_Routing__c> npc = new List<NPC_Routing__c>();
            npc.add(new NPC_Routing__c(Name = 'Other', ISO_Country_Code__c = 'OTHER', User_ID__c = u.Id));
            npc.add(new NPC_Routing__c(Name = 'EMEA', ISO_Country_Code__c = 'EMEA', User_ID__c = u.Id));
            insert npc;
            
            Test.startTest();
            LeadAutoConvertHandler.convertNPCLead(npcLeadMap);
            Test.stopTest();
        }
    }
    
    static testmethod void GetEmailDomain() {
        Test.startTest();
        LeadAutoConvertHandler.getEmailDomain(null, null);
        LeadAutoConvertHandler.getEmailDomain('test@test.com', null);
        LeadAutoConvertHandler.getEmailDomain('test@test.com', '');
        LeadAutoConvertHandler.getEmailDomain(null, 'test@test.com');
        LeadAutoConvertHandler.getEmailDomain('', 'test@test.com');
        LeadAutoConvertHandler.getEmailDomain('test@test.com', 'test@test.com');
        LeadAutoConvertHandler.getEmailDomain('test@test1.com', 'test@test2.com');
        Test.stopTest();
    }
    
    public static testmethod void marketoUserMassTest() {
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;
        
        Lead_Auto_Convert_Status__c leadDataList = Lead_Auto_Convert_Status__c.getInstance('Auto Convert');
        List<String> qualifiedStatus = new List<String>();
        if (leadDataList != NULL && leadDataList.Qualified_Status__c != NULL) {
            qualifiedStatus = leadData.Qualified_Status__c.split(',');
        }
        
        Profile marketoUser = [Select Id from Profile where name = 'Marketo Integration'];
        
        User u = new User();
        u.ProfileId = marketoUser.Id;
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
        
        
        List<Lead> l = new List<Lead>();
        for(integer i = 0; i<20; i++) {
            l.add(new Lead(
                LastName = 'MiaMiaMia',
                Company = 'Test Company',
                Email = 'ee12@kltesttesttest.com',
                Status = qualifiedStatus[Math.mod(i,5)]
            ));
        }
        
        //runAs marketo
        System.runAs(u) {
            insert l;
        }
        
    }
    
    public static testmethod void eloquaUserMassTest() {
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;
        
        Lead_Auto_Convert_Status__c leadDataList = Lead_Auto_Convert_Status__c.getInstance('Auto Convert');
        List<String> qualifiedStatus = new List<String>();
        if (leadDataList != NULL && leadDataList.Qualified_Status__c != NULL) {
            qualifiedStatus = leadData.Qualified_Status__c.split(',');
        }
        
        Profile eloquaUser = [Select Id from Profile where name = 'Sales Operations - Data Admin'];
        
        User u = new User();
        u.ProfileId = eloquaUser.Id;
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
        
        
        List<Lead> l = new List<Lead>();
        for(integer i = 0; i<40; i++) {
            l.add(new Lead(
                LastName = 'MiaMiaMia',
                Company = 'Test Company',
                Email = 'ee12@kltesttesttest.com',
                Status = qualifiedStatus[Math.mod(i,5)]
            ));
        }
        
        //runAs eloqua
        System.runAs(u) {
            insert l;
        }
        
    }
    
    static testmethod void StatusTest() {
        Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f;
        
        Lead_Auto_Convert_Status__c leaddata = new Lead_Auto_Convert_Status__c (
            Name='Auto Convert', 
            Qualified_Status__c ='Open,Contacted,BDR Engaged,Opportunity,Sales Qualified,Assigned to Account',
        	AccountRTExclude__c = '012400000009nVmAAI');
		insert leadData;

        User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

        List<Contact> autoContact0 = [SELECT id FROM Contact Where Email = 'dfwe@miamiatest.com'];
		System.assertEquals(0, autoContact0.size());
        
        System.RunAs(au) {
            List<Account> a = new List<Account>();
            a.add(new Account(
                Name = 'Test Account1',
                Employee_Size__c = '0 - 50',
                Website = 'http://www.checkboxtest.com'
            ));
            insert a;
    
            Email_Domain__c e = new Email_Domain__c(
                Name = 'miamiatest.com',
                Account__c = a[0].Id,
                Approved__c = true
            );
            insert e;
            
            List<Lead> l = new List<Lead>();
            
            Lead_Auto_Convert_Status__c leadDataList = Lead_Auto_Convert_Status__c.getInstance('Auto Convert');
            List<String> qualifiedStatus = new List<String>();
            if (leadDataList != NULL && leadDataList.Qualified_Status__c != NULL) {
                qualifiedStatus = leadData.Qualified_Status__c.split(',');
            }
                       
            for(String s: qualifiedStatus) {
                l.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'dfwe@miamiatest.com',
                Status = s
            	));
                System.debug('----> '+s);
            }
            insert l;
            
        }
    }

}