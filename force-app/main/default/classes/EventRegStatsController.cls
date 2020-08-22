/**********************************************************
//Created by: Gram Bischof 03/12/2020
//Last Modified: Gram Bischof 03/13/2020
//Class: EventRegStatsController
//Description: This is the Controller class of EventRegStats 
//Lightning Component
***********************************************************/
public class EventRegStatsController {
    @AuraEnabled
    public static wrapEventDetails getEventDetails(String RecordId) {
        
        String remainingSeats;
        List<Event_Certification__c> theEventCertList = [SELECT Id FROM Event_Certification__c WHERE Event_ID__c =: RecordId AND Status__c =: 'Enrolled'];
        
        Event theEvent = [SELECT Id, Enrollment_Limit__c FROM Event WHERE Id =: RecordId limit 1];
       
        if(theEvent.Enrollment_Limit__c == null || (Integer.valueof(theEvent.Enrollment_Limit__c - theEventCertList.size())) < 0 ) {
            remainingSeats = '';
        } else {
            remainingSeats = Integer.valueof(theEvent.Enrollment_Limit__c - theEventCertList.size()) + '';
        }
        List<Partner_Certification__c> thepartCertList = [SELECT Id FROM Partner_Certification__c WHERE Certification_Stage__c =: 'Completed' AND ID IN (SELECT Partner_Certification__c FROM Event_Certification__c WHERE Event_ID__c =: RecordId)];
        
        wrapEventDetails testWrap = new wrapEventDetails(theEventCertList.size(), remainingSeats, thepartCertList.size());
        return testWrap;
    }
    public class wrapEventDetails {
        @AuraEnabled
        public Integer totalRegistered {get; set;}
        @AuraEnabled
        public  String remainingSeats {get; set;}
        @AuraEnabled
        public  Integer certificationsCompleted {get; set;}
        
        public wrapEventDetails(Integer totalReg, String remSeat, Integer completedCert) {
            totalRegistered = totalReg;
            remainingSeats = remSeat;
            certificationsCompleted = completedCert;
        }
    }
}