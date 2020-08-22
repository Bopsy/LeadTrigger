/*** * * * * *
*
* Name:        LffHelper_Test (Test class)
* Description: Unit test class for LffHelper
* Created:     Mar 28, 2016
* Author:      Divesh Bafna
* Company:     
*
* * * */
@isTest
private class LffHelper_Test 
{
    static List<Campaign> campList ;
    static List<CampaignMember> campMemList ;
    static List<Lifecycle_Field_Funnel__c > lFFList ;
    static integer NumberOfRec = 2;
    static List<Lead> leadList = new List<Lead>();
    
    
    public static void createData(){
        leadList = TestDataFactory.createLeadList(NumberOfRec);
        for(integer rec = 0; rec <NumberOfRec ; rec++ ){
            leadList[rec].status = 'Contacted';
            leadList[rec].Eloqua_Lead_Rating__c = 'A' + rec;
        }        
        insert leadList;
        
        campList = new List<Campaign>();
        campMemList = new List<CampaignMember>();
        for(lead ld : leadList){
            campList.addall(TestDataFactory.createCampaignList(NumberOfRec));    
            string previousvalue = '';        
            for(CampaignMember cm : TestDataFactory.createCampaignMemList(NumberOfRec)){
                cm.leadid = ld.id;
                campMemList.add(cm);
                if(previousvalue == 'Responded'){
                    cm.status = 'Sent';
                    previousvalue = 'Sent';
                }
                else{
                    cm.status = 'Responded';
                    previousvalue = 'Responded';
                }
            }
        }        
        insert campList ;        
        
        for(integer rec = 0; rec < campList.size(); rec++ ){
            campMemList[rec].CampaignId = campList[rec].id;            
        }
        insert campMemList ;        
    }
    
    static testMethod  void validateEmptyCampaignLffHelper(){
        createData();
        lFFList = TestDataFactory.createlFFList(NumberOfRec);
        
        CampaignMember latestCM = campMemList[campMemList.size()-1];
        CampaignMember oldestCM = campMemList[0];
        
        Test.startTest();
        for(Lifecycle_Field_Funnel__c lff : lFFList){
            LffHelper.populateLFFRecord(lff,latestCM,oldestCM);            
            system.assertequals(lff.First_Touch_Campaign_Member_Status__c,oldestCM.Status);
            system.assertequals(lff.First_Touch_Campaign__c ,oldestCM.CampaignId);
            system.assertequals(lff.First_Touch_Campaign_Member_ID__c ,oldestCM.id);
            system.assertequals(lff.First_Touch_UTM_Content__c ,oldestCM.UTM_Content__c );
            system.assertequals(lff.First_Touch_UTM_Medium__c ,oldestCM.UTM_Medium__c );
            system.assertequals(lff.First_Touch_UTM_Source__c ,oldestCM.UTM_Source__c );
            system.assertequals(lff.First_Touch_UTM_Term__c ,oldestCM.UTM_Term__c );
            system.assertequals(lff.First_Touch_Associated_Date__c ,oldestCM.createdDate );
            
            system.assertequals(lff.Last_Touch_UTM_Content__c ,latestCM.UTM_Content__c);
            system.assertequals(lff.Last_Touch_UTM_Medium__c ,latestCM.UTM_Medium__c);
            system.assertequals(lff.Last_Touch_UTM_Source__c ,latestCM.UTM_Source__c);
            system.assertequals(lff.Last_Touch_UTM_Term__c ,latestCM.UTM_Term__c);
            system.assertequals(lff.Last_Touch_Associated_Date__c ,latestCM.createdDate);
            system.assertequals(lff.Last_Touch_Campaign_Member_ID__c ,latestCM.id);
            system.assertequals(lff.Last_Touch_Campaign__c ,latestCM.CampaignId);
            system.assertequals(lff.Last_Touch_Campaign_Member_Status__c ,latestCM.Status);
            
            System.assertEquals(oldestCM.Campaign.Type,lff.First_Touch_Campaign_Type__c);
            System.assertEquals(oldestCM.Campaign.SubType__c,lff.First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(oldestCM.Campaign.Product_Type__c,lff.First_Touch_Product__c);
            System.assertEquals(latestCM.Campaign.Product_Type__c,lff.Last_Touch_Campaign_Product__c);
            System.assertEquals(latestCM.Campaign.SubType__c,lff.Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(latestCM.Campaign.Type,lff.Last_Touch_Campaign_Type__c);
                        
            System.assertEquals(latestCM.CampaignId,lff.Last_Touch_SQL_Campaign__c);
            System.assertEquals(latestCM.Status,lff.Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(latestCM.createdDate,lff.Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(latestCM.Campaign.Type,lff.Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(latestCM.Campaign.SubType__c,lff.Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(latestCM.UTM_Content__c,lff.Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(latestCM.UTM_Medium__c,lff.Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(latestCM.UTM_Source__c,lff.Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(latestCM.UTM_Term__c,lff.Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(latestCM.Campaign.Product_Type__c,lff.Last_SQL_Touch_Product__c); 
            System.assertEquals(latestCM.CampaignId, lff.Last_Touch_SQL_Campaign__c);             
        }    
        Test.stopTest();    
    }
    
    static testMethod  void validateLffWithValuesHelper(){
        createData();
        lFFList = TestDataFactory.createlFFList(NumberOfRec);
        for(Lifecycle_Field_Funnel__c lff : lFFList){
            lff.First_Touch_Campaign_Member_Status__c = campMemList[1].Status;
            lff.First_Touch_Campaign__c = campMemList[1].CampaignId;
            lff.First_Touch_Campaign_Member_ID__c = campMemList[1].id;
            lff.First_Touch_UTM_Content__c = campMemList[1].UTM_Content__c + 'test';
            lff.First_Touch_UTM_Medium__c = campMemList[1].UTM_Medium__c + 'test';
            lff.First_Touch_UTM_Source__c = campMemList[1].UTM_Source__c + 'test';
            lff.First_Touch_UTM_Term__c = campMemList[1].UTM_Term__c + 'test';
            lff.First_Touch_Associated_Date__c = campMemList[1].createdDate;
            
            lff.Last_Touch_UTM_Content__c = campMemList[1].UTM_Content__c + 'test';
            lff.Last_Touch_UTM_Medium__c = campMemList[1].UTM_Medium__c + 'test';
            lff.Last_Touch_UTM_Source__c = campMemList[1].UTM_Source__c + 'test';            
            lff.Last_Touch_UTM_Term__c = campMemList[1].UTM_Term__c + 'test';
            lff.Last_Touch_Associated_Date__c = campMemList[1].createdDate;
            lff.Last_Touch_Campaign_Member_ID__c = campMemList[1].id;
            lff.Last_Touch_Campaign__c = campMemList[1].CampaignId;
            lff.Last_Touch_Campaign_Member_Status__c = campMemList[1].Status;
            
            lff.Last_Touch_SQL_Campaign__c = campMemList[1].CampaignId;
            lff.Last_Touch_SQL_Campaign_Member_Status__c = campMemList[1].Status + 'test';
            lff.Last_Touch_SQL_Associated_Date__c = campMemList[1].createdDate;
            lff.Last_Touch_SQL_Campaign_Type__c = campMemList[1].Campaign.Type + 'test';
            lff.Last_Touch_SQL_Campaign_Sub_Type__c = campMemList[1].Campaign.SubType__c + 'test';
            lff.Last_SQL_Touch_UTM_Content__c = campMemList[1].UTM_Content__c + 'test';
            lff.Last_SQL_Touch_UTM_Source__c = campMemList[1].UTM_Source__c + 'test';
            lff.Last_SQL_Touch_UTM_Medium__c = campMemList[1].UTM_Medium__c + 'test';
            lff.Last_SQL_Touch_UTM_Term__c = campMemList[1].UTM_Term__c + 'test';
            lff.Last_SQL_Touch_Product__c = campMemList[1].Campaign.Product_Type__c + 'test';
            
        }
        
        insert lFFList;
        CampaignMember latestCM = null;
        CampaignMember oldestCM = null;
        
        
        Test.startTest();
        for(Lifecycle_Field_Funnel__c lff : lFFList){
            LffHelper.populateLFFRecord(lff,latestCM,oldestCM);            
            system.assertequals(lff.First_Touch_Campaign_Member_Status__c,campMemList[1].Status);
            system.assertequals(lff.First_Touch_Campaign__c ,campMemList[1].CampaignId);
            system.assertequals(lff.First_Touch_Campaign_Member_ID__c ,campMemList[1].id);
            system.assertequals(lff.First_Touch_UTM_Content__c ,campMemList[1].UTM_Content__c + 'test');
            system.assertequals(lff.First_Touch_UTM_Medium__c ,campMemList[1].UTM_Medium__c + 'test');
            system.assertequals(lff.First_Touch_UTM_Source__c ,campMemList[1].UTM_Source__c + 'test');
            system.assertequals(lff.First_Touch_UTM_Term__c ,campMemList[1].UTM_Term__c + 'test');
            system.assertequals(lff.First_Touch_Associated_Date__c ,campMemList[1].createddate);
            
            system.assertequals(lff.Last_Touch_UTM_Content__c ,campMemList[1].UTM_Content__c+ 'test');
            system.assertequals(lff.Last_Touch_UTM_Medium__c ,campMemList[1].UTM_Medium__c+ 'test');
            system.assertequals(lff.Last_Touch_UTM_Source__c ,campMemList[1].UTM_Source__c+ 'test');
            system.assertequals(lff.Last_Touch_UTM_Term__c ,campMemList[1].UTM_Term__c+ 'test');
            system.assertequals(lff.Last_Touch_Associated_Date__c ,campMemList[1].createddate);
            system.assertequals(lff.Last_Touch_Campaign_Member_ID__c ,campMemList[1].id);
            system.assertequals(lff.Last_Touch_Campaign__c ,campMemList[1].CampaignId);
            system.assertequals(lff.Last_Touch_Campaign_Member_Status__c ,campMemList[1].Status); 
            
            System.assertEquals(campMemList[1].Campaign.Type,lff.First_Touch_Campaign_Type__c);
            System.assertEquals(campMemList[1].Campaign.SubType__c,lff.First_Touch_Campaign_Sub_Type__c);
            System.assertEquals(campMemList[1].Campaign.Product_Type__c,lff.First_Touch_Product__c);
            System.assertEquals(campMemList[1].Campaign.Product_Type__c,lff.Last_Touch_Campaign_Product__c);
            System.assertEquals(campMemList[1].Campaign.SubType__c,lff.Last_Touch_Campaign_Sub_Type__c);
            System.assertEquals(campMemList[1].Campaign.Type,lff.Last_Touch_Campaign_Type__c);
            
            System.assertEquals(campMemList[1].CampaignId,lff.Last_Touch_SQL_Campaign__c);
            System.assertEquals(campMemList[1].Status + 'test',lff.Last_Touch_SQL_Campaign_Member_Status__c);
            System.assertEquals(campMemList[1].createdDate,lff.Last_Touch_SQL_Associated_Date__c);
            System.assertEquals(campMemList[1].Campaign.Type + 'test',lff.Last_Touch_SQL_Campaign_Type__c);
            System.assertEquals(campMemList[1].Campaign.SubType__c + 'test',lff.Last_Touch_SQL_Campaign_Sub_Type__c);
            System.assertEquals(campMemList[1].UTM_Content__c + 'test',lff.Last_SQL_Touch_UTM_Content__c);
            System.assertEquals(campMemList[1].UTM_Medium__c + 'test',lff.Last_SQL_Touch_UTM_Medium__c);
            System.assertEquals(campMemList[1].UTM_Source__c + 'test',lff.Last_SQL_Touch_UTM_Source__c);
            System.assertEquals(campMemList[1].UTM_Term__c + 'test',lff.Last_SQL_Touch_UTM_Term__c);
            System.assertEquals(campMemList[1].Campaign.Product_Type__c + 'test',lff.Last_SQL_Touch_Product__c);  
            System.assertEquals(campMemList[1].CampaignId, lff.Last_Touch_SQL_Campaign__c);         
        }   
        Test.stopTest();    
    }

}