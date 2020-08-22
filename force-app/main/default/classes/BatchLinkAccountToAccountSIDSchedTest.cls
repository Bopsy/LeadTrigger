@isTest
private class BatchLinkAccountToAccountSIDSchedTest {

   // CRON expression: midnight on March 15.
   // Because this is a test, job executes
   // immediately after Test.stopTest().
   public static String CRON_EXP = '0 0 0 15 3 ? 2022';

   static testmethod void ScheduleBatchJob() {
      setupTestRecords();
      
      Test.startTest();

      // Schedule the test job
      String jobId = System.schedule('BatchLinkAccountToAccountSIDScheduler',
                        CRON_EXP, 
                        new BatchLinkAccountToAccountSIDScheduler());
         
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

        List<Account> a = new List<Account>();
        a.add(new Account(
            Name = 'Test Account1',
            OwnerId = u.Id,
            Employee_Size__c = '0 - 50',
            Website = 'http://www.linkaccountsidtest1.com'
        ));
        a.add(new Account(
            Name = 'Test Account2',
            OwnerId = u.Id,
            Employee_Size__c = '0 - 50',
            Website = 'http://www.linkaccountsidtest2.com'
        ));
        insert a;

        List<Email_Domain__c> e = new List<Email_Domain__c>();
        // Email domain approved
        e.add(new Email_Domain__c(
        	Name = 'linkaccountsidtest1.com',
        	Account__c = a[0].Id,
        	Approved__c = true
        ));
        // Email domain not approved
        e.add(new Email_Domain__c(
        	Name = 'linkaccountsidtest2.com',
        	Account__c = a[0].Id,
        	Approved__c = false
        ));
        insert e;
        
        List<Account_SID__c> s = new List<Account_SID__c>();
        // Email domain approved
        s.add(new Account_SID__c(
	        Name = 'SID-1234567890',
	        OwnerUser_SID__c = '1234567890',
	        Account_SID_Status__c = 'ACTIVE',
	        OwnerUser_Email_Address__c = 'test12345@linkaccountsidtest1.com'
	        
        ));
        // Email domain approved by Account SID record not active
        s.add(new Account_SID__c(
	        Name = 'SID-2345678901',
	        OwnerUser_SID__c = '2345678901',
	        Account_SID_Status__c = 'INACTIVE',
	        OwnerUser_Email_Address__c = 'test12345@linkaccountsidtest1.com'
	        
        ));
        // Email domain not approved
        s.add(new Account_SID__c(
	        Name = 'SID-3456789012',
	        OwnerUser_SID__c = '3456789012',
	        Account_SID_Status__c = 'ACTIVE',
	        OwnerUser_Email_Address__c = 'test12345@linkaccountsidtest2.com'
	        
        )); 
        // Freemail Test
        s.add(new Account_SID__c(
	        Name = 'SID-3456789012',
	        OwnerUser_SID__c = '3456789012',
	        Account_SID_Status__c = 'ACTIVE',
	        OwnerUser_Email_Address__c = 'test12345@gmail.com'
	        
        )); 
        insert s;
   }
}