/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  FoundryDSRTriggerServiceTest
*
* @description 	  Test class for FoundryDSRTriggerService class, test include:
					1. clearCampaignMemberTest
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui	 <ncui@twilio.com>
* @modifiedBy     Mia Cui    <ncui@twilio.com>
* @version        1.0
* @created        2020-03-10
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		
*
**/
@isTest
public class FoundryDSRTriggerServiceTest {
	static testmethod void clearCampaignMemberTest(){
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
        
        
        foundry.Status__c = 'Declined';
        update foundry;
        
        foundry = [SELECT campaign__c FROM Foundry_Deal_Support_Request__c WHERE id =: foundry.Id LIMIT 1];
        
        cm = [SELECT contactID FROM CampaignMember WHERE campaignID =: foundry.campaign__c];
        System.assert(cm.size() == 0);
    }
}