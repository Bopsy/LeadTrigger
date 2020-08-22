@isTest
private class BatchMQLeadToLFF_Test{

    static final String MQL_REJECTED_STATUS = '3 - Rejected';

    static List<Lead> leadList = new List<Lead>();
    static List<Contact> conList = new List<Contact>();
    static Account account;
    static integer NumberOfRec = 2;
    static List<FSR__c> fSRList = new List<FSR__c>();
    static List<Campaign> campList = new List<Campaign>();
    static List<CampaignMember> campMemList = new List<CampaignMember>();

    static void createLeadData(){
        leadList = TestDataFactory.createLeadList(NumberOfRec);
        for(integer rec = 0; rec < NumberOfRec ; rec++ ){
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

    static testMethod void testNewMqlLeadWithNoLFF(){
        createLeadData();
        fSRList = TestDataFactory.createFSRList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++){
            fSRList[rec].Lead__c = leadList[rec].id;
        }
        insert fSRList ;

        campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].LeadId = leadList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        test.startTest();
            BatchMQLeadToLFF bat = new BatchMQLeadToLFF(1);
            database.executebatch(bat);
            System.schedule('LFF MQL Batch Chain - Hourly Test', '0 0 * * * ?', new BatchMQLeadToLFF());
        test.stopTest();

        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c,
                                        leadid, Status, lead.Eloqua_Lead_Rating__c, createdDate,
                                        UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, campaignid
                                        from CampaignMember where id IN: campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> leadCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            leadCampMap.put(cm.leadid,cm);
        }

        List<FSR__c> newFSRList = [SELECT id, lead__c, lead__r.Eloqua_Lead_Rating__c, contact__c, Contact__r.Eloqua_Lead_Rating__c,
                                        (SELECT id, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c,
                                            First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                            Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c,
                                            Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                            Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c, Last_Touch_SQL_Campaign_Type__c,
                                            Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c,
                                            Current_Funnel_Stage__c, MQL_Rejected_Date__c, First_Touch_UTM_Content__c,
                                            Last_Touch_Campaign__c, Last_Touch_Associated_Date__c, Last_Touch_UTM_Term__c,
                                            Last_Touch_UTM_Source__c, Last_Touch_UTM_Medium__c, Last_Touch_UTM_Content__c,
                                            Last_Touch_Campaign_Member_ID__c, First_Touch_Campaign__c,
                                            Last_Touch_Campaign_Member_Status__c, First_Touch_Campaign_Member_Status__c,
                                            First_Touch_Associated_Date__c, First_Touch_UTM_Term__c,
                                            First_Touch_UTM_Source__c, First_Touch_UTM_Medium__c,
                                            First_Touch_Campaign_Member_ID__c, MQL_Interest_Score__c,
                                            Inquiry_Date_Entered__c
                                        FROM Lifecycle_Field_Funnels__r )
                                    FROM FSR__c WHERE Id IN : fSRList ];
        System.assertEquals(NumberOfRec , newFSRList.size());

        map<id,List<Lifecycle_Field_Funnel__c>> fSRLFFcampMap = new Map<id,List<Lifecycle_Field_Funnel__c>>();

        for(FSR__c fsr: newFSRList ){
            fSRLFFcampMap.put(fsr.lead__c,fsr.Lifecycle_Field_Funnels__r);
        }


        for(id ld: fSRLFFcampMap.keyset())
        {
            for(Lifecycle_Field_Funnel__c lff : fSRLFFcampMap.get(ld)){

                System.assertEquals(leadCampMap.get(ld).lead.Eloqua_Lead_Rating__c , lff.MQL_Interest_Score__c);
                System.assertEquals(leadCampMap.get(ld).CreatedDate, lff.Inquiry_Date_Entered__c);

                System.assertEquals(leadCampMap.get(ld).id, lff.First_Touch_Campaign_Member_ID__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Content__c, lff.First_Touch_UTM_Content__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Medium__c , lff.First_Touch_UTM_Medium__c );
                System.assertEquals(leadCampMap.get(ld).UTM_Source__c , lff.First_Touch_UTM_Source__c );
                System.assertEquals(leadCampMap.get(ld).UTM_Term__c , lff.First_Touch_UTM_Term__c );
                System.assertEquals(leadCampMap.get(ld).CreatedDate, lff.First_Touch_Associated_Date__c );
                System.assertEquals(leadCampMap.get(ld).Campaignid, lff.First_Touch_Campaign__c );
                System.assertEquals(leadCampMap.get(ld).id, lff.Last_Touch_Campaign_Member_ID__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Content__c, lff.Last_Touch_UTM_Content__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Medium__c , lff.Last_Touch_UTM_Medium__c );
                System.assertEquals(leadCampMap.get(ld).UTM_Source__c , lff.Last_Touch_UTM_Source__c );
                System.assertEquals(leadCampMap.get(ld).UTM_Term__c , lff.Last_Touch_UTM_Term__c );
                System.assertEquals(leadCampMap.get(ld).CreatedDate, lff.Last_Touch_Associated_Date__c );
                System.assertEquals(leadCampMap.get(ld).Campaignid, lff.Last_Touch_Campaign__c );
                System.assertEquals(leadCampMap.get(ld).Status, lff.First_Touch_Campaign_Member_Status__c );
                System.assertEquals(leadCampMap.get(ld).Status, lff.Last_Touch_Campaign_Member_Status__c );
                System.assertEquals(leadCampMap.get(ld).CreatedDate, lff.Inquiry_Date_Entered__c );

                System.assertEquals(leadCampMap.get(ld).Campaign.Type,lff.First_Touch_Campaign_Type__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.SubType__c,lff.First_Touch_Campaign_Sub_Type__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Product_Type__c,lff.First_Touch_Product__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Product_Type__c,lff.Last_Touch_Campaign_Product__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.SubType__c,lff.Last_Touch_Campaign_Sub_Type__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Type,lff.Last_Touch_Campaign_Type__c);

                System.assertEquals(leadCampMap.get(ld).CampaignId,lff.Last_Touch_SQL_Campaign__c);
                System.assertEquals(leadCampMap.get(ld).Status,lff.Last_Touch_SQL_Campaign_Member_Status__c);
                System.assertEquals(leadCampMap.get(ld).createdDate,lff.Last_Touch_SQL_Associated_Date__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Type,lff.Last_Touch_SQL_Campaign_Type__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.SubType__c,lff.Last_Touch_SQL_Campaign_Sub_Type__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Content__c,lff.Last_SQL_Touch_UTM_Content__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Medium__c,lff.Last_SQL_Touch_UTM_Medium__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Source__c,lff.Last_SQL_Touch_UTM_Source__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Term__c,lff.Last_SQL_Touch_UTM_Term__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Product_Type__c,lff.Last_SQL_Touch_Product__c);
                System.assertEquals(leadCampMap.get(ld).id,lff.Last_Touch_SQL_Campaign_Member_ID__c);
            }
        }
    }

    static testMethod void testNewMqlContactNoLFF(){
        createContactData();

        fSRList = TestDataFactory.createFSRList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++){
            fSRList[rec].contact__c = conlist[rec].id;
        }
        insert fSRList ;

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
            BatchMQLeadToLFF bat = new BatchMQLeadToLFF(1);
            database.executebatch(bat);
        test.stopTest();


        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, leadid,
                                            Status, lead.Eloqua_Lead_Rating__c, contact.Eloqua_Lead_Rating__c, createdDate,
                                            UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, campaignid
                                        from CampaignMember where id IN: campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap= new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }

        List<FSR__c> newFSRList = [SELECT id, lead__c, lead__r.Eloqua_Lead_Rating__c, contact__c, Contact__r.Eloqua_Lead_Rating__c,
                                        (SELECT id, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c, First_Touch_Campaign_Sub_Type__c,
                                            First_Touch_Product__c, Last_Touch_Campaign_Product__c, Last_Touch_Campaign_Sub_Type__c,
                                            Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c, Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c,
                                            Last_SQL_Touch_UTM_Medium__c, Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c,
                                            Last_Touch_SQL_Campaign_Type__c, Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c,
                                            Last_Touch_SQL_Campaign_Member_Status__c, Current_Funnel_Stage__c, MQL_Rejected_Date__c, First_Touch_UTM_Content__c,
                                            Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,
                                            Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,
                                            Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,
                                            Last_Touch_Campaign_Member_Status__c,
                                            First_Touch_Campaign_Member_Status__c,
                                            First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,
                                            First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c,
                                            First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,
                                            Inquiry_Date_Entered__c
                                        FROM Lifecycle_Field_Funnels__r )
                                    FROM FSR__c WHERE Id IN : fSRList ];
        System.assertEquals(NumberOfRec , newFSRList.size());

        map<id,List<Lifecycle_Field_Funnel__c>> fSRLFFcampMap = new Map<id,List<Lifecycle_Field_Funnel__c>>();

        for(FSR__c fsr: newFSRList ){
            fSRLFFcampMap.put(fsr.contact__c,fsr.Lifecycle_Field_Funnels__r);
        }

        for(id con: fSRLFFcampMap.keyset())
        {
            for(Lifecycle_Field_Funnel__c lff : fSRLFFcampMap.get(con)){

                System.assertEquals(contactCampMap.get(con).contact.Eloqua_Lead_Rating__c, lff.MQL_Interest_Score__c);
                System.assertEquals(contactCampMap.get(con).createddate, lff.Inquiry_Date_Entered__c);

                System.assertEquals(contactCampMap.get(con).id, lff.First_Touch_Campaign_Member_ID__c);
                System.assertEquals(contactCampMap.get(con).UTM_Content__c, lff.First_Touch_UTM_Content__c);
                System.assertEquals(contactCampMap.get(con).UTM_Medium__c , lff.First_Touch_UTM_Medium__c );
                System.assertEquals(contactCampMap.get(con).UTM_Source__c , lff.First_Touch_UTM_Source__c );
                System.assertEquals(contactCampMap.get(con).UTM_Term__c , lff.First_Touch_UTM_Term__c );
                System.assertEquals(contactCampMap.get(con).CreatedDate, lff.First_Touch_Associated_Date__c );
                System.assertEquals(contactCampMap.get(con).Campaignid, lff.First_Touch_Campaign__c );
                System.assertEquals(contactCampMap.get(con).id, lff.Last_Touch_Campaign_Member_ID__c);
                System.assertEquals(contactCampMap.get(con).UTM_Content__c, lff.Last_Touch_UTM_Content__c);
                System.assertEquals(contactCampMap.get(con).UTM_Medium__c , lff.Last_Touch_UTM_Medium__c );
                System.assertEquals(contactCampMap.get(con).UTM_Source__c , lff.Last_Touch_UTM_Source__c );
                System.assertEquals(contactCampMap.get(con).UTM_Term__c , lff.Last_Touch_UTM_Term__c );
                System.assertEquals(contactCampMap.get(con).CreatedDate, lff.Last_Touch_Associated_Date__c );
                System.assertEquals(contactCampMap.get(con).Campaignid, lff.Last_Touch_Campaign__c );
                System.assertEquals(contactCampMap.get(con).Status, lff.First_Touch_Campaign_Member_Status__c );
                System.assertEquals(contactCampMap.get(con).Status, lff.Last_Touch_Campaign_Member_Status__c );
                System.assertEquals(contactCampMap.get(con).createddate, lff.Inquiry_Date_Entered__c );

                System.assertEquals(contactCampMap.get(con).Campaign.Type,lff.First_Touch_Campaign_Type__c);
                System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,lff.First_Touch_Campaign_Sub_Type__c);
                System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,lff.First_Touch_Product__c);
                System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,lff.Last_Touch_Campaign_Product__c);
                System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,lff.Last_Touch_Campaign_Sub_Type__c);
                System.assertEquals(contactCampMap.get(con).Campaign.Type,lff.Last_Touch_Campaign_Type__c);

                System.assertEquals(contactCampMap.get(con).CampaignId,lff.Last_Touch_SQL_Campaign__c);
                System.assertEquals(contactCampMap.get(con).Status,lff.Last_Touch_SQL_Campaign_Member_Status__c);
                System.assertEquals(contactCampMap.get(con).createdDate,lff.Last_Touch_SQL_Associated_Date__c);
                System.assertEquals(contactCampMap.get(con).Campaign.Type,lff.Last_Touch_SQL_Campaign_Type__c);
                System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,lff.Last_Touch_SQL_Campaign_Sub_Type__c);
                System.assertEquals(contactCampMap.get(con).UTM_Content__c,lff.Last_SQL_Touch_UTM_Content__c);
                System.assertEquals(contactCampMap.get(con).UTM_Medium__c,lff.Last_SQL_Touch_UTM_Medium__c);
                System.assertEquals(contactCampMap.get(con).UTM_Source__c,lff.Last_SQL_Touch_UTM_Source__c);
                System.assertEquals(contactCampMap.get(con).UTM_Term__c,lff.Last_SQL_Touch_UTM_Term__c);
                System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,lff.Last_SQL_Touch_Product__c);
                System.assertEquals(contactCampMap.get(con).id,lff.Last_Touch_SQL_Campaign_Member_ID__c);

                //Ashwani: TODO - ADD ALL FIELDS to ASSERT
            }
        }
    }

    static testMethod void testNewMqlLeadWithInactiveLFF(){
        createLeadData();

        fSRList = TestDataFactory.createFSRList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++){
            fSRList[rec].Lead__c = leadList[rec].id;
            fSRList[rec].MQL_Date_Entered__c = Date.today();
            fSRList[rec].MQL_Status__c = MQL_REJECTED_STATUS;
            fSRList[rec].Rejected_Reason__c = 'Fraud';
        }
        insert fSRList ;

        campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].LeadId = leadList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        List<Lifecycle_Field_Funnel__c > lFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            lFFList[rec].Lead__c = leadList[rec].id;
            lFFList[rec].MQL__c = fSRList[rec].id;
        }
        insert lFFList ;

        test.startTest();
            BatchMQLeadToLFF bat = new BatchMQLeadToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        for(FSR__c newFSR : [SELECT id,(SELECT id FROM Lifecycle_Field_Funnels__r WHERE LFF_Active__c = TRUE)
                                    FROM FSR__c WHERE Id IN : fSRList])
        {
            System.assertEquals(0, newFSR.Lifecycle_Field_Funnels__r.size());
        }
       // System.assert(false, 'Needs to be implemented from Test Scripts, spreadsheet');
    }

    static testMethod void testNewMqlContactWithInactiveLFF(){
        createContactData();

        fSRList = TestDataFactory.createFSRList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++){
            fSRList[rec ].contact__c= conList[rec ].id;
            fSRList[rec ].MQL_Date_Entered__c = Date.today();
            fSRList[rec ].MQL_Status__c = MQL_REJECTED_STATUS;
            fSRList[rec ].Rejected_Reason__c = 'Fraud';
        }
        insert fSRList ;

        List<Lifecycle_Field_Funnel__c > lFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            lFFList[rec].contact__c = conlist[rec].id;
            lFFList[rec].MQL__c = fSRList[rec].id;
        }
        insert lFFList ;

        test.startTest();
            BatchMQLeadToLFF bat = new BatchMQLeadToLFF(1);
            database.executebatch(bat);
        test.stopTest();

       for(FSR__c newFSR : [SELECT id,(SELECT id FROM Lifecycle_Field_Funnels__r WHERE LFF_Active__c = TRUE)
                                    FROM FSR__c WHERE Id IN: fSRList])
        {
            System.assertEquals(0, newFSR.Lifecycle_Field_Funnels__r.size());
        }
        //System.assert(false, 'Needs to be implemented from Test Scripts, spreadsheet');
    }

    static testMethod void testNewMqlLeadWithActiveLFF(){
        createLeadData();

        createLeadData();
        fSRList = TestDataFactory.createFSRList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++){
            fSRList[rec].Lead__c = leadList[rec].id;
        }
        insert fSRList ;

        List<Lifecycle_Field_Funnel__c > lFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            lFFList[rec].Lead__c = leadList[rec].id;
            lFFList[rec].MQL__c = fSRList[rec].id;
        }
        insert lFFList ;

        campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].LeadId = leadList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
            lFFList[rec].Inquiry_Date_Entered__c = date.today() - 7;
        }
        insert campMemList ;

        test.startTest();
            BatchMQLeadToLFF bat = new BatchMQLeadToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, leadid,
                                            Status, lead.Eloqua_Lead_Rating__c, createdDate, UTM_Content__c,
                                            UTM_Medium__c, UTM_Source__c, UTM_Term__c, campaignid
                                        from CampaignMember where id IN: campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> leadCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            leadCampMap.put(cm.leadid,cm);
        }

        List<FSR__c> newFSRList = [SELECT id, lead__c, lead__r.Eloqua_Lead_Rating__c, contact__c, Contact__r.Eloqua_Lead_Rating__c,
                                        (SELECT id, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c,
                                            First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                            Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c,
                                            Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                            Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c, Last_Touch_SQL_Campaign_Type__c,
                                            Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c,
                                            Current_Funnel_Stage__c, MQL_Rejected_Date__c, First_Touch_UTM_Content__c,
                                            Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,
                                            Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,
                                            Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,
                                            Last_Touch_Campaign_Member_Status__c,
                                            First_Touch_Campaign_Member_Status__c,
                                            First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,
                                            First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c,
                                            First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,
                                            Inquiry_Date_Entered__c
                                        FROM Lifecycle_Field_Funnels__r )
                                    FROM FSR__c WHERE Id IN : fSRList ];
        System.assertEquals(NumberOfRec , newFSRList.size());

        map<id,List<Lifecycle_Field_Funnel__c>> fSRLFFcampMap = new Map<id,List<Lifecycle_Field_Funnel__c>>();

        for(FSR__c fsr: newFSRList ){
            fSRLFFcampMap.put(fsr.lead__c,fsr.Lifecycle_Field_Funnels__r);
        }

        for(id ld: fSRLFFcampMap.keyset())
        {
            for(Lifecycle_Field_Funnel__c lff : fSRLFFcampMap.get(ld)){

                System.assertEquals(leadCampMap.get(ld).lead.Eloqua_Lead_Rating__c , lff.MQL_Interest_Score__c);
                System.assertEquals(null, lff.Inquiry_Date_Entered__c);

                System.assertEquals(leadCampMap.get(ld).id, lff.First_Touch_Campaign_Member_ID__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Content__c, lff.First_Touch_UTM_Content__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Medium__c , lff.First_Touch_UTM_Medium__c );
                System.assertEquals(leadCampMap.get(ld).UTM_Source__c , lff.First_Touch_UTM_Source__c );
                System.assertEquals(leadCampMap.get(ld).UTM_Term__c , lff.First_Touch_UTM_Term__c );
                System.assertEquals(leadCampMap.get(ld).CreatedDate, lff.First_Touch_Associated_Date__c );
                System.assertEquals(leadCampMap.get(ld).Campaignid, lff.First_Touch_Campaign__c );
                System.assertEquals(leadCampMap.get(ld).id, lff.Last_Touch_Campaign_Member_ID__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Content__c, lff.Last_Touch_UTM_Content__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Medium__c , lff.Last_Touch_UTM_Medium__c );
                System.assertEquals(leadCampMap.get(ld).UTM_Source__c , lff.Last_Touch_UTM_Source__c );
                System.assertEquals(leadCampMap.get(ld).UTM_Term__c , lff.Last_Touch_UTM_Term__c );
                System.assertEquals(leadCampMap.get(ld).CreatedDate, lff.Last_Touch_Associated_Date__c );
                System.assertEquals(leadCampMap.get(ld).Campaignid, lff.Last_Touch_Campaign__c );
                System.assertEquals(leadCampMap.get(ld).Status, lff.First_Touch_Campaign_Member_Status__c );
                System.assertEquals(leadCampMap.get(ld).Status, lff.Last_Touch_Campaign_Member_Status__c );
                System.assertEquals(null, lff.Inquiry_Date_Entered__c );

                System.assertEquals(leadCampMap.get(ld).Campaign.Type,lff.First_Touch_Campaign_Type__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.SubType__c,lff.First_Touch_Campaign_Sub_Type__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Product_Type__c,lff.First_Touch_Product__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Product_Type__c,lff.Last_Touch_Campaign_Product__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.SubType__c,lff.Last_Touch_Campaign_Sub_Type__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Type,lff.Last_Touch_Campaign_Type__c);

                System.assertEquals(leadCampMap.get(ld).CampaignId,lff.Last_Touch_SQL_Campaign__c);
                System.assertEquals(leadCampMap.get(ld).Status,lff.Last_Touch_SQL_Campaign_Member_Status__c);
                System.assertEquals(leadCampMap.get(ld).createdDate,lff.Last_Touch_SQL_Associated_Date__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Type,lff.Last_Touch_SQL_Campaign_Type__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.SubType__c,lff.Last_Touch_SQL_Campaign_Sub_Type__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Content__c,lff.Last_SQL_Touch_UTM_Content__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Medium__c,lff.Last_SQL_Touch_UTM_Medium__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Source__c,lff.Last_SQL_Touch_UTM_Source__c);
                System.assertEquals(leadCampMap.get(ld).UTM_Term__c,lff.Last_SQL_Touch_UTM_Term__c);
                System.assertEquals(leadCampMap.get(ld).Campaign.Product_Type__c,lff.Last_SQL_Touch_Product__c);
                System.assertEquals(leadCampMap.get(ld).id,lff.Last_Touch_SQL_Campaign_Member_ID__c);
                //Ashwani: TODO - ADD ALL FIELDS to ASSERT
            }
        }
        //System.assert(false, 'Needs to be implemented from Test Scripts, spreadsheet');
    }

    static testMethod void testNewMqlContactWithActiveLFF(){
        createContactData();

        fSRList = TestDataFactory.createFSRList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++){
            fSRList[rec].contact__c = conlist[rec].id;
        }
        insert fSRList ;

        List<Lifecycle_Field_Funnel__c > lFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            lFFList[rec].contact__c = conList[rec].id;
            lFFList[rec].MQL__c = fSRList[rec].id;

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
            BatchMQLeadToLFF bat = new BatchMQLeadToLFF(1);
            database.executebatch(bat);
        test.stopTest();


        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, leadid,
                                            Status, lead.Eloqua_Lead_Rating__c, contact.Eloqua_Lead_Rating__c, createdDate,
                                            UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, campaignid
                                        from CampaignMember where id IN: campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap= new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }

        List<FSR__c> newFSRList = [SELECT id, lead__c, lead__r.Eloqua_Lead_Rating__c, contact__c, Contact__r.Eloqua_Lead_Rating__c,
                                        (SELECT id, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c,
                                            First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                            Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c,
                                            Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                            Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c, Last_Touch_SQL_Campaign_Type__c,
                                            Last_Touch_SQL_Associated_Date__c, Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c,
                                            Current_Funnel_Stage__c, MQL_Rejected_Date__c, First_Touch_UTM_Content__c,
                                            Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,
                                            Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,
                                            Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,
                                            Last_Touch_Campaign_Member_Status__c,
                                            First_Touch_Campaign_Member_Status__c,
                                            First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,
                                            First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c,
                                            First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,
                                            Inquiry_Date_Entered__c
                                        FROM Lifecycle_Field_Funnels__r )
                                    FROM FSR__c WHERE Id IN : fSRList ];
        System.assertEquals(NumberOfRec , newFSRList.size());

        map<id,List<Lifecycle_Field_Funnel__c>> fSRLFFcampMap = new Map<id,List<Lifecycle_Field_Funnel__c>>();

        for(FSR__c fsr: newFSRList ){
            fSRLFFcampMap.put(fsr.contact__c,fsr.Lifecycle_Field_Funnels__r);
        }

        for(id con: fSRLFFcampMap.keyset())
        {
            for(Lifecycle_Field_Funnel__c lff : fSRLFFcampMap.get(con)){
               System.assertEquals(null, lff.Inquiry_Date_Entered__c);

            System.assertEquals(contactCampMap.get(con).contact.Eloqua_Lead_Rating__c, lff.MQL_Interest_Score__c);
            System.assertEquals(contactCampMap.get(con).id, lff.First_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c, lff.First_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c , lff.First_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(con).UTM_Source__c , lff.First_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(con).UTM_Term__c , lff.First_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(con).CreatedDate, lff.First_Touch_Associated_Date__c );
            System.assertEquals(contactCampMap.get(con).Campaignid, lff.First_Touch_Campaign__c );

            System.assertEquals(contactCampMap.get(con).id, lff.Last_Touch_Campaign_Member_ID__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c, lff.Last_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c , lff.Last_Touch_UTM_Medium__c );
            System.assertEquals(contactCampMap.get(con).UTM_Source__c , lff.Last_Touch_UTM_Source__c );
            System.assertEquals(contactCampMap.get(con).UTM_Term__c , lff.Last_Touch_UTM_Term__c );
            System.assertEquals(contactCampMap.get(con).CreatedDate, lff.Last_Touch_Associated_Date__c );
            System.assertEquals(contactCampMap.get(con).Campaignid, lff.Last_Touch_Campaign__c );

            System.assertEquals(contactCampMap.get(con).Campaign.Type,lff.First_Touch_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,lff.First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,lff.First_Touch_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,lff.Last_Touch_Campaign_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,lff.Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Type,lff.Last_Touch_Campaign_Type__c);

            System.assertEquals(contactCampMap.get(con).CampaignId,lff.Last_Touch_SQL_Campaign__c);
            System.assertEquals(contactCampMap.get(con).Status,lff.Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(contactCampMap.get(con).createdDate,lff.Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Type,lff.Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,lff.Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).UTM_Content__c,lff.Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(contactCampMap.get(con).UTM_Medium__c,lff.Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(contactCampMap.get(con).UTM_Source__c,lff.Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(contactCampMap.get(con).UTM_Term__c,lff.Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,lff.Last_SQL_Touch_Product__c);
            System.assertEquals(contactCampMap.get(con).id,lff.Last_Touch_SQL_Campaign_Member_ID__c);
            //Ashwani: TODO - ADD ALL FIELDS to ASSERT
        }
       // System.assert(false, 'Needs to be implemented from Test Scripts, spreadsheet');
    }
    }

    static testMethod void testNewMqlContactWithActiveLFFWrongCampaignM(){
        createContactData();

        fSRList = TestDataFactory.createFSRList(NumberOfRec);
        for(integer rec = 0; rec < NumberOfRec ; rec++){
            fSRList[rec].contact__c = conlist[rec].id;
        }
        insert fSRList ;

        List<Lifecycle_Field_Funnel__c > lFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec < NumberOfRec ; rec++ ){
            lFFList[rec].contact__c = conList[rec].id;
            lFFList[rec].MQL__c = fSRList[rec].id;
        }
        insert lFFList ;

        campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec < NumberOfRec ; rec++ ){
            campMemList[rec].contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
            campMemList[rec].Status = 'Sent';
        }
        insert campMemList ;

        test.startTest();
            BatchMQLeadToLFF bat = new BatchMQLeadToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        List<CampaignMember> cMList = [SELECT id, leadid, Status, lead.Eloqua_Lead_Rating__c, contact.Eloqua_Lead_Rating__c,
                                            createdDate, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c, campaignid
                                        from CampaignMember where id IN: campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap= new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }

        List<FSR__c> newFSRList = [SELECT id, lead__c, lead__r.Eloqua_Lead_Rating__c, contact__c, Contact__r.Eloqua_Lead_Rating__c,
                                        (SELECT id, Last_Touch_SQL_Campaign_Member_ID__c, First_Touch_Campaign_Type__c, First_Touch_Campaign_Sub_Type__c,
                                            First_Touch_Product__c, Last_Touch_Campaign_Product__c, Last_Touch_Campaign_Sub_Type__c,
                                            Last_Touch_Campaign_Type__c, Last_SQL_Touch_Product__c, Last_SQL_Touch_UTM_Term__c,
                                            Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c, Last_SQL_Touch_UTM_Content__c,
                                            Last_Touch_SQL_Campaign_Sub_Type__c, Last_Touch_SQL_Campaign_Type__c, Last_Touch_SQL_Associated_Date__c,
                                            Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c, Current_Funnel_Stage__c,
                                            MQL_Rejected_Date__c, First_Touch_UTM_Content__c,
                                            Last_Touch_Campaign__c,Last_Touch_Associated_Date__c,Last_Touch_UTM_Term__c,
                                            Last_Touch_UTM_Source__c,Last_Touch_UTM_Medium__c,Last_Touch_UTM_Content__c,
                                            Last_Touch_Campaign_Member_ID__c,First_Touch_Campaign__c,
                                            Last_Touch_Campaign_Member_Status__c,
                                            First_Touch_Campaign_Member_Status__c,
                                            First_Touch_Associated_Date__c ,First_Touch_UTM_Term__c,
                                            First_Touch_UTM_Source__c ,First_Touch_UTM_Medium__c,
                                            First_Touch_Campaign_Member_ID__c,MQL_Interest_Score__c,
                                            Inquiry_Date_Entered__c
                                        FROM Lifecycle_Field_Funnels__r )
                                    FROM FSR__c WHERE Id IN : fSRList ];
        System.assertEquals(NumberOfRec , newFSRList.size());

        map<id,List<Lifecycle_Field_Funnel__c>> fSRLFFcampMap = new Map<id,List<Lifecycle_Field_Funnel__c>>();

        for(FSR__c fsr: newFSRList ){
            fSRLFFcampMap.put(fsr.contact__c,fsr.Lifecycle_Field_Funnels__r);
        }

        for(id con: fSRLFFcampMap.keyset())
        {
            for(Lifecycle_Field_Funnel__c lff : fSRLFFcampMap.get(con)){
                System.assertEquals(null, lff.Inquiry_Date_Entered__c);

                System.assertEquals(contactCampMap.get(con).contact.Eloqua_Lead_Rating__c, lff.MQL_Interest_Score__c);
                System.assertEquals(null, lff.First_Touch_Campaign_Member_ID__c);
                System.assertEquals(null, lff.First_Touch_UTM_Content__c);
                System.assertEquals(null, lff.First_Touch_UTM_Medium__c );
                System.assertEquals(null, lff.First_Touch_UTM_Source__c );
                System.assertEquals(null, lff.First_Touch_UTM_Term__c );
                System.assertEquals(null, lff.First_Touch_Associated_Date__c );
                System.assertEquals(null, lff.First_Touch_Campaign__c );

                System.assertEquals(null, lff.Last_Touch_Campaign_Member_ID__c);
                System.assertEquals(null, lff.Last_Touch_UTM_Content__c);
                System.assertEquals(null ,lff.Last_Touch_UTM_Medium__c );
                System.assertEquals(null ,lff.Last_Touch_UTM_Source__c );
                System.assertEquals(null ,lff.Last_Touch_UTM_Term__c );
                System.assertEquals(null, lff.Last_Touch_Associated_Date__c );
                System.assertEquals(null, lff.Last_Touch_Campaign__c );

                System.assertEquals(null,lff.First_Touch_Campaign_Type__c);
                System.assertEquals(null,lff.First_Touch_Campaign_Sub_Type__c);
                System.assertEquals(null,lff.First_Touch_Product__c);
                System.assertEquals(null,lff.Last_Touch_Campaign_Product__c);
                System.assertEquals(null,lff.Last_Touch_Campaign_Sub_Type__c);
                System.assertEquals(null,lff.Last_Touch_Campaign_Type__c);

                System.assertEquals(null,lff.Last_Touch_SQL_Campaign__c);
                System.assertEquals(null,lff.Last_Touch_SQL_Campaign_Member_Status__c);
                System.assertEquals(null,lff.Last_Touch_SQL_Associated_Date__c);
                System.assertEquals(null,lff.Last_Touch_SQL_Campaign_Type__c);
                System.assertEquals(null,lff.Last_Touch_SQL_Campaign_Sub_Type__c);
                System.assertEquals(null,lff.Last_SQL_Touch_UTM_Content__c);
                System.assertEquals(null,lff.Last_SQL_Touch_UTM_Medium__c);
                System.assertEquals(null,lff.Last_SQL_Touch_UTM_Source__c);
                System.assertEquals(null,lff.Last_SQL_Touch_UTM_Term__c);
                System.assertEquals(null,lff.Last_SQL_Touch_Product__c);
                System.assertEquals(null,lff.Last_Touch_SQL_Campaign_Member_ID__c);
                //Ashwani: TODO - ADD ALL FIELDS to ASSERT
            }
        }
    }
}