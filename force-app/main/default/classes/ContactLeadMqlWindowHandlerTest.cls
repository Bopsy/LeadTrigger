/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  ContactLeadMqlWindowHandlerTest
*
* @description 	  Test class that contains test methods for ContactLeadMqlWindowHandler	.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2019-10-07
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class ContactLeadMqlWindowHandlerTest {
    static testMethod void testContact(){
        List<Account> accList = TestDataFactory.createAccountList(2);
        List<Contact> contList = TestDataFactory.createContactList(50);
        
        insert accList;
        
        for(Integer i = 0; i < contList.size(); i++){
            String tempString = 'test'+i+'@test.com';
            contList[i].Email = tempString;
            contList[i].AccountId = accList[0].Id;
            contList[i].Engagement_Score__c = 70+i;
        }
        
        insert contList;
        List<MQL_Window__c> lstMqlWin = [Select Id,Contact__c,MQL_Window_Close_Date__c,MQL_Window_Open_Date__c,MQL_Window_Status__c 
                                             from MQL_Window__c where Contact__c IN: contList and MQL_Window_Status__c='Open' order by lastmodifieddate desc];
        system.assertEquals(20, lstMqlWin.size());
        List<Contact> lstCont = [Select Id,Engagement_Score__c,Is_currently_MQL__c from Contact];
        for(Contact objCont: lstCont){
            if(objCont.Is_currently_MQL__c==false){
                objCont.Engagement_Score__c +=100;
            }
            if(objCont.Is_currently_MQL__c==true){
                objCont.Engagement_Score__c -=100;
            }
        }
        update lstCont;
        List<MQL_Window__c> lstMqlWin1 = [Select Id,Contact__c,MQL_Window_Close_Date__c,MQL_Window_Open_Date__c,MQL_Window_Status__c 
                                             from MQL_Window__c where Contact__c IN: lstCont and MQL_Window_Status__c='Open' order by lastmodifieddate desc];
        system.assertEquals(30, lstMqlWin1.size());
    }
    
    static testMethod void testLead(){
        List<Lead> leadList = TestDataFactory.createLeadList(50);
        
        for(Integer i = 0; i < leadList.size(); i++){
            String tempString = 'test'+i+'@test.com';
            leadList[i].Email = tempString;
            leadList[i].Engagement_Score__c = 70+i;
        }
        
        insert leadList;
        List<MQL_Window__c> lstMqlWin = [Select Id,Lead__c,MQL_Window_Close_Date__c,MQL_Window_Open_Date__c,MQL_Window_Status__c
                                             from MQL_Window__c where Lead__c IN: leadList and MQL_Window_Status__c='Open' order by lastmodifieddate desc];
        system.assertEquals(20, lstMqlWin.size());
        List<Lead> lstLead = [Select Id,Engagement_Score__c,Is_currently_MQL__c from Lead];
        for(Lead objLead: lstLead){
            if(objLead.Is_currently_MQL__c==false){
                objLead.Engagement_Score__c +=100;
            }
            if(objLead.Is_currently_MQL__c==true){
                objLead.Engagement_Score__c -=100;
            }
        }
        update lstLead;
        List<MQL_Window__c> lstMqlWin1 = [Select Id,Lead__c,MQL_Window_Close_Date__c,MQL_Window_Open_Date__c,MQL_Window_Status__c 
                                             from MQL_Window__c where Lead__c IN: lstLead and MQL_Window_Status__c='Open' order by lastmodifieddate desc];
        system.assertEquals(30, lstMqlWin1.size());
    }
    
    private static testMethod void testLeadConvert() {
        
        // create a Lead
        Lead lead=new Lead(LastName='Doe',FirstName='John',Company='Test',Status='Inquiry',Engagement_Score__c=120,Profile_Score__c=20);
        insert lead;             
        MQL_Window__c newMqlWin = new MQL_Window__c(Lead__c=lead.id,MQL_Window_Status__c='Open',
                                                                    Engagement_score_at_Open_Stamp__c=lead.Engagement_Score__c,
                                                                    Profile_Score_at_Open_Stamp__c = lead.Profile_Score__c,
                                                                    MQL_Window_Open_Date__c=DateTime.now());
        insert newMqlWin;
        MQL_Window__c newMqlWin1 = new MQL_Window__c(Lead__c=lead.id,MQL_Window_Status__c='Closed',
                                                                    Engagement_score_at_Open_Stamp__c=lead.Engagement_Score__c,
                                                                    Profile_Score_at_Open_Stamp__c = lead.Profile_Score__c,
                                                                    MQL_Window_Open_Date__c=DateTime.now());
        insert newMqlWin1;
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(lead.id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Opportunity');
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
    }
}