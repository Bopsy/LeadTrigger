/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  FoundryCampaignMemberBatchTest
*
* @description 	  Test class for FoundryCampaignMemberBatchTest class, test include:
					1. batch excute test
					4. schedulaer test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui	 <ncui@twilio.com>
* @modifiedBy     Mia Cui    <ncui@twilio.com>
* @version        1.0
* @created        2020-03-05
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		
*
**/
@isTest
public class FoundryCampaignMemberBatchTest {
    static testmethod void positivetest(){
        Account acc = new Account(name = 'Mia Test Co');
        insert acc;
        Contact con = new Contact(LastName = 'Cui');
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Prospecting');
        opp.ForecastCategoryName='Commit';
        opp.StageName = 'Incubate';
        insert opp;
        
        OpportunityContactRole contactRole = new OpportunityContactRole(OpportunityID = opp.id, contactID = con.id);
        insert contactRole;
        
        Foundry_Deal_Support_Request__c foundry = new Foundry_Deal_Support_Request__c(Opportunity__c = opp.id, engagement_type__c = 'Design Consulting');
        insert foundry;
        foundry.Foundry_Consultant__c = UserInfo.getUserID();
        foundry.Meeting_Date__c = System.today() + 10;
        foundry.Status__c = 'Approved';
        update foundry;
        
        Test.startTest();
            FoundryCampaignMemberBatch obj = new FoundryCampaignMemberBatch();
            DataBase.executeBatch(obj);
        Test.stopTest();
        foundry = [SELECT campaign__c FROM Foundry_Deal_Support_Request__c WHERE id =: foundry.Id LIMIT 1];
        
        List<CampaignMember> cm = [SELECT contactID FROM CampaignMember WHERE campaignID =: foundry.campaign__c];
        System.assert(cm.size() == 1);
        System.assert(cm[0].contactID == con.ID);
    }
    
    static testmethod void negativetest(){
        Account acc = new Account(name = 'Mia Test Co');
        insert acc;
        Contact con = new Contact(LastName = 'Cui');
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Prospecting');
        opp.ForecastCategoryName='Commit';
        opp.StageName = 'Incubate';
        insert opp;
        
        OpportunityContactRole contactRole = new OpportunityContactRole(OpportunityID = opp.id, contactID = con.id);
        insert contactRole;
        
        Foundry_Deal_Support_Request__c foundry = new Foundry_Deal_Support_Request__c(Opportunity__c = opp.id, engagement_type__c = 'Design Consulting');
        insert foundry;
        
        Test.startTest();
            FoundryCampaignMemberBatch obj = new FoundryCampaignMemberBatch();
            DataBase.executeBatch(obj);
        Test.stopTest();
        foundry = [SELECT campaign__c FROM Foundry_Deal_Support_Request__c WHERE id =: foundry.Id LIMIT 1];
        
        List<CampaignMember> cm = [SELECT contactID FROM CampaignMember WHERE campaignID =: foundry.campaign__c];
        System.assert(cm.size() == 0);
    }
    
    static testmethod void bulktest(){
        Account acc = new Account(name = 'Mia Test Co');
        insert acc;
        Contact con = new Contact(LastName = 'Cui');
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Prospecting');
        opp.ForecastCategoryName='Commit';
        opp.StageName = 'Incubate';
        insert opp;
        
        List<Contact> conList = new List<Contact>();
        for(integer i = 0; i<30; i++) {
            conList.add(new Contact(LastName = 'Cui' + i));
        }
        insert conList;
        
        List<OpportunityContactRole> contactroleList = new List<OpportunityContactRole>();
        for(integer i = 0; i<30; i++) {
            contactroleList.add(new OpportunityContactRole(OpportunityID = opp.id, contactID = conList[i].id));
        }
        insert contactroleList;
        
        
        
        Foundry_Deal_Support_Request__c foundry = new Foundry_Deal_Support_Request__c(Opportunity__c = opp.id, engagement_type__c = 'Design Consulting');
        insert foundry;
        foundry.Foundry_Consultant__c = UserInfo.getUserID();
        foundry.Meeting_Date__c = System.today() + 10;
        foundry.Status__c = 'Approved';
        update foundry;
        
        Foundry_Deal_Support_Request__c foundry2 = new Foundry_Deal_Support_Request__c(Opportunity__c = opp.id, engagement_type__c = 'Business Consulting');
        insert foundry2;
        foundry2.Foundry_Consultant__c = UserInfo.getUserID();
        foundry2.Meeting_Date__c = System.today() + 10;
        foundry2.Status__c = 'Approved';
        update foundry2;

        Foundry_Deal_Support_Request__c foundry3 = new Foundry_Deal_Support_Request__c(Opportunity__c = opp.id, engagement_type__c = 'Visioneering/Art of the Possible');
        insert foundry3;
        foundry3.Foundry_Consultant__c = UserInfo.getUserID();
        foundry3.Meeting_Date__c = System.today() + 10;
        foundry3.Status__c = 'Approved';
        update foundry3;
        
        Test.startTest();
            FoundryCampaignMemberBatch obj = new FoundryCampaignMemberBatch();
            DataBase.executeBatch(obj);
        Test.stopTest();
        foundry = [SELECT campaign__c FROM Foundry_Deal_Support_Request__c WHERE id =: foundry.Id LIMIT 1];
        foundry2 = [SELECT campaign__c FROM Foundry_Deal_Support_Request__c WHERE id =: foundry2.Id LIMIT 1];
        foundry3 = [SELECT campaign__c FROM Foundry_Deal_Support_Request__c WHERE id =: foundry3.Id LIMIT 1];
        
        List<CampaignMember> cm = [SELECT contactID FROM CampaignMember WHERE campaignID =: foundry.campaign__c];
        List<CampaignMember> cm2 = [SELECT contactID FROM CampaignMember WHERE campaignID =: foundry2.campaign__c];
        List<CampaignMember> cm3 = [SELECT contactID FROM CampaignMember WHERE campaignID =: foundry3.campaign__c];
        System.assert(cm.size() == 30);
        System.assert(cm2.size() == 30);
        System.assert(cm3.size() == 30);
    }
    
    
    static testMethod void testScheduler(){
        String CRON_EXP = '0 0 * * * ?';
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new FoundryCampaignMemberBatch());
        Test.stopTest();
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'FoundryCampaignMemberBatch') LIMIT 1].Status);
    }

}