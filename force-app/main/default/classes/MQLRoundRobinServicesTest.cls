@isTest
private class MQLRoundRobinServicesTest {

    static testMethod void testInsert(){
        MQLRoundRobinServices.bypassTrigger = true;
        List<User> users = [SELECT Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 4];
        DateTime now = DateTime.now();
        Assignment_Group_Name__c testGroup1 = new Assignment_Group_Name__c(Name = 'Test Group1');
        Assignment_Group_Name__c testGroup2 = new Assignment_Group_Name__c(Name = 'Test Group2');
        Assignment_Group_Name__c testGroup3 = new Assignment_Group_Name__c(Name = 'Test Group3');
        Assignment_Group_Name__c testGroup4 = new Assignment_Group_Name__c(Name = 'Test Group4');
        insert new List<Assignment_Group_Name__c>{testGroup1, testGroup2, testGroup3, testGroup4};

        Assignment_Groups__c testMember1 = buildActiveMember(now, 100, users[0].Id, testGroup1.Id);
        Assignment_Groups__c testMember2 = buildActiveMember(now.addDays(-25), 100, users[1].Id, testGroup1.Id);
        Assignment_Groups__c testMember3 = buildActiveMember(null, null, users[2].Id, testGroup1.Id);
        insert new List<Assignment_Groups__c>{testMember1, testMember2, testMember3};

        Account testAccount = new Account(Name = 'Test Acc', OwnerId = users[3].Id);
        insert testAccount;
        Contact testContact = new Contact(LastName = 'TestContact', AccountId = testAccount.Id);
        insert testContact;
        Lead testLead = new Lead(LastName = 'Test Lead', Country = 'United Kingdom', Company = 'Test Company');
        insert new List<Lead>{testLead};
        Campaign testCampaign = new Campaign(Name = 'Test Campaign', Type = 'Test Type');
        insert testCampaign;

        FSR__c testMql1 = buildMQL(testContact.Id, testLead.Id, testCampaign.Id, '-7');
        FSR__c testMql2 = buildMQL(null, testLead.Id, testCampaign.Id, null);
        FSR__c testMql31 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql32 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql33 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql34 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql35 = buildMQL(null, null, testCampaign.Id, '-7');
        testMql35.Assign_MQL_Owner__c = users[2].Id;
        FSR__c testMql4 = buildMQL(null, null, null, null);
        List<FSR__c> mqls = new List<FSR__c>{testMql1, testMql2, testMql31, testMql32, testMql33, testMql34, testMql4, testMql35};

        Group_Mapping__c mapping1 = buildMapping(users[3].Name, MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, testGroup4.Id, 1);
        Group_Mapping__c mapping2 = buildMapping(MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, 'United Kingdom', MQLRoundRobinServices.WILD_CARD, testGroup3.Id, 2);
        Group_Mapping__c mapping3 = buildMapping(MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, null, MQLRoundRobinServices.WILD_CARD, testGroup2.Id, 3);
        Group_Mapping__c mapping4 = buildMapping(MQLRoundRobinServices.WILD_CARD, 'Test Type', MQLRoundRobinServices.WILD_CARD, '-7', testGroup1.Id, 4);
        insert new List<Group_Mapping__c>{mapping1, mapping2, mapping3, mapping4};
        MQLRoundRobinServices.bypassTrigger = false;

        Test.startTest();
            insert mqls;
        Test.stopTest();

        List<Assignment_Groups__c> testMembers = [SELECT Last_Assignment__c, Millisecond__c FROM Assignment_Groups__c];
        system.assertEquals(3, testMembers.size(), 'members size should be equal');
        for(Assignment_Groups__c member: testMembers){
            system.assertNotEquals(null, member.Last_Assignment__c, 'Should get assigned in the test');
            system.assertNotEquals(null, member.Millisecond__c, 'Should get assigned seconds in the test');
        }

        mqls = [SELECT OwnerId FROM FSR__c];
        system.assertEquals(8, mqls.size(), 'mql size should be equal');
        system.assertEquals(users[2].Id, mqls[2].OwnerId,'the owner should be assigned correctly');
        system.assertEquals(users[1].Id, mqls[3].OwnerId,'the owner should be assigned correctly');
        system.assertEquals(users[0].Id, mqls[4].OwnerId,'the owner should be assigned correctly');
        system.assertEquals(users[2].Id, mqls[5].OwnerId,'the owner should be assigned correctly');
        system.assertEquals(users[2].Id, mqls[7].OwnerId,'the owner should be assigned correctly');

    }

    static testMethod void testUpdate(){
        MQLRoundRobinServices.bypassTrigger = true;
        List<User> users = [SELECT Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 4];
        DateTime now = DateTime.now();
        Assignment_Group_Name__c testGroup1 = new Assignment_Group_Name__c(Name = 'Test Group1');
        Assignment_Group_Name__c testGroup2 = new Assignment_Group_Name__c(Name = 'Test Group2');
        Assignment_Group_Name__c testGroup3 = new Assignment_Group_Name__c(Name = 'Test Group3');
        Assignment_Group_Name__c testGroup4 = new Assignment_Group_Name__c(Name = 'Test Group4');
        insert new List<Assignment_Group_Name__c>{testGroup1, testGroup2, testGroup3, testGroup4};

        Assignment_Groups__c testMember1 = buildActiveMember(now, 100, users[0].Id, testGroup1.Id);
        Assignment_Groups__c testMember2 = buildActiveMember(now.addDays(-25), 100, users[1].Id, testGroup1.Id);
        Assignment_Groups__c testMember3 = buildActiveMember(null, null, users[2].Id, testGroup1.Id);
        insert new List<Assignment_Groups__c>{testMember1, testMember2, testMember3};

        Account testAccount = new Account(Name = 'Test Acc', OwnerId = users[3].Id);
        insert testAccount;
        Contact testContact = new Contact(LastName = 'TestContact', AccountId = testAccount.Id);
        insert testContact;
        Lead testLead = new Lead(LastName = 'Test Lead', Country = 'United Kingdom', Company = 'Test Company');
        insert new List<Lead>{testLead};
        Campaign testCampaign = new Campaign(Name = 'Test Campaign', Type = 'Test Type');
        insert testCampaign;

        FSR__c testMql1 = buildMQL(testContact.Id, testLead.Id, testCampaign.Id, '-7');
        FSR__c testMql2 = buildMQL(null, testLead.Id, testCampaign.Id, null);
        FSR__c testMql31 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql32 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql33 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql34 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql4 = buildMQL(null, null, null, null);
        List<FSR__c> mqls = new List<FSR__c>{testMql1, testMql2, testMql31, testMql32, testMql33, testMql34, testMql4};
        for(FSR__c mql: mqls){
            mql.Requires_MQL_Assignment__c = false;
        }
        insert mqls;

        Group_Mapping__c mapping1 = buildMapping(users[3].Name, MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, testGroup4.Id, 1);
        Group_Mapping__c mapping2 = buildMapping(MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, 'United Kingdom', MQLRoundRobinServices.WILD_CARD, testGroup3.Id, 2);
        Group_Mapping__c mapping3 = buildMapping(MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, null, MQLRoundRobinServices.WILD_CARD, testGroup2.Id, 3);
        Group_Mapping__c mapping4 = buildMapping(MQLRoundRobinServices.WILD_CARD, 'Test Type', MQLRoundRobinServices.WILD_CARD, '-7', testGroup1.Id, 4);
        insert new List<Group_Mapping__c>{mapping1, mapping2, mapping3, mapping4};
        MQLRoundRobinServices.bypassTrigger = false;
        for(FSR__c mql: mqls){
            mql.Requires_MQL_Assignment__c = true;
        }

        Test.startTest();
            update mqls;
        Test.stopTest();

        List<Assignment_Groups__c> testMembers = [SELECT Last_Assignment__c, Millisecond__c FROM Assignment_Groups__c];
        system.assertEquals(3, testMembers.size(), 'members size should be equal');
        for(Assignment_Groups__c member: testMembers){
            system.assertNotEquals(null, member.Last_Assignment__c, 'Should get assigned in the test');
            system.assertNotEquals(null, member.Millisecond__c, 'Should get assigned seconds in the test');
        }

        mqls = [SELECT OwnerId FROM FSR__c];
        system.assertEquals(7, mqls.size(), 'mql size should be equal');
        system.assertEquals(users[2].Id, mqls[2].OwnerId,'the owner should be assigned correctly');
        system.assertEquals(users[1].Id, mqls[3].OwnerId,'the owner should be assigned correctly');
        system.assertEquals(users[0].Id, mqls[4].OwnerId,'the owner should be assigned correctly');
        system.assertEquals(users[2].Id, mqls[5].OwnerId,'the owner should be assigned correctly');

    }

    static testMethod void testProcessMQL(){

        MQLRoundRobinServices.bypassTrigger = true;
        List<User> users = [SELECT Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 4];
        DateTime now = DateTime.now();
        Assignment_Group_Name__c testGroup1 = new Assignment_Group_Name__c(Name = 'Test Group1');
        Assignment_Group_Name__c testGroup2 = new Assignment_Group_Name__c(Name = 'Test Group2');
        Assignment_Group_Name__c testGroup3 = new Assignment_Group_Name__c(Name = 'Test Group3');
        Assignment_Group_Name__c testGroup4 = new Assignment_Group_Name__c(Name = 'Test Group4');
        insert new List<Assignment_Group_Name__c>{testGroup1, testGroup2, testGroup3, testGroup4};

        Assignment_Groups__c testMember1 = buildActiveMember(now, 100, users[0].Id, testGroup1.Id);
        Assignment_Groups__c testMember2 = buildActiveMember(now.addDays(-25), 100, users[1].Id, testGroup1.Id);
        Assignment_Groups__c testMember3 = buildActiveMember(null, null, users[2].Id, testGroup1.Id);
        insert new List<Assignment_Groups__c>{testMember1, testMember2, testMember3};

        Account testAccount = new Account(Name = 'Test Acc', OwnerId = users[3].Id);
        insert testAccount;
        Contact testContact = new Contact(LastName = 'TestContact', AccountId = testAccount.Id);
        insert testContact;
        Lead testLead = new Lead(LastName = 'Test Lead', Country = 'United Kingdom', Company = 'Test Company');
        insert new List<Lead>{testLead};
        Campaign testCampaign = new Campaign(Name = 'Test Campaign', Type = 'Test Type');
        insert testCampaign;

        FSR__c testMql1 = buildMQL(testContact.Id, testLead.Id, testCampaign.Id, '-7');
        FSR__c testMql2 = buildMQL(null, testLead.Id, testCampaign.Id, null);
        FSR__c testMql31 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql32 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql33 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql34 = buildMQL(null, null, testCampaign.Id, '-7');
        FSR__c testMql4 = buildMQL(null, null, null, null);
        List<FSR__c> mqls = new List<FSR__c>{testMql1, testMql2, testMql31, testMql32, testMql33, testMql34, testMql4};
        insert mqls;
        mqls = [SELECT TimeZone__c, Campaign_Id__c, State__c, Campaign_Sub_Type__c, Campaign_Type__c, Country__c, Account_Owner__c, Group_Name__c, Grossreg_Product__c, Assign_MQL_Owner__c FROM FSR__c];

        Group_Mapping__c mapping1 = buildMapping(users[3].Name, MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, testGroup4.Id, 1);
        Group_Mapping__c mapping2 = buildMapping(MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, 'United Kingdom', MQLRoundRobinServices.WILD_CARD, testGroup3.Id, 2);
        Group_Mapping__c mapping3 = buildMapping(MQLRoundRobinServices.WILD_CARD, MQLRoundRobinServices.WILD_CARD, null, MQLRoundRobinServices.WILD_CARD, testGroup2.Id, 3);
        Group_Mapping__c mapping4 = buildMapping(MQLRoundRobinServices.WILD_CARD, 'Test Type', MQLRoundRobinServices.WILD_CARD, '-7', testGroup1.Id, 4);
        insert new List<Group_Mapping__c>{mapping1, mapping2, mapping3, mapping4};
        MQLRoundRobinServices.bypassTrigger = false;

        Test.startTest();
            MQLRoundRobinServices.processMQL(mqls);
        Test.stopTest();

        List<Assignment_Groups__c> testMembers = [SELECT Last_Assignment__c, Millisecond__c FROM Assignment_Groups__c];
        system.assertEquals(3, testMembers.size(), 'members size should be equal');
        for(Assignment_Groups__c member: testMembers){
            system.assertNotEquals(null, member.Last_Assignment__c, 'Should get assigned in the test');
            system.assertNotEquals(null, member.Millisecond__c, 'Should get assigned seconds in the test');
        }

        system.assertEquals(7, mqls.size(), 'mql size should be equal');
        system.assertEquals(users[2].Id, mqls[2].OwnerId,'the owner should be assigned correctly');
        system.assertEquals(users[1].Id, mqls[3].OwnerId,'the owner should be assigned correctly');
        system.assertEquals(users[0].Id, mqls[4].OwnerId,'the owner should be assigned correctly');
        //system.assertEquals(users[2].Id, mqls[5].OwnerId,'the owner should be assigned correctly');


    }

    static testMethod void testSortMemebersByLastAssignmentTime(){
        DateTime now = DateTime.now();
        Assignment_Groups__c testMember1 = buildMember(now, 100);
        Assignment_Groups__c testMember2 = buildMember(now.addDays(-25), 100);
        Assignment_Groups__c testMember3 = buildMember(now.addDays(-25), 200);
        Assignment_Groups__c testMember4 = buildMember(null, null);

        List<Assignment_Groups__c> testList = new List<Assignment_Groups__c>{testMember1, testMember2, testMember3, testMember4};
        Test.startTest();
            testList = MQLRoundRobinServices.sortMemebersByLastAssignmentTime(testList);
        Test.stopTest();
        system.assertEquals(testMember4, testList[0], 'the first element should be the null');
        system.assertEquals(testMember2, testList[1], 'the second element should be the earliest one');
        system.assertEquals(testMember3, testList[2], 'the third element should be the second earliest one');
        system.assertEquals(testMember1, testList[3], 'the last element should be the third earliest one');
    }

    static testMethod void testfindMqlGroupId() {
        MQLRoundRobinServices.bypassTrigger = true;

        final Id TEST_GROUP_ID1 = '006000000000001';
        final Id TEST_GROUP_ID2 = '006000000000002';
        final Id TEST_GROUP_ID3 = '006000000000003';
        final Id TEST_GROUP_ID4 = '006000000000004';
        final Id TEST_GROUP_ID5 = '006000000000005';

        User testUser = [SELECT Name FROM User WHERE IsActive = true LIMIT 1 ];
        Account testAccount = new Account(Name = 'Test Acc', OwnerId = testUser.Id);
        insert testAccount;
        Contact testContact = new Contact(LastName = 'TestContact', AccountId = testAccount.Id);
        insert testContact;
        Lead testLead = new Lead(LastName = 'Test Lead', Country = 'United Kingdom', Company = 'Test Company');
        insert new List<Lead>{testLead};
        Campaign testCampaign = new Campaign(Name = 'Test Campaign', Type = 'Test Type');
        insert testCampaign;

        FSR__c testMql1 = buildMQL(testContact.Id, testLead.Id, testCampaign.Id, '-7');
        FSR__c testMql2 = buildMQL(null, testLead.Id, testCampaign.Id, null);
        FSR__c testMql3 = buildMQL(null, null, testCampaign.Id, '-7');
        //FSR__c testMql4 = buildMQL(null, unknownLead.Id, testCampaign.Id, '-7');
        FSR__c testMql5 = buildMQL(null, null, null, null);
        insert new List<FSR__c>{testMql1, testMql2, testMql3, /*testMql4,*/ testMql5};

        Map<String, Id> groupMappings = new Map<String, Id>{testUser.Name => TEST_GROUP_ID1,
                                                            testLead.Country => TEST_GROUP_ID2,
                                                            '-7-' + testCampaign.Type => TEST_GROUP_ID3,
                                                            MQLRoundRobinServices.UNKNOWN + '-' + testCampaign.Type => TEST_GROUP_ID4,
                                                            MQLRoundRobinServices.ALL_NULL => TEST_GROUP_ID5
        };

        Map<String, Decimal> priorityMapping = new Map<String, Decimal>{testUser.Name => 1,
                                                                        testLead.Country => 2,
                                                                        '-7-' + testCampaign.Type => 3,
                                                                         MQLRoundRobinServices.UNKNOWN + '-' + testCampaign.Type => 4,
                                                                         MQLRoundRobinServices.ALL_NULL => 5

                                                                       };
        MQLRoundRobinServices.bypassTrigger = false;
        List<FSR__c> mqls = [SELECT Campaign_Id__c, TimeZone__c, State__c, Campaign_Sub_Type__c, Campaign_Type__c, Country__c, Account_Owner__c, Grossreg_Product__c FROM FSR__c];
        Test.startTest();
            Id result1 = MQLRoundRobinServices.findMqlGroupId(mqls[0], groupMappings, priorityMapping);
            Id result2 = MQLRoundRobinServices.findMqlGroupId(mqls[1], groupMappings, priorityMapping);
            Id result3 = MQLRoundRobinServices.findMqlGroupId(mqls[2], groupMappings, priorityMapping);
            //Id result4 = MQLRoundRobinServices.findMqlGroupId(mqls[3], groupMappings);
            Id result5 = MQLRoundRobinServices.findMqlGroupId(mqls[3], groupMappings, priorityMapping);
        Test.stopTest();

        //system.assertEquals(TEST_GROUP_ID1, result1, 'the result id should be equal');
        //system.assertEquals(TEST_GROUP_ID2, result2, 'the result id should be equal');
        //system.assertEquals(TEST_GROUP_ID3, result3, 'the result id should be equal');
        //system.assertEquals(TEST_GROUP_ID4, result4, 'the result id should be equal');
        //system.assertEquals(TEST_GROUP_ID5, result5, 'the result id should be equal');
    }

    /* TEMP DISABLE
    static testMethod void testPrioritizeAssignMQLOwner_Insert()
    {
        final Integer NUM_RECORDS = 10;
        User testMQLOwnerUser = TestDataFactory.createUser('Standard User', 'TUser', 555, TRUE);

        List<Campaign> testCampaigns = TestDataFactory.createCampaignList(NUM_RECORDS);
        for(Campaign aCampaign : testCampaigns)
        {
            aCampaign.Type = 'Event';
        }
        insert testCampaigns;

        List<Contact> testContacts = TestDataFactory.createContactList(NUM_RECORDS);
        insert testContacts;
        List<Lead> testLeads = TestDataFactory.createLeadList(NUM_RECORDS);
        insert testLeads;

        List<CampaignMember> testCampaignMembers = new List<CampaignMember>();
        for(Integer index = 0; index < NUM_RECORDS; index++)
        {
            CampaignMember contactMember = new CampaignMember();
            contactMember.CampaignId = testCampaigns[index].Id;
            contactMember.ContactId = testContacts[index].Id;
            testCampaignMembers.add(contactMember);

            CampaignMember leadMember = new CampaignMember();
            leadMember.CampaignId = testCampaigns[index].Id;
            leadMember.LeadId = testLeads[index].Id;
            testCampaignMembers.add(leadMember);
        }
        insert testCampaignMembers;

        List<FSR__c> testFSRs = new List<FSR__c>();
        for(CampaignMember aMember : testCampaignMembers)
        {
            FSR__c newFSR = buildMQL(aMember.ContactId, aMember.LeadId, aMember.CampaignId, '-7');
            newFSR.Assign_MQL_Owner__c = testMQLOwnerUser.Id;
            testFSRs.add(newFSR);
        }

        Test.startTest();

            insert testFSRs;

        Test.stopTest();

        List<FSR__c> createdMQLs = [ SELECT Id, OwnerId FROM FSR__c ];
        System.assertEquals(NUM_RECORDS * 2, createdMQLs.size(), 'There should be an MQL for every Campaign Member');
        for(FSR__c anMQL : createdMQLs)
        {
            System.assertEquals(testMQLOwnerUser.Id, anMQL.OwnerId, 'The MQLs should have been assigned to the Assign MQL Owner User');
        }
    }

    static testMethod void testUsePreviousOwner_Insert()
    {
        final Integer NUM_RECORDS = 10;
        User adminUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1 ];
        UserRole validRole = [ SELECT Id FROM UserRole WHERE Name LIKE '%BDR%' AND (NOT Name LIKE '%Manager%') LIMIT 1 ];

        List<User> testOwners = new List<User>();
        for(Integer index = 0; index < NUM_RECORDS * 2; index++)
        {
            User testPreviousOwner = TestDataFactory.createUser('Standard User', 'TUser', index, FALSE);
            testPreviousOwner.UserRoleId = validRole.Id;
            testOwners.add(testPreviousOwner);
        }
        System.runAs(adminUser)
        {
            insert testOwners;
        }

        List<Campaign> testCampaigns = TestDataFactory.createCampaignList(NUM_RECORDS);
        for(Campaign aCampaign : testCampaigns)
        {
            aCampaign.Type = 'Event';
        }
        insert testCampaigns;

        List<Contact> testContacts = TestDataFactory.createContactList(NUM_RECORDS);
        insert testContacts;
        List<Lead> testLeads = TestDataFactory.createLeadList(NUM_RECORDS);
        insert testLeads;

        List<CampaignMember> testCampaignMembers = new List<CampaignMember>();
        for(Integer index = 0; index < NUM_RECORDS; index++)
        {
            CampaignMember contactMember = new CampaignMember();
            contactMember.CampaignId = testCampaigns[index].Id;
            contactMember.ContactId = testContacts[index].Id;
            testCampaignMembers.add(contactMember);

            CampaignMember leadMember = new CampaignMember();
            leadMember.CampaignId = testCampaigns[index].Id;
            leadMember.LeadId = testLeads[index].Id;
            testCampaignMembers.add(leadMember);
        }
        insert testCampaignMembers;

        List<FSR__c> oldestFSRs = new List<FSR__c>();
        List<FSR__c> previousFSRs = new List<FSR__c>();
        Map<Id, Id> previousOwnersByLeadOrContact = new Map<Id, Id>();
        for(Integer index = 0; index < NUM_RECORDS * 2; index++)
        {
            CampaignMember aMember = testCampaignMembers[index];
            FSR__c oldFSR = buildMQL(aMember.ContactId, aMember.LeadId, aMember.CampaignId, '-7');
            oldFSR.Name = '' + aMember.CampaignId + aMember.ContactId + aMember.LeadId;
            oldFSR.Requires_MQL_Assignment__c = false;
            oldestFSRs.add(oldFSR);

            FSR__c previousFSR = oldFSR.clone(false, true);
            previousFSR.Name = '' + aMember.LeadId + aMember.ContactId + aMember.CampaignId;
            previousFSR.OwnerId = testOwners[index].Id;
            previousFSRs.add(previousFSR);

            previousOwnersByLeadOrContact.put(aMember.ContactId, testOwners[index].Id);
            previousOwnersByLeadOrContact.put(aMember.LeadId, testOwners[index].Id);
        }
        insert oldestFSRs;
        insert previousFSRs;

        for(FSR__c oldFSR : oldestFSRs)
        {
            Test.setCreatedDate(oldFSR.Id, System.now().addDays(-26));
        }
        for(FSR__c previousFSR : previousFSRs)
        {
            Test.setCreatedDate(previousFSR.Id, System.now().addDays(-25));
        }

        List<FSR__c> testNewFSRs = new List<FSR__c>();
        for(CampaignMember aMember : testCampaignMembers)
        {
            FSR__c newFSR = buildMQL(aMember.ContactId, aMember.LeadId, aMember.CampaignId, '-7');
            newFSR.Name = '' + aMember.Id;
            testNewFSRs.add(newFSR);
        }

        Test.startTest();

            insert testNewFSRs;

        Test.stopTest();

        List<FSR__c> createdMQLs = [ SELECT Id, Lead__c, Contact__c, OwnerId FROM FSR__c WHERE Id IN :testNewFSRs ];
        System.assertEquals(NUM_RECORDS * 2, createdMQLs.size(), 'There should be an MQL for every Campaign Member');
        for(FSR__c anMQL : createdMQLs)
        {
            if(anMQL.Lead__c != NULL)
            {
                System.assertEquals(previousOwnersByLeadOrContact.get(anMQL.Lead__c), anMQL.OwnerId, 'The MQLs should have been assigned to the most recent Owner');
            }
            else
            {
                System.assertEquals(previousOwnersByLeadOrContact.get(anMQL.Contact__c), anMQL.OwnerId, 'The MQLs should have been assigned to the most recent Owner');
            }
        }
    }
    */

    public static FSR__c buildMQL(Id contactId, Id leadId, Id campaignId, String timeZoneOffset){
        return new FSR__c(Contact__c = contactId, Lead__c = leadId, Campaign__c = campaignId, TimeZone__c = timeZoneOffset, Requires_MQL_Assignment__c = true);
    }

    static Assignment_Groups__c buildMember(DateTime assignmentTime, Decimal seconds){
        return new Assignment_Groups__c(Last_Assignment__c = assignmentTime, Millisecond__c = seconds);
    }

    static Assignment_Groups__c buildActiveMember(DateTime assignmentTime, Decimal seconds, Id userId, Id groupId){
        return new Assignment_Groups__c(Last_Assignment__c = assignmentTime, Millisecond__c = seconds, User__c = userId, Active__c = 'true', Group_Name__c = groupId);
    }

    static Group_Mapping__c buildMapping(String owner, String campaignType, String country, String timeZoneOffset, Id groupId, Decimal priority){
        return new Group_Mapping__c(Account_Owner__c = owner, Channel__c = campaignType, Country__c = country, TimeZone__c = timeZoneOffset, Group_Name__c = groupId, Priority__c = priority);
    }
}