/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  SignalTicketHelperTest
*
* @description 	  Test class that contains the unit test related to Signal Ticket object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu	 <jayu@twilio.com>
* @version        1.0
* @created        2020-01-10
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*			
**/
@isTest
private class SignalTicketHelperTest {
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
    
    //Test Method ensures that only one Signal Ticket, but two Signal Ticket Splits get created and assigned to
    //the correct Salesperson.
    static testMethod void ensure_Single_Ticket_Attribution_Works_With_Different_Opp_And_Account_Owner(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email, 
                                     		Profile.Name, 
                                     		UserRole.Name,
                                     		Full_Name__c,
                                     	    Manager.Full_Name__c,
                                     	    Manager.Role_Team__c,
                                     	    Sub_Team__c,
                                     		Sub_Region__c,
                                     		Role_Team__c
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        User testSalesManager1 = new User();
        User testSalesManager2 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            } else if (u.LastName == 'TestSalesManager1'){
                testSalesManager1 = u;
            } else if (u.LastName == 'TestSalesManager2'){
                testSalesManager2 = u;
            }
        }
        
        Apttus__APTS_Agreement__c agreementForReview = [SELECT Id, 
                                                        	   OwnerId,
                                                        	   Owner.Name,
                                                        	   Related_Opportunity_APTS__r.Owner.Name,
                                                        	   Related_Opportunity_APTS__c,
                                                        	   Apttus__Account__r.OwnerId,
                                                        	   Apttus__Account__c
                                                        FROM Apttus__APTS_Agreement__c LIMIT 1];
        Single_BI_Discount__c singleBIDiscount = [SELECT Id, Billable_Item__r.Name, Agreement__c, Agreement__r.Name
                                                  FROM Single_BI_Discount__c WHERE Agreement__c = :agreementForReview.Id LIMIT 1];
        singleBIDiscount.Quantity__c = 10;
        update singleBIDiscount;
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :agreementForReview.Related_Opportunity_APTS__c];
        opp.OwnerId = testSalesUser1.Id;
        update opp;
        
        Account accountRec = [SELECT Id FROM Account WHERE Id = :agreementForReview.Apttus__Account__c];
        accountRec.ownerId = testSalesUser2.Id;
        update accountRec;
        
        agreementForReview.Apttus__Status__c = 'Activated';
        Test.startTest();
        update agreementForReview;
        Test.stopTest();
        
        List<Signal_Ticket__c> signalTicket = [SELECT Id, 
                                                      Sales_Rep_Stamp__c,
                                               		  Sales_Rep_Mgr_Stamp__c,
                                              		  Sales_Rep_Mgr_Team_Stamp__c,
                                              		  Sales_Rep_Region_Stamp__c,
                                              		  Sales_Rep_Sub_Region_Stamp__c,
                                              		  Sales_Rep_Team_Stamp__c,
                                               		  Quantity__c,
                                              		  Order_Form__c
                                               FROM Signal_Ticket__c];
        
        System.assertEquals(1, signalTicket.size());
        for(Signal_Ticket__c sigTick : signalTicket){
            System.assertEquals(testSalesUser1.Full_Name__c, sigTick.Sales_Rep_Stamp__c);
            System.assertEquals(testSalesUser1.Manager.Full_Name__c, sigTick.Sales_Rep_Mgr_Stamp__c);
            System.assertEquals(testSalesUser1.Manager.Role_Team__c, sigTick.Sales_Rep_Mgr_Team_Stamp__c);
            System.assertEquals(testSalesuser1.Sub_Team__c, sigTick.Sales_Rep_Region_Stamp__c);
            System.assertEquals(testSalesuser1.Sub_Region__c, sigTick.Sales_Rep_Sub_Region_Stamp__c);
            System.assertEquals(testSalesUser1.Role_Team__c, sigTick.Sales_Rep_Team_Stamp__c);
        }
        
        List<Signal_Ticket_Split__c> signalTicketSplit = [SELECT Id, 
                                                          		 Sales_Rep_Stamp__c,
                                                          		 Sales_Rep_Mgr_Stamp__c,
                                                          		 Sales_Rep_Sub_Region_Stamp__c,
                                                          		 Sales_Rep_Region_Stamp__c,
                                                          		 Signal_Ticket__c
                                               FROM Signal_Ticket_Split__c];
        Integer numberOfSplits = 0;
        for(Signal_Ticket_Split__c sts : signalTicketSplit){
            System.debug('Signal Ticket Split --> ' + sts);
            if(sts.Sales_Rep_Stamp__c == testSalesUser1.Full_Name__c){
                System.assertEquals(testSalesUser1.Full_Name__c, sts.Sales_Rep_Stamp__c);
                System.assertEquals(testSalesUser1.Manager.Full_Name__c, sts.Sales_Rep_Mgr_Stamp__c);
                System.assertEquals(testSalesuser1.Sub_Team__c, sts.Sales_Rep_Region_Stamp__c);
                System.assertEquals(testSalesuser1.Sub_Region__c, sts.Sales_Rep_Sub_Region_Stamp__c);
                numberOfSplits++;
            } else if (sts.Sales_Rep_Stamp__c == testSalesUser2.Full_Name__c){
                System.assertEquals(testSalesUser2.Full_Name__c, sts.Sales_Rep_Stamp__c);
                System.assertEquals(testSalesUser2.Manager.Full_Name__c, sts.Sales_Rep_Mgr_Stamp__c);
                System.assertEquals(testSalesuser2.Sub_Team__c, sts.Sales_Rep_Region_Stamp__c);
                System.assertEquals(testSalesuser2.Sub_Region__c, sts.Sales_Rep_Sub_Region_Stamp__c);
                numberOfSplits++;
            }
        }
        System.assertEquals(numberOfSplits, signalTicketSplit.size());
    }
    
    //Test Method ensures that only one Signal Ticket and only one Signal Ticket Split gets created and assigned to
    //the correct Salesperson.
    static testMethod void ensure_Single_Ticket_Attribution_Works_With_Same_Opp_And_Account_Owner(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email, 
                                     		Profile.Name, 
                                     		UserRole.Name,
                                     		Full_Name__c,
                                     	    Manager.Full_Name__c,
                                     	    Manager.Role_Team__c,
                                     		ManagerId,
                                     	    Sub_Team__c,
                                     		Sub_Region__c,
                                     		Role_Team__c
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        User testSalesUser3 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            } else if (u.LastName == 'TestSalesUser3'){
                testSalesUser3 = u;
            }
        }
        
        
        Apttus__APTS_Agreement__c agreementForReview = [SELECT Id, 
                                                        	   OwnerId,
                                                        	   Owner.Name,
                                                        	   Related_Opportunity_APTS__r.Owner.Name,
                                                        	   Related_Opportunity_APTS__c,
                                                        	   Apttus__Account__r.OwnerId,
                                                        	   Apttus__Account__c
                                                        FROM Apttus__APTS_Agreement__c LIMIT 1];
        Single_BI_Discount__c singleBIDiscount = [SELECT Id, Billable_Item__r.Name, Agreement__c, Agreement__r.Name
                                                  FROM Single_BI_Discount__c WHERE Agreement__c = :agreementForReview.Id LIMIT 1];
        singleBIDiscount.Quantity__c = 10;
        update singleBIDiscount;
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :agreementForReview.Related_Opportunity_APTS__c];
        opp.OwnerId = testSalesUser1.Id;
        update opp;
        
        Account accountRec = [SELECT Id FROM Account WHERE Id = :agreementForReview.Apttus__Account__c];
        accountRec.ownerId = testSalesUser1.Id;
        update accountRec;
        
        agreementForReview.Apttus__Status__c = 'Activated';
        Test.startTest();
        update agreementForReview;
        Test.stopTest();
        
        List<Signal_Ticket__c> signalTicket = [SELECT Id, 
                                                      Sales_Rep_Stamp__c,
                                               		  Sales_Rep_Mgr_Stamp__c,
                                              		  Sales_Rep_Mgr_Team_Stamp__c,
                                              		  Sales_Rep_Region_Stamp__c,
                                              		  Sales_Rep_Sub_Region_Stamp__c,
                                              		  Sales_Rep_Team_Stamp__c,
                                               		  Quantity__c,
                                              		  Order_Form__c
                                               FROM Signal_Ticket__c];
        
        System.assertEquals(1, signalTicket.size());
        for(Signal_Ticket__c sigTick : signalTicket){
            System.assertEquals(testSalesUser1.Full_Name__c, sigTick.Sales_Rep_Stamp__c);
            System.assertEquals(testSalesUser1.Manager.Full_Name__c, sigTick.Sales_Rep_Mgr_Stamp__c);
            System.assertEquals(testSalesUser1.Manager.Role_Team__c, sigTick.Sales_Rep_Mgr_Team_Stamp__c);
            System.assertEquals(testSalesuser1.Sub_Team__c, sigTick.Sales_Rep_Region_Stamp__c);
            System.assertEquals(testSalesuser1.Sub_Region__c, sigTick.Sales_Rep_Sub_Region_Stamp__c);
            System.assertEquals(testSalesUser1.Role_Team__c, sigTick.Sales_Rep_Team_Stamp__c);
        }
        
        List<Signal_Ticket_Split__c> signalTicketSplit = [SELECT Id, 
                                                          		 Sales_Rep_Stamp__c,
                                                          		 Sales_Rep_Mgr_Stamp__c,
                                                          		 Sales_Rep_Sub_Region_Stamp__c,
                                                          		 Sales_Rep_Region_Stamp__c,
                                                          		 Signal_Ticket__c
                                               FROM Signal_Ticket_Split__c];
        System.assertEquals(1, signalTicketSplit.size());
        for(Signal_Ticket_Split__c sts : signalTicketSplit){
            System.assertEquals(testSalesUser1.Full_Name__c, sts.Sales_Rep_Stamp__c);
            System.assertEquals(testSalesUser1.Manager.Full_Name__c, sts.Sales_Rep_Mgr_Stamp__c);
            System.assertEquals(testSalesuser1.Sub_Team__c, sts.Sales_Rep_Region_Stamp__c);
            System.assertEquals(testSalesuser1.Sub_Region__c, sts.Sales_Rep_Sub_Region_Stamp__c);
        }
    }
    
    //Test Method ensures that Single BI Discount quantities aggregate correctly.
    static testMethod void ensure_Single_Ticket_Attribution_Has_Correct_Quantity(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email, 
                                     		Profile.Name, 
                                     		UserRole.Name,
                                     		Full_Name__c,
                                     	    Manager.Full_Name__c,
                                     	    Manager.Role_Team__c,
                                     	    Sub_Team__c,
                                     		Sub_Region__c,
                                     		Role_Team__c
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            }
        }
        
        Apttus__APTS_Agreement__c agreementForReview = [SELECT Id, 
                                                        	   OwnerId,
                                                        	   Owner.Name,
                                                        	   Related_Opportunity_APTS__r.Owner.Name,
                                                        	   Related_Opportunity_APTS__c,
                                                        	   Apttus__Account__r.OwnerId,
                                                        	   Apttus__Account__c
                                                        FROM Apttus__APTS_Agreement__c LIMIT 1];
        List<Single_BI_Discount__c> singleBIDiscounts = [SELECT Id, Billable_Item__r.Name, Agreement__c, Agreement__r.Name
                                                  		 FROM Single_BI_Discount__c WHERE Agreement__c = :agreementForReview.Id];
        singleBIDiscounts[0].Quantity__c = 10;
        singleBIDiscounts[1].Quantity__c = 44;
        update singleBIDiscounts;
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :agreementForReview.Related_Opportunity_APTS__c];
        opp.OwnerId = testSalesUser1.Id;
        update opp;
        
        Account accountRec = [SELECT Id FROM Account WHERE Id = :agreementForReview.Apttus__Account__c];
        accountRec.ownerId = testSalesUser1.Id;
        update accountRec;
        
        agreementForReview.Apttus__Status__c = 'Activated';
        Test.startTest();
        update agreementForReview;
        Test.stopTest();
        
        Signal_Ticket__c signalTicket = [SELECT Id, 
                                                 Sales_Rep_Stamp__c,
                                                 Sales_Rep_Mgr_Stamp__c,
                                                 Sales_Rep_Mgr_Team_Stamp__c,
                                                 Sales_Rep_Region_Stamp__c,
                                                 Sales_Rep_Sub_Region_Stamp__c,
                                                 Sales_Rep_Team_Stamp__c,
                                                 Quantity__c,
                                                 Order_Form__c
                                         FROM Signal_Ticket__c
                                         WHERE Order_Form__c = :agreementForReview.Id];
        
        System.assertEquals(54, signalTicket.Quantity__c);
    }
    
    //Test Method tests the negative and that no Signal Ticket or Signal Ticket Split gets created.
    static testMethod void ensure_Single_Ticket_Records_Are_Not_Created(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email, 
                                     		Profile.Name, 
                                     		UserRole.Name,
                                     		Full_Name__c,
                                     	    Manager.Full_Name__c,
                                     	    Manager.Role_Team__c,
                                     	    Sub_Team__c,
                                     		Sub_Region__c,
                                     		Role_Team__c
                                     FROM User 
                                     WHERE CreatedDate = TODAY];
        
        User testSalesUser1 = new User();
        User testSalesUser2 = new User();
        
        for(User u : usersForReview){
            if(u.LastName == 'TestSalesUser1'){
                testSalesUser1 = u;
            } else if (u.LastName == 'TestSalesUser2'){
                testSalesUser2 = u;
            }
        }
        
        Apttus__APTS_Agreement__c agreementForReview = [SELECT Id, 
                                                        	   OwnerId,
                                                        	   Owner.Name,
                                                        	   Related_Opportunity_APTS__r.Owner.Name,
                                                        	   Related_Opportunity_APTS__c,
                                                        	   Apttus__Account__r.OwnerId,
                                                        	   Apttus__Account__c
                                                        FROM Apttus__APTS_Agreement__c LIMIT 1];
        List<Single_BI_Discount__c> singleBIDiscounts = [SELECT Id, Billable_Item__r.Name, Agreement__c, Agreement__r.Name
                                                  		 FROM Single_BI_Discount__c WHERE Agreement__c = :agreementForReview.Id];
        singleBIDiscounts[0].Quantity__c = 10;
        singleBIDiscounts[1].Quantity__c = 44;
        update singleBIDiscounts;
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :agreementForReview.Related_Opportunity_APTS__c];
        opp.OwnerId = testSalesUser1.Id;
        update opp;
        
        Account accountRec = [SELECT Id FROM Account WHERE Id = :agreementForReview.Apttus__Account__c];
        accountRec.ownerId = testSalesUser1.Id;
        update accountRec;
        
        //DELETE Custom Setting Records to prevent Signal Tickets from being created even though they have the proper
        //Single BI Discount records.
        List<Signal_Ticket_Billable_Item_SFDC_ID__c> signalTicketBIs = [SELECT Id, Name FROM Signal_Ticket_Billable_Item_SFDC_ID__c];
        delete signalTicketBIs;
        
        agreementForReview.Apttus__Status__c = 'Activated';
        Test.startTest();
        update agreementForReview;
        Test.stopTest();
        
        List<Signal_Ticket__c> signalTickets = [SELECT Id, 
                                                      Sales_Rep_Stamp__c,
                                               		  Sales_Rep_Mgr_Stamp__c,
                                              		  Sales_Rep_Mgr_Team_Stamp__c,
                                              		  Sales_Rep_Region_Stamp__c,
                                              		  Sales_Rep_Sub_Region_Stamp__c,
                                              		  Sales_Rep_Team_Stamp__c,
                                               		  Quantity__c,
                                              		  Order_Form__c
                                               FROM Signal_Ticket__c];
        
        System.assertEquals(0, signalTickets.size());
        
        List<Signal_Ticket_Split__c> signalTicketSplits = [SELECT Id, 
                                                          		 Sales_Rep_Stamp__c,
                                                          		 Sales_Rep_Mgr_Stamp__c,
                                                          		 Sales_Rep_Sub_Region_Stamp__c,
                                                          		 Sales_Rep_Region_Stamp__c,
                                                          		 Signal_Ticket__c
                                               FROM Signal_Ticket_Split__c];
        
        System.assertEquals(0, signalTicketSplits.size());
    }
    
    //Test Method ensures that only one Signal Ticket, but two Signal Ticket Splits get created and assigned to
    //the correct Salesperson.
    static testMethod void ensure_Single_Ticket_Attribution_Works_With_Different_Opp_And_Account_Owner_But_Same_Manager(){
        List<User> usersForReview = [SELECT Id, 
                                     		FirstName, 
                                     		LastName, 
                                     		Email, 
                                     		Profile.Name, 
                                     		UserRole.Name,
                                     		Full_Name__c,
                                     		ManagerId,
                                     	    Manager.Full_Name__c,
                                     	    Manager.Role_Team__c,
                                     	    Sub_Team__c,
                                     		Sub_Region__c,
                                     		Role_Team__c
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
            }else if (u.LastName == 'TestSalesManager1'){
                testSalesManager1 = u;
            } else if (u.LastName == 'TestSalesManager2'){
                testSalesManager2 = u;
            }
        }
        
        Apttus__APTS_Agreement__c agreementForReview = [SELECT Id, 
                                                        	   OwnerId,
                                                        	   Owner.Name,
                                                        	   Related_Opportunity_APTS__r.Owner.Name,
                                                        	   Related_Opportunity_APTS__c,
                                                        	   Apttus__Account__r.OwnerId,
                                                        	   Apttus__Account__c
                                                        FROM Apttus__APTS_Agreement__c LIMIT 1];
        Single_BI_Discount__c singleBIDiscount = [SELECT Id, Billable_Item__r.Name, Agreement__c, Agreement__r.Name
                                                  FROM Single_BI_Discount__c WHERE Agreement__c = :agreementForReview.Id LIMIT 1];
        singleBIDiscount.Quantity__c = 10;
        update singleBIDiscount;
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :agreementForReview.Related_Opportunity_APTS__c];
        opp.OwnerId = testSalesUser1.Id;
        update opp;
        
        Account accountRec = [SELECT Id FROM Account WHERE Id = :agreementForReview.Apttus__Account__c];
        accountRec.ownerId = testSalesUser3.Id;
        update accountRec;
        
        agreementForReview.Apttus__Status__c = 'Activated';
        Test.startTest();
        update agreementForReview;
        Test.stopTest();
        
        List<Signal_Ticket__c> signalTicket = [SELECT Id, 
                                                      Sales_Rep_Stamp__c,
                                               		  Sales_Rep_Mgr_Stamp__c,
                                              		  Sales_Rep_Mgr_Team_Stamp__c,
                                              		  Sales_Rep_Region_Stamp__c,
                                              		  Sales_Rep_Sub_Region_Stamp__c,
                                              		  Sales_Rep_Team_Stamp__c,
                                               		  Quantity__c,
                                              		  Order_Form__c
                                               FROM Signal_Ticket__c];
        
        System.assertEquals(1, signalTicket.size());
        for(Signal_Ticket__c sigTick : signalTicket){
            System.assertEquals(testSalesUser1.Full_Name__c, sigTick.Sales_Rep_Stamp__c);
            System.assertEquals(testSalesUser1.Manager.Full_Name__c, sigTick.Sales_Rep_Mgr_Stamp__c);
            System.assertEquals(testSalesUser1.Manager.Role_Team__c, sigTick.Sales_Rep_Mgr_Team_Stamp__c);
            System.assertEquals(testSalesuser1.Sub_Team__c, sigTick.Sales_Rep_Region_Stamp__c);
            System.assertEquals(testSalesuser1.Sub_Region__c, sigTick.Sales_Rep_Sub_Region_Stamp__c);
            System.assertEquals(testSalesUser1.Role_Team__c, sigTick.Sales_Rep_Team_Stamp__c);
        }
        
        List<Signal_Ticket_Split__c> signalTicketSplit = [SELECT Id, 
                                                          		 Sales_Rep_Stamp__c,
                                                          		 Sales_Rep_Mgr_Stamp__c,
                                                          		 Sales_Rep_Sub_Region_Stamp__c,
                                                          		 Sales_Rep_Region_Stamp__c,
                                                          		 Sales_Manager_Ticket_Credit__c,
                                                          		 Sales_Rep_Ticket_Credit__c,
                                                          		 Signal_Ticket__c,
                                                          		 Sales_Rep_Quota__c,
                                                          		 Sales_Manager_Quota__c
                                               			  FROM Signal_Ticket_Split__c];
        Integer numberOfSplits = 0;
        for(Signal_Ticket_Split__c sts : signalTicketSplit){
            if(sts.Sales_Rep_Stamp__c == testSalesUser1.Full_Name__c){
                System.assertEquals(testSalesUser1.Full_Name__c, sts.Sales_Rep_Stamp__c);
                System.assertEquals(testSalesUser1.Manager.Full_Name__c, sts.Sales_Rep_Mgr_Stamp__c);
                System.assertEquals(testSalesUser1.Sub_Team__c, sts.Sales_Rep_Region_Stamp__c);
                System.assertEquals(testSalesUser1.Sub_Region__c, sts.Sales_Rep_Sub_Region_Stamp__c);
                System.assertEquals(testSalesUser1.Id, sts.Sales_Rep_Ticket_Credit__c);
                System.assertEquals(testSalesUser1.ManagerId, sts.Sales_Manager_Ticket_Credit__c);
                numberOfSplits++;
            } else if (sts.Sales_Rep_Stamp__c == testSalesUser3.Full_Name__c){
                System.assertEquals(testSalesUser3.Full_Name__c, sts.Sales_Rep_Stamp__c);
                System.assertEquals(testSalesUser3.Manager.Full_Name__c, sts.Sales_Rep_Mgr_Stamp__c);
                System.assertEquals(testSalesUser3.Sub_Team__c, sts.Sales_Rep_Region_Stamp__c);
                System.assertEquals(testSalesUser3.Sub_Region__c, sts.Sales_Rep_Sub_Region_Stamp__c);
                System.assertEquals(testSalesUser3.Id, sts.Sales_Rep_Ticket_Credit__c);
                System.assertEquals(testSalesUser1.ManagerId, testSalesUser3.ManagerId);
                System.assertEquals(null, sts.Sales_Manager_Ticket_Credit__c);
                numberOfSplits++;
            }
        }
        System.assertEquals(numberOfSplits, signalTicketSplit.size());
        System.assertEquals(2, numberOfSplits);
    }
}