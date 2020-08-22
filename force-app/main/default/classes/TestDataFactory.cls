/****
Class: TestDataFactory
Creates data. Used for Test class
Changes:   18-March-2016 : test class refactored as per new set of guidelines in "Clean Up Unit Tests", Divesh Bafna
           27-May-2016 : Add Campaign_Member_Updated_Date__c field with value as Today in createCampaignMemList method.- Purushottam
           02-Mar-2019 : Add createUser and createTasks for CSM functionality
****/
@IsTest
public with sharing class TestDataFactory {

    public static Lead createLead()
    {
        Lead leadObj = new Lead(Status = 'Open', LastName = 'testLName', Company = 'test');
        return leadObj;
    }

    public static List<Lead> createLeadList(integer Num)
    {
        List<Lead> leadList = new List<Lead>();
        for(integer recordNumber=0; recordNumber < Num ; recordNumber++)
        {
            Lead leadObj = new Lead();
            leadObj.Status = 'Open';
            leadObj.Firstname = 'TestFirstName';
            leadObj.LastName = 'testLName' + recordNumber;
            leadObj.Company = 'test';
            leadList.add(leadObj);
        }
        return leadList ;
    }

    public static List<account> createAccountList(integer Num)
    {
        List<account> accountList = new List<account>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++)
        {
            account acc = new account();
            acc.name = 'AccountTest' + recordNumber;
            acc.Channel_Account_Status__c = 'Inactive';
            accountList.add(acc);
        }
        return accountList ;
    }

    public static List<Contact> createContactList(integer Num)
    {
        List<contact> conList = new List<contact>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++)
        {
            contact con = new contact();
            con.firstname = 'con' + recordNumber + ' ';
            con.lastname = 'test' + recordNumber ;
            con.Title = 'CFO';
            con.Preferred_Email__c = 'test@test'+recordNumber +'.com';
            con.Eloqua_Lead_Rating__c = 'A'+recordNumber ;
            conList.add(con);
        }
        return conList;

    }

    public static List<Account_SID__c> createAccSIDList(integer Num){

        List<Account_SID__c> accSIDList = new List<Account_SID__c>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++)
        {
            Account_SID__c aSID = new Account_SID__c();
            aSID.name = 'SID'+recordNumber;
            aSID.OwnerUser_SID__c = '1234567'+recordNumber;
            aSID.OwnerUser_Email_Address__c = 'cont'+recordNumber+'@xyz.com';
            accSIDList.add(aSID);
        }
        return accSIDList ;
    }


     public static List<opportunity> createOpportunityList(integer Num)
    {
        List<opportunity> oppList = new List<opportunity>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++)
        {
            opportunity opp = new opportunity();
            opp.name = 'test opp' + recordNumber;
            opp.amount = 321.00;
            opp.ForecastCategoryName = 'Omitted';
            opp.StageName = 'Qualified';
            opp.CloseDate = date.today() + 20 ;
            opp.Launch_Date__c = date.today();
            opp.FY_16_Primary_Product__c = 'Programmable Authentication (Authy)';
            opp.FY_16_Use_Case__c = 'Account Verification';
            oppList.add(opp);
        }
        return oppList;

    }

    public static List<Account_Sid_Mapping__c> createAccSIDmappingList(integer Num){
        List<Account_Sid_Mapping__c> accSIDList= new List<Account_Sid_Mapping__c>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++)
        {
            Account_Sid_Mapping__c asm = new Account_Sid_Mapping__c();
            asm.Object_API_Name__c = 'Lead';
            asm.Source_Field_API_Name__c = 'OwnerUser_SID__c';
            asm.Target_Field_API_Name__c = 'OwnerUser_SID__c';
            asm.name = 'Test Field Map'+recordNumber;
            accSIDList.add(asm);
        }
        return accSIDList ;
    }

    public static List<Campaign> createCampaignList(integer Num){
        List<Campaign> campList = new List<Campaign>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++ ){
            Campaign camp = new Campaign();
            camp.name='testcampaign'+recordNumber ;
            camp.Type='Growth';
            camp.SubType__c = 'Support';
            camp.Product_Type__c = 'Support';
            campList.add(camp);
        }
        return campList ;
    }

    public static List<CampaignMember> createCampaignMemList(integer Num){
        List<CampaignMember> campMemList = new List<CampaignMember>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++ ){
            CampaignMember campMem = new CampaignMember (Status = 'Responded',
            UTM_Content__c = 'C'+recordNumber,
            UTM_Medium__c  = 'M' + recordNumber,
            UTM_Source__c = 'S'+recordNumber,
            UTM_Term__c = 'T'+recordNumber,
            Campaign_Member_Updated_Date__c = System.today());
            campMemList.add(campMem)  ;
        }
        return campMemList ;
    }

    public static List<FSR__c> createFSRList(integer Num){
        List<FSR__c> fSRList = new List<FSR__c>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++){

            Blob blobKey = Crypto.GenerateAESKey(128);
            String hexKey = EncodingUtil.ConvertTohex(blobKey);
            String uniqueKey = hexKey.substring(hexKey.length() - (hexKey.length()/4));

            FSR__c fSRRecord= new FSR__c ();
            fSRRecord.name = uniqueKey+recordNumber;
            fSRRecord.FSR_Key__c = uniqueKey+recordNumber;
            fSRList.add(fSRRecord);
        }
        return fSRList;
    }

    public static list<Lifecycle_Field_Funnel__c > createlFFList(integer Num){
        List<Lifecycle_Field_Funnel__c > lFFList = new List<Lifecycle_Field_Funnel__c >();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++){
            Lifecycle_Field_Funnel__c newLFF = new Lifecycle_Field_Funnel__c ();
            lFFList.add(newLFF);
        }
        return lFFList ;
    }

    public static list<Use_Case_Interest__c> createUCIList(integer Num){
        List<Use_Case_Interest__c> uciList = new List<Use_Case_Interest__c>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++){
            Use_Case_Interest__c uci = new Use_Case_Interest__c();
            uci .FY_16_Primary_Product__c = 'Programmable Authentication (Authy)';
            uci .FY_16_Use_Case__c = 'Account Verification';
            uci .Status__c = 'Open';
            uciList.add(uci);
        }
        return uciList ;
    }

    public static list<OpportunityContactRole> createOppConRole(integer Num){
        List<OpportunityContactRole> oppConList = new List<OpportunityContactRole>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++){
            OpportunityContactRole oppConRole = new OpportunityContactRole();
            oppConRole.isPrimary = true;
            oppConList.add(oppConRole);
        }
        return oppConList;
    }


    public static List<Twilio_Usage__c> createTwilioUsages(integer Num){
        List<Twilio_Usage__c> tUsageList = new List<Twilio_Usage__c>();
        for(integer recordNumber=0; recordNumber < Num; recordNumber++){
            Twilio_Usage__c TwUsage= new Twilio_Usage__c();
            TwUsage.name = 'Test TU'+ recordNumber ;
            TwUsage.AccountSid__c= 'Test Sid ' + 0;
            TwUsage.Month__c= date.today().month();
            TwUsage.Product__c = 'Test Product';
            TwUsage.Currency__c= 'Test currency' ;
            TwUsage.Total__c= 100 ;
            TwUsage.CounterKey__c= 'Test Key'+recordNumber ;
            TwUsage.Year__c= date.today().year();
            TwUsage.Volume__c= 10 ;
            TwUsage.Owner_User_ID__c= '123456780';
            TwUsage.Magic_User_ID__c= '12365478956';
            tUsageList.add(TwUsage);
        }
        return tUsageList;
    }

    public static Task createTask()
    {
        User userObj = createUser();
        insert userObj;
        Lead leadObj = createLeadList(1)[0];
        insert leadObj;
        String emailcontent = 'Additional To:test@email.com \n Test, \n Business Development Rep \n Twilio test \n'
                               + ' On Mon, May 27, 2013 at 2:18 PM, Test, USer <test@email.com \n '
                               +' Test, \n Business Development Rep \n Twilio test \n';

        Task taskObj = new Task(Subject = 'test subject', Status = 'Not Started', Priority = 'Normal', OwnerId = userObj.Id,
                                 Description = emailcontent, WhoId = leadObj.Id);
        return taskObj;
    }
    public static User createUser()
    {
        Profile p = [Select Id, Name from Profile where Name = 'System Administrator'];
        String namePrefix = 'TestUser' + math.rint(math.random() * 100000);
        AggregateResult[] userCount = [Select count(id) userCount From user where username like :namePrefix];
        Object users = userCount[0].get('userCount');

        User testUser = new User();
        testUser.Email = 'test@test.com';
        testUser.Username = namePrefix+users+'@testuser.test';
        testUser.LastName = 'testManager';
        testUser.Alias = 'testM';
        testUser.ProfileId = p.Id;
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.TimeZoneSidKey = 'America/Chicago';
        testUser.EmailEncodingKey = 'UTF-8';
        //insert testUser;
        return testUser;
    }
    public static void createTaskHelperConstant()
    {
        //TaskHelperConstant__c taskHelperConstant = new TaskHelperConstant__c(Name = 'Responded' ,Signature__c = 'Business Development Rep');
        List<TaskHelperConstant__c> taskhelperList = new List<TaskHelperConstant__c>{new TaskHelperConstant__c(Name = 'Responded' ,Signature__c = 'Business Development Rep'),
                                                     new TaskHelperConstant__c(Name = 'BDR Engaged' ,Signature__c = 'Business Development Representative')};
        insert taskhelperList;
        //TaskHelperConstant__c taskHelperConstant = new TaskHelperConstant__c(Name = 'BDR Engaged' ,Signature__c = 'Business Development Representative');
    }

    public static List<Forecast_Schedule__c> createForecastSchedules( Integer numSchedules, Id opportunityId, Date startDate, Decimal forecastAmount )
    {
        List<Forecast_Schedule__c> testSchedules = new List<Forecast_Schedule__c>();
        for( Integer index = 0; index < numSchedules; index++ )
        {
            Forecast_Schedule__c newSchedule = new Forecast_Schedule__c();
            newSchedule.Opportunity__c = opportunityId;
            newSchedule.Forecast_Amount__c = forecastAmount;
            newSchedule.Start_Date__c = startDate;
            startDate = startDate.addMonths(1).toStartOfMonth();
            newSchedule.End_Date__c = startDate.addDays(-1);
            testSchedules.add( newSchedule );
        }

        return testSchedules;
    }

    public static User createUser(String profileName, String userFullName, Integer uniqueSuffix, Boolean doInsert)
    {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));

        //this will make sure user names are unique
        String uniqueName = orgId + dateString + randomInt;

        Profile profile = [ Select Id From Profile Where Name = :profileName limit 1 ];

        User userRecord = new User(UserName = uniqueName+'@test.com' + uniqueSuffix,
                                   Email = uniqueName+'@test.com' + uniqueSuffix,
                                   EmailEncodingKey = 'UTF-8',
                                   LastName = userFullName ,
                                   LanguageLocaleKey = 'en_US',
                                   TimeZoneSidKey = 'America/Los_Angeles',
                                   LocaleSidKey = 'en_US',
                                   Alias = 'user ' + uniqueSuffix,
                                   ProfileId = profile.Id
                                  );
        if(doInsert)
        {
            insert userRecord;
        }
        return userRecord;
    }

    public static List<Task> createTasks(Integer counter,Id whatId, Boolean doInsert)
    {
        List<Task> taskList = new List<Task>();

        for(Integer i=0 ; i < counter ;i++)
        {
            Task taskObj = new Task();
            taskObj.WhatId = whatId;
            taskObj.OwnerId = UserInfo.getUserId();
            taskObj.Subject = 'Test Subject'+i;
            taskObj.Status = 'Completed';
            taskObj.Priority = 'Email';
            taskList.add(taskObj);
        }
        if(doInsert)
        {
            insert taskList;
        }
        return taskList;
    }


}