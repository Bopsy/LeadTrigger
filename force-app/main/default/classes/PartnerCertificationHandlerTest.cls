//Created by: Nitish 3/4/2020
//Last Modified: Nitish 3/4/2020
//
//Description: 
//This is the test class that use to test 
//PartnerCertificationHandler class with the test plan.
/**********************************************************/
@isTest
public class PartnerCertificationHandlerTest {
     
    //Description: 
    //This is the test setup method that use to provide
    //the data to the test class.
    @testSetup static void setup() {
        
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        system.debug('portalRole is ' + portalRole);
        
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'bopsyTest@test.com',
            Alias = 'testBop',
            Email='BopsyTest@gmail.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bopsy',
            Lastname='Test',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);
        System.debug('portalAccountOwner1::'+portalAccountOwner1);
        
            System.runAs ( portalAccountOwner1 ) {
                //Create account
                  Account portalAccount = new Account(
                        Name = 'TestAccount',
                        OwnerId = portalAccountOwner1.Id
                    );
                  
                Database.insert(portalAccount);
                
                    //Create contact
                    Contact contact = new Contact(
                        FirstName = 'Test',
                        Lastname = 'McTesty',
                        AccountId = portalAccount.Id,
                        Preferred_Email__c ='TestBopsy@gmail.com',
                        Contact_Type__c='Billing Contact',
                        Title='Testing',
                        Account_Admin__c=true
                    );
                
                Database.insert(contact);
                
                //Create user
                Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%**Partner Community User Login**%' Limit 1];
                
                    User user1 = new User(
                        Username = System.now().millisecond() + 'test'+contact.LastName+'@test.com',
                        ContactId = contact.Id,
                        ProfileId = portalProfile.Id,
                        Alias = 'test123',
                        Email = contact.Preferred_Email__c,
                        EmailEncodingKey = 'UTF-8',
                        LastName = 'McTesty'+contact.LastName,
                        CommunityNickname = 'test12345'+contact.LastName,
                        TimeZoneSidKey = 'America/Los_Angeles',
                        LocaleSidKey = 'en_US',
                        LanguageLocaleKey = 'en_US'
                    );
                   
                Database.insert(user1);
                
                
            }
        
    }
    
    //Description: 
    //This method use to unit test the updateAccountOnPartnerCertificationInsert
    //method of trigger handler class.
    public static testMethod void testupdateAccountOnPartnerCertificationInsert() {
        
        List<Event> eventList=new List<Event>();
        for(Integer i=0;i<4;i++) {
                    
                    Event event=new Event();
                    event.Subject='Email';
                    event.StartDateTime=Datetime.now();
                    event.EndDateTime=Datetime.now().addDays(1);
                    event.Type='Class';
                    event.Enrollment_Limit__c=12;
                    
                    eventList.add(event);
        }
        insert eventList;
        
        
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%**Partner Community User Login**%' Limit 1];
        
        List<Contact> portalContact=new List<Contact>([select id,Name,AccountId from Contact]);
        System.debug('portalContact::'+portalContact);
        
               
        List<User> user=new List<User>([select id,Name,ProfileId,ContactId from User where ProfileId=:portalProfile.Id AND ContactId=:portalContact[0].Id]);
        System.debug('User::'+user);
        
        System.runAs(user[0]) {
            for(Event event:EventList) {
                //Calling the Enroll button method of CalenderEventController
                //to enroll the event from the portal user that we have created.
                CalendarEventController.enrollContact(event.Id,event.Subject);
            }
        }
       
        List<Partner_Certification__c> partnerCertificationList=new List<Partner_Certification__c>([select id,Name,	Contact__c,Training_Track__c,Certification_Stage__c,Account__c from Partner_Certification__c where Contact__c=:portalContact[0].Id]);
        System.debug('partnerCertificationList::'+partnerCertificationList);
        System.assertEquals(4,partnerCertificationList.size());
        
        List<Partner_Certification__c> updatedPartnerCertificationList=new List<Partner_Certification__c>();
        
        //Updating the partner Certification 
        //partnerCertification 1 update
        Partner_Certification__c partnerCertification1=partnerCertificationList[0];
        partnerCertification1.Certification_Stage__c='Completed';
        partnerCertification1.Training_Track__c='Support';
        
        updatedPartnerCertificationList.add(partnerCertification1);
        
        //partnerCertification 2 update
        Partner_Certification__c partnerCertification2=partnerCertificationList[1];
        partnerCertification2.Certification_Stage__c='Completed';
        partnerCertification2.Training_Track__c='Sales';
        
        updatedPartnerCertificationList.add(partnerCertification2);
        
        //partnerCertification 3 update
        Partner_Certification__c partnerCertification3=partnerCertificationList[2];
        partnerCertification3.Certification_Stage__c='Completed';
        partnerCertification3.Training_Track__c='Support';
        
        updatedPartnerCertificationList.add(partnerCertification3);
        
        //partnerCertification 4 update
        Partner_Certification__c partnerCertification4=partnerCertificationList[3];
        partnerCertification4.Certification_Stage__c='Completed';
        partnerCertification4.Training_Track__c='Sales';
        
        updatedPartnerCertificationList.add(partnerCertification4);
        PartnerCertificationHandler.flag=true;
        
        Test.startTest();
        	update updatedPartnerCertificationList;
        test.stopTest();
        System.debug('updatedPartnerCertificationList::'+updatedPartnerCertificationList);
        
        List<Account> account=new List<Account>([select id,Name,Build_Certified_Individuals__c from Account where Name='TestAccount']);
        
        System.assertEquals(2, account[0].Build_Certified_Individuals__c);     
        
       
    }

    //Description: 
    //This method use to unit test the updateAccountOnPartnerCertificationInsert
    //method of trigger handler class on the insert case for the 
    //Partner Certification.
    public static testMethod void testUpdateAccountForPartCerforInsert() {
        
        List<Event> eventList=new List<Event>();
        for(Integer i=0;i<4;i++) {
                    
                    Event event=new Event();
                    event.Subject='Email';
                    event.StartDateTime=Datetime.now();
                    event.EndDateTime=Datetime.now().addDays(1);
                    event.Type='Class';
                    event.Enrollment_Limit__c=12;
                    
                    eventList.add(event);
        }
        insert eventList;
        
        List<Contact> portalContact=new List<Contact>([select id,Name,AccountId from Contact]);
        System.debug('portalContact::'+portalContact);
        
        List<Account> account=new List<Account>([select id,Name from Account where Id=:portalContact[0].AccountId]);
       
        PartnerCertificationHandler.flag=false;
        
        List<Partner_Certification__c> partnerCertList=new List<Partner_Certification__c>();
        for(Integer i=0;i<3;i++) {
            
            Partner_Certification__c partnerCertification1=new Partner_Certification__c();
            partnerCertification1.Account__c=account[0].Id;
            partnerCertification1.Contact__c=portalContact[0].Id;
            partnerCertification1.Certification_Stage__c='Completed';
            partnerCertification1.Training_Track__c='Flex';
          
            partnerCertList.add(partnerCertification1);
        }
        //Testing for Insert case

        insert partnerCertList;
        
        PartnerCertificationHandler.flag=true;
        
        Partner_Certification__c partnerCertification2=new Partner_Certification__c();
        partnerCertification2.Account__c=account[0].Id;
        partnerCertification2.Contact__c=portalContact[0].Id;
        partnerCertification2.Certification_Stage__c='Pending Approval';
        partnerCertification2.Training_Track__c='Sales';
        
        
        insert partnerCertification2;
        
        Test.startTest();
        
        PartnerCertificationHandler.flag=true;
        
        partnerCertification2.Certification_Stage__c='Completed';
        update partnerCertification2;
        
        Test.stoptest();
        
        List<Account> updatedAccount=new List<Account>([select id,Name,Build_Certified_Individuals__c from Account where Name='TestAccount']);
        
        System.assertEquals(2, updatedAccount[0].Build_Certified_Individuals__c); 
        
    }
    
    public static testMethod void testDeleteforRollup(){
        Contact portalContact = [select id,Name,AccountId from Contact Limit 1];
        System.debug('portalContact::'+portalContact);
        
        Account testAccount = [select id,Name from Account where Id=:portalContact.AccountId];
        testAccount.Build_Certified_Individuals__c = 2;
        update testAccount;
        
        PartnerCertificationHandler.flag=false;
        
        List<Partner_Certification__c> partnerCertList=new List<Partner_Certification__c>();
        for(Integer i=0;i<3;i++) {
            
            Partner_Certification__c partnerCertification1=new Partner_Certification__c();
            partnerCertification1.Account__c=testAccount.Id;
            partnerCertification1.Contact__c=portalContact.Id;
            partnerCertification1.Certification_Stage__c='Completed';
            partnerCertification1.Training_Track__c='Flex';
          
            partnerCertList.add(partnerCertification1);
        }
        //Testing for Insert case

        insert partnerCertList;
        
        
        Partner_Certification__c partnerCertification2=new Partner_Certification__c();
        partnerCertification2.Account__c=testAccount.Id;
        partnerCertification2.Contact__c=portalContact.Id;
        partnerCertification2.Certification_Stage__c='Completed';
        partnerCertification2.Training_Track__c='Sales';
        
        
        insert partnerCertification2;
        
        Test.startTest();
        	PartnerCertificationHandler.flag=true;
        	delete partnerCertList;
        Test.stopTest();
        
       testAccount = [select id,Name,Build_Certified_Individuals__c from Account where Id=:testAccount.Id];
       System.assertEquals(1,testAccount.Build_Certified_Individuals__c);
    }
    
    public static testMethod void testDeleteAllRollup(){
        Contact portalContact = [select id,Name,AccountId from Contact Limit 1];
        System.debug('portalContact::'+portalContact);
        
        Account testAccount = [select id,Name from Account where Id=:portalContact.AccountId];
        testAccount.Build_Certified_Individuals__c = 2;
        update testAccount;
        
        PartnerCertificationHandler.flag=false;
        
        List<Partner_Certification__c> partnerCertList=new List<Partner_Certification__c>();
        for(Integer i=0;i<3;i++) {
            
            Partner_Certification__c partnerCertification1=new Partner_Certification__c();
            partnerCertification1.Account__c=testAccount.Id;
            partnerCertification1.Contact__c=portalContact.Id;
            partnerCertification1.Certification_Stage__c='Completed';
            partnerCertification1.Training_Track__c='Flex';
          
            partnerCertList.add(partnerCertification1);
        }
        //Testing for Insert case

        insert partnerCertList;
        
        
        Partner_Certification__c partnerCertification2=new Partner_Certification__c();
        partnerCertification2.Account__c=testAccount.Id;
        partnerCertification2.Contact__c=portalContact.Id;
        partnerCertification2.Certification_Stage__c='Completed';
        partnerCertification2.Training_Track__c='Sales';
        
        
        insert partnerCertification2;
        
        partnerCertList.add(partnerCertification2);
        
        Test.startTest();
        	PartnerCertificationHandler.flag=true;
        	delete partnerCertList;
        Test.stopTest();
        
       testAccount = [select id,Name,Build_Certified_Individuals__c from Account where Id=:testAccount.Id];
       System.assertEquals(0,testAccount.Build_Certified_Individuals__c);
    }
    
    public static testMethod void testStatusChangeforRollup(){
        Contact portalContact = [select id,Name,AccountId from Contact Limit 1];
        System.debug('portalContact::'+portalContact);
        
        Account testAccount = [select id,Name from Account where Id=:portalContact.AccountId];
        testAccount.Build_Certified_Individuals__c = 2;
        update testAccount;
        
        PartnerCertificationHandler.flag=false;
        
        List<Partner_Certification__c> partnerCertList=new List<Partner_Certification__c>();
        Partner_Certification__c partnerCertification1=new Partner_Certification__c();
        partnerCertification1.Account__c=testAccount.Id;
        partnerCertification1.Contact__c=portalContact.Id;
        partnerCertification1.Certification_Stage__c='Completed';
        partnerCertification1.Training_Track__c='Flex';
          
        partnerCertList.add(partnerCertification1);
        
        
        Partner_Certification__c partnerCertification2=new Partner_Certification__c();
        partnerCertification2.Account__c=testAccount.Id;
        partnerCertification2.Contact__c=portalContact.Id;
        partnerCertification2.Certification_Stage__c='Completed';
        partnerCertification2.Training_Track__c='Sales';
        
        partnerCertList.add(partnerCertification2);
        
        insert partnerCertList;
        
        Test.startTest();
        	PartnerCertificationHandler.flag=true;
        	partnerCertification2.Certification_Stage__c='Pending Approval';
        	partnerCertification1.Certification_Stage__c='Rejected';
        	update new List<Partner_Certification__c>{partnerCertification1,partnerCertification2};
        Test.stopTest();
        
       testAccount = [select id,Name,Build_Certified_Individuals__c from Account where Id=:testAccount.Id];
       System.assertEquals(0,testAccount.Build_Certified_Individuals__c);
    }
}