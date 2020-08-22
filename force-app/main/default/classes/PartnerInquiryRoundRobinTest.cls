/**********************************************************/
// Created by: Bopsy 12/17/2019
// Last Modified: Bopsy 12/26/2019
//
// Description:
// This test class use to test PartnerInquiryRoundRobin. 
/**********************************************************/
@isTest
public class PartnerInquiryRoundRobinTest {
    
    // Description :setup method use to test records to check the PartnerInquiryRoundRobin Class.
    // Functionality : In setup method we are creating the users , Assignment group Records
    // with group members.
    
    @testSetup 
    public static void setup(){
        
        // Assignment_Group_Name__c of Partner Record Type
        Id partnerRecordTypeId = Schema.SObjectType.Assignment_Group_Name__c.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Assignment_Group_Name__c assignmentGrpName1 =  new Assignment_Group_Name__c();
        assignmentGrpName1.RecordTypeId = partnerRecordTypeId;
        assignmentGrpName1.Type__c = 'Leads';
        assignmentGrpName1.Name = 'Test Assignment Group1';
        
        // Assignment_Group_Name__c of Partner Record Type
        //Id masterRecordTypeId = Schema.SObjectType.Assignment_Group_Name__c.getRecordTypeInfosByName().get('Not Partner').getRecordTypeId();
        Assignment_Group_Name__c assignmentGrpName2 =  new Assignment_Group_Name__c();
        assignmentGrpName2.Type__c = 'Leads';
        assignmentGrpName2.Name = 'Test Assignment Group2';
        
        List<Assignment_Group_Name__c> assignmentGrpNameList = new List<Assignment_Group_Name__c>{assignmentGrpName1 , assignmentGrpName2};
        insert assignmentGrpNameList;
        
        System.debug('assignmentGrpNameList-->'+assignmentGrpNameList);
        MQL_TimeZone__c mqlTimeZoneObj1 = new MQL_TimeZone__c();
        mqlTimeZoneObj1.Name = 'Alabama';
        mqlTimeZoneObj1.Country__c = 'United States';
        mqlTimeZoneObj1.State__c = 'Alabama';
        mqlTimeZoneObj1.TimeZone__c = '-5';
        
        MQL_TimeZone__c mqlTimeZoneObj2 = new MQL_TimeZone__c();
        mqlTimeZoneObj2.Name = 'Alaska';
        mqlTimeZoneObj2.Country__c = 'United States';
        mqlTimeZoneObj2.State__c = 'Alaska';
        mqlTimeZoneObj2.TimeZone__c = '-7';
        
        List<MQL_TimeZone__c> mqlTimeZoneList =  new List<MQL_TimeZone__c>{mqlTimeZoneObj1,mqlTimeZoneObj2};
            insert mqlTimeZoneList;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        UserRole userRole = new UserRole ();
        userRole=[select id from UserRole where name=:'SDR'];
        User user1 = new User(Alias = 'standt', Email='standarduser@bopsyplead1.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id,IsActive=true,UserRoleId = userRole.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@bopsyplead1.com');
        User user2 = new User(Alias = 'standt', Email='standarduser@bopsyplead1.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id,IsActive=true,UserRoleId = userRole.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@bopsyplead2.com');
        User user3 = new User(Alias = 'standt', Email='standarduser@bopsyplead3.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id,IsActive=true,UserRoleId = userRole.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@bopsyplead3.com');
        User user4 = new User(Alias = 'standt', Email='standarduser@bopsyplead4.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id,IsActive=true,UserRoleId = userRole.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@bopsyplead4.com');
        User user5 = new User(Alias = 'standt', Email='standarduser@bopsyplead5.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id,IsActive=true,UserRoleId = userRole.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@bopsyplead5.com');
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        List<User> userList = new List<User>{user1, user2,user3,user4,user5};
            System.runAs ( thisUser ) {
                insert userList;
            }
        
        System.runAs ( userList[2] ) {
            
            //  Assignment_Groups__c for Assignment_Group_Name of Partner Record Types.
            Assignment_Groups__c assignmentGroupsObj1 = new Assignment_Groups__c();
            assignmentGroupsObj1.User__c = userList[0].Id;
            assignmentGroupsObj1.Active__c = 'true';
            assignmentGroupsObj1.Group_Name__c = assignmentGrpNameList[0].Id;
            
            Assignment_Groups__c assignmentGroupsObj2 = new Assignment_Groups__c();
            assignmentGroupsObj2.User__c = userList[1].Id;
            assignmentGroupsObj2.Active__c = 'true';
            assignmentGroupsObj2.Group_Name__c = assignmentGrpNameList[0].Id;
            
            //  Assignment_Groups__c for Assignment_Group_Name of Not Partner Record Types.
            Assignment_Groups__c assignmentGroupsObj3 = new Assignment_Groups__c();
            assignmentGroupsObj3.User__c = userList[3].Id;
            assignmentGroupsObj3.Active__c = 'true';
            assignmentGroupsObj3.Group_Name__c = assignmentGrpNameList[1].Id;
            
            Assignment_Groups__c assignmentGroupsObj4 = new Assignment_Groups__c();
            assignmentGroupsObj4.User__c = userList[4].Id;
            assignmentGroupsObj4.Active__c = 'true';
            assignmentGroupsObj4.Group_Name__c = assignmentGrpNameList[1].Id;
            
            List<Assignment_Groups__c> assignmentGrpList = new List<Assignment_Groups__c>{assignmentGroupsObj1 , assignmentGroupsObj2,assignmentGroupsObj3 , assignmentGroupsObj4};
                insert assignmentGrpList; 
        } 
    }
    
    // Description :This method testing the beforeInsert method of PartnerInquiryRoundRobin.
    // Functionality : This method inserting four leads and 1 inquiry per lead and
    // checking the Inquiry owner
    @isTest  
    public static void testPartnerInquiryRoundRobinUpdate(){
        List<User> userList = new List<User>();
        Set<String> userNameList = new Set<String>{'standarduser@bopsyplead1.com','standarduser@bopsyplead2.com','standarduser@bopsyplead4.com','standarduser@bopsyplead5.com'};
            userList =  [select id,Name,UserName from user where Username IN : userNameList] ; 
        //PartnerInquiryRoundRobin.bypassTrigger = false;
        
        
        List<Assignment_Group_Name__c> assignmentGrpNameList = new List<Assignment_Group_Name__c>();
        assignmentGrpNameList = [select id from Assignment_Group_Name__c ];
        Group_Mapping__c mapping1 = buildMapping(null,userList[1].Id, PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[0].Id, 1);
        Group_Mapping__c mapping2 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, 'Test Type', 'United Kingdom', PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[0].Id, 2);
        Group_Mapping__c mapping3 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, null, PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[0].Id, 3);
        Group_Mapping__c mapping4 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, 'Test Type', PartnerInquiryRoundRobin.WILD_CARD, '-7', assignmentGrpNameList[0].Id, 4);
        
        Group_Mapping__c mapping5 = buildMapping(null,userList[1].Id, PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[1].Id, 1);
        Group_Mapping__c mapping6 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, 'Test Type', 'United Kingdom', PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[1].Id, 2);
        Group_Mapping__c mapping7 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, null, PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[1].Id, 3);
        Group_Mapping__c mapping8 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, 'Test Type', PartnerInquiryRoundRobin.WILD_CARD, '-7', assignmentGrpNameList[1].Id, 4);
        
        List<Group_Mapping__c> grpMappingList = new List<Group_Mapping__c>{mapping1, mapping2, mapping3, mapping4,mapping5, mapping6, mapping7, mapping8};
            insert   grpMappingList;
        
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Internal Lead').getRecordTypeId();//Internal Lead
        Lead leadObj1 = new Lead();
        leadObj1.RecordTypeId = leadRecordTypeId;
        leadObj1.Status = 'New';
        leadObj1.LastName = 'test LastName1';
        leadObj1.Company = 'test LastName1';
        leadObj1.LeadSource = '';
        Lead leadObj2 = new Lead();
        leadObj2.RecordTypeId = leadRecordTypeId;
        leadObj2.Status = 'New';
        leadObj2.LastName = 'test LastName2';
        leadObj2.Company = 'test LastName2';
        leadObj2.LeadSource = '';
        Lead leadObj3 = new Lead();
        leadObj3.RecordTypeId = leadRecordTypeId;
        leadObj3.Status = 'New';
        leadObj3.LastName = 'test LastName3';
        leadObj3.Company = 'test LastName3';
        leadObj3.LeadSource = '';
        Lead leadObj4 = new Lead();
        leadObj4.RecordTypeId = leadRecordTypeId;
        leadObj4.Status = 'New';
        leadObj4.LastName = 'test LastName4';
        leadObj4.Company = 'test LastName4';
        leadObj4.LeadSource = '';
        
        Id partnerLeadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId();
        // Partner Lead record type leads
        Lead leadObj5 = new Lead();
        leadObj5.RecordTypeId = partnerLeadRecordTypeId;
        leadObj5.Status = 'New';
        leadObj5.LastName = 'test LastName5';
        leadObj5.Company = 'test LastName5';
        leadObj5.Country = 'United States';
        //leadObj1.LeadSource = '';
        
        Lead leadObj6 = new Lead();
        leadObj6.RecordTypeId = partnerLeadRecordTypeId;
        leadObj6.Status = 'New';
        leadObj6.LastName = 'test LastName6';
        leadObj6.Company = 'test LastName6';
        leadObj6.Country = 'United States';
        //leadObj6.LeadSource = '';
        
        Lead leadObj7 = new Lead();
        leadObj7.RecordTypeId = partnerLeadRecordTypeId;
        leadObj7.Status = 'New';
        leadObj7.LastName = 'test LastName7';
        leadObj7.Company = 'test LastName7';
        leadObj7.Country = 'United States';
        //leadObj7.LeadSource = '';
        
        Lead leadObj8 = new Lead();
        leadObj8.RecordTypeId = partnerLeadRecordTypeId;
        leadObj8.Status = 'New';
        leadObj8.LastName = 'test LastName8';
        leadObj8.Company = 'test LastName8';
        leadObj8.Country = 'United States';
        
        List<Lead> leadList = new List<Lead>{leadObj1,leadObj2,leadObj3,leadObj4,leadObj5,leadObj6,leadObj7,leadObj8};
            insert leadList;
        
        Account testAccount = new Account(Name = 'Test Acc', OwnerId = userList[0].Id);
        insert testAccount;
        Contact testContact = new Contact(LastName = 'TestContact', AccountId = testAccount.Id);
        insert testContact;
        
        Account testAccount1 = new Account(Name = 'Test Acc1', OwnerId = userList[3].Id , BillingCountry='United Kingdom');
        insert testAccount1;
        Contact testContact1 = new Contact(LastName = 'TestContact1', AccountId = testAccount.Id, MailingCountry ='United Kingdom');
        insert testContact1;
        
        Campaign testCampaign = new Campaign(Name = 'Test Campaign', Type = 'Test Type');
        insert testCampaign;
        
        Id consultingRecordTypeId = Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('Consulting').getRecordTypeId();
        Id pQLRecordTypeId = Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('PQL').getRecordTypeId();
        // Inquiry for Technology Partner Type Leads
        FSR__c FSRObj1 = new FSR__c();
        FSRObj1.Name = 'Test FSR1';
        FSRObj1.Lead__c = leadList[0].Id;
        FSRObj1.Requires_MQL_Assignment__c = true;
        FSRObj1.Contact__c = testContact.Id;
        FSRObj1.Campaign__c = testCampaign.Id;
        FSRObj1.TimeZone__c = '-7';
        FSRObj1.recordTypeID = consultingRecordTypeId;
        
        FSR__c FSRObj2 = new FSR__c();
        FSRObj2.Name = 'Test FSR2';
        FSRObj2.Lead__c = leadList[1].Id;
        FSRObj2.Requires_MQL_Assignment__c = true;
        FSRObj2.Campaign__c = testCampaign.Id;
        FSRObj2.recordTypeID = consultingRecordTypeId;
        
        FSR__c FSRObj3 = new FSR__c();
        FSRObj3.Name = 'Test FSR3';
        FSRObj3.Lead__c = leadList[2].Id;
        FSRObj3.Requires_MQL_Assignment__c = true;
        FSRObj3.recordTypeID = consultingRecordTypeId;
        
        FSR__c FSRObj4 = new FSR__c();
        FSRObj4.Name = 'Test FSR4';
        FSRObj4.Lead__c = leadList[3].Id;
        FSRObj4.Requires_MQL_Assignment__c = true;
        FSRObj4.recordTypeID = consultingRecordTypeId;
        
          // Inquiry for Partner Lead type Leads
          FSR__c FSRObj5 = new FSR__c();
        FSRObj5.Name = 'Test FSR5';
        FSRObj5.Lead__c = leadList[4].Id;
        FSRObj5.Requires_MQL_Assignment__c = true;
        FSRObj5.Contact__c = testContact1.ID;
        FSRObj5.recordTypeID = pQLRecordTypeId;
        
        FSR__c FSRObj6 = new FSR__c();
        FSRObj6.Name = 'Test FSR6';
        FSRObj6.Lead__c = leadList[5].Id;
        FSRObj6.Requires_MQL_Assignment__c = true;
        FSRObj6.recordTypeID = pQLRecordTypeId;
        
        FSR__c FSRObj7 = new FSR__c();
        FSRObj7.Name = 'Test FSR7';
        FSRObj7.Lead__c = leadList[6].Id;
        FSRObj7.Requires_MQL_Assignment__c = true;
        FSRObj7.recordTypeID = pQLRecordTypeId;
        
        FSR__c FSRObj8 = new FSR__c();
        FSRObj8.Name = 'Test FSR8';
        FSRObj8.Lead__c = leadList[7].Id;
        FSRObj8.Requires_MQL_Assignment__c = true;
        FSRObj8.recordTypeID = pQLRecordTypeId;
        
        List<FSR__c> inquiryList = new List<FSR__c>{FSRObj1,FSRObj2,FSRObj3,FSRObj4,FSRObj5,FSRObj6,FSRObj7,FSRObj8};
        insert inquiryList;
        System.debug('inquiryList--->'+inquiryList);
        
        test.startTest();
            List<FSR__c> inquiryList1 = new List<FSR__c>();
            for(integer i=0 ; i<inquiryList.size() ; i++){
                FSR__c f = inquiryList[i];
                f.Requires_MQL_Assignment__c = true;
                inquiryList1.add(f);
                
            }
            update inquiryList1;
        Test.stopTest();
        
        inquiryList1 = [select id,recordTypeId, OwnerId , Assign_MQL_Owner__c from FSR__c where Id IN : inquiryList1];
		Map<Id,List<Fsr__c>> userToInquiryMap = new Map<Id,List<Fsr__c>>();
        for(FSR__C inq : inquiryList1){
            if(!userToInquiryMap.containsKey(inq.OwnerId)){
                userToInquiryMap.put(inq.OwnerId, new List<FSR__C>());
            }
            userToInquiryMap.get(inq.OwnerId).add(inq);
            //userToInquiryMap.put(inq.OwnerId, new List<FSR__C>);
        }
        
        System.assertEquals(2, userToInquiryMap.get(userList[0].Id).size());
        System.assertEquals(2, userToInquiryMap.get(userList[1].Id).size());
        System.assertEquals(2, userToInquiryMap.get(userList[2].Id).size());
        System.assertEquals(2, userToInquiryMap.get(userList[3].Id).size());
         
    }
    
    // Description :This method testing the beforeUpdate method of PartnerInquiryRoundRobin.
    // Functionality : This method inserting four leads and 1 inquiry per lead and
    // checking the Inquiry owner
    public static testMethod void testPartnerInquiryRoundRobinInsert(){
        
        List<User> userList = new List<User>();
        Set<String> userNameList = new Set<String>{'standarduser@bopsyplead1.com','standarduser@bopsyplead2.com',
            					'standarduser@bopsyplead4.com','standarduser@bopsyplead5.com'};
        userList =  [select id,Name,UserName from user where Username IN : userNameList] ; 
        System.debug('userList--->'+userList);
        //PartnerInquiryRoundRobin.bypassTrigger = false;
        
        
		List<Assignment_Group_Name__c> assignmentGrpNameList = new List<Assignment_Group_Name__c>();
        assignmentGrpNameList = [select id,recordType.Name from Assignment_Group_Name__c ];
        System.debug('assignmentGrpNameList-->'+assignmentGrpNameList);
        // GroupMapping for Assignment_Group_Name of Partner Type  
        Group_Mapping__c mapping1 = buildMapping(null,userList[1].Id, PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[0].Id, 1);
        Group_Mapping__c mapping2 = buildMapping('Alaska',PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, 'United States', PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[0].Id, 2);
        Group_Mapping__c mapping3 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, null, PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[0].Id, 3);
        Group_Mapping__c mapping4 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, 'Test Type', PartnerInquiryRoundRobin.WILD_CARD, '-7', assignmentGrpNameList[0].Id, 4);
        Group_Mapping__c mapping5 = buildMapping('Alaska',PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, 'United Kingdom', PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[0].Id, 2);
        Group_Mapping__c mapping6 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, 'United States', PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[0].Id, 2);
        
        // GroupMapping for Assignment_Group_Name of non Partner Type  
        Group_Mapping__c mapping7 = buildMapping(null,userList[2].Id, PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[1].Id, 1);
        Group_Mapping__c mapping8 = buildMapping('Alaska',PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, 'United States', PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[1].Id, 2);
        Group_Mapping__c mapping9 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, null, PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[1].Id, 3);
        Group_Mapping__c mapping10 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, 'Test Type', PartnerInquiryRoundRobin.WILD_CARD, '-7', assignmentGrpNameList[1].Id, 4);
        Group_Mapping__c mapping11 = buildMapping('Alaska',PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, 'United Kingdom', PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[1].Id, 2);
        Group_Mapping__c mapping12 = buildMapping(null,PartnerInquiryRoundRobin.WILD_CARD, PartnerInquiryRoundRobin.WILD_CARD, 'United States', PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[1].Id, 2);
        
        Group_Mapping__c mapping14 = buildMapping('Alaska',userList[3].Id, PartnerInquiryRoundRobin.WILD_CARD, 'United States', PartnerInquiryRoundRobin.WILD_CARD, assignmentGrpNameList[1].Id, 2);

        List<Group_Mapping__c> grpMappingList = new List<Group_Mapping__c>{mapping1,mapping2,mapping3,mapping4,mapping5,mapping6,mapping7,mapping8,mapping9,mapping10,
            mapping11,mapping12};  
                insert grpMappingList;
        
        //Leads with Technology Partner Record Type 
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Internal Lead').getRecordTypeId();
        Lead leadObj1 = new Lead();
        leadObj1.RecordTypeId = leadRecordTypeId;
        leadObj1.Status = 'New';
        leadObj1.LastName = 'test LastName1';
        leadObj1.Company = 'test LastName1';
        leadObj1.Country = 'United States';
        leadObj1.LeadSource = '';
        
        Lead leadObj2 = new Lead();
        leadObj2.RecordTypeId = leadRecordTypeId;
        leadObj2.Status = 'New';
        leadObj2.LastName = 'test LastName2';
        leadObj2.Company = 'test LastName2';
        leadObj2.Country = 'United States';
        leadObj2.LeadSource = '';
        
        Lead leadObj3 = new Lead();
        leadObj3.RecordTypeId = leadRecordTypeId;
        leadObj3.Status = 'New';
        leadObj3.LastName = 'test LastName3';
        leadObj3.Company = 'test LastName3';
        leadObj3.Country = 'United States';
        leadObj3.LeadSource = '';
        
        Lead leadObj4 = new Lead();
        leadObj4.RecordTypeId = leadRecordTypeId;
        leadObj4.Status = 'New';
        leadObj4.LastName = 'test LastName4';
        leadObj4.Company = 'test LastName4';
        leadObj4.Country = 'United States';
        leadObj4.LeadSource = '';
        
         //Leads with Technology Partner Record Type
        Id partnerLeadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId();
        Lead leadObj5 = new Lead();
        leadObj5.RecordTypeId = partnerLeadRecordTypeId;
        leadObj5.Status = 'New';
        leadObj5.LastName = 'test LastName5';
        leadObj5.Company = 'test LastName5';
        leadObj5.Country = 'United States';
        //leadObj1.LeadSource = '';
        
        Lead leadObj6 = new Lead();
        leadObj6.RecordTypeId = partnerLeadRecordTypeId;
        leadObj6.Status = 'New';
        leadObj6.LastName = 'test LastName6';
        leadObj6.Company = 'test LastName6';
        leadObj6.Country = 'United States';
        //leadObj6.LeadSource = '';
        
        Lead leadObj7 = new Lead();
        leadObj7.RecordTypeId = partnerLeadRecordTypeId;
        leadObj7.Status = 'New';
        leadObj7.LastName = 'test LastName7';
        leadObj7.Company = 'test LastName7';
        leadObj7.Country = 'United States';
        //leadObj7.LeadSource = '';
        
        Lead leadObj8 = new Lead();
        leadObj8.RecordTypeId = partnerLeadRecordTypeId;
        leadObj8.Status = 'New';
        leadObj8.LastName = 'test LastName8';
        leadObj8.Company = 'test LastName8';
        leadObj8.Country = 'United States';
        //leadObj8.LeadSource = '';
        
        List<Lead> leadList = new List<Lead>{leadObj1,leadObj2,leadObj3,leadObj4,leadObj5,leadObj6,leadObj7,leadObj8};
            insert leadList;
        
        Account testAccount = new Account(Name = 'Test Acc', OwnerId = userList[0].Id , BillingCountry='United Kingdom');
        insert testAccount;
        Contact testContact = new Contact(LastName = 'TestContact', AccountId = testAccount.Id, MailingCountry ='United Kingdom');
        insert testContact;
        
        Account testAccount1 = new Account(Name = 'Test Acc', OwnerId = userList[3].Id , BillingCountry='United Kingdom');
        insert testAccount1;
        Contact testContact1 = new Contact(LastName = 'TestContact', AccountId = testAccount.Id, MailingCountry ='United Kingdom');
        insert testContact1;
        
        // RecordTypeMap
        Map<String,Id> FSRRTMap = new  Map<String,Id>{
            'Consulting' => Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('Consulting').getRecordTypeId(),
            'Technology' => Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('Technology').getRecordTypeId(),
            'PQL' => Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('PQL').getRecordTypeId()
        };
        
        
        // Inquiry for PQL
        FSR__c FSRObj1 = new FSR__c();
        FSRObj1.Name = 'Test FSR1';
        FSRObj1.Lead__c = leadList[0].Id;
        FSRObj1.Requires_MQL_Assignment__c = true;
        FSRObj1.Contact__c = testContact.ID;
        FSRObj1.RecordTypeId = FSRRTMap.get('PQL');
        
        FSR__c FSRObj2 = new FSR__c();
        FSRObj2.Name = 'Test FSR2';
        FSRObj2.Lead__c = leadList[1].Id;
        FSRObj2.Requires_MQL_Assignment__c = true;
        FSRObj2.RecordTypeId = FSRRTMap.get('PQL');
        
        FSR__c FSRObj3 = new FSR__c();
        FSRObj3.Name = 'Test FSR3';
        FSRObj3.Lead__c = leadList[2].Id;
        FSRObj3.Requires_MQL_Assignment__c = true;
        FSRObj3.RecordTypeId = FSRRTMap.get('PQL');
        
        FSR__c FSRObj4 = new FSR__c();
        FSRObj4.Name = 'Test FSR4';
        FSRObj4.Lead__c = leadList[3].Id;
        FSRObj4.Requires_MQL_Assignment__c = true;
        FSRObj4.RecordTypeId = FSRRTMap.get('PQL');
        
        // Inquiry for Partner Lead type Leads
        FSR__c FSRObj5 = new FSR__c();
        FSRObj5.Name = 'Test FSR5';
        FSRObj5.Lead__c = leadList[4].Id;
        FSRObj5.Requires_MQL_Assignment__c = true;
        FSRObj5.Contact__c = testContact1.ID;
        FSRObj5.RecordTypeId = FSRRTMap.get('Consulting');
        
        FSR__c FSRObj6 = new FSR__c();
        FSRObj6.Name = 'Test FSR6';
        FSRObj6.Lead__c = leadList[5].Id;
        FSRObj6.Requires_MQL_Assignment__c = true;
        FSRObj6.RecordTypeId = FSRRTMap.get('Consulting');
        
        FSR__c FSRObj7 = new FSR__c();
        FSRObj7.Name = 'Test FSR7';
        FSRObj7.Lead__c = leadList[6].Id;
        FSRObj7.Requires_MQL_Assignment__c = true;
        FSRObj7.RecordTypeId = FSRRTMap.get('Technology');
        
        FSR__c FSRObj8 = new FSR__c();
        FSRObj8.Name = 'Test FSR8';
        FSRObj8.Lead__c = leadList[7].Id;
        FSRObj8.Requires_MQL_Assignment__c = true;
        FSRObj8.RecordTypeId = FSRRTMap.get('Technology');
        
        Test.startTest();
        	List<FSR__c> inquiryList = new List<FSR__c>{FSRObj1,FSRObj2,FSRObj3,FSRObj4,FSRObj5,FSRObj6,FSRObj7,FSRObj8};
        	insert inquiryList;
        Test.stopTest();
        
        inquiryList = [select id,recordTypeId, OwnerId , Assign_MQL_Owner__c from FSR__c where Id IN : inquiryList];
		Map<Id,List<Fsr__c>> userToInquiryMap = new Map<Id,List<Fsr__c>>();
        for(FSR__C inq : inquiryList){
            if(!userToInquiryMap.containsKey(inq.OwnerId)){
                userToInquiryMap.put(inq.OwnerId, new List<FSR__C>());
            }
            userToInquiryMap.get(inq.OwnerId).add(inq);
            
        }
        
        System.assertEquals(4, userList.size());
        System.assertEquals(4, userToInquiryMap.keySet().size());
        
        
        System.assertEquals(2, userToInquiryMap.get(userList[0].Id).size());
        System.assertEquals(2, userToInquiryMap.get(userList[1].Id).size());
        System.assertEquals(2, userToInquiryMap.get(userList[2].Id).size());
        System.assertEquals(2, userToInquiryMap.get(userList[3].Id).size());

    }  
    
    
    static Group_Mapping__c buildMapping(String state , String owner, String campaignType, String country, String timeZoneOffset, Id groupId, Decimal priority){
        return new Group_Mapping__c( State__c = state ,Account_Owner__c = owner, Channel__c = campaignType, Country__c = country, TimeZone__c = timeZoneOffset, Group_Name__c = groupId, Priority__c = priority);
    }
    
    
}