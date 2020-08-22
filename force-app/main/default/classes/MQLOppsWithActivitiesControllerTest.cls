@isTest
private class MQLOppsWithActivitiesControllerTest {

    static FSR__c mqlRelatedToContact;
    static FSR__c mqlRelatedToLead;
    static List<Task> tskList;
    static ApexPages.StandardSetController stdSetController;

    static testMethod void mqlRelatedToContact() {
        setupTestRecords();
        System.debug('TEST METHOD: mqlRelatedToContact');

        Apexpages.StandardController con = new ApexPages.StandardController(mqlRelatedToContact);
        MQLOppsWithActivitiesController obj = new MQLOppsWithActivitiesController(con);

        Test.startTest();
        List<MQLOppsWithActivitiesController.ActivityWrapper> activities = obj.ContActivities;
        System.assertEquals(2,activities.size());
        
        List<MQLOppsWithActivitiesController.ActivityWrapper> activities1 = obj.AcctActivities;
        System.assertEquals(8,activities1.size());
        obj.con = stdSetController;
        System.assertEquals(7,obj.getlstOpps().size());
        obj.next();
        obj.previous();
        obj.first1();
        obj.last1();
        obj.first2();
        obj.last2();
        obj.previous2();
        obj.next2();
        Test.stopTest();

    }

    static testMethod void mqlRelatedToLead() {
        setupTestRecords();
        System.debug('TEST METHOD: mqlRelatedToLead');

        Apexpages.StandardController con = new ApexPages.StandardController(mqlRelatedToLead);
        MQLOppsWithActivitiesController obj = new MQLOppsWithActivitiesController(con);

        Test.startTest();
        List<MQLOppsWithActivitiesController.ActivityWrapper> activities = obj.ContActivities;
        System.assertEquals(2,activities.size());
        Test.stopTest();
    }

    static void setupTestRecords() {
        String timeZoneKey = 'America/Los_Angeles';
        User user = TestDataFactory.createUser();
        user.TimeZoneSidKey = timeZoneKey;
        insert user;

        Account acc = new Account(Name = 'Test Acc', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert acc;

        Contact con = new Contact(LastName = 'TestContact', AccountId = acc.Id);
        insert con;

        Lead ld = new Lead(LastName = 'TestLead', Company = 'Test Company');
        insert ld;
        
        List<Opportunity> lstOpp = TestDataFactory.createOpportunityList(7);
        for(opportunity opp: lstOpp){
            opp.StageName = 'Incubate';
            opp.Account = acc;
        }
        insert lstOpp;

        stdSetController = new ApexPages.StandardSetController(lstOpp);
        
        List<FSR__c> mqlList = TestDataFactory.createFSRList(2);
        mqlRelatedToContact = mqlList[0];
        mqlRelatedToContact.Contact__c = con.Id;

        mqlRelatedToLead = mqlList[1];
        mqlRelatedToLead.Lead__c = ld.Id;
        insert mqlList;
        
        Task contactTsk1 = new Task(WhoId = con.Id, WhatId = acc.Id, Subject = 'Email: contact test', ActivityDate = date.today().addDays(1), Status = 'Not Started');
        Task contactTsk2 = new Task(WhoId = con.Id, WhatId = acc.Id, Subject = 'Call: contact test', ActivityDate = date.today().addDays(-1), Status = 'Completed');
        Task leadTsk1 = new Task(WhoId = ld.Id, Subject = 'Email: lead test', ActivityDate = date.today().addDays(1), Status = 'Not Started');
        Task leadTsk2 = new Task(WhoId = ld.Id, Subject = 'Call: lead test', ActivityDate = date.today().addDays(-1), Status = 'Completed');
        Task ActTsk1 = new Task(WhatId = acc.Id, Subject = 'Email: lead test', ActivityDate = date.today().addDays(1), Status = 'Not Started');
        Task ActTsk2 = new Task(WhatId = acc.Id, Subject = 'Call: lead test', ActivityDate = date.today().addDays(-1), Status = 'Completed');
        Task ActTsk3 = new Task(WhatId = acc.Id, Subject = 'Email: lead test', ActivityDate = date.today().addDays(1), Status = 'Not Started');
        Task ActTsk4 = new Task(WhatId = acc.Id, Subject = 'Call: lead test', ActivityDate = date.today().addDays(-1), Status = 'Completed');
        Task ActTsk5 = new Task(WhatId = acc.Id, Subject = 'Email: lead test', ActivityDate = date.today().addDays(1), Status = 'Not Started');
        Task ActTsk6 = new Task(WhatId = acc.Id, Subject = 'Call: lead test', ActivityDate = date.today().addDays(-1), Status = 'Completed');
        tskList = new List<Task>{ contactTsk1, contactTsk2, leadTsk1, leadTsk2,ActTsk1,ActTsk2,ActTsk3,ActTsk4,ActTsk5,ActTsk6 };
        insert tskList;

    }
}