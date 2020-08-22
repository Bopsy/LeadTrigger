@isTest
private class BatchCampaignMemberToLFF_Test {

    static final String NON_MARKETING_CAMPAIGN_TYPE = 'Non-Marketing';

    static List<Lead> leadList = new List<Lead>();
    static List<Contact> conList = new List<Contact>();
    static Account account;
    static integer NumberOfRec = 2;
    static List<Campaign> campList = new List<Campaign>();
    static List<CampaignMember> campMemList = new List<CampaignMember>();

    static void createLeadData(){
        leadList = TestDataFactory.createLeadList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            leadList[rec].status = 'Contacted';
            leadList[rec].Eloqua_Lead_Rating__c = 'A' + rec;
        }
        insert leadList;
    }

    static void createContactData(){
        account = new account();
        account.name = 'AccountTest';
        account.Channel_Account_Status__c = 'Inactive';
        insert account;

        conList = TestDataFactory.createContactList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            conList[rec].accountid = account.id;
        }
        insert conList;
    }

    static testMethod void testLeadCMNonMarketingCampaign(){
        //No LFF should be created
        createLeadData();

        campList = TestDataFactory.createCampaignList(1);
        campList[0].Type = NON_MARKETING_CAMPAIGN_TYPE;
        insert campList ;
        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].LeadId = leadList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchCampaignMemberToLFF bat = new BatchCampaignMemberToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        List<Lifecycle_Field_Funnel__c> newLLFList = [select id,name from Lifecycle_Field_Funnel__c where Lead__c IN:leadList];
        System.assertEquals(0, newLLFList.size());
        //System.assert(false, 'Needs to be implemented from Test Scripts, spreadsheet');
    }

    static testMethod void testContactCMNonMarketingCampaign(){
        //No LFF should be created
        createContactData();

        campList = TestDataFactory.createCampaignList(1);
        campList[0].Type = NON_MARKETING_CAMPAIGN_TYPE;
        insert campList ;
        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].Contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchCampaignMemberToLFF bat = new BatchCampaignMemberToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        List<Lifecycle_Field_Funnel__c> newLLFList = [select id,name from Lifecycle_Field_Funnel__c where Contact__c IN: conList];
        System.assertEquals(0, newLLFList.size());

        //System.assert(false, 'Needs to be implemented from Test Scripts, spreadsheet');
    }


    static testMethod void testLeadCMMarketingCampaignLFF(){
        //1 LFF should be created
        createLeadData();

        campList = TestDataFactory.createCampaignList(1);
        campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec < NumberOfRec ; rec++ ){
            campMemList[rec].leadid = leadList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        campMemList = [select id,LeadId, UTM_Content__c, lead.Eloqua_Lead_Rating__c, UTM_Medium__c,UTM_Source__c,UTM_Term__c,Status,CreatedDate,
                       campaignid,Campaign.Type,Campaign.SubType__c,Campaign.Product_Type__c
                       from CampaignMember where Id in :campMemList];

        System.assertEquals(2, campMemList.size());
        map<id,CampaignMember> leadCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : campMemList ){
           leadCampMap.put(cm.leadid,cm);
        }

        test.startTest();
            BatchCampaignMemberToLFF bat = new BatchCampaignMemberToLFF(1);
            database.executebatch(bat);
            System.schedule('LFF Batch Chain - Hourly Test', '0 0 * * * ?', new BatchCampaignMemberToLFF(1));
        test.stopTest();

        List<Lifecycle_Field_Funnel__c> newLLFList = [select id, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c,
                                                        First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                                        Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c,
                                                        Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                                        Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c, Last_Touch_SQL_Campaign_Type__c,
                                                        Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c,
                                                        Inquiry_Date_Entered__c, First_Touch_Campaign_Member_Status__c, Last_Touch_Campaign_Member_Status__c,
                                                        Last_Touch_Associated_Date__c, name,Inquiry_Interest_Score__c, Last_Touch_Campaign__c,
                                                        First_Touch_Campaign__c, First_Touch_Associated_Date__c, Last_Touch_UTM_Term__c, Last_Touch_UTM_Source__c,
                                                        Last_Touch_UTM_Medium__c, Last_Touch_UTM_Content__c, First_Touch_UTM_Term__c,
                                                        First_Touch_UTM_Source__c, First_Touch_UTM_Medium__c, First_Touch_UTM_Content__c,
                                                        Lead__c, First_Touch_Campaign_Member_ID__c, Last_Touch_Campaign_Member_ID__c
                                                    from Lifecycle_Field_Funnel__c where Lead__c IN:leadList];
        System.assertEquals(2, newLLFList.size());
        map<id,Lifecycle_Field_Funnel__c> LFFcampMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFcampMap.put(lff.lead__c,lff);
        }

        for(id ldid : LFFcampMap.keyset()){
            System.assertEquals(leadCampMap.get(ldid).id,LFFcampMap.get(ldid).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(ldid).id,LFFcampMap.get(ldid).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Content__c ,LFFcampMap.get(ldid).First_Touch_UTM_Content__c);

            System.assertEquals(leadCampMap.get(ldid).UTM_Medium__c ,LFFcampMap.get(ldid).First_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Source__c ,LFFcampMap.get(ldid).First_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Term__c ,LFFcampMap.get(ldid).First_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Content__c,LFFcampMap.get(ldid).Last_Touch_UTM_Content__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Medium__c ,LFFcampMap.get(ldid).Last_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Source__c ,LFFcampMap.get(ldid).Last_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Term__c ,LFFcampMap.get(ldid).Last_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(ldid).CreatedDate,LFFcampMap.get(ldid).First_Touch_Associated_Date__c);
            System.assertEquals(leadCampMap.get(ldid).CreatedDate,LFFcampMap.get(ldid).Last_Touch_Associated_Date__c);

            System.assertEquals(leadCampMap.get(ldid).campaignid,LFFcampMap.get(ldid).Last_Touch_Campaign__c);
            System.assertEquals(leadCampMap.get(ldid).campaignid,LFFcampMap.get(ldid).First_Touch_Campaign__c);
            System.assertEquals(ldid,LFFcampMap.get(ldid).Lead__c);
            System.assertEquals(leadCampMap.get(ldid).lead.Eloqua_Lead_Rating__c,LFFcampMap.get(ldid).Inquiry_Interest_Score__c);
            System.assertEquals(leadCampMap.get(ldid).Status,LFFcampMap.get(ldid).First_Touch_Campaign_Member_Status__c);
            System.assertEquals(leadCampMap.get(ldid).Status,LFFcampMap.get(ldid).Last_Touch_Campaign_Member_Status__c);
            System.assertEquals(leadCampMap.get(ldid).CreatedDate,LFFcampMap.get(ldid).Inquiry_Date_Entered__c);

            System.assertEquals(leadCampMap.get(ldid).Campaign.Type,LFFcampMap.get(ldid).First_Touch_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.SubType__c,LFFcampMap.get(ldid).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Product_Type__c,LFFcampMap.get(ldid).First_Touch_Product__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Product_Type__c,LFFcampMap.get(ldid).Last_Touch_Campaign_Product__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.SubType__c,LFFcampMap.get(ldid).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Type,LFFcampMap.get(ldid).Last_Touch_Campaign_Type__c);


            System.assertEquals(leadCampMap.get(ldid).CampaignId,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign__c);
            System.assertEquals(leadCampMap.get(ldid).Status,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(leadCampMap.get(ldid).createdDate,LFFcampMap.get(ldid).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Type,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.SubType__c,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Content__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Medium__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Source__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Term__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Product_Type__c,LFFcampMap.get(ldid).Last_SQL_Touch_Product__c);

            System.assertEquals(leadCampMap.get(ldid).id,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Member_ID__c);

        }
    }

    static testMethod void testContactCMMarketingCampaignLFF()
    {
        //1 LFF should be created
        createContactData();

        campList = TestDataFactory.createCampaignList(1);
        campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].Contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchCampaignMemberToLFF bat = new BatchCampaignMemberToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, Status,
                                        createdDate, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, campaignid,
                                        contactid, contact.Eloqua_Lead_Rating__c from CampaignMember where id IN:campMemList ];
        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT id, name, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c,
                                                        First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                                        Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c,
                                                        Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                                        Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c, Last_Touch_SQL_Campaign_Type__c,
                                                        Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c,
                                                        Last_Touch_Associated_Date__c, Inquiry_Interest_Score__c, Last_Touch_Campaign__c,
                                                        First_Touch_Campaign__c, First_Touch_Associated_Date__c, Last_Touch_UTM_Term__c,
                                                        Last_Touch_UTM_Source__c, Last_Touch_UTM_Medium__c, Last_Touch_UTM_Content__c,
                                                        First_Touch_UTM_Term__c, contact__c, First_Touch_UTM_Source__c, First_Touch_UTM_Medium__c,
                                                        First_Touch_UTM_Content__c, Lead__c, First_Touch_Campaign_Member_ID__c, Last_Touch_Campaign_Member_ID__c,
                                                        Inquiry_Date_Entered__c, First_Touch_Campaign_Member_Status__c, Last_Touch_Campaign_Member_Status__c
                                                     from Lifecycle_Field_Funnel__c where Contact__c IN:ConList];

        System.assertEquals(2, newLLFList.size());
        map<id,Lifecycle_Field_Funnel__c> LFFcampMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFcampMap.put(lff.contact__c,lff);
        }

        for(id conid: LFFcampMap.keyset()){
            System.assertEquals(contactCampMap.get(conid).id,LFFcampMap.get(conid).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(conid).id,LFFcampMap.get(conid).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Content__c ,LFFcampMap.get(conid).First_Touch_UTM_Content__c);

            System.assertEquals(contactCampMap.get(conid).UTM_Medium__c ,LFFcampMap.get(conid).First_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Source__c ,LFFcampMap.get(conid).First_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Term__c ,LFFcampMap.get(conid).First_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Content__c,LFFcampMap.get(conid).Last_Touch_UTM_Content__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Medium__c ,LFFcampMap.get(conid).Last_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Source__c ,LFFcampMap.get(conid).Last_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Term__c ,LFFcampMap.get(conid).Last_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(conid).CreatedDate,LFFcampMap.get(conid).First_Touch_Associated_Date__c);
            System.assertEquals(contactCampMap.get(conid).CreatedDate,LFFcampMap.get(conid).Last_Touch_Associated_Date__c);

            System.assertEquals(contactCampMap.get(conid).campaignid,LFFcampMap.get(conid).Last_Touch_Campaign__c);
            System.assertEquals(contactCampMap.get(conid).campaignid,LFFcampMap.get(conid).First_Touch_Campaign__c);
            System.assertEquals(conid,LFFcampMap.get(conid).contact__c);
            System.assertEquals(contactCampMap.get(conid).contact.Eloqua_Lead_Rating__c,LFFcampMap.get(conid).Inquiry_Interest_Score__c);
            System.assertEquals(contactCampMap.get(conid).Status,LFFcampMap.get(conid).First_Touch_Campaign_Member_Status__c);
            System.assertEquals(contactCampMap.get(conid).Status,LFFcampMap.get(conid).Last_Touch_Campaign_Member_Status__c);
            System.assertEquals(contactCampMap.get(conid).CreatedDate,LFFcampMap.get(conid).Inquiry_Date_Entered__c);

            System.assertEquals(contactCampMap.get(conid).Campaign.Type,LFFcampMap.get(conid).First_Touch_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.SubType__c,LFFcampMap.get(conid).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Product_Type__c,LFFcampMap.get(conid).First_Touch_Product__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Product_Type__c,LFFcampMap.get(conid).Last_Touch_Campaign_Product__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.SubType__c,LFFcampMap.get(conid).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Type,LFFcampMap.get(conid).Last_Touch_Campaign_Type__c);

            System.assertEquals(contactCampMap.get(conid).CampaignId,LFFcampMap.get(conid).Last_Touch_SQL_Campaign__c);
            System.assertEquals(contactCampMap.get(conid).Status,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(contactCampMap.get(conid).createdDate,LFFcampMap.get(conid).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Type,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.SubType__c,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Content__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Medium__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Source__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Term__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Product_Type__c,LFFcampMap.get(conid).Last_SQL_Touch_Product__c);
            System.assertEquals(contactCampMap.get(conid).id,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Member_ID__c);

        }
    }

    static testMethod void testLeadCMMarketingCampaignExistingLFF(){
        //1 LFF should be updated
        createLeadData();

        campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].leadid = leadList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        Lifecycle_Field_Funnel__c newLFF = new Lifecycle_Field_Funnel__c ();
        newLFF.Lead__c = leadlist[0].Id;
        newLFF.First_Touch_Campaign_Member_ID__c = campMemList[0].id;
        newLFF.Last_Touch_Campaign_Member_ID__c = campMemList[0].id;
        insert newLFF;

        Lifecycle_Field_Funnel__c newLFF2 = new Lifecycle_Field_Funnel__c ();
        newLFF2.Lead__c = leadlist[1].Id;
        newLFF2.First_Touch_Campaign_Member_ID__c = campMemList[1].id;
        newLFF2.Last_Touch_Campaign_Member_ID__c = campMemList[1].id;
        insert newLFF2;

        test.startTest();
            BatchCampaignMemberToLFF bat = new BatchCampaignMemberToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, Status,
                                        createdDate, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c,
                                        campaignid, leadid,lead.Eloqua_Lead_Rating__c from CampaignMember where id IN:campMemList ];
        map<id,CampaignMember> leadCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            leadCampMap.put(cm.leadid,cm);
        }

        List<Lifecycle_Field_Funnel__c> newLLFList = [select id, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c,
                                                        First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                                        Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c,
                                                        Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                                        Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c, Last_Touch_SQL_Campaign_Type__c,
                                                        Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c,
                                                        Inquiry_Date_Entered__c, First_Touch_Campaign_Member_Status__c, Last_Touch_Campaign_Member_Status__c,
                                                        Last_Touch_Associated_Date__c, name, Inquiry_Interest_Score__c, Last_Touch_Campaign__c,
                                                        First_Touch_Campaign__c, First_Touch_Associated_Date__c, Last_Touch_UTM_Term__c,
                                                        Last_Touch_UTM_Source__c, Last_Touch_UTM_Medium__c, Last_Touch_UTM_Content__c,
                                                        First_Touch_UTM_Term__c, First_Touch_UTM_Source__c, First_Touch_UTM_Medium__c,
                                                        First_Touch_UTM_Content__c, Lead__c, First_Touch_Campaign_Member_ID__c, Last_Touch_Campaign_Member_ID__c
                                                    from Lifecycle_Field_Funnel__c where Lead__c IN:LeadList];
        System.assertEquals(2, newLLFList.size());
        map<id,Lifecycle_Field_Funnel__c> LFFcampMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFcampMap.put(lff.lead__c,lff);
        }

       for(id ldid : LFFcampMap.keyset()){
            System.assertEquals(leadCampMap.get(ldid).id,LFFcampMap.get(ldid).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Content__c,LFFcampMap.get(ldid).Last_Touch_UTM_Content__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Medium__c ,LFFcampMap.get(ldid).Last_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Source__c ,LFFcampMap.get(ldid).Last_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Term__c ,LFFcampMap.get(ldid).Last_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(ldid).CreatedDate,LFFcampMap.get(ldid).Last_Touch_Associated_Date__c);
            System.assertEquals(leadCampMap.get(ldid).campaignid,LFFcampMap.get(ldid).Last_Touch_Campaign__c);
            System.assertEquals(ldid,LFFcampMap.get(ldid).Lead__c);

            System.assertEquals(leadCampMap.get(ldid).Campaign.Type,LFFcampMap.get(ldid).First_Touch_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.SubType__c,LFFcampMap.get(ldid).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Product_Type__c,LFFcampMap.get(ldid).First_Touch_Product__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Product_Type__c,LFFcampMap.get(ldid).Last_Touch_Campaign_Product__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.SubType__c,LFFcampMap.get(ldid).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Type,LFFcampMap.get(ldid).Last_Touch_Campaign_Type__c);

            System.assertEquals(leadCampMap.get(ldid).CampaignId,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign__c);
            System.assertEquals(leadCampMap.get(ldid).Status,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(leadCampMap.get(ldid).createdDate,LFFcampMap.get(ldid).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Type,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.SubType__c,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Content__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Medium__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Source__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Term__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Product_Type__c,LFFcampMap.get(ldid).Last_SQL_Touch_Product__c);
            System.assertEquals(leadCampMap.get(ldid).id,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Member_ID__c);
        }
    }

    static testMethod void testContactCMMarketingCampaignExistingLFF(){
        //1 LFF should be updated
        createContactData();
         campList = TestDataFactory.createCampaignList(1);
         campList[0].type= 'Event';
        insert campList ;


        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        List<Id> campMemIds = new List<String>();
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].Contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        Lifecycle_Field_Funnel__c newLFF = new Lifecycle_Field_Funnel__c ();
        newLFF.Contact__c = conList[0].Id;
        newLFF.First_Touch_Campaign_Member_ID__c = campMemList[0].id;
        newLFF.Last_Touch_Campaign_Member_ID__c = campMemList[0].id;
        insert newLFF;

        Lifecycle_Field_Funnel__c newLFF2 = new Lifecycle_Field_Funnel__c ();
        newLFF2.Contact__c = conList[1].Id;
        newLFF2.First_Touch_Campaign_Member_ID__c = campMemList[1].id;
        newLFF2.Last_Touch_Campaign_Member_ID__c = campMemList[1].id;
        insert newLFF2;

        test.startTest();
            BatchCampaignMemberToLFF bat = new BatchCampaignMemberToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, Status,
                                        createdDate, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c,
                                        campaignid, contactid, contact.Eloqua_Lead_Rating__c from CampaignMember where id IN:campMemList ];
        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT id, name, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c,
                                                        First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                                        Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c,
                                                        Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                                        Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c, Last_Touch_SQL_Campaign_Type__c,
                                                        Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c,
                                                        Last_Touch_Associated_Date__c, Inquiry_Interest_Score__c, Last_Touch_Campaign__c,
                                                        First_Touch_Campaign__c, First_Touch_Associated_Date__c, Last_Touch_UTM_Term__c,
                                                        Last_Touch_UTM_Source__c, Last_Touch_UTM_Medium__c, Last_Touch_UTM_Content__c,
                                                        First_Touch_UTM_Term__c, contact__c, First_Touch_UTM_Source__c, First_Touch_UTM_Medium__c,
                                                        First_Touch_UTM_Content__c, Lead__c, First_Touch_Campaign_Member_ID__c, Last_Touch_Campaign_Member_ID__c,
                                                        Inquiry_Date_Entered__c, First_Touch_Campaign_Member_Status__c, Last_Touch_Campaign_Member_Status__c
                                                    from Lifecycle_Field_Funnel__c where Contact__c IN:ConList];

        System.assertEquals(2, newLLFList.size());
        map<id,Lifecycle_Field_Funnel__c> LFFcampMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFcampMap.put(lff.contact__c,lff);
        }

        for(id conid: LFFcampMap.keyset()){

            System.assertEquals(contactCampMap.get(conid).id,LFFcampMap.get(conid).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Content__c,LFFcampMap.get(conid).Last_Touch_UTM_Content__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Medium__c ,LFFcampMap.get(conid).Last_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Source__c ,LFFcampMap.get(conid).Last_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Term__c ,LFFcampMap.get(conid).Last_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(conid).CreatedDate,LFFcampMap.get(conid).Last_Touch_Associated_Date__c);
            System.assertEquals(contactCampMap.get(conid).campaignid,LFFcampMap.get(conid).Last_Touch_Campaign__c);
            System.assertEquals(conid,LFFcampMap.get(conid).Contact__c);

            System.assertEquals(contactCampMap.get(conid).Campaign.Type,LFFcampMap.get(conid).First_Touch_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.SubType__c,LFFcampMap.get(conid).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Product_Type__c,LFFcampMap.get(conid).First_Touch_Product__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Product_Type__c,LFFcampMap.get(conid).Last_Touch_Campaign_Product__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.SubType__c,LFFcampMap.get(conid).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Type,LFFcampMap.get(conid).Last_Touch_Campaign_Type__c);

            System.assertEquals(contactCampMap.get(conid).CampaignId,LFFcampMap.get(conid).Last_Touch_SQL_Campaign__c);
            System.assertEquals(contactCampMap.get(conid).Status,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(contactCampMap.get(conid).createdDate,LFFcampMap.get(conid).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Type,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.SubType__c,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Content__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Medium__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Source__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Term__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Product_Type__c,LFFcampMap.get(conid).Last_SQL_Touch_Product__c);
            System.assertEquals(contactCampMap.get(conid).id,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Member_ID__c);
        }
    }

    static testMethod void testLeadCMMarketingCampaignLFFDefConst(){
        //1 LFF should be created
        createLeadData();

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
            BatchCampaignMemberToLFF bat = new BatchCampaignMemberToLFF();
            database.executebatch(bat);
            System.schedule('LFF Batch Chain - Hourly Test', '0 0 * * * ?', new BatchCampaignMemberToLFF());
        test.stopTest();

         List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, Status,
                                            createdDate, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c,
                                            campaignid, leadid, lead.Eloqua_Lead_Rating__c from CampaignMember where id IN:campMemList ];
        map<id,CampaignMember> leadCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            leadCampMap.put(cm.leadid,cm);
        }

        List<Lifecycle_Field_Funnel__c> newLLFList = [select id, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c,
                                                        First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                                        Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c, Inquiry_Date_Entered__c,
                                                        Last_SQL_Touch_Product__c, Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c,
                                                        Last_SQL_Touch_UTM_Medium__c, Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c,
                                                        Last_Touch_SQL_Campaign_Type__c, Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c,
                                                        Last_Touch_SQL_Campaign_Member_Status__c, First_Touch_Campaign_Member_Status__c,
                                                        Last_Touch_Campaign_Member_Status__c, Last_Touch_Associated_Date__c, name,
                                                        Inquiry_Interest_Score__c, Last_Touch_Campaign__c, First_Touch_Campaign__c,
                                                        First_Touch_Associated_Date__c, Last_Touch_UTM_Term__c, Last_Touch_UTM_Source__c,
                                                        Last_Touch_UTM_Medium__c, Last_Touch_UTM_Content__c, First_Touch_UTM_Term__c,
                                                        First_Touch_UTM_Source__c, First_Touch_UTM_Medium__c, First_Touch_UTM_Content__c,
                                                        Lead__c, First_Touch_Campaign_Member_ID__c, Last_Touch_Campaign_Member_ID__c
                                                    from Lifecycle_Field_Funnel__c where Lead__c IN:LeadList];
        System.assertEquals(2, newLLFList.size());
        map<id,Lifecycle_Field_Funnel__c> LFFcampMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFcampMap.put(lff.lead__c,lff);
        }

       for(id ldid : LFFcampMap.keyset()){
            System.assertEquals(leadCampMap.get(ldid).id,LFFcampMap.get(ldid).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(ldid).id,LFFcampMap.get(ldid).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Content__c ,LFFcampMap.get(ldid).First_Touch_UTM_Content__c);

            System.assertEquals(leadCampMap.get(ldid).UTM_Medium__c ,LFFcampMap.get(ldid).First_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Source__c ,LFFcampMap.get(ldid).First_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Term__c ,LFFcampMap.get(ldid).First_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Content__c,LFFcampMap.get(ldid).Last_Touch_UTM_Content__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Medium__c ,LFFcampMap.get(ldid).Last_Touch_UTM_Medium__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Source__c ,LFFcampMap.get(ldid).Last_Touch_UTM_Source__c );
            System.assertEquals(leadCampMap.get(ldid).UTM_Term__c ,LFFcampMap.get(ldid).Last_Touch_UTM_Term__c );
            System.assertEquals(leadCampMap.get(ldid).CreatedDate,LFFcampMap.get(ldid).First_Touch_Associated_Date__c);
            System.assertEquals(leadCampMap.get(ldid).CreatedDate,LFFcampMap.get(ldid).Last_Touch_Associated_Date__c);
            System.assertEquals(leadCampMap.get(ldid).campaignid,LFFcampMap.get(ldid).Last_Touch_Campaign__c);
            System.assertEquals(leadCampMap.get(ldid).campaignid,LFFcampMap.get(ldid).First_Touch_Campaign__c);
            System.assertEquals(ldid,LFFcampMap.get(ldid).Lead__c);
            System.assertEquals(leadCampMap.get(ldid).lead.Eloqua_Lead_Rating__c ,LFFcampMap.get(ldid).Inquiry_Interest_Score__c);

            System.assertEquals(leadCampMap.get(ldid).Campaign.Type,LFFcampMap.get(ldid).First_Touch_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.SubType__c,LFFcampMap.get(ldid).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Product_Type__c,LFFcampMap.get(ldid).First_Touch_Product__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Product_Type__c,LFFcampMap.get(ldid).Last_Touch_Campaign_Product__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.SubType__c,LFFcampMap.get(ldid).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Type,LFFcampMap.get(ldid).Last_Touch_Campaign_Type__c);

            System.assertEquals(leadCampMap.get(ldid).CampaignId,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign__c);
            System.assertEquals(leadCampMap.get(ldid).Status,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(leadCampMap.get(ldid).createdDate,LFFcampMap.get(ldid).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Type,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.SubType__c,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Content__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Medium__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Source__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(leadCampMap.get(ldid).UTM_Term__c,LFFcampMap.get(ldid).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(leadCampMap.get(ldid).Campaign.Product_Type__c,LFFcampMap.get(ldid).Last_SQL_Touch_Product__c);
            System.assertEquals(leadCampMap.get(ldid).id,LFFcampMap.get(ldid).Last_Touch_SQL_Campaign_Member_ID__c);
        }
    }

    static testMethod void testLeadCMMarketingCampaignLFFWrongCampaignM(){
        //1 LFF should be created
        createContactData();
        campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].Contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchCampaignMemberToLFF bat = new BatchCampaignMemberToLFF();
            database.executebatch(bat);
            System.schedule('LFF Batch Chain - Hourly Test', '0 0 * * * ?', new BatchCampaignMemberToLFF());
        test.stopTest();
        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, Status,
                                        createdDate, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, campaignid,
                                        contactid, contact.Eloqua_Lead_Rating__c from CampaignMember where id IN:campMemList ];
        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT id, name, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c,
                                                        First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                                        Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c,
                                                        Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                                        Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c, Last_Touch_SQL_Campaign_Type__c,
                                                        Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c,
                                                        Last_Touch_Associated_Date__c, Inquiry_Interest_Score__c, Last_Touch_Campaign__c,
                                                        First_Touch_Campaign__c, First_Touch_Associated_Date__c, Last_Touch_UTM_Term__c,
                                                        Last_Touch_UTM_Source__c, Last_Touch_UTM_Medium__c, Last_Touch_UTM_Content__c,
                                                        First_Touch_UTM_Term__c, contact__c, First_Touch_UTM_Source__c, First_Touch_UTM_Medium__c,
                                                        First_Touch_UTM_Content__c, Lead__c, First_Touch_Campaign_Member_ID__c, Last_Touch_Campaign_Member_ID__c,
                                                        Inquiry_Date_Entered__c, First_Touch_Campaign_Member_Status__c, Last_Touch_Campaign_Member_Status__c
                                                        from Lifecycle_Field_Funnel__c where Contact__c IN:ConList];

        System.assertEquals(2, newLLFList.size());
        map<id,Lifecycle_Field_Funnel__c> LFFcampMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFcampMap.put(lff.contact__c,lff);
        }

        for(id conid: LFFcampMap.keyset()){
            System.assertEquals(contactCampMap.get(conid).id,LFFcampMap.get(conid).First_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(conid).id,LFFcampMap.get(conid).Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Content__c ,LFFcampMap.get(conid).First_Touch_UTM_Content__c);

            System.assertEquals(contactCampMap.get(conid).UTM_Medium__c ,LFFcampMap.get(conid).First_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Source__c ,LFFcampMap.get(conid).First_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Term__c ,LFFcampMap.get(conid).First_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Content__c,LFFcampMap.get(conid).Last_Touch_UTM_Content__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Medium__c ,LFFcampMap.get(conid).Last_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Source__c ,LFFcampMap.get(conid).Last_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(conid).UTM_Term__c ,LFFcampMap.get(conid).Last_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(conid).CreatedDate,LFFcampMap.get(conid).First_Touch_Associated_Date__c);
            System.assertEquals(contactCampMap.get(conid).CreatedDate,LFFcampMap.get(conid).Last_Touch_Associated_Date__c);
            System.assertEquals(contactCampMap.get(conid).campaignid,LFFcampMap.get(conid).First_Touch_Campaign__c);
            System.assertEquals(contactCampMap.get(conid).campaignid,LFFcampMap.get(conid).Last_Touch_Campaign__c);
            System.assertEquals(conid,LFFcampMap.get(conid).contact__c);
            System.assertEquals(contactCampMap.get(conid).contact.Eloqua_Lead_Rating__c ,LFFcampMap.get(conid).Inquiry_Interest_Score__c);

            System.assertEquals(contactCampMap.get(conid).Campaign.Type,LFFcampMap.get(conid).First_Touch_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.SubType__c,LFFcampMap.get(conid).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Product_Type__c,LFFcampMap.get(conid).First_Touch_Product__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Product_Type__c,LFFcampMap.get(conid).Last_Touch_Campaign_Product__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.SubType__c,LFFcampMap.get(conid).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Type,LFFcampMap.get(conid).Last_Touch_Campaign_Type__c);

            System.assertEquals(contactCampMap.get(conid).CampaignId,LFFcampMap.get(conid).Last_Touch_SQL_Campaign__c);
            System.assertEquals(contactCampMap.get(conid).Status,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(contactCampMap.get(conid).createdDate,LFFcampMap.get(conid).Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Type,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.SubType__c,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Content__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Medium__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Source__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(contactCampMap.get(conid).UTM_Term__c,LFFcampMap.get(conid).Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(contactCampMap.get(conid).Campaign.Product_Type__c,LFFcampMap.get(conid).Last_SQL_Touch_Product__c);
            System.assertEquals(contactCampMap.get(conid).id,LFFcampMap.get(conid).Last_Touch_SQL_Campaign_Member_ID__c);
        }
    }

    static testMethod void testLFFsCreatedWhenOnlyInactivesFound()
    {
        final Integer NUM_RECORDS = 15;
        List<Campaign> testCampaigns = TestDataFactory.createCampaignList(NUM_RECORDS);
        for(Campaign aCampaign : testCampaigns)
        {
            aCampaign.Type = 'Growth';
        }
        insert testCampaigns;

        List<Contact> testContacts = TestDataFactory.createContactList(NUM_RECORDS);
        insert testContacts;

        List<Lifecycle_Field_Funnel__c> testExistingInactiveLFFs = new List<Lifecycle_Field_Funnel__c>();
        for(Contact aContact : testContacts)
        {
            Lifecycle_Field_Funnel__c newLFF = TestDataFactory.createlFFList(1)[0];
            newLFF.Contact__c = aContact.Id;
            newLFF.Inquiry_Date_Entered__c = System.now().addYears(-1); // satisfy critieria to be inactive
            testExistingInactiveLFFs.add(newLFF);
        }
        insert testExistingInactiveLFFs;

        List<CampaignMember> testMembers = new List<CampaignMember>();
        for(Integer index = 0; index < NUM_RECORDS; index++)
        {
            CampaignMember newMember = TestDataFactory.createCampaignMemList(1)[0];
            newMember.ContactId = testContacts[index].Id;
            newMember.CampaignId = testCampaigns[index].Id;
            newMember.Status = 'Responded';
            testMembers.add(newMember);
        }
        insert testMembers;

        Test.startTest();

            BatchCampaignMemberToLFF newBatch = new BatchCampaignMemberToLFF();
            Database.executeBatch(newBatch);

        Test.stopTest();

        List<Lifecycle_Field_Funnel__c> createdLFFs = [ SELECT Id, Contact__c FROM Lifecycle_Field_Funnel__c WHERE (NOT Id IN :testExistingInactiveLFFs) ];
        System.assertEquals(NUM_RECORDS, createdLFFs.size(), 'New LFFs should have been created');
    }
}