@isTest
private class BatchUCInterestToLFF_Test{

    static List<Lead> leadList = new List<Lead>();
    static List<Use_Case_Interest__c> useInterests = new List<Use_Case_Interest__c>();
    static List<Lifecycle_Field_Funnel__c> lFFList = new List<Lifecycle_Field_Funnel__c>();
    static List<Contact> conList = new List<Contact>();
    static List<opportunity> newoppList = new List<opportunity>();
    static List<opportunity> newoppList2 = new List<opportunity>();
    static Account account;
    static integer NumberOfRec = 2;
    static List<Campaign> campList = new List<Campaign>();
    static List<CampaignMember> campMemList = new List<CampaignMember>();


    static void createConData(){
        account = new account();
        account.name = 'AccountTest';
        account.Channel_Account_Status__c = 'Inactive';
        insert account;

        conList = TestDataFactory.createContactList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            conList[rec].accountid = account.id;
        }
        insert conList;

        newoppList = TestDataFactory.createOpportunityList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            newoppList [rec].accountid = account.id;
        }
        insert newoppList ;

        newoppList2 = TestDataFactory.createOpportunityList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            newoppList2[rec].StageName = 'Closed Won';
            newoppList2[rec].accountid = account.id;
        }
        insert newoppList2 ;

    }

    static void createLeadData(){
        leadList = TestDataFactory.createLeadList(NumberOfRec);
        for(integer rec = 0; rec < NumberOfRec ; rec++ ){
            leadList[rec].status = 'Contacted';
            leadList[rec].Eloqua_Lead_Rating__c = 'A' + rec;
        }
        insert leadList;

    }

    static testMethod void testLeadCreateLFFRecordNoLLF(){
        createLeadData();

        List<Use_Case_Interest__c> uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].lead__c = leadList[rec].id;
        }
        insert uciList ;

         campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].leadid = leadList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        //query LFFs to ensure appropriate fields being set

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT Id,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,lead__c,Last_Touch_Campaign_Member_Status__c,First_Touch_Campaign_Member_Status__c,First_Touch_UTM_Content__c,Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,Inquiry_Date_Entered__c, SAL_Date_Entered__c FROM Lifecycle_Field_Funnel__c WHERE Use_Case_Interest__c IN : uciList AND LFF_Active__c = TRUE];
        System.assertEquals(NumberOfRec, newLLFList.size(), 'Should return 1 LFF record from the query');

        map<id,Lifecycle_Field_Funnel__c> LFFleadMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFleadMap.put(lff.lead__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,Status,leadid,createdDate,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> leadCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            leadCampMap.put(cm.leadid,cm);
        }


        for(id con : LFFleadMap.keyset())
        {
            System.assertNotEquals(null, LFFleadMap.get(con).SAL_Date_Entered__c, 'SAL_Date_Entered__c should be set to today');

            System.assertEquals(leadCampMap.get(con).id, LFFleadMap.get(con).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(con).UTM_Content__c, LFFleadMap.get(con).First_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(con).UTM_Medium__c , LFFleadMap.get(con).First_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(con).UTM_Source__c , LFFleadMap.get(con).First_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(con).UTM_Term__c , LFFleadMap.get(con).First_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(con).CreatedDate, LFFleadMap.get(con).First_Touch_Associated_Date__c );
            System.assertEquals(leadCampMap.get(con).Campaignid, LFFleadMap.get(con).First_Touch_Campaign__c );

            System.assertEquals(leadCampMap.get(con).id, LFFleadMap.get(con).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(con).UTM_Content__c, LFFleadMap.get(con).Last_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(con).UTM_Medium__c , LFFleadMap.get(con).Last_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(con).UTM_Source__c , LFFleadMap.get(con).Last_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(con).UTM_Term__c , LFFleadMap.get(con).Last_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(con).CreatedDate, LFFleadMap.get(con).Last_Touch_Associated_Date__c );
            System.assertEquals(leadCampMap.get(con).Campaignid, LFFleadMap.get(con).Last_Touch_Campaign__c );
            System.assertEquals(leadCampMap.get(con).Status, LFFleadMap.get(con).First_Touch_Campaign_Member_Status__c );
            System.assertEquals(leadCampMap.get(con).Status, LFFleadMap.get(con).Last_Touch_Campaign_Member_Status__c );
            System.assertEquals(leadCampMap.get(con).CreatedDate, LFFleadMap.get(con).Inquiry_Date_Entered__c );

            System.assertEquals(leadCampMap.get(con).Campaign.Type,LFFleadMap.get(con).First_Touch_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.SubType__c,LFFleadMap.get(con).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Product_Type__c,LFFleadMap.get(con).First_Touch_Product__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Product_Type__c,LFFleadMap.get(con).Last_Touch_Campaign_Product__c);
            System.assertEquals(leadCampMap.get(con).Campaign.SubType__c,LFFleadMap.get(con).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Type,LFFleadMap.get(con).Last_Touch_Campaign_Type__c);


            System.assertEquals(leadCampMap.get(con).CampaignId,LFFleadMap.get(con).Last_Touch_SQL_Campaign__c);
            System.assertEquals(leadCampMap.get(con).Status,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(leadCampMap.get(con).createdDate,LFFleadMap.get(con).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Type,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.SubType__c,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(con).UTM_Content__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(con).UTM_Medium__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(leadCampMap.get(con).UTM_Source__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(leadCampMap.get(con).UTM_Term__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Product_Type__c,LFFleadMap.get(con).Last_SQL_Touch_Product__c);
            System.assertEquals(leadCampMap.get(con).id,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Member_ID__c);

        }
    }

    static testMethod void testContactCreateLFFRecordNoLLF(){
        createConData();

       List<Use_Case_Interest__c> uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].contact__c= conList[rec].id;
        }
        insert uciList ;

         campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        //query LFFs to ensure appropriate fields being set
        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT Id,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,contact__c,Last_Touch_Campaign_Member_Status__c,First_Touch_Campaign_Member_Status__c,First_Touch_UTM_Content__c,Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,Inquiry_Date_Entered__c, SAL_Date_Entered__c FROM Lifecycle_Field_Funnel__c WHERE Use_Case_Interest__c IN : uciList AND LFF_Active__c = TRUE];
        System.assertEquals(NumberOfRec, newLLFList.size(), 'Should return 1 LFF record from the query');

        map<id,Lifecycle_Field_Funnel__c> LFFconMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFconMap.put(lff.contact__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,Status,contactid,createdDate,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }


        for(id con : LFFconMap.keyset())
        {
            System.assertNotEquals(null, LFFconMap.get(con).SAL_Date_Entered__c, 'SAL_Date_Entered__c should be set to today');

            System.assertEquals(contactCampMap.get(con).id, LFFconMap.get(con).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c, LFFconMap.get(con).First_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c , LFFconMap.get(con).First_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(con).UTM_Source__c , LFFconMap.get(con).First_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(con).UTM_Term__c , LFFconMap.get(con).First_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(con).CreatedDate, LFFconMap.get(con).First_Touch_Associated_Date__c );
            System.assertEquals(contactCampMap.get(con).Campaignid, LFFconMap.get(con).First_Touch_Campaign__c );

            System.assertEquals(contactCampMap.get(con).id, LFFconMap.get(con).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c, LFFconMap.get(con).Last_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c , LFFconMap.get(con).Last_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(con).UTM_Source__c , LFFconMap.get(con).Last_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(con).UTM_Term__c , LFFconMap.get(con).Last_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(con).CreatedDate, LFFconMap.get(con).Last_Touch_Associated_Date__c );
            System.assertEquals(contactCampMap.get(con).Campaignid, LFFconMap.get(con).Last_Touch_Campaign__c );
            System.assertEquals(contactCampMap.get(con).Status, LFFconMap.get(con).First_Touch_Campaign_Member_Status__c );
            System.assertEquals(contactCampMap.get(con).Status, LFFconMap.get(con).Last_Touch_Campaign_Member_Status__c );
            System.assertEquals(contactCampMap.get(con).CreatedDate, LFFconMap.get(con).Inquiry_Date_Entered__c );

            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).First_Touch_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).First_Touch_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).Last_Touch_Campaign_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).Last_Touch_Campaign_Type__c);

            System.assertEquals(contactCampMap.get(con).CampaignId,LFFconMap.get(con).Last_Touch_SQL_Campaign__c);
            System.assertEquals(contactCampMap.get(con).Status,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(contactCampMap.get(con).createdDate,LFFconMap.get(con).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(contactCampMap.get(con).UTM_Source__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(contactCampMap.get(con).UTM_Term__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).Last_SQL_Touch_Product__c);
            System.assertEquals(contactCampMap.get(con).id,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_ID__c);

        }
    }

    static testMethod void testLeadCreateLFFRecordExistingLLF(){
        createLeadData();

        List<Use_Case_Interest__c> uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].lead__c= leadlist[rec].id;
        }
        insert uciList ;

         campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].leadid = leadlist[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        //query LFFs to ensure appropriate fields being set
        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT Id,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,lead__c,Last_Touch_Campaign_Member_Status__c,First_Touch_Campaign_Member_Status__c,First_Touch_UTM_Content__c,Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,Inquiry_Date_Entered__c, SAL_Date_Entered__c FROM Lifecycle_Field_Funnel__c WHERE Use_Case_Interest__c IN : uciList AND LFF_Active__c = TRUE];
        System.assertEquals(NumberOfRec, newLLFList.size(), 'Should return 1 LFF record from the query');

        map<id,Lifecycle_Field_Funnel__c> LFFleadMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFleadMap.put(lff.lead__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,Status,leadid,createdDate,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> leadCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            leadCampMap.put(cm.leadid,cm);
        }


        for(id con : LFFleadMap.keyset())
        {
            System.assertNotEquals(null, LFFleadMap.get(con).SAL_Date_Entered__c, 'SAL_Date_Entered__c should be set to today');

            System.assertEquals(leadCampMap.get(con).id, LFFleadMap.get(con).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(con).UTM_Content__c, LFFleadMap.get(con).First_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(con).UTM_Medium__c , LFFleadMap.get(con).First_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(con).UTM_Source__c , LFFleadMap.get(con).First_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(con).UTM_Term__c , LFFleadMap.get(con).First_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(con).CreatedDate, LFFleadMap.get(con).First_Touch_Associated_Date__c );
            System.assertEquals(leadCampMap.get(con).Campaignid, LFFleadMap.get(con).First_Touch_Campaign__c );

            System.assertEquals(leadCampMap.get(con).id, LFFleadMap.get(con).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(con).UTM_Content__c, LFFleadMap.get(con).Last_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(con).UTM_Medium__c , LFFleadMap.get(con).Last_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(con).UTM_Source__c , LFFleadMap.get(con).Last_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(con).UTM_Term__c , LFFleadMap.get(con).Last_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(con).CreatedDate, LFFleadMap.get(con).Last_Touch_Associated_Date__c );
            System.assertEquals(leadCampMap.get(con).Campaignid, LFFleadMap.get(con).Last_Touch_Campaign__c );
            System.assertEquals(leadCampMap.get(con).Status, LFFleadMap.get(con).First_Touch_Campaign_Member_Status__c );
            System.assertEquals(leadCampMap.get(con).Status, LFFleadMap.get(con).Last_Touch_Campaign_Member_Status__c );
            System.assertEquals(leadCampMap.get(con).createddate, LFFleadMap.get(con).Inquiry_Date_Entered__c );

            System.assertEquals(leadCampMap.get(con).Campaign.Type,LFFleadMap.get(con).First_Touch_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.SubType__c,LFFleadMap.get(con).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Product_Type__c,LFFleadMap.get(con).First_Touch_Product__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Product_Type__c,LFFleadMap.get(con).Last_Touch_Campaign_Product__c);
            System.assertEquals(leadCampMap.get(con).Campaign.SubType__c,LFFleadMap.get(con).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Type,LFFleadMap.get(con).Last_Touch_Campaign_Type__c);

            System.assertEquals(leadCampMap.get(con).CampaignId,LFFleadMap.get(con).Last_Touch_SQL_Campaign__c);
            System.assertEquals(leadCampMap.get(con).Status,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(leadCampMap.get(con).createdDate,LFFleadMap.get(con).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Type,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.SubType__c,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(con).UTM_Content__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(con).UTM_Medium__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(leadCampMap.get(con).UTM_Source__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(leadCampMap.get(con).UTM_Term__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Product_Type__c,LFFleadMap.get(con).Last_SQL_Touch_Product__c);
            System.assertEquals(leadCampMap.get(con).id,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Member_ID__c);
        }
    }

    static testMethod void testContactCreateLFFRecordExistingLLF(){
        createConData();

       List<Use_Case_Interest__c> uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].contact__c= conList[rec].id;
        }
        insert uciList ;

         campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        //query LFFs to ensure appropriate fields being set
        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT Id,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,contact__c,Last_Touch_Campaign_Member_Status__c,First_Touch_Campaign_Member_Status__c,First_Touch_UTM_Content__c,Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,Inquiry_Date_Entered__c, SAL_Date_Entered__c FROM Lifecycle_Field_Funnel__c WHERE Use_Case_Interest__c IN : uciList AND LFF_Active__c = TRUE];
        //System.assertEquals(NumberOfRec, newLLFList.size(), 'Should return 1 LFF record from the query');

        map<id,Lifecycle_Field_Funnel__c> LFFconMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFconMap.put(lff.contact__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,Status,contactid,createdDate,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }


        for(id con : LFFconMap.keyset())
        {
            System.assertNotEquals(null, LFFconMap.get(con).SAL_Date_Entered__c, 'SAL_Date_Entered__c should be set to today');

            System.assertEquals(contactCampMap.get(con).id, LFFconMap.get(con).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c, LFFconMap.get(con).First_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c , LFFconMap.get(con).First_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(con).UTM_Source__c , LFFconMap.get(con).First_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(con).UTM_Term__c , LFFconMap.get(con).First_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(con).CreatedDate, LFFconMap.get(con).First_Touch_Associated_Date__c );
            System.assertEquals(contactCampMap.get(con).Campaignid, LFFconMap.get(con).First_Touch_Campaign__c );

            System.assertEquals(contactCampMap.get(con).id, LFFconMap.get(con).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c, LFFconMap.get(con).Last_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c , LFFconMap.get(con).Last_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(con).UTM_Source__c , LFFconMap.get(con).Last_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(con).UTM_Term__c , LFFconMap.get(con).Last_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(con).CreatedDate, LFFconMap.get(con).Last_Touch_Associated_Date__c );
            System.assertEquals(contactCampMap.get(con).Campaignid, LFFconMap.get(con).Last_Touch_Campaign__c );

            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).First_Touch_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).First_Touch_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).Last_Touch_Campaign_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).Last_Touch_Campaign_Type__c);

            System.assertEquals(contactCampMap.get(con).CampaignId,LFFconMap.get(con).Last_Touch_SQL_Campaign__c);
            System.assertEquals(contactCampMap.get(con).Status,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(contactCampMap.get(con).createdDate,LFFconMap.get(con).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(contactCampMap.get(con).UTM_Source__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(contactCampMap.get(con).UTM_Term__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).Last_SQL_Touch_Product__c);
            System.assertEquals(contactCampMap.get(con).id,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_ID__c);

        }
    }


    static testMethod void testLeadCreateLFFRecordInactiveLLF(){
        createLeadData();

        List<Use_Case_Interest__c> uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].lead__c= leadlist[rec].id;
        }
        insert uciList ;

        List<Lifecycle_Field_Funnel__c > newlFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            newlFFList[rec].lead__c = leadlist[rec].id;
        }
        insert lFFList ;

         campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].leadid = leadlist[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        //query LFFs to ensure appropriate fields being set
        List<CampaignMember> cMList = [SELECT id,createdDate,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,campaignid from CampaignMember where id IN :campMemList ];

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT Id,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,First_Touch_UTM_Content__c,Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,Inquiry_Date_Entered__c, SAL_Date_Entered__c FROM Lifecycle_Field_Funnel__c WHERE Use_Case_Interest__c IN :useInterests AND LFF_Active__c = TRUE];
        System.assertEquals(0, newLLFList.size(), 'Should return 0 LFF record from the query');
    }


    static testMethod void testContactCreateLFFRecordInactiveLLF(){
        createConData();

        List<Use_Case_Interest__c> uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].contact__c= conList[rec].id;
        }
        insert uciList ;

        List<Lifecycle_Field_Funnel__c > newlFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            newlFFList[rec].contact__c = conList[rec].id;
            newlFFList[rec].opportunity__c = newoppList2[rec].id;
        }
        insert lFFList ;

         campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        //query LFFs to ensure appropriate fields being set
        List<CampaignMember> cMList = [SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,createdDate,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,campaignid from CampaignMember where id IN: campMemList ];

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT Id,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,First_Touch_UTM_Content__c,Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,Inquiry_Date_Entered__c, SAL_Date_Entered__c FROM Lifecycle_Field_Funnel__c WHERE Use_Case_Interest__c IN :useInterests AND LFF_Active__c = TRUE];
        System.assertEquals(0, newLLFList.size(), 'Should return 0 LFF record from the query');
    }

    static testMethod void testContactCreateLFFRecordNoLLFDefConstructor(){
        createConData();

        List<Use_Case_Interest__c> uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].contact__c= conList[rec].id;
        }
        insert uciList ;

        campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF();
            database.executebatch(bat);
            System.schedule('LFF UCI Batch Chain - Hourly Test', '0 0 * * * ?', new BatchUCInterestToLFF());
        test.stopTest();

        //query LFFs to ensure appropriate fields being set
        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT Id,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,contact__c,Last_Touch_Campaign_Member_Status__c,First_Touch_Campaign_Member_Status__c,First_Touch_UTM_Content__c,Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,Inquiry_Date_Entered__c, SAL_Date_Entered__c FROM Lifecycle_Field_Funnel__c WHERE Use_Case_Interest__c IN : uciList AND LFF_Active__c = TRUE];
        System.assertEquals(NumberOfRec, newLLFList.size(), 'Should return 1 LFF record from the query');

        map<id,Lifecycle_Field_Funnel__c> LFFconMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFconMap.put(lff.contact__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,Status,contactid,createdDate,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }


        for(id con : LFFconMap.keyset())
        {
            System.assertNotEquals(null, LFFconMap.get(con).SAL_Date_Entered__c, 'SAL_Date_Entered__c should be set to today');

            System.assertEquals(contactCampMap.get(con).id, LFFconMap.get(con).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c, LFFconMap.get(con).First_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c , LFFconMap.get(con).First_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(con).UTM_Source__c , LFFconMap.get(con).First_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(con).UTM_Term__c , LFFconMap.get(con).First_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(con).CreatedDate, LFFconMap.get(con).First_Touch_Associated_Date__c );
            System.assertEquals(contactCampMap.get(con).Campaignid, LFFconMap.get(con).First_Touch_Campaign__c );

            System.assertEquals(contactCampMap.get(con).id, LFFconMap.get(con).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c, LFFconMap.get(con).Last_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c , LFFconMap.get(con).Last_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(con).UTM_Source__c , LFFconMap.get(con).Last_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(con).UTM_Term__c , LFFconMap.get(con).Last_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(con).CreatedDate, LFFconMap.get(con).Last_Touch_Associated_Date__c );
            System.assertEquals(contactCampMap.get(con).Campaignid, LFFconMap.get(con).Last_Touch_Campaign__c );

            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).First_Touch_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).First_Touch_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).Last_Touch_Campaign_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).Last_Touch_Campaign_Type__c);

            System.assertEquals(contactCampMap.get(con).CampaignId,LFFconMap.get(con).Last_Touch_SQL_Campaign__c);
            System.assertEquals(contactCampMap.get(con).Status,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(contactCampMap.get(con).createdDate,LFFconMap.get(con).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(contactCampMap.get(con).UTM_Source__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(contactCampMap.get(con).UTM_Term__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).Last_SQL_Touch_Product__c);
            System.assertEquals(contactCampMap.get(con).id,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_ID__c);

        }
    }

    static testMethod void testContactCreateLFFRecordExistingLLFWrongCampaign(){
        createConData();

         List<Use_Case_Interest__c> uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].contact__c= conList[rec].id;
        }
        insert uciList ;

        List<Lifecycle_Field_Funnel__c > newlFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            newlFFList[rec].contact__c = conList[rec].id;
            newlFFList[rec].Use_Case_Interest__c= uciList[rec].id;
        }
        insert lFFList ;

         campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
            campMemList[rec].Status = 'Sent';
        }
        insert campMemList ;

        test.startTest();
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        //query LFFs to ensure appropriate fields being set
        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT Id,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,contact__c,Last_Touch_Campaign_Member_Status__c,First_Touch_Campaign_Member_Status__c,First_Touch_UTM_Content__c,Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,Inquiry_Date_Entered__c, SAL_Date_Entered__c FROM Lifecycle_Field_Funnel__c WHERE Use_Case_Interest__c IN : uciList AND LFF_Active__c = TRUE];
        System.assertEquals(NumberOfRec, newLLFList.size(), 'Should return 1 LFF record from the query');

        map<id,Lifecycle_Field_Funnel__c> LFFconMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFconMap.put(lff.contact__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,Status,contactid,createdDate,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }


        for(id con : LFFconMap.keyset())
        {
            System.assertNotEquals(null, LFFconMap.get(con).SAL_Date_Entered__c, 'SAL_Date_Entered__c should be set to today');
            System.assertEquals(null, LFFconMap.get(con).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(null, LFFconMap.get(con).First_Touch_UTM_Content__c);
            System.assertEquals(null , LFFconMap.get(con).First_Touch_UTM_Medium__c );
            System.assertEquals(null , LFFconMap.get(con).First_Touch_UTM_Source__c );
            System.assertEquals(null , LFFconMap.get(con).First_Touch_UTM_Term__c );
            System.assertEquals(null, LFFconMap.get(con).First_Touch_Associated_Date__c );
            System.assertEquals(null, LFFconMap.get(con).First_Touch_Campaign__c );

            System.assertEquals(null, LFFconMap.get(con).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(null, LFFconMap.get(con).Last_Touch_UTM_Content__c);
            System.assertEquals(null , LFFconMap.get(con).Last_Touch_UTM_Medium__c );
            System.assertEquals(null , LFFconMap.get(con).Last_Touch_UTM_Source__c );
            System.assertEquals(null , LFFconMap.get(con).Last_Touch_UTM_Term__c );
            System.assertEquals(null, LFFconMap.get(con).Last_Touch_Associated_Date__c );
            System.assertEquals(null, LFFconMap.get(con).Last_Touch_Campaign__c );

            System.assertEquals(null,LFFconMap.get(con).First_Touch_Campaign_Type__c);
            System.assertEquals(null,LFFconMap.get(con).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(null,LFFconMap.get(con).First_Touch_Product__c);
            System.assertEquals(null,LFFconMap.get(con).Last_Touch_Campaign_Product__c);
            System.assertEquals(null,LFFconMap.get(con).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(null,LFFconMap.get(con).Last_Touch_Campaign_Type__c);

             System.assertEquals(null,LFFconMap.get(con).Last_Touch_SQL_Campaign__c);
            System.assertEquals(null,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(null,LFFconMap.get(con).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(null,LFFconMap.get(con).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(null,LFFconMap.get(con).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(null,LFFconMap.get(con).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(null,LFFconMap.get(con).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(null,LFFconMap.get(con).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(null,LFFconMap.get(con).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(null,LFFconMap.get(con).Last_SQL_Touch_Product__c);
            System.assertEquals(null,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_ID__c);
        }
    }

    static testMethod void testLeadCampaignmemberForExistingLLF(){
        createLeadData();

        List<Use_Case_Interest__c> uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].lead__c= leadlist[rec].id;
        }
        insert uciList ;

        lFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            lFFList[rec].Use_Case_Interest__c= uciList[rec].id;
            lFFList[rec].Lead__c = leadlist[rec].id;
        }
        insert lFFList ;

         campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].leadid = leadlist[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchUCInterestToLFF bat = new BatchUCInterestToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        //query LFFs to ensure appropriate fields being set
        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT Id,Last_Touch_SQL_Campaign_Member_ID__c,First_Touch_Campaign_Type__c,First_Touch_Campaign_Sub_Type__c,First_Touch_Product__c,Last_Touch_Campaign_Product__c,Last_Touch_Campaign_Sub_Type__c,Last_Touch_Campaign_Type__c,Last_SQL_Touch_Product__c,Last_SQL_Touch_UTM_Term__c,Last_SQL_Touch_UTM_Source__c,Last_SQL_Touch_UTM_Medium__c,Last_SQL_Touch_UTM_Content__c,Last_Touch_SQL_Campaign_Sub_Type__c,Last_Touch_SQL_Campaign_Type__c,Last_Touch_SQL_Associated_Date__c,Last_Touch_SQL_Campaign__c,Last_Touch_SQL_Campaign_Member_Status__c,lead__c,Last_Touch_Campaign_Member_Status__c,First_Touch_Campaign_Member_Status__c,First_Touch_UTM_Content__c,Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c ,First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,Inquiry_Date_Entered__c, SAL_Date_Entered__c FROM Lifecycle_Field_Funnel__c WHERE Id IN : lFFList];
        System.assertEquals(NumberOfRec, newLLFList.size(), 'Should return 1 LFF record from the query');

        map<id,Lifecycle_Field_Funnel__c> LFFleadMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFleadMap.put(lff.lead__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c,Status,leadid,createdDate,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> leadCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            leadCampMap.put(cm.leadid,cm);
        }


        for(id con : LFFleadMap.keyset())
        {
            System.assertNotEquals(null, LFFleadMap.get(con).SAL_Date_Entered__c, 'SAL_Date_Entered__c should be set to today');

            System.assertEquals(leadCampMap.get(con).id, LFFleadMap.get(con).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(con).UTM_Content__c, LFFleadMap.get(con).First_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(con).UTM_Medium__c , LFFleadMap.get(con).First_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(con).UTM_Source__c , LFFleadMap.get(con).First_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(con).UTM_Term__c , LFFleadMap.get(con).First_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(con).CreatedDate, LFFleadMap.get(con).First_Touch_Associated_Date__c );
            System.assertEquals(leadCampMap.get(con).Campaignid, LFFleadMap.get(con).First_Touch_Campaign__c );

            System.assertEquals(leadCampMap.get(con).id, LFFleadMap.get(con).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(con).UTM_Content__c, LFFleadMap.get(con).Last_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(con).UTM_Medium__c , LFFleadMap.get(con).Last_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(con).UTM_Source__c , LFFleadMap.get(con).Last_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(con).UTM_Term__c , LFFleadMap.get(con).Last_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(con).CreatedDate, LFFleadMap.get(con).Last_Touch_Associated_Date__c );
            System.assertEquals(leadCampMap.get(con).Campaignid, LFFleadMap.get(con).Last_Touch_Campaign__c );
            System.assertEquals(leadCampMap.get(con).Status, LFFleadMap.get(con).First_Touch_Campaign_Member_Status__c );
            System.assertEquals(leadCampMap.get(con).Status, LFFleadMap.get(con).Last_Touch_Campaign_Member_Status__c );

            System.assertEquals(leadCampMap.get(con).Campaign.Type,LFFleadMap.get(con).First_Touch_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.SubType__c,LFFleadMap.get(con).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Product_Type__c,LFFleadMap.get(con).First_Touch_Product__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Product_Type__c,LFFleadMap.get(con).Last_Touch_Campaign_Product__c);
            System.assertEquals(leadCampMap.get(con).Campaign.SubType__c,LFFleadMap.get(con).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Type,LFFleadMap.get(con).Last_Touch_Campaign_Type__c);

            System.assertEquals(leadCampMap.get(con).CampaignId,LFFleadMap.get(con).Last_Touch_SQL_Campaign__c);
            System.assertEquals(leadCampMap.get(con).Status,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(leadCampMap.get(con).createdDate,LFFleadMap.get(con).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Type,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(con).Campaign.SubType__c,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(con).UTM_Content__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(con).UTM_Medium__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(leadCampMap.get(con).UTM_Source__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(leadCampMap.get(con).UTM_Term__c,LFFleadMap.get(con).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(leadCampMap.get(con).Campaign.Product_Type__c,LFFleadMap.get(con).Last_SQL_Touch_Product__c);
            System.assertEquals(leadCampMap.get(con).id,LFFleadMap.get(con).Last_Touch_SQL_Campaign_Member_ID__c);
        }
    }
}