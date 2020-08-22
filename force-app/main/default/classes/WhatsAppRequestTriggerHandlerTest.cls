/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           WhatsAppRequestTriggerHandlerTest
*
* @description    Test class for WhatsAppRequestTriggerHandler
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-08-21
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class WhatsAppRequestTriggerHandlerTest {
    
    static testmethod void WhatsAppRequestTriggerHandlerTest1() {
        Campaign objCam = new Campaign(name='testcampaignWhatsapp');
        insert objCam;

        Campaigns_for_Whatsapp_Request__c  setting = new Campaigns_for_Whatsapp_Request__c ();
        setting.Name = objCam.id;
        insert setting;
        
        Campaign_member_to_Whatsapp_mappings__c  setting1 = new Campaign_member_to_Whatsapp_mappings__c ();
        setting1.Name = 'Campaign';
        setting1.Campaign_member_API__c = 'CampaignId';
        setting1.Whatsapp_Request_API__c = 'Campaign__c';
        insert setting1;
        
        Campaign_member_to_Whatsapp_mappings__c  setting2 = new Campaign_member_to_Whatsapp_mappings__c ();
        setting2.Name = 'Description Line 1';
        setting2.Campaign_member_API__c = 'Description Line 1';
        setting2.Whatsapp_Request_API__c = 'Company_Ownership_Model__c';
        insert setting2;
        
        Campaign_member_to_Whatsapp_mappings__c  setting3 = new Campaign_member_to_Whatsapp_mappings__c ();
        setting3.Name = 'Lead';
        setting3.Campaign_member_API__c = 'LeadId';
        setting3.Whatsapp_Request_API__c = 'Lead__c';
        insert setting3;
        
        List<Lead> lstLead = new List<Lead>();
        for (Integer i=0;i<30;i++) {
        lstLead.add(new Lead(
            LastName = 'Test Lead'+i,
            Company = 'Test Company'+i,
            Email = 'test12345@checkboxtest.comm'+i,
            Status = 'Open'
        ));
        }
        
        insert lstLead;
        FSR__c mql= new FSR__c();
        mql.Lead__c = lstLead[0].id;
        mql.Campaign__c = objCam.id;
        insert mql;
        
        Account acc= new Account();
        acc.name = 'test';
        insert acc;
        
        Account_SID__c asid = new Account_SID__c();
        asid.Account_SID__c = 'test11';
        insert asid;
        
        List<Contact> lstContact = new List<Contact>();
        for (Integer i=0;i<30;i++) {
        lstContact.add(new Contact(
            LastName = 'Test Contact'+i,
            Email = 'test12345@checkboxtest.comm'+i,
            AccountId= acc.id
        ));
        }
        
        insert lstContact;
        
        test.startTest();
        List<CampaignMember> lstmem = new List<CampaignMember>();
        Integer counter = -10;
        for (Integer i=0;i<30;i++) {
            lstmem.add(new CampaignMember(
                CampaignId = objCam.id,
                LeadId = lstLead[i].id,
                Status = 'Registered',
                Eloqua_Campaign_Association_Done__c = true,
                Campaign_Member_Updated_Date__c = DateTime.now().addMinutes(counter),
                Description__c = 'Registered'
            ));
            counter++;
        }
        
        CampaignMember_to_FSR_Mapping__c cmfsr = new CampaignMember_to_FSR_Mapping__c(
            Name = 'Campaign Member Updated Date',
            FSR_Field__c = 'Date_Submitted__c',
            CampaignMember_Field__c = 'Campaign_Member_Updated_Date__c'
        );
        insert cmfsr;
        
        insert lstmem;
        
        List<WhatsApp_Request__c> lstWhatsapp = [Select Id,lead__c,Company_Ownership_Model__c from WhatsApp_Request__c];
        for(WhatsApp_Request__c objmem: lstWhatsapp){
            system.assertEquals(objmem.Company_Ownership_Model__c, 'Registered');
            for (Integer i=29;i>0;i--) {
            	objmem.Contact__c = lstContact[i].id;
                objmem.Account_SID_text__c = 'test11';
            }
        }
        update lstWhatsapp;
        test.stopTest();
    }
}