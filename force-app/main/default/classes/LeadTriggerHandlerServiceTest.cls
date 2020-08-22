@isTest
Private class LeadTriggerHandlerServiceTest {
	static testmethod void wesiteFieldUpdate() {
        Free_Email_Domains__c f1 = new Free_Email_Domains__c(Name = '163.com');
        Free_Email_Domains__c f2 = new Free_Email_Domains__c(Name = 'gmail.com');
        insert f1;
        insert f2;

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
                LastName = 'Test Lead1',
                Company = 'Test Company',
                Email = 'miatest1@notfreedomain.com',
                LeadSource = 'Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            l.add(new Lead(
                LastName = 'Test Lead2',
                Company = 'Test Company',
                Email = 'miatest2@gmail.com',
                LeadSource = 'Full Service Request',
                Status = 'Open',
                OwnerId = u.Id
            ));
            
            
            List<Lead> massLead = new List<Lead>();
            for (integer i = 0; i<100; i++) {
                if (i < 50) {
                    massLead.add(new Lead(
                        LastName = 'MASS Lead TEST'+ i,
                        Company = 'Test Company',
                        Email = 'miatest@notfreedomain.com',
                        LeadSource = 'Full Service Request',
                        Status = 'Open',
                        OwnerId = u.Id
                    ));
                } else {
                    massLead.add(new Lead(
                        LastName = 'MASS Lead TEST'+ i,
                        Company = 'Test Company',
                        Email = 'miatest@gmail.com',
                        LeadSource = 'Full Service Request',
                        Status = 'Open',
                        OwnerId = u.Id
                    ));
                }
            }
            
            Test.startTest();
            insert l;
            
            insert massLead;
            
            //TESTING Scenario: Insert lead with FREE EMAIL DOAMIN, Website Field should be null
            Lead free = [SELECT WEBSITE, EMAIL FROM LEAD WHERE email = 'miatest2@gmail.com' LIMIT 1];
            System.assertEquals(NULL, free.Website);
            
            //TESTING Scenario: Insert lead with NOT FREE EMAIL DOAMIN, then update to FREE EMAIL DOMAIN
            Lead notfree = [SELECT WEBSITE, EMAIL FROM LEAD WHERE email = 'miatest1@notfreedomain.com' LIMIT 1];
            System.assertEquals('http://www.notfreedomain.com', notfree.Website);
            notfree.Email = 'miatest1@163.com';
            update notfree;
            Lead notfree1 = [SELECT WEBSITE, EMAIL FROM LEAD WHERE email = 'miatest1@163.com' LIMIT 1];
            System.assertEquals(NULL, notfree1.Website);
            
            //TESTING Scenario: Mass insert lead with NOT FREE EMAIL DOMAIN and FREE EMAIL DOMAIN
            List<Lead> massLeadList = [SELECT WEBSITE, EMAIL FROM LEAD WHERE LastName LIKE '%MASS Lead TEST%'];
            for(Lead mLead: massLeadList) {
                if (mLead.email.split('@')[1] == 'gmail.com') {
                    System.assertEquals(NULL, mLead.Website);
                } else {
                    System.assertEquals('http://www.notfreedomain.com', mLead.Website);
                }
            }
            Test.stopTest();
        }
    }
}