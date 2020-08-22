/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  BatchUpdateLicenseDateTest
*
* @description 	  Test class for BatchUpdateLicenseDate class, test include:
					1. batch excute test
					2. overrideDate test
					3. negative test with non-Active record type
					4. schedulaer test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui	 <ncui@twilio.com>
* @modifiedBy     Mia Cui    <ncui@twilio.com>
* @version        1.0
* @created        2019-08-27
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		
*
**/
@isTest
public class BatchUpdateLicenseDateTest {
    static testmethod void test(){
        List<sfLma__License__c> lstLicense= new List<sfLma__License__c>();
        Id activeRecType = [SELECT Id 
                            FROM recordtype 
                            WHERE developername = 'Active'][0].Id;
        
        Id expiredRecType = [SELECT Id 
                            FROM recordtype 
                            WHERE developername = 'Expired'][0].Id;
        
        Account_SID__c sid = new Account_SID__c(name = '1111111111');
        insert sid;
        
        for(Integer i=0 ;i <200;i++){
            sfLma__License__c newLic = new sfLma__License__c(RecordTypeId = activeRecType, sfLma__Seats__c = 10,
                                                             Account_SID__c = sid.Id);
            lstLicense.add(newLic);
        }
        insert lstLicense;
        
        Test.startTest();
            BatchUpdateLicenseDate obj = new BatchUpdateLicenseDate();
            DataBase.executeBatch(obj);
        Test.stopTest();
        
        List<sfLma__License__c> recAfterUpdate = [SELECT ID, Next_Billing_date__c FROM sfLma__License__c Where Account_SID__c =: sid.Id];
        for(sfLma__License__c rec: recAfterUpdate) {
            System.assertEquals(Date.today(), rec.Next_Billing_date__c);
        }

    }

	static testmethod void testOverrideDate(){
        List<sfLma__License__c> lstLicense= new List<sfLma__License__c>();
        Id activeRecType = [SELECT Id 
                            FROM recordtype 
                            WHERE developername = 'Active'][0].Id;
        
        Account_SID__c sid = new Account_SID__c(name = '1111111111');
        insert sid;
        
        for(Integer i=0 ;i <200;i++){
            sfLma__License__c newLic = new sfLma__License__c(RecordTypeId = activeRecType, sfLma__Seats__c = 10,
                                                             Account_SID__c = sid.Id);
            lstLicense.add(newLic);
        }
        insert lstLicense;
        
        Test.startTest();
            BatchUpdateLicenseDate obj = new BatchUpdateLicenseDate();
        	obj.overrideDate = Date.today();
            DataBase.executeBatch(obj);
        Test.stopTest();
        
        List<sfLma__License__c> recAfterUpdate = [SELECT ID, Next_Billing_date__c FROM sfLma__License__c Where Account_SID__c =: sid.Id];
        for(sfLma__License__c rec: recAfterUpdate) {
            System.assertEquals(Date.today(), rec.Next_Billing_date__c);
        }

    }
    
    static testmethod void negativeTest(){
        List<sfLma__License__c> lstLicense= new List<sfLma__License__c>();
        
        Id expiredRecType = [SELECT Id 
                            FROM recordtype 
                            WHERE developername = 'Expired'][0].Id;
        
        Account_SID__c sid = new Account_SID__c(name = '1111111110');
        insert sid;
        
        for(Integer i=0 ;i <200;i++){
            sfLma__License__c newLic = new sfLma__License__c(RecordTypeId = expiredRecType, sfLma__Seats__c = 10,
                                                             Account_SID__c = sid.Id);
            lstLicense.add(newLic);
        }
        insert lstLicense;
        
        Test.startTest();
            BatchUpdateLicenseDate obj = new BatchUpdateLicenseDate();
            DataBase.executeBatch(obj);
        Test.stopTest();
        
        List<sfLma__License__c> recAfterUpdate = [SELECT ID, Next_Billing_date__c FROM sfLma__License__c Where Account_SID__c =: sid.Id];
        for(sfLma__License__c rec: recAfterUpdate) {
            System.assertEquals(NULL, rec.Next_Billing_date__c);
        }

    }
    
    static testMethod void testScheduler(){
        String CRON_EXP = '0 0 * * * ?';
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new BatchUpdateLicenseDate());
        Test.stopTest();
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchUpdateLicenseDate') LIMIT 1].Status);
    }

}