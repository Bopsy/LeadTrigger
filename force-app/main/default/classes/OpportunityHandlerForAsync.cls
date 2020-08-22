/******************************************
//Created By: Gram Bischof
//Last Modified by: Gram Bischof {05/22/2020}
//Description:
//Test Class: OpportunityHandlerForAsyncTest
*******************************************/
public class OpportunityHandlerForAsync {

    public static void OppAsyncWorkflowsFromTrigger(List<Opportunity> theOppList, Map<ID, Opportunity> theOldOppMap) {

        Map<String,Id> theEmailTemplateMap = new Map<String,Id>();
        Map<String,Id> theUserMap = new Map<String,Id>();
        Map<String,Id> theToEmailIdsMap = new Map<String,Id>();
        List<String> theEmailAddressesList = new List <String>();
        List<SendEmailDataWrapper> theWrapperList = new List<SendEmailDataWrapper>();
        
        List<EmailTemplate> theEmailTemplateList = [SELECT Id, Name FROM EmailTemplate WHERE Name =: 'COVID Bell' OR Name =: 'Sales Bell Email from Manager Approval' OR Name =: 'Partner Opp Sales Bell' OR Name=: 'COVID-19 Partner Offer Email Alert' OR Name=: 'SQL Notification (Opp)' OR Name =: 'SendGrid Opportunity Closed' OR Name =: 'Sales Bell Email from Manager Approval' OR Name =: 'Sales Bell 100k Commit w/Partner' OR Name =: 'SurveyMonkey Review AE Template' OR Name =: 'SurveyMonkey Review SE Template' OR Name =: 'Notify_Expert Services' OR Name =: 'SQL Status moved to Rescheduling' OR Name =: 'Notify Opp Owner of Exception SID Status Change' OR Name =: 'SC Ops Consultation Notification' OR Name =: 'SE Added to Twilio Sales Engineer'];
        List<User> theUserList = [SELECT Id, Email, Name FROM User WHERE Name =: 'Ralf Schiffert' OR Name =: 'Henry Hai' OR Name =: 'Brittany Blecher' OR Name =: 'Rebecca Lauber' OR Name =: 'Renu Asuti' OR Name =: 'Ashlyn Kohler' OR Name =: 'Davis Dong' OR Name =: 'Dree Lee' OR Name =: 'Philip Sykes' OR Name =: 'Kevin Louie' OR Name =: 'Michelle Paitich' OR Name =: 'Tayler Hickey' OR Name =: 'Dominic Munoz' OR Name =: 'Paty Hanna' OR Name =: 'Sean Newell' OR Name =: 'Jen Sec'];     
        List<OrgWideEmailAddress> theToEmailList = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'donotreply@twilio.com'];
        Id theAcntManaRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Account Management').getRecordTypeId();
        Id theConsPartRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Consulting Partner').getRecordTypeId();
        Id theTechPartRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Technology Partner').getRecordTypeId();
        Id theRenoOppRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renegotiation Opportunity').getRecordTypeId();
        Id theExpanOppRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Expansion Opportunity').getRecordTypeId();
        Id theDirectSalesRecordId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Direct Sales').getRecordTypeId();
        
        for(User theUser : theUserList) {
            if(!theUserMap.containskey(theUser.Name)) theUserMap.put(theUser.Name,theUser.Id);
        }
        
        for(OrgWideEmailAddress theOrgWide : theToEmailList) {
            if(!theToEmailIdsMap.containskey(theOrgWide.Address)) theToEmailIdsMap.put(theOrgWide.Address,theOrgWide.Id);
        }
        
        for(EmailTemplate theEmail : theEmailTemplateList) {
            if(!theEmailTemplateMap.containskey(theEmail.Name)) theEmailTemplateMap.put(theEmail.Name,theEmail.Id);
        }
        
        for(Opportunity theOpp : theOppList) {
            //#1 Opportunity_ExpertServices
            if(((theOldOppMap == null && !String.isEmpty(theOpp.Twilio_Expert_Services_Engaged__c)) || (theOldOppMap != null && theOldOppMap.get(theOpp.Id).Twilio_Expert_Services_Engaged__c != theOpp.Twilio_Expert_Services_Engaged__c)) && ( theOpp.Twilio_Expert_Services_Engaged__c == 'Use Case Acceleration Bundle' || theOpp.Twilio_Expert_Services_Engaged__c == 'Architecture Services Required' || theOpp.Twilio_Expert_Services_Engaged__c == 'Customer SOW Required')) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theUserMap.get('Ralf Schiffert'));
                theEmailAddressesList.add(theUserMap.get('Henry Hai'));
                theEmailAddressesList.add(theOpp.OwnerId);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Notify_Expert Services'), UserInfo.getUserId(), theEmailAddressesList));
            }
            
            //#2 SQL Status moved to Rescheduling
            if(((theOldOppMap == null && !String.isEmpty(theOpp.SQLStatus__c)) || (theOldOppMap != null && theOldOppMap.get(theOpp.Id).SQLStatus__c != theOpp.SQLStatus__c)) && theOpp.SQLStatus__c == 'Rescheduling') {
                theEmailAddressesList = new List<String>();
                if(theOpp.Owner_Mgr_Email__c != null) theEmailAddressesList.add(theOpp.Owner_Mgr_Email__c);
                theEmailAddressesList.add(theOpp.OwnerId);
                if(theOpp.CreatedById != null) theEmailAddressesList.add(theOpp.CreatedById);
				theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('SQL Status moved to Rescheduling'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
            }
            
            //#3 Sales Operations Approval is Approved
            //#4 Sales Operations Approval is Denied
            if(((theOldOppMap == null && !String.isEmpty(theOpp.Sales_Operations_Exception_Approval__c)) || (theOldOppMap != null && theOldOppMap.get(theOpp.Id).Sales_Operations_Exception_Approval__c != theOpp.Sales_Operations_Exception_Approval__c)) && (theOpp.Sales_Operations_Exception_Approval__c == 'Approved' || theOpp.Sales_Operations_Exception_Approval__c == 'Declined')){
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theOpp.OwnerId);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Notify Opp Owner of Exception SID Status Change'), UserInfo.getUserId(), theEmailAddressesList));
            }
            
            //#5 SC Ops Consultation is True
            if(((theOldOppMap == null) || (theOldOppMap != null && theOldOppMap.get(theOpp.Id).SC_Ops_Consultation__c != theOpp.SC_Ops_Consultation__c)) && theOpp.SC_Ops_Consultation__c == true) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theUserMap.get('Brittany Blecher'));
                theEmailAddressesList.add('sc@twilio.com');
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('SC Ops Consultation Notification'), UserInfo.getUserId(), theEmailAddressesList));
                
            }
            
            //#6 Alert Sales Engineer when Added to Opportunity - Primary
            if(((theOldOppMap == null && theOpp.Technical_Lead__c != null) || (theOldOppMap != null && theOldOppMap.get(theOpp.Id).Technical_Lead__c != theOpp.Technical_Lead__c)) && theOpp.Technical_Lead__c != null) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theOpp.Technical_Lead__c);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('SE Added to Twilio Sales Engineer'), UserInfo.getUserId(), theEmailAddressesList));
            }
            
            //#7 Alert Sales Engineer when Added to Opportunity - Secondary
            if(((theOldOppMap == null && theOpp.Twilio_Sales_Engineer_Secondary__c != null) || (theOldOppMap != null && theOldOppMap.get(theOpp.Id).Twilio_Sales_Engineer_Secondary__c != theOpp.Twilio_Sales_Engineer_Secondary__c)) && theOpp.Twilio_Sales_Engineer_Secondary__c != null) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theOpp.Twilio_Sales_Engineer_Secondary__c);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('SE Added to Twilio Sales Engineer'), UserInfo.getUserId(), theEmailAddressesList));
            }
            
            //#8 Alert Sales Engineer when Added to Opportunity - Teriary
            if(((theOldOppMap == null && theOpp.Twilio_Sales_Engineer_Tertiary__c != null) || (theOldOppMap != null && theOldOppMap.get(theOpp.Id).Twilio_Sales_Engineer_Tertiary__c != theOpp.Twilio_Sales_Engineer_Tertiary__c)) && theOpp.Twilio_Sales_Engineer_Tertiary__c != null) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theOpp.Twilio_Sales_Engineer_Tertiary__c);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('SE Added to Twilio Sales Engineer'), UserInfo.getUserId(), theEmailAddressesList));
            }
            
            //#9 Send NPS Surveys to AE and SE
            if(theOpp.StageName =='Closed Won' && theOpp.Technical_Lead__c != null && theOpp.RecordTypeId == theDirectSalesRecordId && theOpp.Owner.UserRole != null && theOpp.Owner.UserRole.Name.Contains('West') && !theOpp.Owner.UserRole.Name.Contains('Commercial') && !theOpp.Owner.UserRole.Name.Contains('Mid-Market')) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theOpp.OwnerId);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('SurveyMonkey Review SE Template'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
                
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theOpp.Technical_Lead__c);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('SurveyMonkey Review AE Template'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
                
            }
            
            //#10 Opportunity Sales Bell w/Partner
            if(theOpp.Sales_Bell_Criteria_Met__c == true && theOpp.Partner_Involved__c != 'N/A' && theOpp.Partner_Involved__c != null && theOpp.Link_to_Partner_Logo__c != 'N/A' && theOpp.Link_to_Partner_Logo__c != null && theOpp.Partner_Involvement__c != 'N/A' && theOpp.Partner_Involvement__c != null && (theOpp.StageName == 'Closed Won' || theOpp.StageName == '6 - Closed Won' || theOpp.StageName == 'Closed - Launched') && theOpp.RecordTypeId != theRenoOppRecordId && 
			((theOldOppMap == null) || (theOldOppMap != null && (theOldOppMap.get(theOpp.Id).StageName != theOpp.StageName || 
			theOldOppMap.get(theOpp.Id).RecordTypeId != theOpp.RecordTypeId || theOldOppMap.get(theOpp.Id).Sales_Bell_Criteria_Met__c != theOpp.Sales_Bell_Criteria_Met__c || 
			theOldOppMap.get(theOpp.Id).Partner_Involved__c != theOpp.Partner_Involved__c || theOldOppMap.get(theOpp.Id).Link_to_Partner_Logo__c != theOpp.Link_to_Partner_Logo__c ||
			theOldOppMap.get(theOpp.Id).Partner_Involvement__c != theOpp.Partner_Involvement__c)))) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theUserMap.get('Rebecca Lauber'));
                theEmailAddressesList.add(theUserMap.get('Renu Asuti'));
                theEmailAddressesList.add(theUserMap.get('Ashlyn Kohler'));
                theEmailAddressesList.add(theUserMap.get('Davis Dong'));
                theEmailAddressesList.add('sales-strategy@twilio.com');
                theEmailAddressesList.add('psykes@twilio.com');
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Sales Bell 100k Commit w/Partner'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
            }
            
            //#11 Opportunity Sales Bell - 100k Commit
            if(theOpp.Account.Global_2000__c == false && theOpp.Partner_Involved__c == 'N/A' && theOpp.Sales_Bell_Criteria_Met__c == TRUE && (theOpp.StageName == 'Closed Won' || theOpp.StageName == '6 - Closed Won' || theOpp.StageName == 'Closed - Launched') && theOpp.RecordTypeId != theRenoOppRecordId && theOpp.RecordTypeId != theDirectSalesRecordId &&
			((theOldOppMap == null) || (theOldOppMap != null && (theOldOppMap.get(theOpp.Id).StageName != theOpp.StageName || 
            theOldOppMap.get(theOpp.Id).Account.Global_2000__c != theOpp.Account.Global_2000__c ||
			theOldOppMap.get(theOpp.Id).RecordTypeId != theOpp.RecordTypeId || theOldOppMap.get(theOpp.Id).Partner_Involved__c != theOpp.Partner_Involved__c)))) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theUserMap.get('Dree Lee'));
                theEmailAddressesList.add(theUserMap.get('Renu Asuti'));
                theEmailAddressesList.add(theUserMap.get('Philip Sykes'));
                theEmailAddressesList.add(theUserMap.get('Kevin Louie'));
                theEmailAddressesList.add('sales-strategy@twilio.com');
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Sales Bell Email from Manager Approval'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
            }
            
            //#12 SendGrid Opps Closed Notification
            if(theOpp.StageName == 'Closed Won' && ((theOpp.Number_of_Twilio_Products__c - theOpp.Number_of_Twilio_Product_Non_Email__c) > 0) ) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theOpp.OwnerId);
                if(theOpp.SendGrid_Specialist__c != null) theEmailAddressesList.add(theOpp.SendGrid_Specialist__c);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('SendGrid Opportunity Closed'), UserInfo.getUserId(), theEmailAddressesList));
            }
            
            //#13 SQL Notification (Opp)
            if(theOpp.Primary_Product__c != null && theOpp.SQLStatus__c != 'SQL Accepted' && theOpp.RecordTypeId !=  theAcntManaRecordId && (theOpp.RecordTypeId ==  theConsPartRecordId || theOpp.RecordTypeId ==  theTechPartRecordId) && 
			((theOldOppMap == null) || (theOldOppMap != null && (theOldOppMap.get(theOpp.Id).Primary_Product__c != theOpp.Primary_Product__c || 
			theOldOppMap.get(theOpp.Id).RecordTypeId != theOpp.RecordTypeId || theOldOppMap.get(theOpp.Id).SQLStatus__c != theOpp.SQLStatus__c )))) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theOpp.OwnerId);
                if(theOpp.CreatedById != null) theEmailAddressesList.add(theOpp.CreatedById);
                if(theOpp.SendGrid_Specialist__c != null) theEmailAddressesList.add(theOpp.SendGrid_Specialist__c);                
                if(theOpp.Solution_Sales_Specialist__c != null) theEmailAddressesList.add(theOpp.Solution_Sales_Specialist__c);
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('SQL Notification (Opp)'), UserInfo.getUserId(), theEmailAddressesList));
            }
            
            //#14 COVID-19 Partner Offer Email Alert
            if(((theOldOppMap == null && !String.isEmpty(theOpp.Covid_19_Response_Reason__c)) || (theOldOppMap != null && theOldOppMap.get(theOpp.Id).Covid_19_Response_Reason__c != theOpp.Covid_19_Response_Reason__c)) && theOpp.Covid_19_Response_Reason__c != null) {
                if(theOpp.Covid_19_Response_Reason__c.containsIgnoreCase('Partner Offer')) {
                    theEmailAddressesList = new List<String>();
                    theEmailAddressesList.add(theUserMap.get('Michelle Paitich'));
                    theEmailAddressesList.add(theUserMap.get('Tayler Hickey'));
                    theEmailAddressesList.add(theUserMap.get('Dominic Munoz'));
                    if(theOpp.Alliances_Rep__c != null) theEmailAddressesList.add(theOpp.Alliances_Rep__c);
                    theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('COVID-19 Partner Offer Email Alert'), UserInfo.getUserId(), theEmailAddressesList));
                }
            }
            
            //#15 Partner Opportunity Sales Bell - 200k Commit
            if(theOpp.StageName == 'Partner - FR' && (theOpp.RecordTypeId == theConsPartRecordId || theOpp.RecordTypeId == theTechPartRecordId) && theOpp.Partner_Description__c != '' && theOpp.Use_Case_Description__c != '' && theOpp.How_we_won__c != '' && theOpp.Showcase_Link__c != '' && theOpp.Twilio_Team_involved__c != '' && theOpp.Link_to_Partner_Logo__c != '' && theOpp.Total_PTCV_Amount__c >= 200000 && theOpp.Partner_Sales_Bell_Check__c && 
			((theOldOppMap == null) || (theOldOppMap != null && (theOldOppMap.get(theOpp.Id).StageName != theOpp.StageName || 
			theOldOppMap.get(theOpp.Id).RecordTypeId != theOpp.RecordTypeId || theOldOppMap.get(theOpp.Id).Partner_Description__c != theOpp.Partner_Description__c || 
			theOldOppMap.get(theOpp.Id).Use_Case_Description__c != theOpp.Use_Case_Description__c || theOldOppMap.get(theOpp.Id).How_we_won__c != theOpp.How_we_won__c ||
			theOldOppMap.get(theOpp.Id).Showcase_Link__c != theOpp.Showcase_Link__c || 
			theOldOppMap.get(theOpp.Id).Twilio_Team_involved__c != theOpp.Twilio_Team_involved__c || 
			theOldOppMap.get(theOpp.Id).Link_to_Partner_Logo__c != theOpp.Link_to_Partner_Logo__c || 
			theOldOppMap.get(theOpp.Id).Partner_Sales_Bell_Check__c != theOpp.Partner_Sales_Bell_Check__c ||
			theOldOppMap.get(theOpp.Id).Total_PTCV_Amount__c != theOpp.Total_PTCV_Amount__c)))) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theUserMap.get('Paty Hanna'));
                theEmailAddressesList.add(theUserMap.get('Sean Newell'));
                theEmailAddressesList.add('sales-strategy@twilio.com');
                theEmailAddressesList.add('psykes@twilio.com');
                theEmailAddressesList.add('ddong@twilio.com');
                theEmailAddressesList.add('akohler@twilio.com');
                theEmailAddressesList.add('drlee@twilio.com');
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Partner Opp Sales Bell'), UserInfo.getUserId(), theEmailAddressesList));
                
            }
            
            //#16 Resend Sales Bell - Global 2000
            if(theOpp.Re_send_Sales_Bell__c && (theOpp.StageName == 'Closed Won' || theOpp.StageName == '6 - Closed Won' || theOpp.StageName == 'Closed - Launched' || theOpp.StageName == 'Closed Won - Omitted') && theOpp.Account.Global_2000__c && 
			((theOldOppMap == null) || (theOldOppMap != null && (theOldOppMap.get(theOpp.Id).StageName != theOpp.StageName || 
			theOldOppMap.get(theOpp.Id).Re_send_Sales_Bell__c != theOpp.Re_send_Sales_Bell__c || 
			theOldOppMap.get(theOpp.Id).Account.Global_2000__c != theOpp.Account.Global_2000__c)))) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theUserMap.get('Dree Lee'));
                theEmailAddressesList.add(theUserMap.get('Philip Sykes'));
                theEmailAddressesList.add(theUserMap.get('Renu Asuti'));
                theEmailAddressesList.add(theUserMap.get('Kevin Louie'));
                theEmailAddressesList.add('sales-strategy@twilio.com');
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Sales Bell Email from Manager Approval'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
                
            } 
            
            //#17 Resend Sales Bell - 100k Commit
            if(theOpp.Re_send_Sales_Bell__c && (theOpp.StageName == 'Closed Won' || theOpp.StageName == '6 - Closed Won' || theOpp.StageName == 'Closed - Launched' || theOpp.StageName == 'Closed Won - Omitted') && theOpp.Account.Global_2000__c == False && 
			(theOldOppMap != null && theOldOppMap.get(theOpp.Id).Re_send_Sales_Bell__c != theOpp.Re_send_Sales_Bell__c) || 
			(theOldOppMap != null && theOldOppMap.get(theOpp.Id).StageName != theOpp.StageName) ||
            (theOldOppMap != null && theOldOppMap.get(theOpp.Id).Account.Global_2000__c != theOpp.Account.Global_2000__c)) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theUserMap.get('Dree Lee'));
                theEmailAddressesList.add(theUserMap.get('Philip Sykes'));
                theEmailAddressesList.add(theUserMap.get('Renu Asuti'));
                theEmailAddressesList.add(theUserMap.get('Kevin Louie'));
                theEmailAddressesList.add('sales-strategy@twilio.com');
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Sales Bell Email from Manager Approval'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
                
            }
            
            //#18 Send Sales Bell after Manager Approval
            if(theOpp.StageName == 'Closed Won' && theOpp.RecordTypeId == theDirectSalesRecordId && theOpp.Opt_Out_of_Sales_Bell_Emails__c == false && theOpp.Sales_Bell_Criteria_Met__c && theOpp.Sales_Rep_Submitted_for_Close_Won__c && theOpp.Close_Win_Manager_Approval_Complete__c && theOpp.Ready_for_Manager_Review__c && theOpp.Time_Sales_Bell_Sent__c == null && 
               (theOpp.Partner_Involvement__c == null || theOpp.Partner_Involvement__c == 'N/A' || theOpp.Partner_Involvement__c == 'NA') && 
				((theOldOppMap == null) || (theOldOppMap != null && (theOldOppMap.get(theOpp.Id).StageName != theOpp.StageName || 
				theOldOppMap.get(theOpp.Id).RecordTypeId != theOpp.RecordTypeId || theOldOppMap.get(theOpp.Id).Opt_Out_of_Sales_Bell_Emails__c != theOpp.Opt_Out_of_Sales_Bell_Emails__c || 
				theOldOppMap.get(theOpp.Id).Sales_Bell_Criteria_Met__c != theOpp.Sales_Bell_Criteria_Met__c || theOldOppMap.get(theOpp.Id).Sales_Rep_Submitted_for_Close_Won__c != theOpp.Sales_Rep_Submitted_for_Close_Won__c ||
				theOldOppMap.get(theOpp.Id).Close_Win_Manager_Approval_Complete__c != theOpp.Close_Win_Manager_Approval_Complete__c || 
				theOldOppMap.get(theOpp.Id).Ready_for_Manager_Review__c != theOpp.Ready_for_Manager_Review__c || 
				theOldOppMap.get(theOpp.Id).Time_Sales_Bell_Sent__c != theOpp.Time_Sales_Bell_Sent__c || 
				theOldOppMap.get(theOpp.Id).Partner_Involvement__c != theOpp.Partner_Involvement__c)))) {
                   theEmailAddressesList = new List<String>();
                   theEmailAddressesList.add(theUserMap.get('Dree Lee'));
                   theEmailAddressesList.add(theUserMap.get('Philip Sykes'));
                   theEmailAddressesList.add(theUserMap.get('Renu Asuti'));
                   theEmailAddressesList.add(theUserMap.get('Jen Sec'));
                   theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Sales Bell Email from Manager Approval'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
                   
               }
            
            //#19 Send COVID Bell
            if(theOpp.StageName == 'Closed Won' && theOpp.RecordTypeId == theDirectSalesRecordId && theOpp.Opt_Out_of_Sales_Bell_Emails__c == false && theOpp.Sales_Bell_Criteria_Met__c && theOpp.Sales_Rep_Submitted_for_Close_Won__c && theOpp.Covid_19_Response__c != null && theOpp.Close_Win_Manager_Approval_Complete__c == false && 
			((theOldOppMap == null) || (theOldOppMap != null && (theOldOppMap.get(theOpp.Id).StageName != theOpp.StageName || 
			theOldOppMap.get(theOpp.Id).RecordTypeId != theOpp.RecordTypeId || theOldOppMap.get(theOpp.Id).Opt_Out_of_Sales_Bell_Emails__c != theOpp.Opt_Out_of_Sales_Bell_Emails__c || 
			theOldOppMap.get(theOpp.Id).Sales_Bell_Criteria_Met__c != theOpp.Sales_Bell_Criteria_Met__c || theOldOppMap.get(theOpp.Id).Sales_Rep_Submitted_for_Close_Won__c != theOpp.Sales_Rep_Submitted_for_Close_Won__c ||
			theOldOppMap.get(theOpp.Id).Close_Win_Manager_Approval_Complete__c != theOpp.Close_Win_Manager_Approval_Complete__c || 
			theOldOppMap.get(theOpp.Id).Covid_19_Response__c != theOpp.Covid_19_Response__c)))) {
                theEmailAddressesList = new List<String>();
                theEmailAddressesList.add(theUserMap.get('Philip Sykes'));
                theEmailAddressesList.add('psykes@twilio.com');
                theEmailAddressesList.add('jsec@twilio.com');
                theEmailAddressesList.add('drlee@twilio.com');
                theEmailAddressesList.add('rasuti@twilio.com');
                theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('COVID Bell'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
                
            }
            
            //#20 Send Sales/Partner Bell after Manager Approval
            if(theOpp.StageName == 'Closed Won' && theOpp.RecordTypeId == theDirectSalesRecordId && theOpp.Opt_Out_of_Sales_Bell_Emails__c == false && theOpp.Sales_Bell_Criteria_Met__c && theOpp.Sales_Rep_Submitted_for_Close_Won__c && theOpp.Close_Win_Manager_Approval_Complete__c && theOpp.Ready_for_Manager_Review__c && theOpp.Time_Sales_Bell_Sent__c == null && 
               (theOpp.Partner_Involvement__c != null || theOpp.Partner_Involvement__c != 'N/A' || theOpp.Partner_Involvement__c != 'NA') && 
              ((theOldOppMap == null) || (theOldOppMap != null && (theOldOppMap.get(theOpp.Id).StageName != theOpp.StageName || 
				theOldOppMap.get(theOpp.Id).RecordTypeId != theOpp.RecordTypeId || theOldOppMap.get(theOpp.Id).Opt_Out_of_Sales_Bell_Emails__c != theOpp.Opt_Out_of_Sales_Bell_Emails__c || 
				theOldOppMap.get(theOpp.Id).Sales_Bell_Criteria_Met__c != theOpp.Sales_Bell_Criteria_Met__c || theOldOppMap.get(theOpp.Id).Sales_Rep_Submitted_for_Close_Won__c != theOpp.Sales_Rep_Submitted_for_Close_Won__c ||
				theOldOppMap.get(theOpp.Id).Close_Win_Manager_Approval_Complete__c != theOpp.Close_Win_Manager_Approval_Complete__c || theOldOppMap.get(theOpp.Id).Ready_for_Manager_Review__c != theOpp.Ready_for_Manager_Review__c ||
				theOldOppMap.get(theOpp.Id).Sales_Rep_Submitted_for_Close_Won__c != theOpp.Sales_Rep_Submitted_for_Close_Won__c)))) {
                   theEmailAddressesList = new List<String>();
                   
                   theEmailAddressesList.add(theUserMap.get('Dree Lee'));
                   theEmailAddressesList.add(theUserMap.get('Philip Sykes'));
                   theEmailAddressesList.add(theUserMap.get('Renu Asuti'));
                   theEmailAddressesList.add(theUserMap.get('Jen Sec'));
                   theWrapperList.add(new SendEmailDataWrapper(theEmailTemplateMap.get('Sales Bell Email from Manager Approval'), theToEmailIdsMap.get('donotreply@twilio.com'), theEmailAddressesList));
                   
               }
        }
        
        if(!theWrapperList.isEmpty()) {
            OpportunityHandlerForAsync.OppAsyncWorkflows(theWrapperList);
        } 
        
    } 
    
    public static void OppAsyncWorkflows(List<SendEmailDataWrapper> theWrapperList) {
        List<Messaging.singleEmailMessage> mailList = new List<Messaging.singleEmailMessage>();
        for(SendEmailDataWrapper theEmailWrap : theWrapperList) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();  
            email.setToAddresses(theEmailWrap.ToAddress);
            email.setTemplateId(theEmailWrap.templateId);
            if(theEmailWrap.FromAddress != userInfo.getUserId()) email.setOrgWideEmailAddressId(theEmailWrap.FromAddress);
            email.setTargetObjectId(userInfo.getUserId());
            email.setSaveAsActivity(false);
            mailList.add(email);
        }
        if(!mailList.isEmpty()) {
            List<Messaging.SendEmailResult> sendEmailResultList = Messaging.sendEmail(mailList);
            system.debug('sendEmailResultList=>'+sendEmailResultList);
        }        
    }
    
}