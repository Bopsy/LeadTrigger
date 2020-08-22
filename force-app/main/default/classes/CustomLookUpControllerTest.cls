/**********************************************************/
// Created by: Bopsy 12/16/2019
// Last Modified: Bopsy 12/16/2019
//
// Description:
// This test class use to test CustomLookUpController. 
/**********************************************************/
@isTest
public class CustomLookUpControllerTest {
    //Description:setup method use to insert
    //Accounts to check ContactTriggerHandler
    //class. 
    @testSetup 
    public static void setup(){
        try{
            //geting user license.
            Userlicense  userlicense = new Userlicense();
            userlicense = [select id,name from Userlicense where name=:'Salesforce' limit 1];
            
            //insert user
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
            User user = new User(Alias = 'standt', Email='standarduser@bopsyplead.com', 
                                 EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                 LocaleSidKey='en_US', ProfileId = p.Id,IsActive=true,
                                 TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@bopsyplead.com');
            insert user;
            
            // create any standard sobject to  cover the lookupfunctionality
            Account account = new Account();
            account.Name = 'Bopsy';
            account.of_Developers__c = 'Test Developers';
            account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            insert account;
            
            List<Contact> contactList = new List<Contact>();
            // contact with Account
            Contact contactobj = new Contact();
            contactobj.LastName = 'Test Contact';
            contactobj.Contact_Type__c = 'Billing Contact;Portal Owner';
            contactobj.Title = 'Test Title';
            contactobj.Preferred_Email__c = 'Test@test.com';
            contactobj.AccountId = account.Id;  
            contactList.add(contactobj);
            insert contactList;
            
            
            // create record to cover the lead leadConvert controller
            List<Lead> leadList = new List<Lead>();
            Lead leadObjOne = new Lead();
            leadObjOne.LastName = 'Test Lead';
            leadObjOne.company = 'Test Company';
            leadObjOne.Email = 'Test@test.com';
            leadObjOne.Last_Lead_Source__c = 'Inbound Sales Line';
            leadObjOne.LeadSource = 'Inbound Sales Line';
            //leadObjOne.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Technology Partner').getRecordTypeId();
            leadList.add(leadObjOne);   
            
            Lead leadObjTwo = new Lead();
            leadObjTwo.LastName = 'Test Lead';
            leadObjTwo.company = 'Test Company';
            //leadObjTwo.Last_Lead_Source__c = 'Inbound Sales Line';
            //leadObjTwo.LeadSource = 'Inbound Sales Line';
            leadObjTwo.Email = 'Test@gmail.com';
            //leadObjTwo.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Consulting Partner').getRecordTypeId();
            leadList.add(leadObjTwo);       
            insert leadList;
            
            //insert inquiry list with lead lookup
            List<FSR__c> inquiryList = new List<FSR__c>();
            FSR__c inquiryObjOne = new FSR__c();
            inquiryObjOne.Name = 'Test inquiry';
            inquiryObjOne.Company_Description__c = 'Test Company Description ';
            inquiryObjOne.Role_in_Decision_Making__c = 'Test Role in Decision Making';
            inquiryObjOne.Next_Follow_Up_Date__c = Date.today();
            inquiryObjOne.Hook__c = 'Test Hook';
            inquiryObjOne.RecordTypeId = Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('Technology').getRecordTypeId();
            inquiryObjOne.Target_Customer_Size__c = '4';
            inquiryObjOne.Contact_Center_Expertise__c = 'Test Contact Center Expertise';
            inquiryObjOne.Cloud_Based_Partner_Programs__c = 'Test Cloud Based Partner Programs';
            inquiryObjOne.of_Developers__c = 'Test Developers';
            inquiryObjOne.Programming_Language_Proficiency__c = 'Test Programming Language Proficiency';
            inquiryObjOne.How_many_clients_do_you_have__c = 'Test How many clients do you have';
            inquiryObjOne.Twilio_Assistance_Support__c = 'Test Twilio Assistance Support';
            inquiryObjOne.Lead__c = leadList[0].Id;
            inquiryList.add(inquiryObjOne);
            
            FSR__c inquiryObjTwo = new FSR__c();
            inquiryObjTwo.Name = 'Test inquiry2';
            inquiryObjTwo.Company_Description__c = 'Test Company Description ';
            inquiryObjTwo.Role_in_Decision_Making__c = 'Test Role in Decision Making';
            inquiryObjTwo.Next_Follow_Up_Date__c = Date.today(); 
            inquiryObjTwo.Hook__c = 'Test Hook';
            inquiryObjOne.RecordTypeId = Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('Consulting').getRecordTypeId();
            inquiryObjTwo.Target_Customer_Size__c = '4';
            inquiryObjTwo.Contact_Center_Expertise__c = 'Test Contact Center Expertise';
            inquiryObjTwo.Cloud_Based_Partner_Programs__c = 'Test Cloud Based Partner Programs';
            inquiryObjTwo.of_Developers__c = 'Test Developers';
            inquiryObjTwo.Programming_Language_Proficiency__c = 'Test Programming Language Proficiency';
            inquiryObjTwo.How_many_clients_do_you_have__c = 'Test How many clients do you have';
            inquiryObjTwo.Twilio_Assistance_Support__c = 'Test Twilio Assistance Support';
            inquiryObjTwo.Lead__c = leadList[1].Id;
            inquiryList.add(inquiryObjTwo);  
            
            FSR__c inquiryObjThree = new FSR__c();
            inquiryObjThree.Name = 'Test inquiry3';
            inquiryObjThree.Company_Description__c = 'Test Company Description ';
            inquiryObjThree.Role_in_Decision_Making__c = 'Test Role in Decision Making';
            inquiryObjThree.Next_Follow_Up_Date__c = Date.today();
            inquiryObjThree.Hook__c = 'Test Hook';
            inquiryObjThree.Target_Customer_Size__c = '4';
            inquiryObjThree.Contact_Center_Expertise__c = 'Test Contact Center Expertise';
            inquiryObjThree.Cloud_Based_Partner_Programs__c = 'Test Cloud Based Partner Programs';
            inquiryObjThree.of_Developers__c = 'Test Developers';
            inquiryObjThree.Programming_Language_Proficiency__c = 'Test Programming Language Proficiency';
            inquiryObjThree.How_many_clients_do_you_have__c = 'Test How many clients do you have';
            inquiryObjThree.Twilio_Assistance_Support__c = 'Test Twilio Assistance Support';
            inquiryList.add(inquiryObjThree);       
            insert inquiryList;
            
            //create custom setting records
            List<Partner_Inquiry_Mapping__c> partnerInquiryMappingcList = new List<Partner_Inquiry_Mapping__c>();
            Partner_Inquiry_Mapping__c partnerInquiryMappingObj1 = new Partner_Inquiry_Mapping__c();
            partnerInquiryMappingObj1.Name = 'Field1';
            partnerInquiryMappingObj1.Destination_Object__c = 'Opportunity';
            partnerInquiryMappingObj1.Destination_Object_Field__c = 'Hook__c';
            partnerInquiryMappingObj1.Inquiry_Field__c = 'Hook__c';
            partnerInquiryMappingcList.add(partnerInquiryMappingObj1);
            
            Partner_Inquiry_Mapping__c partnerInquiryMappingObj2 = new Partner_Inquiry_Mapping__c();
            partnerInquiryMappingObj2.Name = 'Field2';
            partnerInquiryMappingObj2.Destination_Object__c = 'Contact';
            partnerInquiryMappingObj2.Destination_Object_Field__c = 'Inactive__c';
            partnerInquiryMappingObj2.Inquiry_Field__c = 'High_Priority__c';
            partnerInquiryMappingcList.add(partnerInquiryMappingObj2);
            
            Partner_Inquiry_Mapping__c partnerInquiryMappingObj3 = new Partner_Inquiry_Mapping__c();
            partnerInquiryMappingObj3.Name = 'Field3';
            partnerInquiryMappingObj3.Destination_Object__c = 'Account';
            partnerInquiryMappingObj3.Destination_Object_Field__c = 'of_Developers__c';
            partnerInquiryMappingObj3.Inquiry_Field__c = 'of_Developers__c';
            partnerInquiryMappingcList.add(partnerInquiryMappingObj3);           
            
            insert partnerInquiryMappingcList;
        }
        catch(Exception e){
            system.debug('error'+e.getMessage()+'at line number'+e.getLineNumber());
        }
    }
    
    
    
    //Description : This Method check the fetchLookUpValues  
    //Functionality   
    public static testMethod void fetchLookUpValuesTest(){
        Test.startTest();
        CustomLookUpController.fetchLookUpValues('Bop', 'Account',true);
        Test.stopTest();
        
        // TODO:
        // Add asserts
    }
    
    //Description: This Method use to convert the lead with
    //matching contact
    //Functionality:convert lead into account,contact and opportunity.
    public static testMethod void testPartnerLeadConversionWithMatchingContact(){
        //geting inquiry list.
        List<FSR__c> inquiryList = new List<FSR__c>();
        inquiryList = [select id,RecordType.Name,Name,of_Developers__c,Hook__c,Lead__c from FSR__c order by Name];
        System.debug('inquiryList--testPartnerLeadConversionWithMatchingContact->'+inquiryList[0]);
        
        //getting account.
        Account account = new Account();
        account = [select id,of_Developers__c from account limit 1];
        
        //getting the current user.
        User user = new user();
        user = [select id from user where username='standarduser@bopsyplead.com' limit 1 ];
        
        Test.startTest();
        CustomLookUpController.inquiryConvert( String.valueOf(inquiryList[0].Id), String.valueOf(account.Id) ,String.valueOf(user.Id),String.valueOf(user.Id),false,Account.id);
        Test.stopTest();
        
        //getting the converted lead data
        List<Lead> convertedLead =  new List<Lead>();
        convertedLead = [Select id,ConvertedAccountId,ConvertedContactId,ConvertedopportunityId from Lead where Id=:inquiryList[0].Lead__c and IsConverted=true];
        
        //getting converted contact id
        List<Contact> contactListnew = new List<Contact>();
        contactListnew = [select id from Contact where id =:convertedLead[0].ConvertedContactId];
        
        //getting converted opprtunity id
        List<Opportunity> OpportunityList = new List<Opportunity>();
        OpportunityList = [select id,SQLStatus__c,recordtype.name,Hook__c,ownerId from Opportunity where id =:convertedLead[0].ConvertedopportunityId];
        
        string user_id = user.id;        
        System.assertEquals(String.valueOf(convertedLead[0].ConvertedContactId), String.valueOf(contactListnew[0].Id));
        System.assertEquals(String.valueOf(convertedLead[0].ConvertedAccountId), String.valueOf(account.Id));
        System.assertEquals(String.valueOf(convertedLead[0].ConvertedopportunityId), String.valueOf(OpportunityList[0].Id));
        System.assertEquals(String.valueOf(inquiryList[0].of_Developers__c),String.valueOf(account.of_Developers__c));
        System.assertEquals(String.valueOf(inquiryList[0].Hook__c),String.valueOf(OpportunityList[0].Hook__c));
        System.assertEquals(OpportunityList.size(), 1);
        System.assertEquals(String.valueOf(OpportunityList[0].recordtype.name), 'Consulting Partner');
        System.assertEquals(String.valueOf(OpportunityList[0].ownerId), user_id);
        System.assertEquals(OpportunityList[0].SQLStatus__c,'SQL submitted');
     }
        
    //Description: This Method use to convert the lead with
    //matching contact and cover else conditions.
    //Functionality:convert lead into account,contact and opportunity.
    public static testMethod void testPartnerLeadConversionWithMatchingContactWithTrueVal(){
        //geting inquiry list.
        List<FSR__c> inquiryList = new List<FSR__c>();
        inquiryList = [select id,RecordType.Name,Name,of_Developers__c,Hook__c,Lead__c from FSR__c order by Name];
        System.debug('inquiryList--testPartnerLeadConversionWithMatchingContact->'+inquiryList[0]);
        
        //getting account.
        Account account = new Account();
        account = [select id,of_Developers__c from account limit 1];
        
        //getting the current user.
        User user = new user();
        user = [select id from user where username='standarduser@bopsyplead.com' limit 1 ];
        
        Test.startTest();
        CustomLookUpController.inquiryConvert( String.valueOf(inquiryList[0].Id), String.valueOf(account.Id) ,String.valueOf(user.Id),String.valueOf(user.Id),true,Account.id);
        Test.stopTest();
        
        //getting the converted lead data
        List<Lead> convertedLead =  new List<Lead>();
        convertedLead = [Select id,ConvertedAccountId,ConvertedContactId,ConvertedopportunityId from Lead where Id=:inquiryList[0].Lead__c and IsConverted=true];
        
        //getting converted contact id
        List<Contact> contactListnew = new List<Contact>();
        contactListnew = [select id from Contact where id =:convertedLead[0].ConvertedContactId];
        
        //getting converted opprtunity id
        List<Opportunity> OpportunityList = new List<Opportunity>();
        OpportunityList = [select id,SQLStatus__c,recordtype.name,Hook__c,ownerId from Opportunity where id =:convertedLead[0].ConvertedopportunityId];
        
        string user_id = user.id;        
        System.assertEquals(String.valueOf(convertedLead[0].ConvertedContactId), String.valueOf(contactListnew[0].Id));
        System.assertEquals(String.valueOf(convertedLead[0].ConvertedAccountId), String.valueOf(account.Id));
        System.assertEquals(String.valueOf(convertedLead[0].ConvertedopportunityId), String.valueOf(OpportunityList[0].Id));
        System.assertEquals(String.valueOf(inquiryList[0].of_Developers__c),String.valueOf(account.of_Developers__c));
        System.assertEquals(String.valueOf(inquiryList[0].Hook__c),String.valueOf(OpportunityList[0].Hook__c));
        System.assertEquals(OpportunityList.size(), 1);
        System.assertEquals(String.valueOf(OpportunityList[0].recordtype.name), 'Direct Sales');
        System.assertEquals(String.valueOf(OpportunityList[0].ownerId), user_id);
        System.assertEquals(OpportunityList[0].SQLStatus__c,'SQL submitted');
     }
    
    //Description: This Method use to convert the lead without
    //matching contact
    //Functionality:convert lead into account,contact and opportunity.    
    public static testMethod void testPartnerLeadConversionWithoutMatchingContact(){
        
        //geting inquiry list.
        List<FSR__c> inquiryList = new List<FSR__c>();
        inquiryList = [select id,RecordTypeId,Name,Lead__c,of_Developers__c,Hook__c from FSR__c order by Name];
        System.debug('inquiryList-testPartnerLeadConversionWithoutMatchingContact->'+inquiryList[1]);
        //getting account.
        Account account = new Account();
        account = [select id,of_Developers__c from account limit 1];
        
        //getting the current user.
        User user = new user();
        user = [select id from user  where username='standarduser@bopsyplead.com' limit 1];       
        
        Test.startTest();
        CustomLookUpController.inquiryConvert( String.valueOf(inquiryList[1].Id), String.valueOf(account.Id) , String.valueOf(user.Id),String.valueOf(user.Id),false,'');
        Test.stopTest();
        
        //getting the converted lead data
        List<Lead> convertednewLead =  new List<Lead>();
        convertednewLead = [Select id,ConvertedAccountId,ConvertedContactId,ConvertedopportunityId from Lead where Id=:inquiryList[1].Lead__c and IsConverted=true];
        
        //getting converted contact id
        List<Contact> contactListnew = new List<Contact>();
        contactListnew = [select id,email from Contact where id=:convertednewLead[0].ConvertedContactId];
        
        //getting converted Opportunity id
        List<Opportunity> OpportunityList = new List<Opportunity>();
        OpportunityList = [select id,SQLStatus__c,recordtype.name,Hook__c,ownerId from Opportunity where id =:convertednewLead[0].ConvertedopportunityId];
        
        //getting Lead email which lead we use in current inquiry lookup.
        list <lead> leadlist = new list <lead>();
        leadlist = [select Email from lead where email =:'Test@gmail.com'];
        
        string user_id = user.id;
        System.assertEquals(String.valueOf(contactListnew[0].email), leadlist[0].email);
        System.assertEquals(String.valueOf(OpportunityList[0].ownerId), user_id);
        System.assertEquals(String.valueOf(convertednewLead[0].ConvertedAccountId), String.valueOf(account.Id));
        System.assertEquals(String.valueOf(convertednewLead[0].ConvertedopportunityId), String.valueOf(OpportunityList[0].Id));
        System.assertEquals(String.valueOf(inquiryList[0].of_Developers__c),String.valueOf(account.of_Developers__c));
        System.assertEquals(String.valueOf(OpportunityList[0].recordtype.name), 'Direct Sales');
        System.assertEquals(OpportunityList.size(), 1);
        System.assertEquals(String.valueOf(inquiryList[0].Hook__c),String.valueOf(OpportunityList[0].Hook__c));
    	System.assertEquals(OpportunityList[0].SQLStatus__c,'SQL submitted');
    }
    
    //Description: This Method use to convert the lead without
    //matching contact
    //Functionality:convert lead into account,contact and opportunity.    
    public static testMethod void testPartnerContactConversion(){
        
        //geting contact
        Contact testContact = [Select id,email,AccountId From Contact];
        
        //create inquiry
     	FSR__c inquiryObj = new FSR__c();
       	inquiryObj.Name = 'Test inquiry custom';
        inquiryObj.Company_Description__c = 'Test Company Description ';
        inquiryObj.Role_in_Decision_Making__c = 'Test Role in Decision Making';
        inquiryObj.Next_Follow_Up_Date__c = Date.today();
        inquiryObj.Hook__c = 'Test Hook';
        inquiryObj.RecordTypeId = Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('Technology').getRecordTypeId();
        inquiryObj.Target_Customer_Size__c = '4';
        inquiryObj.Contact_Center_Expertise__c = 'Test Contact Center Expertise';
        inquiryObj.Cloud_Based_Partner_Programs__c = 'Test Cloud Based Partner Programs';
        inquiryObj.of_Developers__c = 'Test Developers';
        inquiryObj.Programming_Language_Proficiency__c = 'Test Programming Language Proficiency';
        inquiryObj.How_many_clients_do_you_have__c = 'Test How many clients do you have';
        inquiryObj.Twilio_Assistance_Support__c = 'Test Twilio Assistance Support';
        inquiryObj.Contact__c = testContact.id;
     	insert inquiryObj;
        
        //getting the current user.
        User user = new user();
        user = [select id from user  where username='standarduser@bopsyplead.com' limit 1];       
        
        Test.startTest();
        	CustomLookUpController.inquiryConvert( String.valueOf(inquiryObj.Id), String.valueOf(testContact.AccountId) , String.valueOf(user.Id),String.valueOf(user.Id),false,'');
        Test.stopTest();
        
        // query new fields from inquiry
        inquiryObj = [Select id,Opportunity__c,Hook__c,ownerId From FSR__c Where Id = :inquiryObj.id];
        
        //getting converted Opportunity id
        Opportunity newOpp = [select id,SQLStatus__c,recordtype.name,Hook__c,ownerId from Opportunity where id =:inquiryObj.Opportunity__c];        
        
        string user_id = user.id;
        System.assert(newOpp != null);
        System.assertEquals(String.valueOf(newOpp.ownerId), user_id);
        System.assertEquals(String.valueOf(newOpp.recordtype.name), 'Technology Partner');
        System.assertEquals(String.valueOf(inquiryObj.Hook__c),String.valueOf(newOpp.Hook__c));
    	//System.assertEquals(newOpp.SQLStatus__c,'SQL submitted');
    }
    
    
    //Description: This Method use to cover the condition if 
    //inquiry is not contain lead lookup.
    public static testMethod void inquiryWithoutLead(){   
        
        //geting inquiry list.
        List<FSR__c> inquiryList = new List<FSR__c>();
        inquiryList = [select id,Name,Lead__c from FSR__c order by Name];
        
        //getting account.
        Account account = new Account();
        account = [select id from account limit 1];
        
        //getting the current user.
        User user = new user();
        user = [select id from user  where username='standarduser@bopsyplead.com' limit 1];
        Test.startTest();       
        CustomLookUpController.inquiryConvert( String.valueOf(inquiryList[2].Id), String.valueOf(account.Id) ,String.valueOf(user.Id),'',true,'');
        Test.stopTest();
        
        //getting the converted lead data
        List<Lead> convertedLead =  new List<Lead>();
        convertedLead = [Select id,ConvertedAccountId,ConvertedContactId,ConvertedopportunityId from Lead where Id=:inquiryList[0].Lead__c and IsConverted=true];
        System.assertEquals(0,convertedLead.size());
    }   
    
    //Description: Unit test to ensure the account is returned
    public static testMethod void unitTestgetAccountFromContact(){
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(AccountId=testAccount.Id,FirstName='Test',LastName='Person',email='test@test.com');
        insert testContact;
        
        FSR__c testInquiry = new FSR__c(Contact__c=testContact.id);
        insert testInquiry;
        
        Account returnedAccount;
        Test.startTest();
       
        CustomLookupController.doInitWrap wrapper=new CustomLookupController.doInitWrap();
         wrapper= CustomLookupController.getAccountFromContact(testInquiry.Id);
              
         returnedAccount=wrapper.newAccount;
        
        Test.stopTest();
        
        System.assert(returnedAccount != null);
        System.assertEquals(returnedAccount.id, testAccount.id);
        System.assertEquals(returnedAccount.Name, testAccount.Name);
    }
    
    //Description: Use to test the createNewAccount method
    //of the controller
    public static testMethod void unitTestcreateNewAccount()
    {
        
        Account account=new Account();
        account.Name='Test Account';
        account.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        
        Account newAccount=CustomLookupController.createNewAccount(account);
        
        System.assert(newAccount!=null);
        System.assertEquals('Test Account', newAccount.Name);

    }
}