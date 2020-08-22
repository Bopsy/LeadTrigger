/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  SignalTicketSplitTriggerServiceTest
*
* @description 	  Test class that contains the unit test related to Signal Ticket Split object..
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu	 <jayu@twilio.com>
* @version        1.0
* @created        2020-02-20
* @modified       Testing VS Code
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*			
**/
@isTest
private class SignalTicketSplitTriggerServiceTest {
	@testSetup static void setup_Agreement_Test_Records() {
        insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
        insert new Validation_Rule_Bypass_Settings__c(SetupOwnerId=UserInfo.getOrganizationId(), Agreement_Dataload_Validation_Bypass__c = TRUE);
        Id ORDER_FORM_RECORDTYPE_ID = [SELECT Id FROM RecordType WHERE DeveloperName = 'Order_Form' LIMIT 1].Id;
        List<User> testSalesUsers = new List<User>();
        List<User> testSalesManagers = new List<User>();
        Integer currentYear = Date.today().year();
        
        List<UserRole> userRolesForInsert = new List<UserRole>();
        for(Integer i = 0; i < 4; i++){
            UserRole tempRole = new UserRole(Name = 'AE - Enterprise - Test ' + i);
            userRolesForInsert.add(tempRole);
        }
        System.runAs(new User(Id = UserInfo.getUserId())){
            insert userRolesForInsert;
            Id salesProfileId = [Select Id from Profile where name = '**Global AM' LIMIT 1].Id;
            testSalesManagers.add(new User(LastName = 'TestManager1',
                                            Email = 'testSalesManager1' + System.now().getTime() + '@example.com.test',
                                            UserName = 'testSalesManager1' + System.now().getTime() + '@example.com.test',
                                            ProfileId = salesProfileId,
                                            UserRoleId = userRolesForInsert[0].Id,
                                            LocaleSidKey = 'en_US',
                                            LanguageLocaleKey = 'en_US',
                                            TimezoneSidKey = 'America/New_York',
                                            EmailEncodingKey = 'UTF-8',
                                          	Alias = 'TMana1'));
            testSalesManagers.add(new User(LastName = 'TestManager2',
                                            Email = 'testSalesManager2' + System.now().getTime() + '@example.com.test',
                                            UserName = 'testSalesManager2' + System.now().getTime() + '@example.com.test',
                                            ProfileId = salesProfileId,
                                            UserRoleId = userRolesForInsert[1].Id,
                                            LocaleSidKey = 'en_US',
                                            LanguageLocaleKey = 'en_US',
                                            TimezoneSidKey = 'America/New_York',
                                            EmailEncodingKey = 'UTF-8',
                                          	Alias = 'TMana2'));
            insert testSalesManagers;
            
            testSalesUsers.add(new User(LastName = 'TestSalesUser1',
                                            Email = 'testSalesUser1' + System.now().getTime() + '@example.com.test',
                                            UserName = 'testSalesUser1' + System.now().getTime() + '@example.com.test',
                                            ProfileId = salesProfileId,
                                            UserRoleId = userRolesForInsert[2].Id,
                                            LocaleSidKey = 'en_US',
                                            LanguageLocaleKey = 'en_US',
                                            TimezoneSidKey = 'America/New_York',
                                            EmailEncodingKey = 'UTF-8',
                                        	Alias = 'TSale1',
                                            ManagerId = testSalesManagers[0].Id));
            testSalesUsers.add(new User(LastName = 'TestSalesUser2',
                                            Email = 'testSalesUser2' + System.now().getTime() + '@example.com.test',
                                            UserName = 'testSalesUser2' + System.now().getTime() + '@example.com.test',
                                            ProfileId = salesProfileId,
                                            UserRoleId = userRolesForInsert[3].Id,
                                            LocaleSidKey = 'en_US',
                                            LanguageLocaleKey = 'en_US',
                                            TimezoneSidKey = 'America/New_York',
                                            EmailEncodingKey = 'UTF-8',
                                        	Alias = 'TSale2',
                                            ManagerId = testSalesManagers[1].Id));
            testSalesUsers.add(new User(LastName = 'TestSalesUser3',
                                            Email = 'testSalesUser3' + System.now().getTime() + '@example.com.test',
                                            UserName = 'testSalesUser3' + System.now().getTime() + '@example.com.test',
                                            ProfileId = salesProfileId,
                                            UserRoleId = userRolesForInsert[3].Id,
                                            LocaleSidKey = 'en_US',
                                            LanguageLocaleKey = 'en_US',
                                            TimezoneSidKey = 'America/New_York',
                                            EmailEncodingKey = 'UTF-8',
                                        	Alias = 'TSale3',
                                            ManagerId = testSalesManagers[0].Id));
            insert testSalesUsers;
        }
        
        List<Signal_Ticket_Quota__c> quotaRecs = new List<Signal_Ticket_Quota__c>();
        for(User managerUser : testSalesManagers){
            Signal_Ticket_Quota__c signalTicketQuota = new Signal_Ticket_Quota__c(OwnerId = managerUser.Id,
                                                                                  Quota__c = 200,
                                                                                  Year__c = currentYear,
                                                                                  Ticket_Credits__c = 0);
            quotaRecs.add(signalTicketQuota);
        }
        
        for(User salesUser : testSalesUsers){
            Signal_Ticket_Quota__c signalTicketQuota = new Signal_Ticket_Quota__c(OwnerId = salesUser.Id,
                                                                                  Quota__c = 200,
                                                                                  Year__c = currentYear,
                                                                                  Ticket_Credits__c = 0);
            quotaRecs.add(signalTicketQuota);
        }
        insert quotaRecs;
        
        Integer numberOfRecords = 4;
        Id orderFormRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Order_Form'].Id;
        
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Account_SID__c sid = new Account_SID__c(Name = 'Test SID');
        insert sid;
        
        List<Opportunity> oppsForInsert = new List<Opportunity>();
        
        for(Integer i = 0; i < numberOfRecords; i++){
            Opportunity newOpp = new Opportunity(Name= 'Test Opp', AccountId = testAcc.Id,
                                                 ForecastCategoryName='Commit', StageName = 'Incubate', 
                                                 CloseDate = Date.today(), Amount = 100, 
                                                 Year_1_Committed_Bookings__c =100,
                                                 OwnerId = testSalesUsers[0].Id);
            
            oppsForInsert.add(newOpp);
        }
        insert oppsForInsert;
        
        Date deadlineDate = Date.today().addDays(200);
        List<Apttus__APTS_Agreement__c> agrsForInsert = new List<Apttus__APTS_Agreement__c>();
        for(Integer i = 0; i < numberOfRecords; i++){
            Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c=testAcc.id,
                                                                                    Related_Opportunity_APTS__c= oppsForInsert[i].id,
                                                                                    Total_Committed_Revenue_Input__c = 5000, 
                                                                                    Commit_Frequency__c = 'Monthly', Term_Range__c = '12', 
                                                                                    APTS_Agreement_Effective_Date__c= Date.newInstance(2017,10,3),
                                                                                    Commit_Start_Month__c = Date.newInstance(2017,10,3),
                                                                                    Apttus__Status__c = 'Initiate',Authy_Commit__c = 100,
                                                                                    Programmable_Messaging_Commit__c = 200,
                                                                                    Customer_Signature_Deadline__c = deadlineDate,
                                                                                    RecordTypeId = ORDER_FORM_RECORDTYPE_ID);
            if(i < 2){
                testAgreement.OwnerId = testSalesUsers[0].Id;
            } else {
                testAgreement.OwnerId = testSalesUsers[1].Id;
            }
        	agrsForInsert.add(testAgreement);
        }
        insert agrsForInsert;
        
        List<Billable_Item__c> bisForInsert = new List<Billable_Item__c>();
        Billable_Item__c testSignalTicketBI = new Billable_Item__c(Name = 'Signal Ticket', 
                                                                   Price__c = 1.0, 
                                                                   Status__c = 'Active');
        
        Billable_Item__c testSignalTicketSuperclassBI = new Billable_Item__c(Name = 'Signal Ticket + Superclass', 
                                                                             Price__c = 1.0, 
                                                                             Status__c = 'Active');
        bisForInsert.add(testSignalTicketBI);
        bisForInsert.add(testSignalTicketSuperclassBI);
        insert bisForInsert;
        
        List<Signal_Ticket_Billable_Item_SFDC_ID__c> signalTicketBIs = new List<Signal_Ticket_Billable_Item_SFDC_ID__c>();
        signalTicketBIs.add(new Signal_Ticket_Billable_Item_SFDC_ID__c(Name = testSignalTicketBI.Id));
        signalTicketBIs.add(new Signal_Ticket_Billable_Item_SFDC_ID__c(Name = testSignalTicketSuperclassBI.Id));
        insert signalTicketBIs;
        
        List<Signal_Ticket_Attribution_Field_Mapping__c> signalTicketFieldMapping = new List<Signal_Ticket_Attribution_Field_Mapping__c>();
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Account',
                                                                                    Source_Field_API_Name__c = 'Apttus__Account__c',
                                                                                    Signal_Ticket_API_Name__c = 'Account__c'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Account Owner',
                                                                                    Source_Field_API_Name__c = 'Apttus__Account__r.Owner.Full_Name__c',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Stamp__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Secondary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Account Owner Id',
                                                                                    Source_Field_API_Name__c = 'Apttus__Account__r.OwnerId',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Ticket_Credit__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Secondary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Account Owner Manager',
                                                                                    Source_Field_API_Name__c = 'Apttus__Account__r.Owner.Manager.Full_Name__c',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Mgr_Stamp__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Secondary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Account Owner Manager Id',
                                                                                    Source_Field_API_Name__c = 'Apttus__Account__r.Owner.ManagerId',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Manager_Ticket_Credit__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Secondary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Account Owner Sub Region',
                                                                                    Source_Field_API_Name__c = 'Apttus__Account__r.Owner.Sub_Region__c',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Sub_Region_Stamp__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Secondary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Account Owner Sub Team',
                                                                                    Source_Field_API_Name__c = 'Apttus__Account__r.Owner.Sub_Team__c',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Region_Stamp__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Secondary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Opportunity Owner',
                                                                                    Source_Field_API_Name__c = 'Related_Opportunity_APTS__r.Owner.Full_Name__c',
                                                                                    Signal_Ticket_API_Name__c = 'Sales_Rep_Stamp__c',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Stamp__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Primary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Opportunity Owner Id',
                                                                                    Source_Field_API_Name__c = 'Related_Opportunity_APTS__r.OwnerId',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Ticket_Credit__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Primary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Opportunity Owner Manager',
                                                                                    Source_Field_API_Name__c = 'Related_Opportunity_APTS__r.Owner.Manager.Full_Name__c',
                                                                                    Signal_Ticket_API_Name__c = 'Sales_Rep_Mgr_Stamp__c',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Mgr_Stamp__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Primary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Opportunity Owner Manager Id',
                                                                                    Source_Field_API_Name__c = 'Related_Opportunity_APTS__r.Owner.ManagerId',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Manager_Ticket_Credit__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Primary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Opportunity Owner Manager Team',
                                                                                    Source_Field_API_Name__c = 'Related_Opportunity_APTS__r.Owner.Manager.Role_Team__c',
                                                                                    Signal_Ticket_API_Name__c = 'Sales_Rep_Mgr_Team_Stamp__c'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Opportunity Owner Region',
                                                                                    Source_Field_API_Name__c = 'Related_Opportunity_APTS__r.Owner.Sub_Team__c',
                                                                                    Signal_Ticket_API_Name__c = 'Sales_Rep_Region_Stamp__c',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Region_Stamp__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Primary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Opportunity Owner Sub Region',
                                                                                    Source_Field_API_Name__c = 'Related_Opportunity_APTS__r.Owner.Sub_Region__c',
                                                                                    Signal_Ticket_API_Name__c = 'Sales_Rep_Sub_Region_Stamp__c',
                                                                                    Signal_Ticket_Split_API_Name__c = 'Sales_Rep_Sub_Region_Stamp__c',
                                                                                    Signal_Ticket_Split_Type__c = 'Primary'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Opportunity Owner Team',
                                                                                    Source_Field_API_Name__c = 'Related_Opportunity_APTS__r.Owner.Role_Team__c',
                                                                                    Signal_Ticket_API_Name__c = 'Sales_Rep_Team_Stamp__c'));
        signalTicketFieldMapping.add(new Signal_Ticket_Attribution_Field_Mapping__c(Name = 'Order Form',
                                                                                    Source_Field_API_Name__c = 'Id',
                                                                                    Signal_Ticket_API_Name__c = 'Order_Form__c'));
        insert signalTicketFieldMapping;
        
        List<Single_BI_Discount__c> singleBIDiscountsForInsert = new List<Single_BI_Discount__c>();
        for(Integer i = 0; i < numberOfRecords; i++){
            singleBIDiscountsForInsert.add(new Single_BI_Discount__c(Billable_Item__c = testSignalTicketBI.Id, 
                                                                     Agreement__c = agrsForInsert[i].Id, 
                                                                     Name = 'test Signal Ticket' + i));
            singleBIDiscountsForInsert.add(new Single_BI_Discount__c(Billable_Item__c = testSignalTicketSuperclassBI.Id, 
                                                                     Agreement__c = agrsForInsert[i].Id, 
                                                                     Name = 'test Signal Ticket Superclass' + i));
        }
        insert singleBIDiscountsForInsert;
    }
    
    //Test Method ensures that Signal Ticket Quotas get calculated correctly when Signal Ticket Splits are Inserted.
    static testMethod void ensure_Single_Ticket_Quota_Gets_Updated_On_Signal_Ticket_Split_Insert(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        User testSalesUser3 = new User();
        User testSalesManager1 = new User();
        User testSalesManager2 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            } else if (u.LastName == 'TestSalesUser3'){
                testSalesUser3 = u;
            }else if (u.LastName == 'TestManager1'){
                testSalesManager1 = u;
            } else if (u.LastName == 'TestManager2'){
                testSalesManager2 = u;
            }
        }
        
        Signal_Ticket_Quota__c testSalesUser1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser2Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser3Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager2Quota = new Signal_Ticket_Quota__c();
        
        List<Signal_Ticket_Quota__c> quotaRecs = [SELECT Id,
                                                 		 OwnerId,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                testSalesUser1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                testSalesUser2Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                testSalesUser3Quota = quotaRec;
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                testSalesManager1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                testSalesManager2Quota = quotaRec;
            }
            System.assertEquals(0, quotaRec.Ticket_Credits__c);
        }

		List<Signal_Ticket__c> signalTickets = new List<Signal_Ticket__c>();        
        Signal_Ticket__c signalTicketRec1 = new Signal_Ticket__c(Quantity__c = 100);
        Signal_Ticket__c signalTicketRec2 = new Signal_Ticket__c(Quantity__c = 200);
        Signal_Ticket__c signalTicketRec3 = new Signal_Ticket__c(Quantity__c = 300);
        Signal_Ticket__c signalTicketRec4 = new Signal_Ticket__c(Quantity__c = 400);
        signalTickets.add(signalTicketRec1);
        signalTickets.add(signalTicketRec2);
        signalTickets.add(signalTicketRec3);
        signalTickets.add(signalTicketRec4);
        insert signalTickets;
        
        List<Signal_Ticket_Split__c> signalTicketSplits = new List<Signal_Ticket_Split__c>();
        for(Signal_Ticket__c signalTicket : signalTickets){
            Signal_Ticket_Split__c ticketSplitPrimary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser1.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager1.Id);
            signalTicketSplits.add(ticketSplitPrimary);
            
            Signal_Ticket_Split__c ticketSplitSecondary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser2.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager2.Id);
            signalTicketSplits.add(ticketSplitSecondary);
        }
        insert signalTicketSplits;
        
        List<Signal_Ticket_Quota__c> quotaRecs2 = [SELECT Id,
                                                 		 OwnerId,
                                                   		 Owner.Name,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs2){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            }
        }
		
        Signal_Ticket_Split__c addSplit = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicketRec1.Id,
                                                                     Sales_Rep_Ticket_Credit__c = testSalesUser1.Id,
                                                                     Sales_Manager_Ticket_Credit__c = testSalesManager2.Id);
        Test.startTest();
        insert addSplit;
        Test.stopTest();
        
        List<Signal_Ticket_Quota__c> quotaRecsForReview = [SELECT Id,
                                                                  OwnerId,
                                                                  Owner.Name,
                                                                  Year__c,
                                                                  Ticket_Credits__c
                                                           FROM Signal_Ticket_Quota__c];
        
        System.assertEquals(5, quotaRecsForReview.size());
        for(Signal_Ticket_Quota__c quotaRec : quotaRecsForReview){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(1100, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(1100, quotaRec.Ticket_Credits__c);
            }
        }
    }
    
    //Test Method ensures that Signal Ticket Quotas get calculated correctly when Signal Ticket are Updated.
    static testMethod void ensure_Single_Ticket_Quota_Gets_Updated_On_Signal_Ticket_Update(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        User testSalesUser3 = new User();
        User testSalesManager1 = new User();
        User testSalesManager2 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            } else if (u.LastName == 'TestSalesUser3'){
                testSalesUser3 = u;
            }else if (u.LastName == 'TestManager1'){
                testSalesManager1 = u;
            } else if (u.LastName == 'TestManager2'){
                testSalesManager2 = u;
            }
        }
        
        Signal_Ticket_Quota__c testSalesUser1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser2Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser3Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager2Quota = new Signal_Ticket_Quota__c();
        
        List<Signal_Ticket_Quota__c> quotaRecs = [SELECT Id,
                                                 		 OwnerId,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                testSalesUser1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                testSalesUser2Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                testSalesUser3Quota = quotaRec;
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                testSalesManager1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                testSalesManager2Quota = quotaRec;
            }
            System.assertEquals(0, quotaRec.Ticket_Credits__c);
        }

		List<Signal_Ticket__c> signalTickets = new List<Signal_Ticket__c>();        
        Signal_Ticket__c signalTicketRec1 = new Signal_Ticket__c(Quantity__c = 100);
        Signal_Ticket__c signalTicketRec2 = new Signal_Ticket__c(Quantity__c = 200);
        Signal_Ticket__c signalTicketRec3 = new Signal_Ticket__c(Quantity__c = 300);
        Signal_Ticket__c signalTicketRec4 = new Signal_Ticket__c(Quantity__c = 400);
        signalTickets.add(signalTicketRec1);
        signalTickets.add(signalTicketRec2);
        signalTickets.add(signalTicketRec3);
        signalTickets.add(signalTicketRec4);
        insert signalTickets;
        
        List<Signal_Ticket_Split__c> signalTicketSplits = new List<Signal_Ticket_Split__c>();
        for(Signal_Ticket__c signalTicket : signalTickets){
            Signal_Ticket_Split__c ticketSplitPrimary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser1.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager1.Id);
            signalTicketSplits.add(ticketSplitPrimary);
            
            Signal_Ticket_Split__c ticketSplitSecondary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser2.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager2.Id);
            signalTicketSplits.add(ticketSplitSecondary);
        }
        insert signalTicketSplits;
        
        List<Signal_Ticket_Quota__c> quotaRecs2 = [SELECT Id,
                                                 		 OwnerId,
                                                   		 Owner.Name,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs2){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            }
        }
		
        List<Signal_Ticket__c> signalTicketsForUpdate = new List<Signal_Ticket__c>();
        signalTicketRec1.Quantity__c = 10; //Was 100
        signalTicketRec4.Quantity__c = 450; //Was 400
		signalTicketsForUpdate.add(signalTicketRec1);
        signalTicketsForUpdate.add(signalTicketRec4);
        
        Test.startTest();
        update signalTicketsForUpdate;
        Test.stopTest();
        
        List<Signal_Ticket_Quota__c> quotaRecsForReview = [SELECT Id,
                                                                  OwnerId,
                                                                  Owner.Name,
                                                                  Year__c,
                                                                  Ticket_Credits__c
                                                           FROM Signal_Ticket_Quota__c];
        
        System.assertEquals(5, quotaRecsForReview.size());
        for(Signal_Ticket_Quota__c quotaRec : quotaRecsForReview){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(960, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(960, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(960, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(960, quotaRec.Ticket_Credits__c);
            }
        }
    }
    
    //Test Method ensures that Signal Ticket Quotas get calculated correctly when Signal Ticket Splits are Updated.
    static testMethod void ensure_Single_Ticket_Quota_Gets_Updated_On_Signal_Ticket_Split_Update(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        User testSalesUser3 = new User();
        User testSalesManager1 = new User();
        User testSalesManager2 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            } else if (u.LastName == 'TestSalesUser3'){
                testSalesUser3 = u;
            }else if (u.LastName == 'TestManager1'){
                testSalesManager1 = u;
            } else if (u.LastName == 'TestManager2'){
                testSalesManager2 = u;
            }
        }
        
        Signal_Ticket_Quota__c testSalesUser1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser2Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser3Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager2Quota = new Signal_Ticket_Quota__c();
        
        List<Signal_Ticket_Quota__c> quotaRecs = [SELECT Id,
                                                 		 OwnerId,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                testSalesUser1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                testSalesUser2Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                testSalesUser3Quota = quotaRec;
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                testSalesManager1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                testSalesManager2Quota = quotaRec;
            }
            System.assertEquals(0, quotaRec.Ticket_Credits__c);
        }

		List<Signal_Ticket__c> signalTickets = new List<Signal_Ticket__c>();        
        Signal_Ticket__c signalTicketRec1 = new Signal_Ticket__c(Quantity__c = 100);
        Signal_Ticket__c signalTicketRec2 = new Signal_Ticket__c(Quantity__c = 200);
        Signal_Ticket__c signalTicketRec3 = new Signal_Ticket__c(Quantity__c = 300);
        Signal_Ticket__c signalTicketRec4 = new Signal_Ticket__c(Quantity__c = 400);
        signalTickets.add(signalTicketRec1);
        signalTickets.add(signalTicketRec2);
        signalTickets.add(signalTicketRec3);
        signalTickets.add(signalTicketRec4);
        insert signalTickets;
        
        List<Signal_Ticket_Split__c> signalTicketSplits = new List<Signal_Ticket_Split__c>();
        for(Signal_Ticket__c signalTicket : signalTickets){
            Signal_Ticket_Split__c ticketSplitPrimary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser1.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager1.Id);
            signalTicketSplits.add(ticketSplitPrimary);
            
            Signal_Ticket_Split__c ticketSplitSecondary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser2.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager2.Id);
            signalTicketSplits.add(ticketSplitSecondary);
        }
        insert signalTicketSplits;
        
        List<Signal_Ticket_Quota__c> quotaRecs2 = [SELECT Id,
                                                 		 OwnerId,
                                                   		 Owner.Name,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs2){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            }
        }
		
        List<Signal_Ticket_Split__c> signalTicketSplitsForUpdate = new List<Signal_Ticket_Split__c>();
        List<Signal_Ticket_Split__c> signalTicketSplitsForReview = [SELECT Id,
                                                                           Sales_Rep_Quota__c,
                                                                           Sales_Manager_Quota__c
                                                                    FROM Signal_Ticket_Split__c];
        for(Signal_Ticket_Split__c splitRec : signalTicketSplitsForReview){
            if(splitRec.Sales_Rep_Quota__c != testSalesUser1Quota.Id){
                splitRec.Sales_Rep_Quota__c = testSalesUser1Quota.Id;
            } 
            if(splitRec.Sales_Manager_Quota__c != testSalesManager1Quota.Id){
                splitRec.Sales_Manager_Quota__c = testSalesManager1Quota.Id;
            }
            signalTicketSplitsForUpdate.add(splitRec);
        }
        
        Test.startTest();
        update signalTicketSplitsForUpdate;
        Test.stopTest();
        
        List<Signal_Ticket_Quota__c> quotaRecsForReview = [SELECT Id,
                                                                  OwnerId,
                                                                  Owner.Name,
                                                                  Year__c,
                                                                  Ticket_Credits__c
                                                           FROM Signal_Ticket_Quota__c];
        
        System.assertEquals(5, quotaRecsForReview.size());
        for(Signal_Ticket_Quota__c quotaRec : quotaRecsForReview){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(2000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(2000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }
        }
    }
    
    //Test Method ensures that Signal Ticket Quotas get calculated correctly when Signal Ticket Splits are Updated.
    static testMethod void ensure_Single_Ticket_Quota_Gets_Updated_If_Rep_Is_Also_Manager(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        User testSalesUser3 = new User();
        User testSalesManager1 = new User();
        User testSalesManager2 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            } else if (u.LastName == 'TestSalesUser3'){
                testSalesUser3 = u;
            }else if (u.LastName == 'TestManager1'){
                testSalesManager1 = u;
            } else if (u.LastName == 'TestManager2'){
                testSalesManager2 = u;
            }
        }
        
        Signal_Ticket_Quota__c testSalesUser1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser2Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser3Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager2Quota = new Signal_Ticket_Quota__c();
        
        List<Signal_Ticket_Quota__c> quotaRecs = [SELECT Id,
                                                 		 OwnerId,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                testSalesUser1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                testSalesUser2Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                testSalesUser3Quota = quotaRec;
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                testSalesManager1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                testSalesManager2Quota = quotaRec;
            }
            System.assertEquals(0, quotaRec.Ticket_Credits__c);
        }

		List<Signal_Ticket__c> signalTickets = new List<Signal_Ticket__c>();        
        Signal_Ticket__c signalTicketRec1 = new Signal_Ticket__c(Quantity__c = 100);
        Signal_Ticket__c signalTicketRec2 = new Signal_Ticket__c(Quantity__c = 200);
        Signal_Ticket__c signalTicketRec3 = new Signal_Ticket__c(Quantity__c = 300);
        Signal_Ticket__c signalTicketRec4 = new Signal_Ticket__c(Quantity__c = 400);
        signalTickets.add(signalTicketRec1);
        signalTickets.add(signalTicketRec2);
        signalTickets.add(signalTicketRec3);
        signalTickets.add(signalTicketRec4);
        insert signalTickets;
        
        List<Signal_Ticket_Split__c> signalTicketSplits = new List<Signal_Ticket_Split__c>();
        for(Signal_Ticket__c signalTicket : signalTickets){
            Signal_Ticket_Split__c ticketSplitPrimary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser1.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager1.Id);
            signalTicketSplits.add(ticketSplitPrimary);
            
            Signal_Ticket_Split__c ticketSplitSecondary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser2.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager2.Id);
            signalTicketSplits.add(ticketSplitSecondary);
        }
        insert signalTicketSplits;
        
        List<Signal_Ticket_Quota__c> quotaRecs2 = [SELECT Id,
                                                 		 OwnerId,
                                                   		 Owner.Name,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs2){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            }
        }
		
        //Test Sales User 1 is now set as the Manager of some signal ticket split records.
        List<Signal_Ticket_Split__c> signalTicketSplitsForUpdate = new List<Signal_Ticket_Split__c>();
        List<Signal_Ticket_Split__c> signalTicketSplitsForReview = [SELECT Id,
                                                                           Sales_Rep_Quota__c,
                                                                           Sales_Manager_Quota__c
                                                                    FROM Signal_Ticket_Split__c];
        for(Signal_Ticket_Split__c splitRec : signalTicketSplitsForReview){
            if(splitRec.Sales_Manager_Quota__c != testSalesManager1Quota.Id){
                splitRec.Sales_Manager_Quota__c = testSalesUser1Quota.Id;
            }
            signalTicketSplitsForUpdate.add(splitRec);
        }
        
        Test.startTest();
        update signalTicketSplitsForUpdate;
        Test.stopTest();
        
        List<Signal_Ticket_Quota__c> quotaRecsForReview = [SELECT Id,
                                                                  OwnerId,
                                                                  Owner.Name,
                                                                  Year__c,
                                                                  Ticket_Credits__c
                                                           FROM Signal_Ticket_Quota__c];
        
        System.assertEquals(5, quotaRecsForReview.size());
        for(Signal_Ticket_Quota__c quotaRec : quotaRecsForReview){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(2000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }
        }
    }
    
    //Test Method ensures that Signal Ticket Quotas get calculated correctly when Signal Ticket Splits are deleted.
    static testMethod void ensure_Single_Ticket_Quota_Gets_Updated_On_Signal_Ticket_Split_Delete(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        User testSalesUser3 = new User();
        User testSalesManager1 = new User();
        User testSalesManager2 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            } else if (u.LastName == 'TestSalesUser3'){
                testSalesUser3 = u;
            }else if (u.LastName == 'TestManager1'){
                testSalesManager1 = u;
            } else if (u.LastName == 'TestManager2'){
                testSalesManager2 = u;
            }
        }
        
        Signal_Ticket_Quota__c testSalesUser1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser2Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser3Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager2Quota = new Signal_Ticket_Quota__c();
        
        List<Signal_Ticket_Quota__c> quotaRecs = [SELECT Id,
                                                 		 OwnerId,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                testSalesUser1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                testSalesUser2Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                testSalesUser3Quota = quotaRec;
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                testSalesManager1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                testSalesManager2Quota = quotaRec;
            }
            System.assertEquals(0, quotaRec.Ticket_Credits__c);
        }

		List<Signal_Ticket__c> signalTickets = new List<Signal_Ticket__c>();        
        Signal_Ticket__c signalTicketRec1 = new Signal_Ticket__c(Quantity__c = 100);
        Signal_Ticket__c signalTicketRec2 = new Signal_Ticket__c(Quantity__c = 200);
        Signal_Ticket__c signalTicketRec3 = new Signal_Ticket__c(Quantity__c = 300);
        Signal_Ticket__c signalTicketRec4 = new Signal_Ticket__c(Quantity__c = 400);
        signalTickets.add(signalTicketRec1);
        signalTickets.add(signalTicketRec2);
        signalTickets.add(signalTicketRec3);
        signalTickets.add(signalTicketRec4);
        insert signalTickets;
        
        List<Signal_Ticket_Split__c> signalTicketSplits = new List<Signal_Ticket_Split__c>();
        for(Signal_Ticket__c signalTicket : signalTickets){
            Signal_Ticket_Split__c ticketSplitPrimary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser1.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager1.Id);
            signalTicketSplits.add(ticketSplitPrimary);
            
            Signal_Ticket_Split__c ticketSplitSecondary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser2.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager2.Id);
            signalTicketSplits.add(ticketSplitSecondary);
        }
        insert signalTicketSplits;
        
        List<Signal_Ticket_Quota__c> quotaRecs2 = [SELECT Id,
                                                 		 OwnerId,
                                                   		 Owner.Name,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs2){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            }
        }
		
        //List<Signal_Ticket_Split__c> signalTicketSplitsForUpdate = new List<Signal_Ticket_Split__c>();
        List<Signal_Ticket_Split__c> signalTicketSplitsForReview = [SELECT Id,
                                                                    	   Signal_Ticket_Quantity__c,
                                                                           Sales_Rep_Quota__c,
                                                                           Sales_Manager_Quota__c
                                                                    FROM Signal_Ticket_Split__c
                                                                    WHERE Signal_Ticket_Quantity__c = 400];
        
        Test.startTest();
        delete signalTicketSplitsForReview;
        Test.stopTest();
        
        List<Signal_Ticket_Quota__c> quotaRecsForReview = [SELECT Id,
                                                                  OwnerId,
                                                                  Owner.Name,
                                                                  Year__c,
                                                                  Ticket_Credits__c
                                                           FROM Signal_Ticket_Quota__c];
        
        System.assertEquals(5, quotaRecsForReview.size());
        for(Signal_Ticket_Quota__c quotaRec : quotaRecsForReview){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(600, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(600, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(600, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(600, quotaRec.Ticket_Credits__c);
            }
        }
    }
    
    //Test Method ensures that Signal Ticket Quotas get calculated correctly when Signal Tickets are updated to Canceled.
    static testMethod void ensure_Single_Ticket_Quota_Gets_Updated_On_Signal_Ticket_Cancelation(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        User testSalesUser3 = new User();
        User testSalesManager1 = new User();
        User testSalesManager2 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            } else if (u.LastName == 'TestSalesUser3'){
                testSalesUser3 = u;
            }else if (u.LastName == 'TestManager1'){
                testSalesManager1 = u;
            } else if (u.LastName == 'TestManager2'){
                testSalesManager2 = u;
            }
        }
        
        Signal_Ticket_Quota__c testSalesUser1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser2Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesUser3Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager1Quota = new Signal_Ticket_Quota__c();
        Signal_Ticket_Quota__c testSalesManager2Quota = new Signal_Ticket_Quota__c();
        
        List<Signal_Ticket_Quota__c> quotaRecs = [SELECT Id,
                                                 		 OwnerId,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                testSalesUser1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                testSalesUser2Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                testSalesUser3Quota = quotaRec;
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                testSalesManager1Quota = quotaRec;
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                testSalesManager2Quota = quotaRec;
            }
            System.assertEquals(0, quotaRec.Ticket_Credits__c);
        }

		List<Signal_Ticket__c> signalTickets = new List<Signal_Ticket__c>();        
        Signal_Ticket__c signalTicketRec1 = new Signal_Ticket__c(Quantity__c = 100);
        Signal_Ticket__c signalTicketRec2 = new Signal_Ticket__c(Quantity__c = 200);
        Signal_Ticket__c signalTicketRec3 = new Signal_Ticket__c(Quantity__c = 300);
        Signal_Ticket__c signalTicketRec4 = new Signal_Ticket__c(Quantity__c = 400);
        signalTickets.add(signalTicketRec1);
        signalTickets.add(signalTicketRec2);
        signalTickets.add(signalTicketRec3);
        signalTickets.add(signalTicketRec4);
        insert signalTickets;
        
        List<Signal_Ticket_Split__c> signalTicketSplits = new List<Signal_Ticket_Split__c>();
        for(Signal_Ticket__c signalTicket : signalTickets){
            Signal_Ticket_Split__c ticketSplitPrimary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser1.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager1.Id);
            signalTicketSplits.add(ticketSplitPrimary);
            
            Signal_Ticket_Split__c ticketSplitSecondary = new Signal_Ticket_Split__c(Signal_Ticket__c = signalTicket.Id,
                                                                                Sales_Rep_Ticket_Credit__c = testSalesUser2.Id,
                                                                                Sales_Manager_Ticket_Credit__c = testSalesManager2.Id);
            signalTicketSplits.add(ticketSplitSecondary);
        }
        insert signalTicketSplits;
        
        List<Signal_Ticket_Quota__c> quotaRecs2 = [SELECT Id,
                                                 		 OwnerId,
                                                   		 Owner.Name,
                                                 		 Year__c,
                                                 		 Ticket_Credits__c
                                                  FROM Signal_Ticket_Quota__c];
        
        for(Signal_Ticket_Quota__c quotaRec : quotaRecs2){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(1000, quotaRec.Ticket_Credits__c);
            }
        }
		
        List<Signal_Ticket__c> signalTicketsForUpdate = new List<Signal_Ticket__c>();
        //signalTicketRec1.Quantity__c = 10; //Was 100
        //signalTicketRec4.Quantity__c = 450; //Was 400
        signalTicketRec1.Signal_Ticket_Status__c = 'Canceled';
        signalTicketRec4.Signal_Ticket_Status__c = 'Canceled';
		signalTicketsForUpdate.add(signalTicketRec1);
        signalTicketsForUpdate.add(signalTicketRec4);
        
        Test.startTest();
        update signalTicketsForUpdate;
        Test.stopTest();
        
        List<Signal_Ticket_Quota__c> quotaRecsForReview = [SELECT Id,
                                                                  OwnerId,
                                                                  Owner.Name,
                                                                  Year__c,
                                                                  Ticket_Credits__c
                                                           FROM Signal_Ticket_Quota__c];
        
        System.assertEquals(5, quotaRecsForReview.size());
        Integer quotaRecsReviewed = 0;
        for(Signal_Ticket_Quota__c quotaRec : quotaRecsForReview){
            if(quotaRec.OwnerId == testSalesUser1.Id){
                System.assertEquals(500, quotaRec.Ticket_Credits__c);
                quotaRecsReviewed++;
            } else if (quotaRec.OwnerId == testSalesUser2.Id){
                System.assertEquals(500, quotaRec.Ticket_Credits__c);
                quotaRecsReviewed++;
            } else if (quotaRec.OwnerId == testSalesUser3.Id){
                System.assertEquals(0, quotaRec.Ticket_Credits__c);
                quotaRecsReviewed++;
            }else if (quotaRec.OwnerId == testSalesManager1.Id){
                System.assertEquals(500, quotaRec.Ticket_Credits__c);
                quotaRecsReviewed++;
            } else if (quotaRec.OwnerId == testSalesManager2.Id){
                System.assertEquals(500, quotaRec.Ticket_Credits__c);
                quotaRecsReviewed++;
            }
        }
        System.assertEquals(5, quotaRecsReviewed);
    }
}