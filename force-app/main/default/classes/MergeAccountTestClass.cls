/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class MergeAccountTestClass {

    static testMethod void accountCreation() {
        Datetime now = Datetime.now();
        Integer year = now.year();
        Integer month = now.month(); 
        String current_months_year = String.valueOf(year);
        String current_months_month = now.format('MMMMM');
    
		Free_Email_Domains__c f = new Free_Email_Domains__c(Name = 'gmail.com');
		insert f;

        Account a1 = new Account(Name = 'Test Account 1', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert a1;

        Email_Domain__c e1 = new Email_Domain__c(Name = 'test-lead-autoconvert-12345.com', Account__c = a1.Id);
        insert e1;
        
        Account a2 = new Account(Name = 'Test Account 2', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567891');
        insert a2;

        Email_Domain__c e2 = new Email_Domain__c(Name = 'test-lead-autoconvert-23456.com', Account__c = a2.Id);
        insert e2;

        List<Twilio_Usage__c> u = new List<Twilio_Usage__c>();
        
        u.add(new Twilio_Usage__c(
            AccountSid__c = 'abcdef1234567890',
            Product__c = 'Net Billings',
            Month__c = month,
            Year__c = year,
            Total__c = 40.00,
            Volume__c = 2,
            Currency__c = 'USD')
        );
        
        u.add(new Twilio_Usage__c(
            AccountSid__c = 'abcdef1234567891',
            Product__c = 'Net Billings',
            Month__c = month,
            Year__c = year,
            Total__c = 40.00,
            Volume__c = 2,
            Currency__c = 'USD')
        );

        insert u;
        
        List<Twilio_Forecast__c> forecasts1 = [
            SELECT Id, Rep_Override__c
            FROM Twilio_Forecast__c
            WHERE Account__c = :a1.Id
            ORDER BY Fiscal_Month__c
        ];
        
        if (!forecasts1.isEmpty()) {
            forecasts1[0].Rep_Override__c = 10;
            forecasts1[1].Rep_Override__c = 10;
        }
        update forecasts1;

        List<Twilio_Forecast__c> forecasts2 = [
            SELECT Id, Rep_Override__c
            FROM Twilio_Forecast__c
            WHERE Account__c = :a2.Id
            ORDER BY Fiscal_Month__c
        ];
        
        if (!forecasts2.isEmpty()) {
            forecasts2[0].Rep_Override__c = 10;
        }
        update forecasts2;

        Test.startTest();
        merge a1 a2;      
        Test.stopTest();   
    }
}