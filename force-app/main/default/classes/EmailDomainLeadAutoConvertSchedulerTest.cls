@isTest
private class EmailDomainLeadAutoConvertSchedulerTest {

   // CRON expression: midnight on March 15.
   // Because this is a test, job executes
   // immediately after Test.stopTest().
   public static String CRON_EXP = '0 0 0 15 3 ? 2022';

   static testmethod void EmailDomainLeadAutoConvertSchedulerTest1() {
      setupTestRecords();
      
      Test.startTest();

      // Schedule the test job
      String jobId = System.schedule('EmailDomainLeadAutoConvertScheduler',
                        CRON_EXP, 
                        new EmailDomainLeadAutoConvertScheduler());
         
      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(CRON_EXP, 
         ct.CronExpression);

      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the next time the job will run
      System.assertEquals('2022-03-15 00:00:00', 
      String.valueOf(ct.NextFireTime));
      Test.stopTest();
   }
   
   static void setupTestRecords() {
		Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
		insert f;

        Profile p = [Select Id, Name from Profile where name = 'Standard User'];
        Profile ap = [Select Id, Name from Profile where name = 'System Administrator'];
        
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
        	Approved__c = false
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
        l.add(new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test12345@npctest.com',
            LeadSource = 'Full Service Request',
            Status = 'Responded',
            ISO_Country_Code__c = 'TEST',
            NPC_Date_5__c = Date.today(),
            OwnerId = u.Id
        ));
        insert l;

		DoNotAutoConvert__c dnac = new DoNotAutoConvert__c(Name = ap.Name, Profile_ID__c = ap.Id);
		insert dnac;
		
		e.Approved__c = true;
        update e;
   }
}