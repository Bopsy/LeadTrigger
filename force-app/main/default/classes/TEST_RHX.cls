@isTest(SeeAllData=true)
public class TEST_RHX {
    
    static testMethod void Twilio_Usage() {
        
// Changed because of "Non-selective query againt large object type (more than 100000 rows)""
//        List<sObject> sourceList = [SELECT Id
//                                    FROM Twilio_Usage__c
//                                    LIMIT 1];
		List<Twilio_Usage__c> sourceList = new List<Twilio_Usage__c>();

        if(sourceList.size() == 0) {
            sourceList.add(
                    new Twilio_Usage__c( AccountSid__c = '7y723yrhuceh9uisjd9fi2je', Currency__c = 'Dollars', Year__c = 2020, Month__c = 1, Total__c = 1, Product__c = 'stuff')
                );
        }
    	Database.upsert(sourceList);        
    }

}