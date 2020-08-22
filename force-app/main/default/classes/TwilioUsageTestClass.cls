@isTest 
private class TwilioUsageTestClass {
    static testMethod void validateTwilioUsage() {
    
       TwilioUsage__c t = new TwilioUsage__c(CounterKey__c='test', Year__c=2014, Month__c=12, Product__c='hello', AccountSid__c='goodbye', Total__c=12.34, Volume__c=44, Currency__c='USD');
       System.debug('inserting');

       // Insert usage
       insert t;
    
    }
}