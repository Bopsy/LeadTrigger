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
private class PartnerPortalTest {

    static Integer recordMax = 10;
    
    static User standardUser;
    static User salesOpsUser;
    static User eloquaUser;
    
    static Opportunity testOpp;
    static List<Account> accountList;
    static List<Contact> contactList;
    static List<User> userList;
    static Map<Id,User> userPartnerMap;
    static List<Use_Case_to_Opp_Record_Type__c> useCaseToOppRecTypeList;
    
    static testMethod void ShowcaseLeadAutoConvert() {
        setupTestRecords();

        //
        // Changed run as user to be the existing "Sales Operations" user so it would be exempted
        // from the following Lead validation rules:
        //
        //    Consolidated_Last_Lead_Source_Edit_Rules
        //    Consolidation_of_LeadSource_Edit_Rules
        //    Partner_Pass_No_SQL_required_fields
        //
        System.RunAs(eloquaUser) {
            Integer i = 0;
            List<Lead> leads = new List<Lead>();
            leads.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'newtestuser-' + i + '@test-partner-portal-autoconvert-' + i + '.com',
                LeadSource = 'Showcase',
                Status = 'Open',
                CountryCode = 'US',
                StateCode = 'CA',
                Showcase_Employee_Size__c = '0 - 50',
                Showcase_Use_Case__c = useCaseToOppRecTypeList[0].Use_Case__c,
                OwnerId = standardUser.Id,
                Partner_ID__c = userPartnerMap.get(userList[0].Id).Partner_ID_Text__c
            ));

            Test.startTest();
            insert(leads);
            
            // Test the post autoconvert process
            //Lead l = leads[0];
            //List<Map<String,String>> convertedLeadProperties = new List<Map<String,String>>();
            //convertedLeadProperties.add(new Map<String,String> {
            //    'Lead.Name' => (String.isBlank(l.FirstName) ? '' : (l.FirstName + ' ')) + l.LastName,
            //    'Lead.Description' => l.Description,
            //    'Lead.Partner_ID__c' => l.Partner_ID__c,
            //    'Lead.CountryCode__c' => l.CountryCode,
            //    'Lead.State__c' => l.StateCode,
            //    'Lead.Showcase_Employee_Size__c' => l.Showcase_Employee_Size__c,
            //    'Lead.Showcase_Use_Case__c' => l.Showcase_Use_Case__c,
            //    'Opportunity.OwnerId' => standardUser.Id,
            //    'Lead.Id' => l.Id,
            //    'Contact.Id' => contactList[i].Id,
            //    'Opportunity.Id' => testOpp.Id
            //});
            //LeadTriggerHandler.partnerPortalPostAutoConversion(new Map<Id,Lead> { l.Id => l }, convertedLeadProperties);    
            
            Test.stopTest();
        }
    }

    static testMethod void ShowcaseContactAutoConvert() {
        setupTestRecords();

        //
        // Changed run as user to be the existing "Sales Operations" user so it would be exempted
        // from the following Lead validation rules:
        //
        //    Consolidated_Last_Lead_Source_Edit_Rules
        //    Consolidation_of_LeadSource_Edit_Rules
        //    Partner_Pass_No_SQL_required_fields
        //
        System.RunAs(eloquaUser) {
            Contact c = contactList[0];
            c.Lead_Source_Most_Recent_ELOQUA__c = 'Showcase';
            c.MailingCountryCode = 'US';
            c.MailingStateCode= 'CA';
            c.Showcase_Employee_Size__c = '0 - 50';
            c.Showcase_Use_Case__c = useCaseToOppRecTypeList[0].Use_Case__c;
            c.Partner_ID__c = userPartnerMap.get(userList[0].Id).Partner_ID_Text__c;
            
            Test.startTest();
            update(c);
            Test.stopTest();
        }
    }

    static testMethod void TwilioOrgShowcaseLeadAutoConvert() {
        setupTestRecords();

        //
        // Changed run as user to be the existing "Sales Operations" user so it would be exempted
        // from the following Lead validation rules:
        //
        //    Consolidated_Last_Lead_Source_Edit_Rules
        //    Consolidation_of_LeadSource_Edit_Rules
        //    Partner_Pass_No_SQL_required_fields
        //
        System.RunAs(eloquaUser) {
            Integer i = 0;
            List<Lead> leads = new List<Lead>();
            leads.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'newtestuser-' + i + '@test-partner-portal-autoconvert-' + i + '.com',
                LeadSource = 'Twilio.org Showcase',
                Status = 'Open',
                CountryCode = 'US',
                StateCode = 'CA',
                Showcase_Employee_Size__c = '0 - 50',
                Showcase_Use_Case__c = useCaseToOppRecTypeList[0].Use_Case__c,
                OwnerId = standardUser.Id,
                Partner_ID__c = userPartnerMap.get(userList[0].Id).Partner_ID_Text__c
            ));

            Test.startTest();
            insert(leads);
            
            // Test the post autoconvert process
            //Lead l = leads[0];
            //List<Map<String,String>> convertedLeadProperties = new List<Map<String,String>>();
            //convertedLeadProperties.add(new Map<String,String> {
            //    'Lead.Name' => (String.isBlank(l.FirstName) ? '' : (l.FirstName + ' ')) + l.LastName,
            //    'Lead.Description' => l.Description,
            //    'Lead.Partner_ID__c' => l.Partner_ID__c,
            //    'Lead.CountryCode__c' => l.CountryCode,
            //    'Lead.State__c' => l.StateCode,
            //    'Lead.Showcase_Employee_Size__c' => l.Showcase_Employee_Size__c,
            //    'Lead.Showcase_Use_Case__c' => l.Showcase_Use_Case__c,
            //    'Opportunity.OwnerId' => standardUser.Id,
            //    'Lead.Id' => l.Id,
            //    'Contact.Id' => contactList[i].Id,
            //    'Opportunity.Id' => testOpp.Id
            //});
            //LeadTriggerHandler.partnerPortalPostAutoConversion(new Map<Id,Lead> { l.Id => l }, convertedLeadProperties);    
            
            Test.stopTest();
        }
    }

    static testMethod void TwilioOrgShowcaseContactAutoConvert() {
        setupTestRecords();

        //
        // Changed run as user to be the existing "Sales Operations" user so it would be exempted
        // from the following Lead validation rules:
        //
        //    Consolidated_Last_Lead_Source_Edit_Rules
        //    Consolidation_of_LeadSource_Edit_Rules
        //    Partner_Pass_No_SQL_required_fields
        //
        System.RunAs(eloquaUser) {
            Contact c = contactList[0];
            c.Lead_Source_Most_Recent_ELOQUA__c = 'Twilio.org Showcase';
            c.MailingCountryCode = 'US';
            c.MailingStateCode= 'CA';
            c.Showcase_Employee_Size__c = '0 - 50';
            c.Showcase_Use_Case__c = useCaseToOppRecTypeList[0].Use_Case__c;
            c.Partner_ID__c = userPartnerMap.get(userList[0].Id).Partner_ID_Text__c;
            
            Test.startTest();
            update(c);
            Test.stopTest();
        }
    }


    static testMethod void DealRegistrationLeadAutoConvert() {
        setupTestRecords();

        System.RunAs(salesOpsUser) {
            Integer i = 0;
            List<Lead> leads = new List<Lead>();
            leads.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'newtestuser-' + i + '@test-partner-portal-autoconvert-' + i + '.com',
                LeadSource = 'Deal Registration',
                Status = 'Open',
                Deal_Type__c = 'Deal Registration',
                CountryCode = 'US',
                StateCode = 'CA',
                Showcase_Employee_Size__c = '0 - 50',
                Showcase_Use_Case__c = useCaseToOppRecTypeList[0].Use_Case__c,
                OwnerId = standardUser.Id,
                Partner_ID__c = userPartnerMap.get(userList[0].Id).Partner_ID_Text__c
            ));
    
            Test.startTest();
            insert(leads);
                
            // Test the post autoconvert process
            Lead l = leads[0];
            List<Map<String,String>> convertedLeadProperties = new List<Map<String,String>>();
            convertedLeadProperties.add(new Map<String,String> {
                'Lead.Name' => (String.isBlank(l.FirstName) ? '' : (l.FirstName + ' ')) + l.LastName,
                'Lead.Description' => l.Description,
                'Lead.Partner_ID__c' => l.Partner_ID__c,
                'Lead.Showcase_Use_Case__c' => l.Showcase_Use_Case__c,
                'Opportunity.OwnerId' => standardUser.Id,
                'Opportunity.Qualified_Lead_Source__c' => 'Deal Registration',
                'Lead.Id' => l.Id,
                'Contact.Id' => contactList[i].Id,
                'Opportunity.Id' => testOpp.Id
            });
            LeadTriggerHandler.partnerDealSubmissionPostAutoConversion(new Map<Id,Lead> { l.Id => l }, convertedLeadProperties);    
                
            Test.stopTest();
        }
    }

    static testMethod void ReferralLeadAutoConvert() {
        setupTestRecords();

        System.RunAs(salesOpsUser) {
            Integer i = 0;
            List<Lead> leads = new List<Lead>();
            leads.add(new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'newtestuser-' + i + '@test-partner-portal-autoconvert-' + i + '.com',
                LeadSource = 'Referral',
                Status = 'Open',
                Deal_Type__c = 'Referral',
                CountryCode = 'US',
                StateCode = 'CA',
                Showcase_Employee_Size__c = '0 - 50',
                Showcase_Use_Case__c = useCaseToOppRecTypeList[0].Use_Case__c,
                OwnerId = standardUser.Id,
                Partner_ID__c = userPartnerMap.get(userList[0].Id).Partner_ID_Text__c
            ));
    
            Test.startTest();
            insert(leads);
                
            // Test the post autoconvert process
            Lead l = leads[0];
            List<Map<String,String>> convertedLeadProperties = new List<Map<String,String>>();
            convertedLeadProperties.add(new Map<String,String> {
                'Lead.Name' => (String.isBlank(l.FirstName) ? '' : (l.FirstName + ' ')) + l.LastName,
                'Lead.Description' => l.Description,
                'Lead.Partner_ID__c' => l.Partner_ID__c,
                'Lead.Showcase_Use_Case__c' => l.Showcase_Use_Case__c,
                'Opportunity.OwnerId' => standardUser.Id,
                'Opportunity.Qualified_Lead_Source__c' => 'Referral',
                'Lead.Id' => l.Id,
                'Contact.Id' => contactList[i].Id,
                'Opportunity.Id' => testOpp.Id
            });
            LeadTriggerHandler.partnerDealSubmissionPostAutoConversion(new Map<Id,Lead> { l.Id => l }, convertedLeadProperties);    
                
            Test.stopTest();
        }
    }

    static void setupTestRecords() {
        //
        // Must change run as user to be the existing "Sales Operations" user so it would be exempted
        // from the following Lead validation rules:
        //
        //    Consolidated_Last_Lead_Source_Edit_Rules
        //    Consolidation_of_LeadSource_Edit_Rules
        //    Partner_Pass_No_SQL_required_fields
        //
//        salesOpsUser = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];
        salesOpsUser = [ SELECT Id FROM User WHERE name = 'Eloqua Marketing' LIMIT 1 ];
        eloquaUser = [ SELECT Id FROM User WHERE name = 'Eloqua Marketing' LIMIT 1 ];

        Profile standardUserProfile = [Select Id from Profile where name = 'System Administrator'];
        standardUser = new User(
            ProfileId = standardUserProfile.Id,
            Username = System.now().getTime() + 'partner-portal-autoconvert-test@test.com',
            Alias = 'testtest',
            Email='test@test-lead-autoconvert-12345.com',
            EmailEncodingKey='UTF-8',
            Firstname='Test',
            Lastname='Test',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        insert standardUser;

        accountList = new List<Account>();
        for (Integer i = 0; i < recordMax; i++) {
            accountList.add(new Account(
                Name = 'TESTACCOUNT' + i,
                Website = 'http://www.test-partner-portal-autoconvert-' + i + '.com',
                //Partner_Account_Level__c = 'Tier 1',
                Partner_ID__c = 'TP-00000' + i
            ));
        }
        insert accountList;

        List<Email_Domain__c> emailDomainList = new List<Email_Domain__c>();
        for (Integer i = 0; i < recordMax; i++) {
            emailDomainList.add(new Email_Domain__c(
                Name = 'test-partner-portal-autoconvert-' + i + '.com',
                Account__c = accountList[i].Id,
                Approved__c = true
            ));
        }
        insert emailDomainList;

        contactList = new List<Contact>();
        for (Integer i = 0; i < recordMax; i++) {
            contactList.add(new Contact(
                LastName = 'TESTCONTACT' + i,
                AccountID = accountList[i].Id,
                Email = 'testuser-' + i + '@test-partner-portal-autoconvert-' + i + '.com'
            ));
        }
        insert contactList;

        Profile partnerUserProfile = [Select ID, Name from Profile Where Name = '**Partner Community DREG & PTP'];
        userList = new List<User>();
        for (Integer i = 0; i < recordMax; i++) {
            String email = 'test_' + i + '@test-' + math.random() + '.com';
            userList.add(new User(
                UserName = email,
                FirstName = 'TEST-FIRST' + i,
                LastName = 'TEST-LAST' + i,
                Alias = 'test',
                Email = email,
                CommunityNickName = 'T' + i + string.valueOf(math.random()).substring(0,4),
                ProfileID = partnerUserProfile.id,
                TimeZoneSidKey = 'America/New_York', 
                LocaleSidKey = 'en_US', 
                EmailEncodingKey = 'UTF-8', 
                LanguageLocaleKey = 'en_US',
                ContactId = contactList[i].Id,
                Partner_ID_Text__c = 'TP-00000' + i
            ));
        }
        insert userList;

        // Query the created users to get the Partner_ID__c that was auto-generated.
        List<Id> ids = new List<Id>();
        for (User u : userList) { ids.add(u.Id); }
        userPartnerMap = new Map<Id,User>([ SELECT Id, Partner_ID_Text__c FROM User WHERE Id IN :ids ]);

        testOpp = new Opportunity(
            Name = 'TestOpp',
            AccountId = accountList[0].Id,
            CloseDate = Date.today(),
            StageName = 'Pilot',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        );
        insert testOpp;
        
        List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
        opportunityContactRoles.add(new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = contactList[0].Id
        ));
        insert opportunityContactRoles;
        
        // Updated the accounts with the Partner ID auto-generated on the User record.
        for (Integer i = 0; i < recordMax; i++) {
            accountList[i].Partner_ID__c = userPartnerMap.get(userList[i].Id).Partner_ID_Text__c;
        }
        update accountList;

        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        useCaseToOppRecTypeList = new List<Use_Case_to_Opp_Record_Type__c>();
        for (Schema.RecordTypeInfo info : rtMapByName.values()) {
            useCaseToOppRecTypeList.add(new Use_Case_to_Opp_Record_Type__c(
                Name = info.getName(),
                Use_Case__c = info.getName(),
                Opp_Record_Type_ID__c = info.getRecordTypeId()
            ));
        }
        insert useCaseToOppRecTypeList;
        
        List<Opp_Owner_Partner_Portal_Routing_Rules__c> oppOwnerPartnerPortalRoutingRules = new List<Opp_Owner_Partner_Portal_Routing_Rules__c>();
        oppOwnerPartnerPortalRoutingRules.add(new Opp_Owner_Partner_Portal_Routing_Rules__c(
            Name = 'DEFAULT',
            CountryCode__c = 'US',
            State__c = 'OTHER',
            Employee_Size__c = 'OTHER',
            Use_Case__c = 'OTHER',
            Owner_ID__c = salesOpsUser.Id
        ));
        oppOwnerPartnerPortalRoutingRules.add(new Opp_Owner_Partner_Portal_Routing_Rules__c(
            Name = 'TEST',
            CountryCode__c = 'US',
            State__c = 'CA',
            Employee_Size__c = '0 - 50',
            Use_Case__c = useCaseToOppRecTypeList[0].Use_Case__c,
            Owner_ID__c = standardUser.Id
        ));
        insert oppOwnerPartnerPortalRoutingRules;
        
        List<PartnerPortalMappings__c> partnerPortalMappings = new List<PartnerPortalMappings__c>();
        for (Integer i = 0; i < recordMax; i++) {
            partnerPortalMappings.add(new PartnerPortalMappings__c(
                Name = 'PPM-' + i,
                Account_ID__c = accountList[i].Id,
                User_ID__c = userList[i].Id,
                Partner_ID__c = userPartnerMap.get(userList[i].Id).Partner_ID_Text__c
            ));
            System.debug('PartnerPortalMappings__c(Name=' + partnerPortalMappings[i].Name
                + ', AccountID=' + partnerPortalMappings[i].Account_ID__c 
                + ', UserID=' + partnerPortalMappings[i].User_ID__c 
                + ', PartnerID=' + partnerPortalMappings[i].Partner_ID__c + ')');
        }
        insert partnerPortalMappings;

        Opportunity_to_PTP_Mappings__c setting = new Opportunity_to_PTP_Mappings__c(
            Name = 'BDR_Notes__c',
            PTP_API_Name__c = 'BDR_Notes__c',
            Opportunity_API_Name__c = 'BDR_Notes__c'
        );
        insert setting;
    }
}