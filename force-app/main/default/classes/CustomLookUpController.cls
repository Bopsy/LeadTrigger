/**********************************************************/
//Created by: Gram Bischof 12/12/2019
//Last Modified: Gram Bischof 04/16/2020
//
//Description: 
//This handles logic of custom lookup 
//and to convert lead , create inquiry
/**********************************************************/
public without sharing class CustomLookUpController {
    
    // Return the matching record with matching name
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName,boolean IsTrue) {
        String searchKey = searchKeyWord + '%';
        List < sObject > returnList = new List < sObject > ();
         String sQuery;
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
       /* if(ObjectName == 'User'){
            sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
        }else if(ObjectName == 'Account'){
            if(IsTrue == false){
                sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
            }
            else if(IsTrue == True){
                String recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
                sQuery =  'select id, Name from Account' + ' where Name LIKE:searchKey and RecordType.ID=: recordtypeId order by createdDate DESC limit 5';
            }
        }else {
            sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';            
        }*/
        
        if(ObjectName == 'Account' && IsTrue == false){
            String recordtypePartnerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            String recordtypeFYId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('FY 16 Account Record Type').getRecordTypeId();
            
            sQuery =  'select id, Name from Account' + ' where Name LIKE:searchKey and (RecordType.ID=: recordtypePartnerId or RecordType.ID=: recordtypeFYId) order by createdDate DESC limit 5';
        }
        else {
            sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';  
            
        }
        
        List < sObject > lstOfRecords = Database.query(sQuery);        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    @AuraEnabled
    public static doInitWrap getAccountFromContact(Id InquiryId){
        
        doInitWrap wrapperObject=new doInitWrap();
        
       // List<RecordType> recordTypeList=new List<RecordType>([select id,Name from RecordType where sObjectType='Account']);
        Map<String,String> RecordTypeNameVSIdMap=new Map<String,String>();
        List<FSR__c> Inquiry=new List<FSR__c>([select id,Name,Lead__r.Company from FSR__c where Id=:InquiryId limit 1]);
        
        /*for(RecordType recordtype:recordTypeList)
        {
            if(recordtype.Name=='FY 16 Account Record Type' || recordtype.Name=='Partner')
            {
                RecordTypeNameVSIdMap.put(recordtype.Name,recordtype.Id);
            }
        }*/
        String recodtypeFY16ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('FY 16 Account Record Type').getRecordTypeId();
        if(recodtypeFY16ID != null)RecordTypeNameVSIdMap.put('FY 16 Account Record Type', recodtypeFY16ID);
        String recodtypePartnerID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        if(recodtypePartnerID != null)RecordTypeNameVSIdMap.put('Partner', recodtypePartnerID);
        
        List<Contact> contactList = new List<Contact>([Select id,AccountId,Account.Name From Contact Where Id IN (Select Contact__c From FSR__c Where Id = :InquiryId)]);
        if(contactList.size()==0) 
        {
            wrapperObject.newAccount=new Account();
            wrapperObject.RecordTypeNameVSIdMap=RecordTypeNameVSIdMap;
            wrapperObject.CompanyAccountName=Inquiry[0].Lead__r.Company;
            return wrapperObject;
        }
        wrapperObject.newAccount= new Account(Id=contactList[0].AccountId,Name=contactList[0].Account.Name);
        wrapperObject.RecordTypeNameVSIdMap=RecordTypeNameVSIdMap;
        wrapperObject.CompanyAccountName=Inquiry[0].Lead__r.Company;
        return wrapperObject;
    }
    
     @AuraEnabled
    public static Account createNewAccount(Account newAccount){
        
        if(newAccount!=null)
        {
            insert newAccount;
            return newAccount;
        }
        else
        {
            return null;
        }
    }
      
    @AuraEnabled
    public static RespClsWrp inquiryConvert(String inquiryId , String accountId ,String userId , String solutionSalesUser,boolean checkboxValue,string influencingPartner){
       RespClsWrp RespClsObj = new RespClsWrp();
       UseCaseConvertController.inConversion = true;
       try{
           
           	// fetch custom setting [Partner_Inquiry_Mapping__c ]record      
            List<Partner_Inquiry_Mapping__c> partnerInquiryMappingList = new List<Partner_Inquiry_Mapping__c>();
            partnerInquiryMappingList = [select id,Destination_Object__c,Destination_Object_Field__c,Inquiry_Field__c from Partner_Inquiry_Mapping__c];
            String fieldsToQueryFromInquiry = '';
            
            for(Partner_Inquiry_Mapping__c inqMapObj : partnerInquiryMappingList){
                if(! fieldsToQueryFromInquiry.containsIgnoreCase(inqMapObj.Inquiry_Field__c))
                    fieldsToQueryFromInquiry = inqMapObj.Inquiry_Field__c+','+fieldsToQueryFromInquiry;
            }
            
           	FSR__c inquiryObj;
           
           	if( fieldsToQueryFromInquiry!='' ){
                //String inquiryId = String.valueOf(inquiryObj.Id);
                fieldsToQueryFromInquiry = 'Select Id,Lead__c,Lead__r.email,Contact__c,Contact__r.Email,Contact__r.Account.Name,RecordTypeId,recordtype.name,Lead__r.RecordTypeId,Lead__r.RecordType.Name,Contact__r.RecordTypeId,Contact__r.RecordType.Name,'+fieldsToQueryFromInquiry.removeEnd(',')+' from FSR__c where Id=:inquiryId';
                inquiryObj = Database.query(fieldsToQueryFromInquiry);
            }
           
                //Get Lead Id from Inquiry
                //FSR__c inquiryObj = [select Id,Lead__c,Lead__r.email,Contact__c,Contact__r.Email,Contact__r.Account.Name,RecordTypeId,recordtype.name from FSR__c where Id=:inquiryId];
                
                // return error if there is no inquiry record
                if(inquiryObj==null){
                    RespClsObj.isError = true;
                    RespClsObj.errMsg = 'Cannot find Inquiry record from ID: '+inquiryId;
                    return RespClsObj;
                }
                
                
                // return error if there is no lead or contact on inquiry
                if(inquiryObj.Lead__c == null && inquiryObj.Contact__c == null){
                    RespClsObj.isError = true;
                    RespClsObj.errMsg = 'No Lead or Contact is associated with this Inquiry';
                    return RespClsObj;    
                }
                
                Map<String,Id> sobjectIds = new Map<String,Id>();
                if(inquiryObj.Contact__c != null) sobjectIds = contactConvert(inquiryObj, accountId, userId, solutionSalesUser, checkboxValue, influencingPartner, partnerInquiryMappingList);
                else sobjectIds = leadConvert(inquiryObj, accountId, userId, solutionSalesUser, checkboxValue, influencingPartner, partnerInquiryMappingList);
                
                if(sobjectIds.containsKey('Opportunity__c')) inquiryObj.Opportunity__c = sobjectIds.get('Opportunity__c');
                if(sobjectIds.containsKey('Contact__c')) inquiryObj.Contact__c = sobjectIds.get('Contact__c');
                inquiryObj.MQL_Status__c = '4 - Converted';
                update inquiryObj;
                
                RespClsObj.successMsg = 'Lead Converted Successfully';
                RespClsObj.isError = false;
                return RespClsObj;
                
                
     	}catch(exception e){
                System.debug('get exception on line number-->'+e.getLineNumber() +' error ->'+e.getStackTraceString()+' msg-->'+e.getMessage());
                throw new AuraHandledException(e.getMessage());
      	}
    }
    
    private static Map<String,Id> contactConvert(FSR__c inquiryObj , String accountId ,String userId , String solutionSalesUser,boolean checkboxValue,string influencingPartner, List<Partner_Inquiry_Mapping__c> partnerInquiryMappingList){
        Contact inquiryContact = new Contact(Id=inquiryObj.Contact__c);
        Account inquiryAccount = new Account(Id=Id.ValueOf(accountId));
        Opportunity newOpp = new Opportunity(Name=inquiryObj.Contact__r.Account.Name + ' - ',StageName='Partner - Qualify',CloseDate=Date.today().addMonths(2),AccountId=Id.valueOf(accountId));
        
        /*
        // fetch custom setting [Partner_Inquiry_Mapping__c ]record      
        List<Partner_Inquiry_Mapping__c> partnerInquiryMappingcList = new List<Partner_Inquiry_Mapping__c>();
        partnerInquiryMappingcList = [select id,Destination_Object__c,Destination_Object_Field__c,Inquiry_Field__c from Partner_Inquiry_Mapping__c limit 1000];
        String fieldsToQueryFromInquiry = '';
            
        for(Partner_Inquiry_Mapping__c inqMapObj : partnerInquiryMappingcList){
        	if(! fieldsToQueryFromInquiry.containsIgnoreCase(inqMapObj.Inquiry_Field__c)) fieldsToQueryFromInquiry = inqMapObj.Inquiry_Field__c+','+fieldsToQueryFromInquiry;
        }
        
        // create query to fetch the required fields from Inquiry ,Account , contact and opportunity
        List<FSR__c> inquiryList = new List<FSR__c>();
        if( fieldsToQueryFromInquiry!='' ){
            String inquiryId = String.valueOf(inquiryObj.Id);
            fieldsToQueryFromInquiry = 'Select '+fieldsToQueryFromInquiry.removeEnd(',')+' from FSR__c where Id=:inquiryId';
            System.debug(inquiryList+'----fieldsToQueryFromInquiry-->'+fieldsToQueryFromInquiry);
            inquiryList = Database.query(fieldsToQueryFromInquiry);
        }
       	*/ 
        
        // fill values from Inquiry Record to Account , contact , opportunity
       	for( Partner_Inquiry_Mapping__c inqMapObj : partnerInquiryMappingList ){
                if( inqMapObj.Destination_Object__c == 'Account' ){
                    inquiryAccount.put(inqMapObj.Destination_Object_Field__c,inquiryObj.get(inqMapObj.Inquiry_Field__c));
                }else if( inqMapObj.Destination_Object__c == 'Contact' ){
                    inquiryContact.put(inqMapObj.Destination_Object_Field__c,inquiryObj.get(inqMapObj.Inquiry_Field__c));
                }else if( inqMapObj.Destination_Object__c == 'Opportunity' ){
                    newOpp.put(inqMapObj.Destination_Object_Field__c,inquiryObj.get(inqMapObj.Inquiry_Field__c));
                } 
       	}
        List<sObject> sObjList =  new List<sObject>();
            
        //Get default record type from the opportunity
        //find all Opportunity record types
        List<Schema.RecordTypeInfo> infos = Schema.SObjectType.Opportunity.RecordTypeInfos;
        Id defaultRecordTypeId;            
        
        //check each one
        for (Schema.RecordTypeInfo info : infos) {
                if (info.DefaultRecordTypeMapping) {
                    defaultRecordTypeId = info.RecordTypeId;
                }
       	}      
        system.debug(defaultRecordTypeId);
            
            //change opportunity owner
            
        PartnerConvertToOpp__c skipvalidation = PartnerConvertToOpp__c.getInstance(UserInfo.getProfileId());
        skipvalidation.Running__c = true;
        if(skipvalidation.id != null) update skipvalidation;
        else insert skipvalidation;
            
        if( userId!=null && userId!=''){
                newOpp.put('OwnerId',userId);
        }
        if( solutionSalesUser!=null && solutionSalesUser!=''){
                newOpp.put('Solution_Sales_Specialist__c',solutionSalesUser);
        }
        if(influencingPartner !=null && influencingPartner !=''){
            	newOpp.put('Partner_Influencer__c',influencingPartner);
        }
            
        if(!checkboxValue){
                
                if(inquiryObj.recordtype.name == 'Technology'){
                    newOpp.put('RecordTypeId',Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Technology Partner').getRecordTypeId());
                }
                else if (inquiryObj.recordtype.name == 'Consulting'){                    
                    newOpp.put('RecordTypeId',Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Consulting Partner').getRecordTypeId());
                }
        }
        else{
        	newOpp.put('AccountId',accountId);
            newOpp.put('RecordTypeId',defaultRecordTypeId);
       	}
        
        newOpp.put('SQLStatus__c','SQL submitted');
       	sObjList.add(inquiryAccount);
        sObjList.add(inquiryContact);
        update sObjList;
        System.debug('sObjList-->'+sObjList);
        System.debug(newOpp);
        insert newOpp;
        System.debug(newOpp);
        insert new OpportunityContactRole(ContactId=inquiryContact.id,OpportunityId=newOpp.id,Role='Decision Maker');
            
        skipvalidation.Running__c = false;
        update skipvalidation; 
        
    	//return ids to update inquiry
        return new Map<String,Id>{'Account__c'=>inquiryAccount.Id,'Contact__c'=>inquiryContact.id,'Opportunity__c'=>newOpp.id};
    }
    
    // convert the lead and updating the values of 
    // Account , contact and opportunity by using the mapping fields from 
    // custom setting Partner_Inquiry_Mapping__c
    // custom setting holds the destination object , destination field, and inquery field
    
    private static Map<String,Id> leadConvert(FSR__c inquiryObj , String accountId ,String userId , String solutionSalesUser,boolean checkboxValue,string influencingPartner, List<Partner_Inquiry_Mapping__c> partnerInquiryMappingList){ 
        
            System.debug('*********leadConvert**********'+solutionSalesUser);
            String leadId='';
            String contactId='';
            String opportunityId='';
            
            // if email is blank or doesn't match with an 
            // existing contact[related to the selected Account]
            // then create new contact
            if(inquiryObj.Lead__r.email != null){
                List<Contact> conList = [select Id from contact where email=:inquiryObj.Lead__r.email AND AccountID=:accountId];
                if(!conList.isEmpty() ){
                    contactId =  conList[0].Id; 
                }
            }
            
        	/*
            // fetch custom setting [Partner_Inquiry_Mapping__c ]record      
            List<Partner_Inquiry_Mapping__c> partnerInquiryMappingcList = new List<Partner_Inquiry_Mapping__c>();
            partnerInquiryMappingcList = [select id,Destination_Object__c,Destination_Object_Field__c,Inquiry_Field__c from Partner_Inquiry_Mapping__c];
            String fieldsToQueryFromInquiry = '';
            
            for(Partner_Inquiry_Mapping__c inqMapObj : partnerInquiryMappingcList){
                if(! fieldsToQueryFromInquiry.containsIgnoreCase(inqMapObj.Inquiry_Field__c))
                    fieldsToQueryFromInquiry = inqMapObj.Inquiry_Field__c+','+fieldsToQueryFromInquiry;
            }
            
            System.debug('fieldsToQueryFromInquiry--->'+fieldsToQueryFromInquiry);
           	*/
            // TODO:
            // Add custom label for Status needed on conversion
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
            
            Database.LeadConvert tempLC = new Database.LeadConvert();
            tempLC.setLeadId(inquiryObj.Lead__c);
            if(!checkboxValue) tempLC.setAccountId(accountId);
            else if(checkboxValue && !String.isEmpty(influencingPartner)) tempLC.setAccountId(Id.valueOf(influencingPartner));
            
            if( contactId !='' ){
                tempLC.setContactId(contactId);  
            }
            tempLC.setConvertedStatus(convertStatus.MasterLabel);
            //leadsToConvertList.add(tempLC);
            //list<Database.LeadConvert>  leadsToConvertList = ;
            
            List<Database.LeadConvertResult> leadConvertResultList = Database.convertLead(new list<Database.LeadConvert>{tempLC}); 
            if(!leadConvertResultList.isEmpty()){
                contactId = leadConvertResultList[0].getContactId();
                opportunityId = leadConvertResultList[0].getOpportunityId();
            }
            
            Account account  = new Account(Id=accountId);
            Opportunity opportunity  = new Opportunity(Id=opportunityId);
            Contact contact  = new Contact(Id=contactId);
            // query on inquery obj to get the required fields
            //List<FSR__c> inquiryList =  new List<FSR__c>();
            
            /*
            // create query to fetch the required fields from Inquiry ,Account , contact and opportunity
            if( fieldsToQueryFromInquiry!='' ){
                String inquiryId = String.valueOf(inquiryObj.Id);
                fieldsToQueryFromInquiry = 'Select '+fieldsToQueryFromInquiry.removeEnd(',')+' from FSR__c where Id=:inquiryId';
                System.debug(inquiryList+'----fieldsToQueryFromInquiry-->'+fieldsToQueryFromInquiry);
                inquiryList = Database.query(fieldsToQueryFromInquiry);
                
            }
			*/
        
            // fill values from Inquiry Record to Account , contact , opportunity
            for( Partner_Inquiry_Mapping__c inqMapObj : partnerInquiryMappingList ){
                if( inqMapObj.Destination_Object__c == 'Account' ){
                    account.put(inqMapObj.Destination_Object_Field__c,inquiryObj.get(inqMapObj.Inquiry_Field__c));
                }else if( inqMapObj.Destination_Object__c == 'Contact' ){
                    contact.put(inqMapObj.Destination_Object_Field__c,inquiryObj.get(inqMapObj.Inquiry_Field__c));
                }else if( inqMapObj.Destination_Object__c == 'Opportunity' ){
                    opportunity.put(inqMapObj.Destination_Object_Field__c,inquiryObj.get(inqMapObj.Inquiry_Field__c));
                } 
            }
            List<sObject> sObjList =  new List<sObject>();
            
            //Get default record type from the opportunity
            //find all Opportunity record types
            List<Schema.RecordTypeInfo> infos = Schema.SObjectType.Opportunity.RecordTypeInfos;
            Id defaultRecordTypeId;            
            //check each one
            for (Schema.RecordTypeInfo info : infos) {
                if (info.DefaultRecordTypeMapping) {
                    defaultRecordTypeId = info.RecordTypeId;
                }
            }      
            system.debug(defaultRecordTypeId);
            
            //change opportunity owner
            
            PartnerConvertToOpp__c skipvalidation = PartnerConvertToOpp__c.getInstance(UserInfo.getProfileId());
            skipvalidation.Running__c = true;
            if(skipvalidation.id != null) update skipvalidation;
            else insert skipvalidation;
            
            if( userId!=null && userId!=''){
                opportunity.put('OwnerId',userId);
            }
            if( solutionSalesUser!=null && solutionSalesUser!=''){
                opportunity.put('Solution_Sales_Specialist__c',solutionSalesUser);
            }
            if(influencingPartner !=null && influencingPartner !=''){
            	opportunity.put('Partner_Influencer__c',influencingPartner);
            }
            
            if(!checkboxValue){
                
                if(inquiryObj.recordtype.name == 'Technology'){
                    opportunity.put('RecordTypeId',Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Technology Partner').getRecordTypeId());
                }
                else if (inquiryObj.recordtype.name == 'Consulting'){                    
                    opportunity.put('RecordTypeId',Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Consulting Partner').getRecordTypeId());
                }
            }
            else{
                opportunity.put('AccountId',accountId);
                opportunity.put('RecordTypeId',defaultRecordTypeId);
            }
        	opportunity.put('SQLStatus__c','SQL submitted');
            sObjList.add(account);
            sObjList.add(opportunity);
            sObjList.add(contact);
            update sObjList;
             
            skipvalidation.Running__c = false;
            update skipvalidation;
        
        //return ids to update inquiry
        return new Map<String,Id>{'Account__c'=>sObjList[0].Id,'Contact__c'=>sObjList[2].Id,'Opportunity__c'=>sObjList[1].Id};
    }
    
    public class doInitWrap{
        
        @AuraEnabled
        public Account newAccount;
        @AuraEnabled
        public Map<String,String> RecordTypeNameVSIdMap;
        @AuraEnabled
        public String CompanyAccountName;
    }
    
    public class RespClsWrp{
        @AuraEnabled
        public string errMsg;
        @AuraEnabled
        public boolean isError ;
        @AuraEnabled
        public string successMsg;
        
  }
}