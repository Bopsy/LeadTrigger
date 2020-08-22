public class AgreementHandlerForAfterTrigger {
    
    public static void afterInsertOrUpdateTrigger(List<Apttus__APTS_Agreement__c> theNewAgrementList, Map<Id, Apttus__APTS_Agreement__c> theOldAgrmntMap) {
        
        Map<String,Id> theEmailTemplateMap = new Map<String,Id>();
        Map<String,Id> theUserMap = new Map<String,Id>();
        Map<String,Id> theToEmailIdsMap = new Map<String,Id>();
        Map<String,List<String>> theUsersIdsInGroup = new Map<String,List<String>>();
        Set<Id> theGroupIds = new Set<Id>();
        List<String> theEmailAddressesList = new List <String>();
        List<SendEmailDataWrapper> theWrapperList = new List<SendEmailDataWrapper>();
        
        List<Group> theGroupList = [SELECT Id, Name FROM Group WHERE Type='Regular' And Name =: 'Legal'];
        List<EmailTemplate> theEmailTemplateList = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName =: 'Notifying_Sales_Rep_that_a_Twilio_Legal_Contact_has_been_assigned_to_the_Agreeme' OR DeveloperName =: 'Termination_Notification' OR DeveloperName =: 'Twilio_Legal_of_Customer_s_NDA_Redlines' OR DeveloperName =: 'Agreement_Fully_Signed' OR DeveloperName=: 'Pending_DocuSign_Count' OR DeveloperName=: 'Twilio_Legal_of_Partner_Agr_Ready_For_Execution_No_Redlines_from_Customer' OR DeveloperName=: 'Notify_Twilio_Legal_of_Carrier_Redlines' OR DeveloperName=: 'Twilio_Legal_of_Carrier_Contract_Ready_For_Execution_No_Redlines_from_Customer' OR DeveloperName=: 'Notify_Twilio_Legal_of_Carrier_Redlines' OR DeveloperName=: 'Sales_of_Twilio_Legal_s_Redlines' OR DeveloperName=: 'Twilio_Legal_of_Customer_s_MSA_Redlines' OR DeveloperName=: 'Twilio_Legal_of_MSA_Ready_For_Execution_No_Redlines_from_Customer' OR DeveloperName=: 'Twilio_Legal_of_NDA_Ready_For_Execution_No_Redlines_from_Customer' OR DeveloperName=: 'Email_Twilio_Legal_Ready_for_Signatures_Amendment' OR DeveloperName=: 'Email_Twilio_Legal_Customers_Redlines_Amendment' OR DeveloperName=: 'Email_Twilio_Sales_Legal_Redlines_Misc_Agmt' OR DeveloperName=: 'Email_Twilio_Legal_Ready_for_Signatures_BAA' OR DeveloperName=: 'Min_Commit_Approval_Request' OR DeveloperName=: 'Min_Commit_Escalate_Request' OR DeveloperName=: 'Agreement_Owner_of_Agreement_Ready_for_Execution' OR DeveloperName=: 'Sales_of_Twilio_Legal_s_Redlines' OR DeveloperName=: 'Order_Form_to_Billing_Review' OR DeveloperName=: 'Order_Form_to_Deal_Desk_Review' OR DeveloperName=: 'Twilio_Legal_of_Customer_s_MSA_Redlines' OR DeveloperName=: 'Order_Form_Pricing_Approved_Not_Implemented_Notification' OR DeveloperName=: 'Order_Form_to_Legal_DocuSign' OR DeveloperName=: 'Notify_Alliances_Director_of_Agreement' OR DeveloperName=: 'Notify_Twilio_Legal_of_Partner_Agreement_Redlines' OR DeveloperName=: 'Super_Network_of_Twilio_Legal_s_Redlines' OR DeveloperName=:'Superseding_Warning' OR DeveloperName =: 'Supplemental_Warning'];
        List<User> theUserList = [SELECT Id, Email, Name FROM User WHERE Name =: 'Henry Patterson' OR Name =: 'Sheryl Li' OR Name =: 'Natasha Byrne' OR Name =: 'Yolanda Schwartz' OR Name =: 'Kevin Louie' OR Name =: 'Lenny Sutsakhan' OR Name =: 'Max Teitelbaum' OR Name =: 'Steve Mooney' OR Name =: 'Dree Lee']; 
        List<OrgWideEmailAddress> theToEmailList = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'donotreply@twilio.com'];
        
        Id theNonDisAgreRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Non Disclosure Agreement').getRecordTypeId();
        Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
        Id theCarrierContractRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Carrier Contract').getRecordTypeId();
        Id theMasterSalesRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Sales Agreement').getRecordTypeId();
        Id thePartnerMSARecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner MSA').getRecordTypeId();
        Id theAmendentRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Amendment').getRecordTypeId();
        Id theBuisAssociateRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Business Associate Agreement').getRecordTypeId();
        Id theOrderFormRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Order Form').getRecordTypeId();
        
        for(User theUser : theUserList) {
            if(!theUserMap.containskey(theUser.Name)) theUserMap.put(theUser.Name,theUser.Id);
        }
        
        for(Group theGroup : theGroupList) {
            theGroupIds.add(theGroup.Id);
        }
        
        List<GroupMember> theGroupMembersList = [SELECT Id, Group.Type, Group.Name, UserOrGroupId FROM GroupMember WHERE Group.id IN: theGroupIds];
        
        for(GroupMember theGroupMember : theGroupMembersList)
        {
            if(!theUsersIdsInGroup.containsKey(theGroupMember.Group.Name)){
                theUsersIdsInGroup.put(theGroupMember.Group.Name, new List<String>{theGroupMember.Id});
            } else{
                List<String> currentEntry = theUsersIdsInGroup.get(theGroupMember.Group.Name);
                currentEntry.add(theGroupMember.Id);
                theUsersIdsInGroup.put(theGroupMember.Group.Name, currentEntry);
            }
        }
        
        for(OrgWideEmailAddress theOrgWide : theToEmailList) {
            if(!theToEmailIdsMap.containskey(theOrgWide.Address)) theToEmailIdsMap.put(theOrgWide.Address,theOrgWide.Id);
        }
        
        for(EmailTemplate theEmail : theEmailTemplateList) {
            if(!theEmailTemplateMap.containskey(theEmail.DeveloperName)) theEmailTemplateMap.put(theEmail.DeveloperName,theEmail.Id);
        }
        
        
        for(Apttus__APTS_Agreement__c theAgremnt : theNewAgrementList) {
            
            //#PB 8 Supplemental and Superseding Warnings
            //Creteria : Agreement is Superseding
            //Creteria : Agreement is Supplemental
            //For After trigger
            if(((theOldAgrmntMap == null && theAgremnt.Agreement_History__c != null) || (theOldAgrmntMap != null && theOldAgrmntMap.get(theAgremnt.Id).Agreement_History__c != theAgremnt.Agreement_History__c)) && theAgremnt.Agreement_History__c == 'Supersedes Existing') { 
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theAgremnt.OwnerId);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Superseding_Warning'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
                
            }
            else if(((theOldAgrmntMap == null && theAgremnt.Agreement_History__c != null) || (theOldAgrmntMap != null && theOldAgrmntMap.get(theAgremnt.Id).Agreement_History__c != theAgremnt.Agreement_History__c)) && theAgremnt.Agreement_History__c == 'Supplements Existing') {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theAgremnt.OwnerId);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Supplemental_Warning'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
                
            }
        }
        
        if(!theWrapperList.isEmpty()) {
            OpportunityHandlerForAsync.OppAsyncWorkflows(theWrapperList);
        } 
        
    }
    
    
    //PB field Update
    public static void processBuilderIntoCodeForAfterEvent(List<Apttus__APTS_Agreement__c> theNewAgrementList, Map<Id, Apttus__APTS_Agreement__c> theOldAgrmntMap) { 
        
        List<Account> theAcntListForUpdate = new List<Account>(); 
        Boolean addToUpdate = false;
        Account theAgrementAccount = new Account();
        
        for(Apttus__APTS_Agreement__c theAgremnt : theNewAgrementList) {
            
            //#PB 4 Agreement Update to Account (Account Legal Name)
            //Creteria : Account Legal Name is Changed 
            //For After Trigger
            if(((theOldAgrmntMap == null && String.isNotEmpty(theAgremnt.Account_Legal_Name_Update__c)) || (theOldAgrmntMap != null && theOldAgrmntMap.get(theAgremnt.Id).Account_Legal_Name_Update__c != theAgremnt.Account_Legal_Name_Update__c))) {
                theAgrementAccount.Id = theAgremnt.Apttus__Account__c;
                theAgrementAccount.Account_Legal_Name__c = theAgremnt.Account_Legal_Name_Update__c;
                addToUpdate = true;
            }
            
            //#PB 5 Agreement Update to Account (Reference Co
            //Creteria : If Reference Consent Status is Changed
            // For After trigger
            if(theAgremnt.Apttus__Status__c == 'Activated'){
                theAgrementAccount.Id = theAgremnt.Apttus__Account__c;
                theAgrementAccount.Name_and_Logo__c = theAgremnt.Reference_Name_and_Logo__c;
                theAgrementAccount.Story__c = theAgremnt.Reference_Story__c;
                theAgrementAccount.Use_Case__c = theAgremnt.Reference_Use_Case__c;
                addToUpdate = true;
            }
            
            //#PB 6 Agreement Update to Account (State/Country of Incorporation)
            //Creteria : State/Country of Incorporation is Changed
            // For After trigger  
            if(((theOldAgrmntMap == null && String.isNotEmpty(theAgremnt.State_Country_of_Incorporation_Update__c)) || (theOldAgrmntMap != null && theOldAgrmntMap.get(theAgremnt.Id).State_Country_of_Incorporation_Update__c != theAgremnt.State_Country_of_Incorporation_Update__c))){
                theAgrementAccount.Id = theAgremnt.Apttus__Account__c;
                theAgrementAccount.State_or_Country_of_Incorporation__c = theAgremnt.State_Country_of_Incorporation_Update__c;
                addToUpdate = true;
            }
            
            //#PB 7 Agreement Update to Account (Type of Business Entity)
            //Creteria : Type of Business Entity is Changed
            //For After trigger 
            if(((theOldAgrmntMap == null && String.isNotEmpty(theAgremnt.Type_of_Business_Entity_Update__c)) || (theOldAgrmntMap != null && theOldAgrmntMap.get(theAgremnt.Id).Type_of_Business_Entity_Update__c != theAgremnt.Type_of_Business_Entity_Update__c))) {
                theAgrementAccount.Id = theAgremnt.Apttus__Account__c;
                theAgrementAccount.Type_of_Business_Entity__c = theAgremnt.Type_of_Business_Entity_Update__c;
                addToUpdate = true;
            }
        }
        if(addToUpdate) theAcntListForUpdate.add(theAgrementAccount);
        if(!theAcntListForUpdate.IsEmpty()) {
            theAcntListForUpdate.sort();
            update theAcntListForUpdate;
        } 
        
    }
    
    //PB field Update
    public static void updateParentAgreementFromChild(List<Apttus__APTS_Agreement__c> theNewAgrementList, Map<Id, Apttus__APTS_Agreement__c> theOldAgrmntMap) {
        
        List<Apttus__APTS_Agreement__c> theAgrmntListForUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c theAgremnt : theNewAgrementList) {
            //#PB 1 : Agreement Status Update_new
            //Creteria : Supercede Agreement
            if(theAgremnt.Agreement_History__c == 'Supersedes Existing' && theAgremnt.Apttus__Status_Category__c == 'In Effect' && theAgremnt.Apttus__Status__c == 'Activated' && theAgremnt.Apttus__Parent_Agreement__c != null) {
                Apttus__APTS_Agreement__c theParentAgreement = new Apttus__APTS_Agreement__c();
                theParentAgreement.Id = theAgremnt.Apttus__Parent_Agreement__c;
                theParentAgreement.Apttus__Status_Category__c = 'Expired';
                theParentAgreement.Apttus__Status__c = 'Superseded';
                theParentAgreement.Superseded_by__c = theAgremnt.Id;
                theAgrmntListForUpdate.add(theParentAgreement);
            }
        }
        Map<String,Apttus__APTS_Agreement__c> theAgrmntMapForUpdate = new Map<String,Apttus__APTS_Agreement__c>();
        theAgrmntMapForUpdate.putAll(theAgrmntListForUpdate);
        if(!theAgrmntMapForUpdate.isEmpty()) update theAgrmntMapForUpdate.Values();
    }
}