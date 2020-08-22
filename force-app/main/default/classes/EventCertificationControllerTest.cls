//Created by: Gram Bischof 10/2/2020
//Last Modified: Gram Bischof 20/2/2020
//
//Description: 
//this class is used to cover the EventCertificationController class.
/**********************************************************/

@isTest
public class EventCertificationControllerTest {
    
    @testSetup
     static void testSetupMethod() {
        //setup
        Event testEvent = new Event();
        testEvent.Subject = 'Test Class';
        testEvent.StartDateTime = date.today();
        testEvent.EndDateTime =  system.today().addDays(2);
        testEvent.OwnerId = UserInfo.getUserId();
        testEvent.Enrollment_Limit__c = 1;
        testEvent.Type = 'Class';
        insert testEvent;
        
        Partner_Certification__c testPC = new Partner_Certification__c();
        testPC.Name__c = 'PCName';
        testPC.Training_Track__c = 'Platform';
        insert testPC;
        
        Event_Certification__c testEC = new Event_Certification__c();
        testEC.Status__c = 'Pending Approval';
        testEC.Event_ID__c = testEvent.id;
        testEC.Partner_Certification__c = testPC.Id;
        insert testEC;
    }
    
    @isTest
    public static void executeBeforeInsertTest(){     
        
        // Here we insert event.
        
        Event objevent = new Event();
        objevent.Subject = 'TEST WEBINAR';
        objevent.StartDateTime = date.today();
        objevent.EndDateTime =  date.today();
        objevent.OwnerId = UserInfo.getUserId();
        objevent.Type = 'Webinar';
        insert objevent;
        
        // Here we insert Event_Certification__c with the event lookup-
        
        Event_Certification__c objCertification = new Event_Certification__c();
        objCertification.Status__c = 'Pending Approval';
        objCertification.Event_ID__c = objevent.id;
        
        test.startTest();
        insert objCertification;
        test.stopTest();
        
        
        //Here we quering Event_Certification__c in the test class.
        
        List <Event_Certification__c> eventList = [select id,Status__c from Event_Certification__c WHERE Id=: objCertification.Id];
        
        system.assertEquals('Enrolled', eventList[0].Status__c);
        system.assertEquals(1, eventList.size());
        
    }
    
    @isTest
    public static void UpdateCertificationStageForPendingEnrolledTest() { 
    
        List<Partner_Certification__c> testPCAssertList = [SELECT Id, Certification_Stage__c FROM Partner_Certification__c];
        system.assertEquals('Pending Approval', testPCAssertList[0].Certification_Stage__c);
        
        List<Event_Certification__c> testECList = [SELECT Id, Status__c FROM Event_Certification__c];
        testECList[0].Status__c = 'Enrolled';
        test.startTest();
        update testECList;
        test.stopTest();
        
        //Assertion
        List<Partner_Certification__c> testPCAssertUpdateList = [SELECT Id, Certification_Stage__c FROM Partner_Certification__c];
        system.assertEquals('Enrolled', testPCAssertUpdateList[0].Certification_Stage__c);
    }
    
    @isTest
    public static void UpdateCertificationStageForRejectedTest() { 
    
        List<Event_Certification__c> testECList = [SELECT Id, Status__c FROM Event_Certification__c];
        testECList[0].Status__c = 'Rejected';
        test.startTest();
        update testECList;
        test.stopTest();
        
        //Assertion
        List<Partner_Certification__c> testPCAssertUpdateList = [SELECT Id, Certification_Stage__c FROM Partner_Certification__c];
        system.assertEquals('Rejected', testPCAssertUpdateList[0].Certification_Stage__c);
    }
}