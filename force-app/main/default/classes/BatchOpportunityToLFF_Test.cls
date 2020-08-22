/* * * * * *
*
* Name:        BatchOpportunityToLFF_Test (Test class)
* Description: Test class for BatchOpportunityToLFF
* Created:     02-Febuary-2016, 16:37 IST
* Author:      Ashwani Soni
* Company:     GoNimbly, Ian
*
* * * */


@isTest
public with sharing class BatchOpportunityToLFF_Test
{
    static account account;
    static integer NumberOfRec = 2;
    static List<Contact> conList;
    static List<Campaign> campList;
    static List<CampaignMember> campMemList;
    static List<opportunity> newoppList;
    static List<opportunity> newoppList2;
    static List<OpportunityContactRole> oppConRoleList;
    static List<Use_Case_Interest__c> uciList;

    
    static void createData()
    {
        conList = new List<Contact>();
        campList = new List<Campaign>();
        campMemList = new List<CampaignMember>();
        newoppList = new List<opportunity>();
        newoppList2 = new List<opportunity>();
        oppConRoleList = new List<OpportunityContactRole >();
        uciList = new List<Use_Case_Interest__c>();

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
        newoppList[0].SQL_Date_Entered__c = date.today();
        insert newoppList ;

        newoppList2 = TestDataFactory.createOpportunityList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            newoppList2[rec].StageName = 'Closed Won';
            newoppList2[rec].accountid = account.id;
        }
        newoppList2[0].SQL_Date_Entered__c = date.today();
        insert newoppList2 ;

        oppConRoleList = TestDataFactory.createOppConRole(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            oppConRoleList[rec].opportunityid = newoppList[rec].id;
            oppConRoleList[rec].contactid = conlist[rec].id;
        }
        insert oppConRoleList ;

        uciList = TestDataFactory.createUCIList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            uciList[rec].contact__c= conList[rec].id;
        }
        insert uciList ;

    }

    static testMethod void testOppWithNoLFF()
    {
        createData();
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
            BatchOpportunityToLFF bat = new BatchOpportunityToLFF(1);
            database.executebatch(bat);
            System.schedule('LFF Opp Batch Chain - Hourly Test', '0 0 * * * ?', new BatchOpportunityToLFF());
        test.stopTest();

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT id, opportunity__r.LFF_Record__c, Last_Touch_SQL_Campaign_Member_ID__c,
                                                        First_Touch_Campaign_Type__c, First_Touch_Campaign_Sub_Type__c,
                                                        First_Touch_Product__c, Last_Touch_Campaign_Product__c,
                                                        Last_Touch_Campaign_Sub_Type__c, Last_Touch_Campaign_Type__c,
                                                        Current_Funnel_Stage__c, Last_SQL_Touch_Product__c, Last_SQL_Touch_UTM_Term__c,
                                                        Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                                        Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c,
                                                        Last_Touch_SQL_Campaign_Type__c, Last_Touch_SQL_Associated_Date__c,
                                                        Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c,
                                                        contact__c, opportunity__c, Inquiry_Date_Entered__c, name,
                                                        First_Touch_Campaign_Member_ID__c, First_Touch_Campaign_Member_Status__c,
                                                        First_Touch_UTM_Content__c, First_Touch_UTM_Medium__c, First_Touch_UTM_Source__c,
                                                        First_Touch_UTM_Term__c, First_Touch_Associated_Date__c, First_Touch_Campaign__c,
                                                        Last_Touch_Campaign_Member_Status__c, Last_Touch_Campaign_Member_ID__c,
                                                        Last_Touch_UTM_Content__c, Last_Touch_UTM_Medium__c, Last_Touch_UTM_Source__c,
                                                        Last_Touch_UTM_Term__c, Last_Touch_Associated_Date__c, Last_Touch_Campaign__c
                                                    from Lifecycle_Field_Funnel__c WHERE LFF_Active__c = TRUE AND opportunity__c IN : newoppList ];

        System.assertEquals(NumberOfRec , newLLFList.size());
        map<id,Lifecycle_Field_Funnel__c> LFFconMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFconMap.put(lff.contact__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, contactid,
                                        status, createdDate, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c,
                                        campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }


        for(id con : LFFconMap.keyset())
        {
            system.debug('test---'+LFFconMap.get(con));
           // System.assertEquals(LFFconMap.get(con).id, LFFconMap.get(con).opportunity__r.LFF_Record__c);
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

    static testMethod void testOppWithActiveLFF()
    {
        createData();
        campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
            campList[0].SubType__c='Whitepaper';
            campList[0].Product_Type__c = 'Support';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        List<Lifecycle_Field_Funnel__c > lFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            lFFList[rec].contact__c = conList[rec].id;
            lFFList[rec].opportunity__c = newoppList[rec].id;
        }
        insert lFFList ;

        test.startTest();
            BatchOpportunityToLFF bat = new BatchOpportunityToLFF(1);
            database.executebatch(bat);
        test.stopTest();

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT id, opportunity__r.LFF_Record__c, Last_Touch_SQL_Campaign_Member_ID__c,
                                                        First_Touch_Campaign_Type__c, First_Touch_Campaign_Sub_Type__c,
                                                        First_Touch_Product__c, Last_Touch_Campaign_Product__c, Last_Touch_Campaign_Sub_Type__c,
                                                        Last_Touch_Campaign_Type__c, Current_Funnel_Stage__c, Last_SQL_Touch_Product__c,
                                                        Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                                        Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c,
                                                        Last_Touch_SQL_Campaign_Type__c, Last_Touch_SQL_Associated_Date__c,
                                                        Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c, contact__c,
                                                        Inquiry_Date_Entered__c, name, First_Touch_Campaign_Member_ID__c,
                                                        First_Touch_Campaign_Member_Status__c, First_Touch_UTM_Content__c,
                                                        First_Touch_UTM_Medium__c, First_Touch_UTM_Source__c, First_Touch_UTM_Term__c,
                                                        First_Touch_Associated_Date__c, First_Touch_Campaign__c,
                                                        Last_Touch_Campaign_Member_Status__c, Last_Touch_Campaign_Member_ID__c,
                                                        Last_Touch_UTM_Content__c, Last_Touch_UTM_Medium__c, Last_Touch_UTM_Source__c,
                                                        Last_Touch_UTM_Term__c, Last_Touch_Associated_Date__c, Last_Touch_Campaign__c
                                                    from Lifecycle_Field_Funnel__c WHERE LFF_Active__c = TRUE AND opportunity__c IN : newoppList];

        System.assertEquals(NumberOfRec , newLLFList.size());
        map<id,Lifecycle_Field_Funnel__c> LFFconMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFconMap.put(lff.contact__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c, contactid,
                                        createdDate, status, UTM_Content__c, UTM_Medium__c, UTM_Source__c, UTM_Term__c,
                                        campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }


        for(id con : LFFconMap.keyset())
        {
            System.assertEquals(LFFconMap.get(con).id, LFFconMap.get(con).opportunity__r.LFF_Record__c);
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

            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).First_Touch_Campaign_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).First_Touch_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).Last_Touch_Campaign_Product__c);
            System.assertEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).Last_Touch_Campaign_Type__c);

            // Inquiry_Date_Entered__c can be filled if LFF creation reason is a Campaign. Here it was Opportunity
            System.assertEquals(null, LFFconMap.get(con).Inquiry_Date_Entered__c );
            if(LFFconMap.get(con).Current_Funnel_Stage__c != '4 - SQL' ){
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
            if(LFFconMap.get(con).Current_Funnel_Stage__c == '4 - SQL' ){
                System.assertNotEquals(contactCampMap.get(con).CampaignId,LFFconMap.get(con).Last_Touch_SQL_Campaign__c);
                System.assertNotEquals(contactCampMap.get(con).Status,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_Status__c);
                System.assertNotEquals(contactCampMap.get(con).createdDate,LFFconMap.get(con).Last_Touch_SQL_Associated_Date__c);
                System.assertNotEquals(contactCampMap.get(con).Campaign.Type,LFFconMap.get(con).Last_Touch_SQL_Campaign_Type__c);
                System.assertNotEquals(contactCampMap.get(con).Campaign.SubType__c,LFFconMap.get(con).Last_Touch_SQL_Campaign_Sub_Type__c);
                System.assertNotEquals(contactCampMap.get(con).UTM_Content__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Content__c);
                System.assertNotEquals(contactCampMap.get(con).UTM_Medium__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Medium__c);
                System.assertNotEquals(contactCampMap.get(con).UTM_Source__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Source__c);
                System.assertNotEquals(contactCampMap.get(con).UTM_Term__c,LFFconMap.get(con).Last_SQL_Touch_UTM_Term__c);
                System.assertNotEquals(contactCampMap.get(con).Campaign.Product_Type__c,LFFconMap.get(con).Last_SQL_Touch_Product__c);
                System.assertNotEquals(contactCampMap.get(con).id,LFFconMap.get(con).Last_Touch_SQL_Campaign_Member_ID__c);
            }

        }
    }

    static testMethod void testOppWithInactiveLFF()
    {
        createData();
        campList = TestDataFactory.createCampaignList(1);
            campList[0].Type= 'Event';
        insert campList ;

        campMemList = TestDataFactory.createCampaignMemList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            campMemList[rec].contactid = conList[rec].id;
            campMemList[rec].CampaignId = campList[0].id;
        }
        insert campMemList ;

        List<Lifecycle_Field_Funnel__c > lFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            lFFList[rec].contact__c = conList[rec].id;
            lFFList[rec].Use_Case_Interest__c = uciList[rec].id;
            lFFList[rec].opportunity__c = newoppList2[rec].id;
            lFFList[rec].Inquiry_Date_Entered__c = date.today() - 366;
        }
        insert lFFList ;

        test.startTest();
            BatchOpportunityToLFF bat2 = new BatchOpportunityToLFF(1);
            database.executebatch(bat2);
        test.stopTest();

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT id from Lifecycle_Field_Funnel__c WHERE LFF_Active__c = true AND  opportunity__c IN : newoppList2];

        System.assertEquals(0, newLLFList.size());

    }

    static testMethod void testOppWithNoLFFProductMatched()
    {
        createData();
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
            BatchUCInterestToLFF bat1 = new BatchUCInterestToLFF(1);
            database.executebatch(bat1);

            BatchOpportunityToLFF bat2 = new BatchOpportunityToLFF(1);
            database.executebatch(bat2);
        test.stopTest();

        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT id, opportunity__r.LFF_Record__c, Last_Touch_SQL_Campaign_Member_ID__c,
                                                        First_Touch_Campaign_Type__c, First_Touch_Campaign_Sub_Type__c, First_Touch_Product__c,
                                                        Last_Touch_Campaign_Product__c, Last_Touch_Campaign_Sub_Type__c,
                                                        Last_Touch_Campaign_Type__c, Current_Funnel_Stage__c, Last_SQL_Touch_Product__c,
                                                        Last_SQL_Touch_UTM_Term__c, Last_SQL_Touch_UTM_Source__c, Last_SQL_Touch_UTM_Medium__c,
                                                        Last_SQL_Touch_UTM_Content__c, Last_Touch_SQL_Campaign_Sub_Type__c,
                                                        Last_Touch_SQL_Campaign_Type__c, Last_Touch_SQL_Associated_Date__c,
                                                        Last_Touch_SQL_Campaign__c, Last_Touch_SQL_Campaign_Member_Status__c, contact__c,
                                                        Use_Case_Interest__r.FY_16_Primary_Product__c, Opportunity__r.FY_16_Primary_Product__c,
                                                        Inquiry_Date_Entered__c, name, First_Touch_Campaign_Member_ID__c,
                                                        First_Touch_Campaign_Member_Status__c, First_Touch_UTM_Content__c,
                                                        First_Touch_UTM_Medium__c, First_Touch_UTM_Source__c, First_Touch_UTM_Term__c,
                                                        First_Touch_Associated_Date__c, First_Touch_Campaign__c,
                                                        Last_Touch_Campaign_Member_Status__c, Last_Touch_Campaign_Member_ID__c,
                                                        Last_Touch_UTM_Content__c, Last_Touch_UTM_Medium__c, Last_Touch_UTM_Source__c,
                                                        Last_Touch_UTM_Term__c, Last_Touch_Associated_Date__c, Last_Touch_Campaign__c
                                                    from Lifecycle_Field_Funnel__c WHERE LFF_Active__c = TRUE AND opportunity__c IN : newoppList];

        System.assertEquals(NumberOfRec , newLLFList.size());
        map<id,Lifecycle_Field_Funnel__c> LFFconMap = new Map<id,Lifecycle_Field_Funnel__c>();

        for(Lifecycle_Field_Funnel__c lff : newLLFList){
            LFFconMap.put(lff.contact__c,lff);
        }

        List<CampaignMember> cMList = [SELECT id, Campaign.Type, Campaign.SubType__c, Campaign.Product_Type__c,
                                        contactid, status, createdDate, UTM_Content__c, UTM_Medium__c, UTM_Source__c,
                                        UTM_Term__c, campaignid from CampaignMember where ID IN :campMemList ];
        System.assertEquals(NumberOfRec , cMList.size());

        map<id,CampaignMember> contactCampMap = new Map<id,CampaignMember>();
        for(CampaignMember cm : cMList ){
            contactCampMap.put(cm.contactid,cm);
        }

        List<Use_Case_Interest__c> newUciList = [SELECT id,Contact__c from Use_Case_Interest__c WHERE id IN: uciList ];
        map<id,id> contactUCIMap = new Map<id,id>();
        for(Use_Case_Interest__c uci : newUciList ){
            contactUCIMap.put(uci.Contact__c,uci.id);
        }

        for(id con : LFFconMap.keyset())
        {
            // Only one LFF will have UCI and Opp both
           System.assertEquals(contactUCIMap.get(con), LFFconMap.get(con).Use_Case_Interest__c);
           System.assertEquals(LFFconMap.get(con).id, LFFconMap.get(con).opportunity__r.LFF_Record__c);
           // Product must be same
            system.assertNotEquals(LFFconMap.get(con).Use_Case_Interest__c,null);
            System.assertEquals(LFFconMap.get(con).Use_Case_Interest__r.FY_16_Primary_Product__c, LFFconMap.get(con).Opportunity__r.FY_16_Primary_Product__c);

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

            if(LFFconMap.get(con).Current_Funnel_Stage__c != '4 - SQL' ){
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
    }

    static testMethod void testMultipleActiveLFFsForOpportunity()
    {
        final Integer NUM_RECORDS = 10;
        final String LEAD_RATING = 'test';

        Account testAccount = TestDataFactory.createAccountList(1)[0];
        insert testAccount;

        List<Contact> testContacts = TestDataFactory.createContactList(NUM_RECORDS);
        for( Contact aContact : testContacts )
        {
            aContact.AccountId = testAccount.Id;
            aContact.Eloqua_Lead_Rating__c = LEAD_RATING;
        }
        insert testContacts;

        List<Opportunity> testOpportunities = new List<Opportunity>();
        List<OpportunityContactRole> testRoles = new List<OpportunityContactRole>();
        for( Contact aContact : testContacts )
        {
            Opportunity newOpportunity = TestDataFactory.createOpportunityList(1)[0];
            testOpportunities.add( newOpportunity );

            OpportunityContactRole newRole = TestDataFactory.createOppConRole(1)[0];
            newRole.ContactId = aContact.Id;
            newRole.Opportunity = newOpportunity;
            testRoles.add( newRole );
        }
        insert testOpportunities;

        for( OpportunityContactRole aRole : testRoles )
        {
            aRole.OpportunityId = aRole.Opportunity.Id;
        }
        insert testRoles;

        List<Lifecycle_Field_Funnel__c> testLFFs = new List<Lifecycle_Field_Funnel__c>();
        for( Contact aContact : testContacts )
        {
            for( Lifecycle_Field_Funnel__c newLFF : TestDataFactory.createlFFList(2) )
            {
                newLFF.Contact__c = aContact.Id;
                testLFFs.add( newLFF );
            }
        }
        insert testLFFs;

        Test.startTest();

            BatchOpportunityToLFF newBatch = new BatchOpportunityToLFF(1);
            Database.executeBatch(newBatch);

        Test.stopTest();

        List<Lifecycle_Field_Funnel__c> updatedLFFs = [ SELECT Id, SQL_Interest_Score__c FROM Lifecycle_Field_Funnel__c ];
        System.assertEquals( 2 * NUM_RECORDS, updatedLFFs.size(), 'There should have been as many LFFs retrieved as created' );
        for( Lifecycle_Field_Funnel__c anLFF : updatedLFFs )
        {
            System.assertEquals( LEAD_RATING, anLFF.SQL_Interest_Score__c, 'Every LFF should have been processed and updated' );
        }

        List<Opportunity> updatedOpportunities = [ SELECT Id, LFF_Record__c, (SELECT Id FROM Demand_Funnel_Reports__r) FROM Opportunity ];
        System.assertEquals( NUM_RECORDS, updatedOpportunities.size(), 'There should be as many Opportunities retrieved as created' );
        for( Opportunity anOpportunity : updatedOpportunities )
        {
            System.assertEquals( 1, anOpportunity.Demand_Funnel_Reports__r.size(), 'Each Opportunity should have had an LFF associated' );
            System.assertEquals( anOpportunity.Demand_Funnel_Reports__r[0].Id, anOpportunity.LFF_Record__c, 'Each Opportunity should look up to one of its children LFFs' );
        }
    }
    
    static testMethod void testOppWithNoPrimaryContactRole()
    {
        createData();
        oppConRoleList[0].IsPrimary = false ;        
        update oppConRoleList[0] ;
        
        test.startTest();                    
            BatchOpportunityToLFF bat = new BatchOpportunityToLFF(1);
            database.executebatch(bat);
        test.stopTest();
        
        List<Lifecycle_Field_Funnel__c> newLLFList = [SELECT id,opportunity__c from Lifecycle_Field_Funnel__c WHERE LFF_Active__c = true AND  opportunity__c IN : newoppList];
        
        System.assertEquals(1, newLLFList.size());
        System.assertEquals(oppConRoleList[1].opportunityid, newLLFList[0].opportunity__c);
    }
}