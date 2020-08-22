//Created by: Gram Bischof 11/19/2019
//Last Modified: Gram Bischof 13/03/2020
//
//Description: 
//this class is used in LightningCalender
//Test Class : CalendarEventControllerTest
/**********************************************************/
public without sharing class CalendarEventController {
    @AuraEnabled
    public static List<EventWrapper> getEvents(){
        
        Map<String, Integer> eventIdsMAp = new Map<String, Integer>();
        Set<String> eventIds = new Set<String>();
        Set<String> eventIdIsApproval = new Set<String>();
        Set<String> eventIdIsRejected = new Set<String>();
        
        
        List<User> currentUser = [SELECT Name, ContactId, Email, CompanyName, Contact.AccountId,Contact.Email from User WHERE Id =:UserInfo.getUserId()];
        for(Event_Certification__c eventCertRecord :[Select Id,Status__c, Event_ID__c, Partner_Certification__r.Contact__c,Contact_Email__c
                                                     from Event_Certification__c
                                                     LIMIT 10000]){
                                                         System.debug(' Event Cert: '+eventCertRecord);
                                                         
                                                         if(eventCertRecord.Status__c == 'Pending Approval'){
                                                             eventIdIsApproval.add(eventCertRecord.Event_ID__c); 
                                                         } 
                                                          if(eventCertRecord.Status__c == 'Rejected'){
                                                             eventIdIsRejected.add(eventCertRecord.Event_ID__c); 
                                                         } 
                                                         if(eventCertRecord.Partner_Certification__r.Contact__c == currentUser[0].ContactId
                                                           || eventCertRecord.Contact_Email__c == currentUser[0].Contact.Email) {
                                                             eventIds.add(eventCertRecord.Event_ID__c);
                                                         }
                                                         if(eventIdsMap.containsKey(eventCertRecord.Event_ID__c)) {  
                                                             Integer count = eventIdsMap.get(eventCertRecord.Event_ID__c)+1;
                                                             eventIdsMap.put(eventCertRecord.Event_ID__c, count);    
                                                         } else {
                                                             eventIdsMap.put(eventCertRecord.Event_ID__c, 1);
                                                         }                           
                                                     }
        
        List<EventWrapper> eventDetailList = new List<EventWrapper>();
        for(Event eventRecord :[Select Id, Location, Description, StartDateTime ,Subject, Type, EndDateTime, IsAllDayEvent, Enrollment_Limit__c, Webinar_Registration_Link__c
                                from Event
                                WHERE RecordType.DeveloperName='Partner']) {
                                    System.debug(' Event IDS '+eventIds+' --- '+eventIds.contains(eventRecord.Id));
                                    EventWrapper ew = new EventWrapper();
                                    ew.id = eventRecord.Id;
                                    ew.subject = eventRecord.Subject;
                                    ew.eventDescription = eventRecord.Description;
                                    ew.eventLocation = eventRecord.Location;
                                    ew.startDateTime = eventRecord.StartDateTime;
                                    ew.endDateTime = eventRecord.EndDateTime;
                                    ew.isAllDay = eventRecord.IsAllDayEvent;
                                    ew.eventType = eventRecord.Type;
                                    ew.registrationLink = eventRecord.Webinar_Registration_Link__c;
                                    ew.isEnrollRequested = eventIds.contains(eventRecord.Id);
                                    ew.isPendingApproval = eventIdIsApproval.contains(eventRecord.Id);
                                    ew.isRejected = eventIdIsRejected.contains(eventRecord.Id);
                                    ew.isClassFull = (eventIdsMap.containsKey(eventRecord.Id) && eventIdsMap.get(eventRecord.Id) >= eventRecord.Enrollment_Limit__c);
                                    if(eventIdsMap.containsKey(eventRecord.Id)) {
                                        ew.seats = (eventRecord.Enrollment_Limit__c != null ? String.valueOf(eventRecord.Enrollment_Limit__c - eventIdsMap.get(eventRecord.Id)) : 'No Limit');
                                    } else {
                                        ew.seats = eventRecord.Enrollment_Limit__c == null ? 'No Limit' : String.valueOf(eventRecord.Enrollment_Limit__c);
                                    }
                                    eventDetailList.add(ew);
                                }
        system.debug('eventDetailList>>>>>>>'+eventDetailList);
        return eventDetailList ; 
    }
    
    @AuraEnabled 
    public static Boolean enrollContact(String eventId, String eventDetail) {
        List<User> currentUser = [SELECT Name, ContactId, Email, CompanyName, Contact.AccountId,Contact.Full_Name__c,Contact.Email from User WHERE Id =:UserInfo.getUserId()];
        System.debug(' cu '+eventId+ '' +eventDetail);
        
        List<Event> eventRecordList = [SELECT id, Subject, OwnerId, Createdby.Email, Createdby.Name, StartDateTime, Training_Track__c, EndDateTime, Location,Webinar_Registration_Link__c, Type FROM Event WHERE Id=:eventId];
        
        List<Event_Certification__c> certEvent = [SELECT Id, Status__c, Partner_Certification__r.Contact__c
                                                  FROM Event_Certification__c 
                                                  WHERE Partner_Certification__r.Contact__c=:currentUser[0].ContactId
                                                  AND Event_Id__c =:eventId];
        
        List<Account_SID__c> accountSID = [SELECT Id, Account_SID__c FROM Account_SID__c WHERE Contact__c=:currentUser[0].ContactId];
        
        //List<Partner_Certification__c> certRecords = new List<Partner_Certification__c>();
        if(certEvent.size() == 0) {
            Partner_Certification__c certRecord; 
            if(eventRecordList[0].Type != 'Webinar') {
                certRecord = new Partner_Certification__c();
                if(eventRecordList.size() > 0) {
                    certRecord.Name__c = eventRecordList[0].Subject;
                    certRecord.Certification_Date__c = Date.valueOf(eventRecordList[0].StartDateTime);
                    //certRecord.Event_End_Date__c = Date.valueOf(eventRecordList[0].EndDateTime);
                    certRecord.Training_Track__c = eventRecordList[0].Training_Track__c;
                }
                certRecord.Contact__c = currentUser[0].ContactId;
                certRecord.Account__c = currentUser[0].Contact.AccountId;
                //certRecord.Email__c = currentUser[0].Email;
                certRecord.Status__c = 'Requested';
                certRecord.Name__c = currentUser[0].Name;
                certRecord.Company__c = currentUser[0].CompanyName;
                insert certRecord;
            }
            //certRecords.add(certRecord);
            
            List<Event_Certification__c> ecertsToInsert = new List<Event_Certification__c>();
            //for(Partner_Certification__c cert : certRecords) {
            Event_Certification__c ecert = new Event_Certification__c();
            if(eventRecordList[0].Type != 'Webinar') ecert.Partner_Certification__c = certRecord.Id;
            ecert.Event_ID__c = eventId;
            ecert.Event_Detail__c = eventDetail;
            ecert.Status__c = 'Pending Approval';
            if(eventRecordList.size() > 0) {
                ecert.Event_Subject__c = eventRecordList[0].Subject;
                ecert.Event_StartDate__c = Date.valueOf(eventRecordList[0].StartDateTime);
                ecert.Event_EndDate__c = Date.valueOf(eventRecordList[0].EndDateTime);
                ecert.Event_Location__c = eventRecordList[0].Location;
                ecert.Cert_Manager_Email__c = eventRecordList[0].Createdby.Email;
                ecert.Event_Training_Track__c = eventRecordList[0].Training_Track__c;
                ecert.Event_Type__c = eventRecordList[0].Type;
                ecert.Event_StartTime__c = eventRecordList[0].StartDateTime.Time();
                ecert.Webinar_Registration_Link__c  = eventRecordList[0].Webinar_Registration_Link__c;
            }
            ecert.Contact_Name__c = currentUser[0].Contact.Full_Name__c;
            ecert.Contact_Email__c = currentUser[0].Contact.Email;
            if(accountSID.size() > 0) {
                ecert.Account_SID_Record__c = accountSID[0].Id;
            }
            ecertsToInsert.add(ecert);
            //}
            
            System.debug(' Cert: '+ecertsToInsert);
            if(ecertsToInsert.size() > 0) {
                insert ecertsToInsert;
                return true;
            } else {
                return false;
            }
        } else {
            return true; // We will always say customer is enrolled.
        }
        
        //insert certRecords;
        
    }
    
    @AuraEnabled
    public static Boolean cancelEnrollment(String eventId) {
        List<User> currentUser = [SELECT Name, ContactId, Email, CompanyName, Contact.AccountId from User WHERE Id =:UserInfo.getUserId()];
        
        List<Event_Certification__c> certEvent = [SELECT Id, Status__c, Partner_Certification__r.Contact__c
                                                  FROM Event_Certification__c 
                                                  WHERE Partner_Certification__r.Contact__c=:currentUser[0].ContactId
                                                  AND Event_Id__c =:eventId];
        
        delete certEvent;
        return true;
    }
    
    @AuraEnabled
    public static List<Event_Certification__c> getMyEvents(){
        List<User> currentUser = [SELECT Name, ContactId, Email, CompanyName, Contact.AccountId, Contact.Email from User WHERE Id =:UserInfo.getUserId()];
        
        Map<Id,Event_Certification__c> certEvent = new Map<Id,Event_Certification__c>([SELECT Id,Event_ID__c, Start_Date__c, Status__c, Partner_Certification__r.Contact__c, Partner_Certification__r.Certification_Date__c, Contact_Email__c, Event_Detail__c
                                                  FROM Event_Certification__c 
                                                  WHERE Partner_Certification__r.Contact__c=:currentUser[0].ContactId OR Contact_Email__c =: currentUser[0].Contact.Email]);
        Map<Id,Id> evntToEventcrtMap = new Map<Id,Id>();
        for(Event_Certification__c evnt: certEvent.values()) evntToEventcrtMap.put(evnt.Event_ID__c,evnt.Id);
        for(Event e: [Select id,StartDateTime From Event Where Id IN :evntToEventcrtMap.keySet()]){
            System.debug('startDates');
            System.debug(certEvent.get(evntToEventcrtMap.get(e.id)).Start_Date__c);
            System.debug(e.StartDateTime);
            //if(evntToEventcrtMap.)
            certEvent.get(evntToEventcrtMap.get(e.id)).Start_Date__c = e.StartDateTime;
            
        }
        system.debug('certEvent>>>>'+certEvent);
        return certEvent.values();
    }
    
    public class EventWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public String eventType;
        @AuraEnabled
        public DateTime startDateTime;
        @AuraEnabled
        public DateTime endDateTime;
        @AuraEnabled
        public Boolean isEnrollRequested;
        @AuraEnabled
        public String eventDescription;
        @AuraEnabled
        public String eventLocation;
        @AuraEnabled
        public Boolean isAllDay;
        @AuraEnabled
        public Boolean isClassFull;
        @AuraEnabled
        public String seats;
        @AuraEnabled
        public String registrationLink;
        @AuraEnabled
        public Boolean isPendingApproval;
        @AuraEnabled
        public Boolean isRejected;
        
    }
}