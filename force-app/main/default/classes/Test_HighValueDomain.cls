/*
 * Class:   Test_HighValueDomain
 * Purpose: Provide test coverage for the trigger SetHighValueDomainLowerCase
 */
@isTest
private class Test_HighValueDomain {

    static testMethod void insertHighValueDomain() {
        High_Value_Domain__c hvd = new High_Value_Domain__c();
        hvd.Name = 'MyTestDomainName.Com';
        insert hvd;
        
        High_Value_Domain__c hvdQueried = [SELECT Name FROM High_Value_Domain__c WHERE id = :hvd.Id LIMIT 1];
        System.assertEquals('mytestdomainname.com', hvdQueried.Name);
    }
    
    static testMethod void updateHighValueDomain() {
        High_Value_Domain__c hvd = new High_Value_Domain__c();
        hvd.Name = 'MyTestDomainName.Com';
        insert hvd;
        
        hvd.Name = 'MyTestDomainNameTwo.Com';
        update hvd;
        
        High_Value_Domain__c hvdQueried = [SELECT Name FROM High_Value_Domain__c WHERE id = :hvd.Id LIMIT 1];
        System.assertEquals('mytestdomainnametwo.com', hvdQueried.Name);
    }
    
}