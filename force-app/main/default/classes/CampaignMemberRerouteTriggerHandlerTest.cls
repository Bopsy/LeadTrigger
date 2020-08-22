/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CampaignMemberTriggerHandlerTest2
*
* @description 	  Test class tests the CampaignMemberTrigger and CampaignMemberTriggerHandler class.  
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-10-09
* @modified       
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class CampaignMemberRerouteTriggerHandlerTest {
    public static Map<String, Id> campaignIdMap = new Map<String,Id>();
	//Setup test data.
    
    @testSetup static void setup(){
        Campaign coreCampaign = new Campaign(Name = 'Core', Talk_to_Sales__c = TRUE);
      	insert coreCampaign;
        
        Campaign nonCoreCampaign = new Campaign(Name = 'Non-Core', Talk_to_Sales__c = TRUE);
        insert nonCoreCampaign;
        
        Campaign_Member_Core_Country__c coreCountryMexico = new Campaign_Member_Core_Country__c(Name = 'Mexico');
        Campaign_Member_Core_Country__c coreCountryDenmark = new Campaign_Member_Core_Country__c(Name = 'Denmark');
        insert coreCountryMexico;
        insert coreCountryDenmark;
        campaignIdMap.put(coreCampaign.Name, coreCampaign.Id);
        campaignIdMap.put(nonCoreCampaign.Name, nonCoreCampaign.Id);
    }
    
    private static testMethod void ensure_CampaignMembers_Are_Routed_to_Core_and_NonCore_Campaign(){
        Set<String> coreCountries = Campaign_Member_Core_Country__c.getAll().keySet();
        List<MQL_Campaign_Id_Mapping__c> mqlCampaignList = new List<MQL_Campaign_Id_Mapping__c>();
        
        List<Campaign> campaignsForReview = [SELECT Id, Name FROM Campaign];
        for(Campaign campaignRec : campaignsForReview){
            campaignIdMap.put(campaignRec.Name, campaignRec.Id);
            MQL_Campaign_Id_Mapping__c mqlCampaignRec = new MQL_Campaign_Id_Mapping__c(Name = campaignRec.Name,
                                                                                       Campaign_Id__c = campaignRec.Id);
            mqlCampaignList.add(mqlCampaignRec);
        }
        insert mqlCampaignList;
        
        //Campaign testCampaign = new Campaign(Name = 'Fake');
      	//insert testCampaign;
        
        Profile p = [Select Id from Profile where name = 'System Administrator'];
        
        User u = new User();
        u.ProfileId = p.Id;
        u.Username = System.now().getTime() + 'test@test.com';
        u.Alias = 'testtest';
        u.Email='test@test-lead-autoconvert-12345.com';
        u.EmailEncodingKey='UTF-8';
        u.Firstname='Test';
        u.Lastname='Test';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.TimeZoneSidKey='America/Chicago';
        insert u;
		
        //Insert 20 Leads with Random Country
        List<String> availableCountries = new List<String>{'Mexico','Denmark', 'Brazil', 'Canada'};
        Integer listSize = availableCountries.size();
        List<Lead> leadsForInsert = new List<Lead>();
        
        for(Integer i = 0; i < 20; i++){
            Integer randomNumber = Integer.valueof((Math.random() * listSize));
        	String randomCountry = availableCountries[randomNumber];
            System.debug('***** THIS IS THE RANDOM NUMBER: [' + randomNumber + '] *****');
            Lead testLead = new Lead(LastName = 'Test', 
                                 Email = 'test@test-lead-autoconvert-12345.com' + String.valueOf(i), 
                                 Company = 'Test Function',
                                 Country = randomCountry);
            leadsForInsert.add(testLead);
        }
        
        insert leadsForInsert;
        
        MQL_Creator_Whitelist__c mqlCW = new MQL_Creator_Whitelist__c(Name = 'Test', User_or_Role_ID__c = u.Id);
        insert mqlCW;
        //User au = [ SELECT Id FROM User WHERE name = 'Sales Operations' LIMIT 1 ];

        System.RunAs(u) {
            Map<String, MQL_Campaign_Id_Mapping__c> mqlCampaignIdMap = MQL_Campaign_Id_Mapping__c.getAll();
            List<CampaignMember> cmRecsForInsert = new List<CampaignMember>();
            Integer numberOfPeopleInCoreCountryList = 0;
            Integer numberOfPeopleNotInCoreCountryList = 0;
            
            for(Lead leadRec : leadsForInsert){
                CampaignMember cmTest = new CampaignMember(CampaignId = mqlCampaignIdMap.get('Non-Core').Campaign_Id__c,
                                                       Status = 'Registered',
                                                       LeadId = leadRec.Id);
                cmRecsForInsert.add(cmTest);
                
                if(coreCountries.contains(leadRec.Country)){
                    numberOfPeopleInCoreCountryList++;
                } else {
                    numberOfPeopleNotInCoreCountryList++;
                }
            }
            insert cmRecsForInsert;
            
            Integer numberOfCoreCampaignMembers = 0;
            Integer numberOfNonCoreCampaignMembers = 0;
            
            List<CampaignMember> cmRecsForReview = [SELECT Id, Country__c, CampaignId, Campaign.Name, Campaign_Member_Updated_Date__c FROM CampaignMember];
            for(CampaignMember cmRec : cmRecsForReview){
                if(cmRec.CampaignId == mqlCampaignIdMap.get('Core').Campaign_Id__c){
                    numberOfCoreCampaignMembers++;
                } else if (cmRec.CampaignId == mqlCampaignIdMap.get('Non-Core').Campaign_Id__c) {
                    numberOfNonCoreCampaignMembers++;
                }
                
                /*if(coreCountries.contains(cmRec.Country__c)){
                    System.assertEquals(mqlCampaignIdMap.get('Core').Campaign_Id__c, cmRec.CampaignId);
                    numberOfCoreCampaignMembers++;
                } else {
                    System.assertEquals(mqlCampaignIdMap.get('Non-Core').Campaign_Id__c, cmRec.CampaignId);
                    numberOfNonCoreCampaignMembers++;
                }*/
            }
            
            System.assertEquals(numberOfPeopleInCoreCountryList, numberOfCoreCampaignMembers);
            System.assertEquals(numberOfPeopleNotInCoreCountryList, numberOfNonCoreCampaignMembers);
            List<FSR__c> mqlsForReview = [SELECT Id FROM FSR__c];
            System.assert(mqlsForReview.size() > 0);
            System.debug('MQLS --->> ' + mqlsForReview);
        	System.debug('***Number of Core Campaign Members: ' + numberOfCoreCampaignMembers);
            System.debug('***Number of Non-Core Campaign Members: ' + numberOfNonCoreCampaignMembers);
        }
    }
    
    private static testMethod void ensure_CampaignMembers_Are_Not_Routed_to_Core_and_NonCore_Campaign_Because_User_Not_In_Custom_Setting(){
        Set<String> coreCountries = Campaign_Member_Core_Country__c.getAll().keySet();
        List<MQL_Campaign_Id_Mapping__c> mqlCampaignList = new List<MQL_Campaign_Id_Mapping__c>();
        
        List<Campaign> campaignsForReview = [SELECT Id, Name FROM Campaign];
        for(Campaign campaignRec : campaignsForReview){
            campaignIdMap.put(campaignRec.Name, campaignRec.Id);
            MQL_Campaign_Id_Mapping__c mqlCampaignRec = new MQL_Campaign_Id_Mapping__c(Name = campaignRec.Name,
                                                                                       Campaign_Id__c = campaignRec.Id);
            mqlCampaignList.add(mqlCampaignRec);
        }
        insert mqlCampaignList;
        
        //Campaign testCampaign = new Campaign(Name = 'Fake');
      	//insert testCampaign;
        
        Profile p = [Select Id from Profile where name = 'System Administrator'];
        
        User u = new User();
        u.ProfileId = p.Id;
        u.Username = System.now().getTime() + 'test@test.com';
        u.Alias = 'testtest';
        u.Email='test@test-lead-autoconvert-12345.com';
        u.EmailEncodingKey='UTF-8';
        u.Firstname='Test';
        u.Lastname='Test';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.TimeZoneSidKey='America/Chicago';
        insert u;
		
        //Insert 20 Leads with Random Country
        List<String> availableCountries = new List<String>{'Mexico','Denmark', 'Brazil', 'Canada'};
        Integer listSize = availableCountries.size();
        List<Lead> leadsForInsert = new List<Lead>();
        
        for(Integer i = 0; i < 20; i++){
            Integer randomNumber = Integer.valueof((Math.random() * listSize));
        	String randomCountry = availableCountries[randomNumber];
            Lead testLead = new Lead(LastName = 'Test', 
                                 Email = 'test@test-lead-autoconvert-12345.com', 
                                 Company = 'Test Function',
                                 Country = randomCountry);
            leadsForInsert.add(testLead);
        }
        
        insert leadsForInsert;
        
        //Records should not be added to the Core and Non-Core Campaigns because the running user is not added to the
        //MQL Creator Whitelist Custom Setting.
        
        //MQL_Creator_Whitelist__c mqlCW = new MQL_Creator_Whitelist__c(Name = 'Test', User_or_Role_ID__c = u.Id);
        //insert mqlCW;

        System.RunAs(u) {
            Map<String, MQL_Campaign_Id_Mapping__c> mqlCampaignIdMap = MQL_Campaign_Id_Mapping__c.getAll();
            List<CampaignMember> cmRecsForInsert = new List<CampaignMember>();
            Integer numberOfPeopleInCoreCountryList = 0;
            Integer numberOfPeopleNotInCoreCountryList = 0;
            
            for(Lead leadRec : leadsForInsert){
                CampaignMember cmTest = new CampaignMember(CampaignId = mqlCampaignIdMap.get('Non-Core').Campaign_Id__c,
                                                       Status = 'Registered',
                                                       LeadId = leadRec.Id);
                cmRecsForInsert.add(cmTest);
                
                if(coreCountries.contains(leadRec.Country)){
                    numberOfPeopleInCoreCountryList++;
                } else {
                    numberOfPeopleNotInCoreCountryList++;
                }
            }
            insert cmRecsForInsert;
            
            System.assert(cmRecsForInsert.size() > 0);
            System.assertEquals(leadsForInsert.size(), cmRecsForInsert.size());
            
            Integer numberOfCoreCampaignMembers = 0;
            Integer numberOfNonCoreCampaignMembers = 0;
            
            List<CampaignMember> cmRecsForReview = [SELECT Id, Country__c, CampaignId, Campaign.Name, Campaign_Member_Updated_Date__c FROM CampaignMember];
            for(CampaignMember cmRec : cmRecsForReview){
                if(cmRec.CampaignId == mqlCampaignIdMap.get('Core').Campaign_Id__c){
                    numberOfCoreCampaignMembers++;
                } else if (cmRec.CampaignId == mqlCampaignIdMap.get('Non-Core').Campaign_Id__c){
                    numberOfNonCoreCampaignMembers++;
                }
                System.assertEquals(mqlCampaignIdMap.get('Non-Core').Campaign_Id__c, cmRec.CampaignId);
                System.assertEquals(null, cmRec.Campaign_Member_Updated_Date__c);
            }
            
            //Ensure no campaign members are moved to the Non-Core and Core Campaigns.
            System.assertEquals(0, numberOfCoreCampaignMembers);
            System.assertEquals(20, numberOfNonCoreCampaignMembers);
        }
    }
    
    
    //Records should not be added to the Core and Non-Core Campaigns because the default campaign is not the Non-Core campaign.
    private static testMethod void ensure_CampaignMembers_Are_Not_Routed_to_Core_and_NonCore_Campaign_Because_Default_Campaign_Wrong(){
        Set<String> coreCountries = Campaign_Member_Core_Country__c.getAll().keySet();
        List<MQL_Campaign_Id_Mapping__c> mqlCampaignList = new List<MQL_Campaign_Id_Mapping__c>();
        
        List<Campaign> campaignsForReview = [SELECT Id, Name FROM Campaign];
        for(Campaign campaignRec : campaignsForReview){
            campaignIdMap.put(campaignRec.Name, campaignRec.Id);
            MQL_Campaign_Id_Mapping__c mqlCampaignRec = new MQL_Campaign_Id_Mapping__c(Name = campaignRec.Name,
                                                                                       Campaign_Id__c = campaignRec.Id);
            mqlCampaignList.add(mqlCampaignRec);
        }
        insert mqlCampaignList;
        
        Campaign testCampaign = new Campaign(Name = 'Fake');
      	insert testCampaign;
        
        Profile p = [Select Id from Profile where name = 'System Administrator'];
        
        User u = new User();
        u.ProfileId = p.Id;
        u.Username = System.now().getTime() + 'test@test.com';
        u.Alias = 'testtest';
        u.Email='test@test-lead-autoconvert-12345.com';
        u.EmailEncodingKey='UTF-8';
        u.Firstname='Test';
        u.Lastname='Test';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.TimeZoneSidKey='America/Chicago';
        insert u;
		
        //Insert 20 Leads with Random Country
        List<String> availableCountries = new List<String>{'Mexico','Denmark', 'Brazil', 'Canada'};
        Integer listSize = availableCountries.size();
        List<Lead> leadsForInsert = new List<Lead>();
        
        for(Integer i = 0; i < 20; i++){
            Integer randomNumber = Integer.valueof((Math.random() * listSize));
        	String randomCountry = availableCountries[randomNumber];
            Lead testLead = new Lead(LastName = 'Test', 
                                 Email = 'test@test-lead-autoconvert-12345.com', 
                                 Company = 'Test Function',
                                 Country = randomCountry);
            leadsForInsert.add(testLead);
        }
        
        insert leadsForInsert;
        
        MQL_Creator_Whitelist__c mqlCW = new MQL_Creator_Whitelist__c(Name = 'Test', User_or_Role_ID__c = u.Id);
        insert mqlCW;

        System.RunAs(u) {
            Map<String, MQL_Campaign_Id_Mapping__c> mqlCampaignIdMap = MQL_Campaign_Id_Mapping__c.getAll();
            List<CampaignMember> cmRecsForInsert = new List<CampaignMember>();
            Integer numberOfPeopleInCoreCountryList = 0;
            Integer numberOfPeopleNotInCoreCountryList = 0;
            
            for(Lead leadRec : leadsForInsert){
                CampaignMember cmTest = new CampaignMember(CampaignId = testCampaign.Id,
                                                       Status = 'Registered',
                                                       LeadId = leadRec.Id);
                cmRecsForInsert.add(cmTest);
                
                if(coreCountries.contains(leadRec.Country)){
                    numberOfPeopleInCoreCountryList++;
                } else {
                    numberOfPeopleNotInCoreCountryList++;
                }
            }
            insert cmRecsForInsert;
            
            System.assert(cmRecsForInsert.size() > 0);
            System.assertEquals(leadsForInsert.size(), cmRecsForInsert.size());
            
            Integer numberOfCoreCampaignMembers = 0;
            Integer numberOfNonCoreCampaignMembers = 0;
            
            List<CampaignMember> cmRecsForReview = [SELECT Id, Country__c, CampaignId, Campaign.Name, Campaign_Member_Updated_Date__c FROM CampaignMember];
            for(CampaignMember cmRec : cmRecsForReview){
                if(cmRec.CampaignId == mqlCampaignIdMap.get('Core').Campaign_Id__c){
                    numberOfCoreCampaignMembers++;
                } else if (cmRec.CampaignId == mqlCampaignIdMap.get('Non-Core').Campaign_Id__c){
                    numberOfNonCoreCampaignMembers++;
                }
                System.assertEquals(testCampaign.Id, cmRec.CampaignId);
                System.assertEquals(null, cmRec.Campaign_Member_Updated_Date__c);
            }
            
            //Ensure no campaign members are moved to the Non-Core and Core Campaigns.
            System.assertEquals(0, numberOfCoreCampaignMembers);
            System.assertEquals(0, numberOfNonCoreCampaignMembers);
        }
    }
}