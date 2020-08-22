//Created by: Gram Bischof 11/19/2019
//Last Modified: Gram Bischof 02/12/2020
//
//Description: 
//this class is the test class of CalendarEventController
/**********************************************************/
@isTest
public class CalendarEventControllerTest 
{
    public static testmethod void verifyEnrollment() {
        
        /*Id superNetworkRecord = [SELECT id FROM RecordType WHERE DeveloperName='Super_Network_Contact'].Id;
        Id superNetworkRecordAcc = [SELECT id FROM RecordType WHERE DeveloperName='Super_Network_Provider'].Id;
        Id partnerEventId = [SELECT id FROM RecordType WHERE DeveloperName='Partner' AND SobjectType='Event'].Id;*/
        
        Id superNetworkRecord = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Super Network Contact').getRecordTypeId();
        Id superNetworkRecordAcc = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Super Network Provider').getRecordTypeId();
        Id partnerEventId = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        
        Account acc = new Account(RecordTypeId=superNetworkRecordAcc,Name='Community Account');
        insert acc;
        Contact contactRecord = new Contact(Title='Power',AccountId=acc.Id, LastName='Fake Name', RecordTypeId=superNetworkRecord);
        insert contactRecord;
        
        Event ev = new Event();
        ev.RecordTypeId = partnerEventId;
        ev.Subject = 'Some Suject';
        ev.StartDateTime = DateTIme.now();
        ev.EndDateTime = DateTime.now().addDays(1);
        ev.Type = 'Meeting';
        insert ev;
        
        
        User u = new user();
        u.LastName = 'Test Code';
        u.Email = 'testpartner@testclaendertwil.com';
        u.ContactId = contactRecord.Id;
        u.Alias = 'Tcode';
        u.Username = 'testpartner@testclaendertwil.com';
        u.CommunityNickname = 'test12';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'GMT';
        u.profileId = [SELECT Id FROM Profile WHERE Name='Partner Community User - Gold'].Id;
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.UserPreferencesLightningExperiencePreferred = false;
        
        //insert u;
        
        System.runAs(u) {
            List<Event_Certification__c> testmyEvents = CalendarEventController.getMyEvents(); 
            List<CalendarEventController.EventWrapper> eventRecords = CalendarEventController.getEvents();
            Boolean isEnrolled = CalendarEventController.enrollContact(eventRecords[0].id, eventRecords[0].subject);
            System.assertEquals(true, isEnrolled);
            Boolean cancelEnroll = CalendarEventController.cancelEnrollment(eventRecords[0].Id);
            System.assertEquals(true, cancelEnroll);
        }
    }
}