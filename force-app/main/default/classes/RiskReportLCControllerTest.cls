@isTest
public class RiskReportLCControllerTest {
	static testmethod void getStakeholderListTest(){
        Case_Constants__c csData = new Case_Constants__c(Name = 'COMS', Trigger_Start_Date__c= date.newInstance(2019, 9, 12), Record_Type_ID__c = '0121W0000009pXLQAY');
        insert csData;
        Account acc = new Account(name = 'TEST co', ownerID = '00540000001plWh');
        insert acc;
        Case risk = new Case(recordtypeID ='0121W000000QP0m', accountID = acc.ID, Next_Step__c = 'TEST', 
                             Next_Follow_Up_Date__c = date.newInstance(2020, 11, 21), Likelihood_of_Save__c = '3', 
                             status = 'Ongoing Risk', ARR_at_Risk__c =500 );
        
        

        
        insert new CXTeam__c(name = UserInfo.getUserID());
        System.runAs(new user(ID = UserInfo.getUserID())) {
            
            Test.startTest();
            insert risk;
        	RiskReportLCController.getStakeholderList(risk.ID);
        	RiskReportLCController.sendTierAlert(risk.ID, 'Tier 2', 'Mia Cui');
            Test.stopTest();
        }
    }
}