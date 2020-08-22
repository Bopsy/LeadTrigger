@isTest
                                
private class CalculateForecastUsageSchedulerTest {

   // CRON expression: midnight on March 15.
   // Because this is a test, job executes
   // immediately after Test.stopTest().
   public static String CRON_EXP = '0 0 0 15 3 ? 2022';

   static testmethod void CalculateForecastUsageSchedulerTest1() {
	  setupTestRecords();
	  
      Test.startTest();

      // Schedule the test job
      String jobId = System.schedule('CalculateForecastUsageScheduler', CRON_EXP, new CalculateForecastUsageScheduler());
         
      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,  NextFireTime FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(CRON_EXP, ct.CronExpression);

      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the next time the job will run
      System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
      Test.stopTest();

   }
   
   static void setupTestRecords() {
   	    Datetime now = Datetime.now();
	    Integer year = now.year();
	    Integer month = now.month(); 
		String current_months_year = String.valueOf(year);
		String current_months_month = now.format('MMMMM');
    
		Account a = new Account(Name = 'Test Account', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
		insert a;

		Lead l = new Lead(LastName = 'Test Lead', Company = 'Test Company', Account_SID__c = 'abcdef1234567891');
		insert l;
		
		List<Twilio_Usage__c> u = new List<Twilio_Usage__c>();
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Total Sales (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 40.00,
			Volume__c = 2,
			Currency__c = 'USD')
		);
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567890',
			Product__c = 'Usage - Short Codes Random (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 20.00,
			Volume__c = 1,
			Currency__c = 'USD')
		);
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567891',
			Product__c = 'Total Sales (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 40.00,
			Volume__c = 2,
			Currency__c = 'USD')
		);
		
		u.add(new Twilio_Usage__c(
			AccountSid__c = 'abcdef1234567891',
			Product__c = 'Usage - Short Codes Random (Amortized)',
			Month__c = month,
			Year__c = year,
			Total__c = 20.00,
			Volume__c = 1,
			Currency__c = 'USD')
		);

		insert u;
   }
}