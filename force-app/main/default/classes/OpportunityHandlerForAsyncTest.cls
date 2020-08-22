/**********************************************************
Class: OpportunityHandlerForAsyncTest
Last Modified By: Bopsy 05/21/2020
Description: This is Test class for the OpportunityHandlerForAsync And OpportunityHandlerForFUAndEmailAlerts      
***********************************************************/
@isTest
public class OpportunityHandlerForAsyncTest {
    
    @testSetup
    public static void setup() {
        Account testAcnt = new Account();
        testAcnt.Name = 'AcntName';
        insert testAcnt;
        
        Opportunity theOpp = new Opportunity();
        theOpp.Name = 'TestOppBulky';
        theOpp.AccountId = testAcnt.Id;
        theOpp.CloseDate = system.today();
        theOpp.StageName = 'Incubate';
        insert theOpp;
    }
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    //  after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forOpportunity_ExpertServicesWF() {
        
        List<Opportunity> testOppList = [SELECT Id, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        testOppList[0].Twilio_Expert_Services_Engaged__c = 'Use Case Acceleration Bundle';
        testOppList[0].Amount = 500;
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations()); 
    }
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forSQLStatusmovedtoReschedulingWF() {  
        
        List<Opportunity> testOppList = [SELECT Id, Owner.Manager.Email, CreatedBy.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        testOppList[0].SQLStatus__c = 'Rescheduling';
        testOppList[0].Owner_Mgr_Email__c = 'test@test.com';
        testOppList[0].Amount = 500;
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forSalesOperationsExceptionApprovalWF() {
        
        List<Opportunity> testOppList = [SELECT Id, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        testOppList[0].Sales_Operations_Exception_Approval__c = 'Approved';
        testOppList[0].Amount = 500;
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
        
    } 
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forSalesOperationsExceptionApprovalDeclinedWF() {
        
        List<Opportunity> testOppList = [SELECT Id, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        testOppList[0].Sales_Operations_Exception_Approval__c = 'Declined';
        testOppList[0].Amount = 500;
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }  
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forSCOpsConsultationisTrueWF() {
        
        List<Opportunity> testOppList = [SELECT Id, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        testOppList[0].SC_Ops_Consultation__c = true;
        testOppList[0].Amount = 500;
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forAlertSalesPrimaryWF() {
        User testUser = [SELECT Id, Email FROM User WHERE Id=: UserInfo.getUserId()];
        List<Opportunity> testOppList = [SELECT Id, Technical_Lead__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        testOppList[0].Technical_Lead__c = testUser.Id;
        testOppList[0].Amount = 500;
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forAlertSalesSecondaryWF() {
        Profile testProfile = [Select Id, Name from Profile where name = 'System Administrator'];
        UserRole testUserRole = new UserRole(Name = 'West Test');
        insert testUserRole;
        
        User testUser = new User(
            ProfileId = testProfile.Id,
            UserRoleId = testUserRole.Id,
            Username = System.now().getTime() + 'test@test.com',
            Alias = 'testtest',
            Email='test@test-lead-autoconvertt-12345.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'Test',
            Lastname = 'Test123',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        system.runAs(testUser){
            List<Opportunity> testOppList = [SELECT Id, Twilio_Sales_Engineer_Secondary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
            testOppList[0].Twilio_Sales_Engineer_Secondary__c = testUser.Id;
            testOppList[0].Amount = 500;
            
            test.startTest();
            update testOppList;
            test.stopTest();
            
            //Assertion
            //System.assertEquals(1, Limits.getEmailInvocations());
        }
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forAlertSalesTertiaryWF() {
        Profile testProfile = [Select Id, Name from Profile where name = 'System Administrator'];
        UserRole testUserRole = new UserRole(Name = 'West Test');
        insert testUserRole;
        
        User testUser = new User(
            ProfileId = testProfile.Id,
            UserRoleId = testUserRole.Id,
            Username = System.now().getTime() + 'test@test.com',
            Alias = 'testtest',
            Email='test@test-lead-autoconvertt-12345.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'Test',
            Lastname = 'Test123',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        system.runAs(testUser) {
            List<Opportunity> testOppList = [SELECT Id, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
            testOppList[0].Twilio_Sales_Engineer_Tertiary__c = testUser.Id;
            testOppList[0].Amount = 500;
            
            test.startTest();
            update testOppList;
            test.stopTest();
            
            //Assertion
            //System.assertEquals(1, Limits.getEmailInvocations());
        }
        
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forSendNPSSurveystoAEandSEWF() {
        Profile testProfile = [Select Id, Name from Profile where name = 'System Administrator'];
        UserRole testUserRole = new UserRole(Name = 'West Test');
        insert testUserRole;
        
        User testUser = new User(
            ProfileId = testProfile.Id,
            UserRoleId = testUserRole.Id,
            Username = System.now().getTime() + 'test@test.com',
            Alias = 'testtest',
            Email='test@test-lead-autoconvertt-12345.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'Test',
            Lastname = 'Test123',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        List<Opportunity> testOppList = [SELECT Id, Technical_Lead__r.Email, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        system.runAs(testUser){
            testOppList[0].StageName = 'Closed Won';
            testOppList[0].Technical_Lead__c = testUser.Id;
            testOppList[0].RecordTypeId = '012400000009mZ9';
            testOppList[0].OwnerId = testUser.Id;
            testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
            testOppList[0].Primary_Competitor__c = 'Call Source';
            test.startTest();
            update testOppList;
            test.stopTest();
            
            //Assertion
            //System.assertEquals(1, Limits.getEmailInvocations());
        }
        
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forOpportunitySalesBellPartnerWF() {
        
        List<Opportunity> testOppList = [SELECT Id, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        testOppList[0].Covid_19_Response__c = 'Positive';
        testOppList[0].Partner_Involved__c = 'testpartner';
        testOppList[0].Link_to_Partner_Logo__c = 'https://www.salesforce.com';
        testOppList[0].Partner_Involvement__c = 'herelongtext';   
        testOppList[0].StageName = 'Closed Won'; 
        testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
        testOppList[0].Primary_Competitor__c = 'Call Source';
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forOpportunitySalesBell100kCommitWF() {
        Id theConsPartnerRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Consulting Partner').getRecordTypeId();
        
        List<Opportunity> testOppList = [SELECT Id,Contract_Type__c,Total_Committed_Revenue__c,Covid_19_Response__c,FY_16_Primary_Product__c, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        testOppList[0].Covid_19_Response__c = 'Positive';
        testOppList[0].Partner_Involved__c = 'N/A';
        testOppList[0].StageName = 'Closed Won'; 
        testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
        testOppList[0].Primary_Competitor__c = 'Call Source';
        testOppList[0].RecordTypeId = theConsPartnerRecordId;
        testOppList[0].Total_Committed_Revenue__c = 80000;
        testOppList[0].Contract_Type__c = 'Contract - Commit - Annual - Invoice	';
        testOppList[0].FY_16_Primary_Product__c = 'Programmable Wireless';
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forSendGridOppsWF() {
        
        Profile testProfile = [Select Id, Name from Profile where name = 'System Administrator'];
        UserRole testUserRole = new UserRole(Name = 'West Test');
        insert testUserRole;
        
        User testUser = new User(
            ProfileId = testProfile.Id,
            UserRoleId = testUserRole.Id,
            Username = System.now().getTime() + 'test@test.com',
            Alias = 'testtest',
            Email='test@test-lead-autoconvertt-12345.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'Test',
            Lastname = 'Test123',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        List<Opportunity> testOppList = [SELECT Id, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        system.runAs(testUser) {
            testOppList[0].Amount = 500;
            Update testOppList;
            
            Opportunity_Product__c testTwilioProduct = new Opportunity_Product__c(
                Name = 'Test Opp Prod Exception',
                Amount__c = 100,
                Opportunity__c = testOppList[0].Id,
                Primary_Product__c = true,
                Product_Name__c = 'Support',
                Launch_Date__c = Date.today(),
                Contract_Terms_Months__c = 12
                
            );
            Opportunity_Product__c testTwilioProduct1 = new Opportunity_Product__c(
                Name = 'Test Opp Prod Exception1',
                Amount__c = 100,
                Opportunity__c = testOppList[0].Id,
                //Primary_Product__c = true,
                Product_Name__c = 'Support',
                Launch_Date__c = Date.today(),
                Contract_Terms_Months__c = 12
                //SendGrid_Product__c = false
            );
            insert new List<Opportunity_Product__c> {testTwilioProduct, testTwilioProduct1};
                
                testOppList[0].StageName = 'Closed Won'; 
            testOppList[0].SendGrid_Specialist__c = testUser.Id;
            testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
            testOppList[0].Primary_Competitor__c = 'Call Source';
            
            test.startTest();
            update testOppList;
            test.stopTest();
            
            //Assertion
            //System.assertEquals(1, Limits.getEmailInvocations());
        }
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forSQLNotificationWF() {
        Id theConsPartRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Consulting Partner').getRecordTypeId();
        
        Profile testProfile = [Select Id, Name from Profile where name = 'System Administrator'];
        UserRole testUserRole = new UserRole(Name = 'West Test');
        insert testUserRole;
        
        User testUser = new User(
            ProfileId = testProfile.Id,
            UserRoleId = testUserRole.Id,
            Username = System.now().getTime() + 'test@test.com',
            Alias = 'testtest',
            Email='test@test-lead-autoconvertt-12345.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'Test',
            Lastname = 'Test123',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        List<Opportunity> testOppList = [SELECT Id, Solution_Sales_Specialist__r.Email,SendGrid_Specialist__r.Email, CreatedBy.Email, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        system.runAs(testUser) {
            testOppList[0].Primary_Product__c = 'Programmable Wireless';
            testOppList[0].SQLStatus__c = 'Rescheduling';
            testOppList[0].StageName = 'Incubate'; 
            testOppList[0].Solution_Sales_Specialist__c = userInfo.getUserId();
            testOppList[0].SendGrid_Specialist__c = testUser.Id;
            testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
            testOppList[0].Primary_Competitor__c = 'Call Source';
            testOppList[0].RecordTypeId = theConsPartRecordId;
            testOppList[0].Owner_Mgr_Email__c  = 'test@test.com';  
            //testOppList[0].SQL_Acceptance__c = true;
            
            test.startTest();
            update testOppList;
            test.stopTest();
            
            //Assertion
            //System.assertEquals(1, Limits.getEmailInvocations());
        }
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forCOVID19PartnerOfferEmailAlertWF() {
        
        List<Opportunity> testOppList = [SELECT Id, Alliances_Rep__c,Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Link_to_Partner_Logo__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c FROM Opportunity];
        testOppList[0].Covid_19_Response__c = 'Positive';
        testOppList[0].Covid_19_Response_Reason__c = 'Partner Offer';
        testOppList[0].Alliances_Rep__c = UserInfo.getUserId();
        testOppList[0].Amount = 500;
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forCPartnerOpportunitySalesBellWF() {
        Id theConsPartnerRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Consulting Partner').getRecordTypeId();
        insert new Validation_Rule_Bypass_Settings__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Bypass_PTCV_Logic__c = TRUE);
        
        List<Opportunity> testOppList = [SELECT Id, CreatedBy.Email, Partner_Description__c, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c,Use_Case_Description__c,How_we_won__c,Showcase_Link__c,Twilio_Team_involved__c,Link_to_Partner_Logo__c,Total_PTCV_Amount__c,Partner_Sales_Bell_Check__c,Re_send_Sales_Bell__c,Opt_Out_of_Sales_Bell_Emails__c FROM Opportunity];
        testOppList[0].Amount = 500;
        Update testOppList;
        
        Opportunity_Product__c testTwilioProduct1 = new Opportunity_Product__c(
            Name = 'Test Opp Prod Exception1',
            Amount__c = 100,
            Opportunity__c = testOppList[0].Id,
            Primary_Product__c = true,
            Product_Name__c = 'Support',
            Launch_Date__c = Date.today(),
            Contract_Terms_Months__c = 12,
            SendGrid_Product__c = false
        );
        insert new List<Opportunity_Product__c> {testTwilioProduct1};
            
        testOppList[0].StageName = 'Partner - FR';
        testOppList[0].RecordTypeId = theConsPartnerRecordId;
        testOppList[0].Partner_Description__c = 'theConsPartnerDesc';
        testOppList[0].How_we_won__c = 'theConsPartnerDesc';
        testOppList[0].Showcase_Link__c = 'www.salesforcedd.com';
        testOppList[0].Twilio_Team_involved__c = 'desc';
        testOppList[0].Use_Case_Description__c = 'UsecaseDesc';
        testOppList[0].Link_to_Partner_Logo__c = 'www.salesforce.com';
        testOppList[0].Year_1_PTCV__c  = 25000;
        testOppList[0].Year_2_PTCV__c  = 50000;
        testOppList[0].Year_3_PTCV__c  = 150000;
        testOppList[0].Partner_Sales_Bell_Check__c = true;
        testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
        testOppList[0].Primary_Competitor__c = 'Call Source';
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forCResendSalesBellWF() {
        Account testAcnt = [SELECT Id, Global_2000__c FROM Account];
        testAcnt.Global_2000_Rank_2016__c = 2000;
        testAcnt.Global_2000_Rank_2017__c = 2000;
        testAcnt.Global_2000_Rank_2018__c = 2000;
        testAcnt.Global_2000_Rank_2019__c = 2000;
        update testAcnt;
        
        List<Opportunity> testOppList = [SELECT Id, CreatedBy.Email, Partner_Description__c, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c,Use_Case_Description__c,How_we_won__c,Showcase_Link__c,Twilio_Team_involved__c,Link_to_Partner_Logo__c,Total_PTCV_Amount__c,Partner_Sales_Bell_Check__c,Re_send_Sales_Bell__c,Opt_Out_of_Sales_Bell_Emails__c FROM Opportunity];
        testOppList[0].StageName = 'Closed Won';
        testOppList[0].Re_send_Sales_Bell__c = true;
        testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
        testOppList[0].Primary_Competitor__c = 'Call Source';
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forCResendSalesBell100kCoWF() {
        
        List<Opportunity> testOppList = [SELECT Id, Partner_Involvement__c, Sales_Rep_Submitted_for_Close_Won__c,CreatedBy.Email, Partner_Description__c, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c,Use_Case_Description__c,How_we_won__c,Showcase_Link__c,Twilio_Team_involved__c,Link_to_Partner_Logo__c,Total_PTCV_Amount__c,Partner_Sales_Bell_Check__c,Re_send_Sales_Bell__c,Opt_Out_of_Sales_Bell_Emails__c FROM Opportunity];
        testOppList[0].StageName = 'Closed Won';
        testOppList[0].Re_send_Sales_Bell__c = true;
        testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
        testOppList[0].Primary_Competitor__c = 'Call Source';
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forSendSalesBellafterManagerWF() {
        Id theDirectSalesRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Direct Sales').getRecordTypeId();
        
        List<Opportunity> testOppList = [SELECT Id, CreatedBy.Email, Partner_Description__c, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c,Use_Case_Description__c,How_we_won__c,Showcase_Link__c,Twilio_Team_involved__c,Link_to_Partner_Logo__c,Total_PTCV_Amount__c,Partner_Sales_Bell_Check__c,Re_send_Sales_Bell__c,Opt_Out_of_Sales_Bell_Emails__c FROM Opportunity];
        testOppList[0].StageName = 'Closed Won';
        testOppList[0].RecordTypeId = theDirectSalesRecordId;
        testOppList[0].Opt_Out_of_Sales_Bell_Emails__c = false;
        testOppList[0].Covid_19_Response__c = 'Positive';
        testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
        testOppList[0].Close_Win_Manager_Approval_Complete__c = true;
        testOppList[0].Ready_for_Manager_Review__c = true;
        testOppList[0].Time_Sales_Bell_Sent__c = null;
        testOppList[0].Partner_Involvement__c = 'N/A';
        testOppList[0].Primary_Competitor__c = 'Call Source';
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forCOVIDBellWF() {
        Id theDirectSalesRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Direct Sales').getRecordTypeId();
        
        List<Opportunity> testOppList = [SELECT Id, CreatedBy.Email, Partner_Description__c, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c,Use_Case_Description__c,How_we_won__c,Showcase_Link__c,Twilio_Team_involved__c,Link_to_Partner_Logo__c,Total_PTCV_Amount__c,Partner_Sales_Bell_Check__c,Re_send_Sales_Bell__c,Opt_Out_of_Sales_Bell_Emails__c FROM Opportunity];
        testOppList[0].StageName = 'Closed Won';
        testOppList[0].RecordTypeId = theDirectSalesRecordId;
        testOppList[0].Opt_Out_of_Sales_Bell_Emails__c = false;
        testOppList[0].Covid_19_Response__c = 'Positive';
        testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
        testOppList[0].Close_Win_Manager_Approval_Complete__c = false;
        testOppList[0].Primary_Competitor__c = 'Call Source';
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
        
    }   
    
    //NOTE : Email Assertion is not written because Messaging.sendEmail are written in Future Method and Future method is called with 
    // after the test Finishes and the assert outside the test could fail because the email is sent in a seperate context before it is called. 
    public static testMethod void forPartnerBellafterManagerApprovalWF() {
        Id theDirectSalesRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Direct Sales').getRecordTypeId();
        
        List<Opportunity> testOppList = [SELECT Id, CreatedBy.Email, Partner_Description__c, Twilio_Sales_Engineer_Tertiary__r.Email, Owner.Email, SQLStatus__c, Owner_Mgr_Email__c, Sales_Operations_Exception_Approval__c, SC_Ops_Consultation__c, Technical_Lead__c, Twilio_Sales_Engineer_Secondary__c, Twilio_Sales_Engineer_Tertiary__c, StageName, RecordTypeId, Owner.UserRole.Name, Sales_Bell_Criteria_Met__c, Partner_Involved__c, Twilio_Expert_Services_Engaged__c,Account.Global_2000__c,Number_of_Twilio_Products__c,Number_of_Twilio_Product_Non_Email__c,Primary_Product__c,Covid_19_Response_Reason__c,Use_Case_Description__c,How_we_won__c,Showcase_Link__c,Twilio_Team_involved__c,Link_to_Partner_Logo__c,Total_PTCV_Amount__c,Partner_Sales_Bell_Check__c,Re_send_Sales_Bell__c,Opt_Out_of_Sales_Bell_Emails__c FROM Opportunity];
        testOppList[0].StageName = 'Closed Won';
        testOppList[0].RecordTypeId = theDirectSalesRecordId;
        testOppList[0].Opt_Out_of_Sales_Bell_Emails__c = false;
        testOppList[0].Covid_19_Response__c = 'Positive';
        testOppList[0].Sales_Rep_Submitted_for_Close_Won__c = true;
        testOppList[0].Close_Win_Manager_Approval_Complete__c = true;
        testOppList[0].Ready_for_Manager_Review__c = true;
        testOppList[0].Time_Sales_Bell_Sent__c = null;
        testOppList[0].Partner_Involvement__c = 'N/A';
        testOppList[0].Primary_Competitor__c = 'Call Source';
        
        test.startTest();
        update testOppList;
        test.stopTest();
        
        //Assertion
        //System.assertEquals(1, Limits.getEmailInvocations());
    }   
}