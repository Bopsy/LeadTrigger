@isTest

private class RecalulateUsageTotalTest {

    static testmethod void test() {
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

    
       Test.startTest();
       Database.executeBatch(new RecalculateUsageTotal());
       Test.stopTest();
    }
}