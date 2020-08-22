/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  orgApplicationUpdateBatchTest
*
* @description 	  Test class for orgApplicationUpdateBatch class, test include:
					1. batch excute test
					4. schedulaer test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui	 <ncui@twilio.com>
* @modifiedBy     Mia Cui    <ncui@twilio.com>
* @version        1.0
* @created        2020-02-19
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		
*
**/
@isTest
public class orgApplicationUpdateBatchTest {
    static testmethod void positivetest(){
        lead mylead = new lead(lastname = 'Cui', Company = 'Mia Test Co', status = 'Contacted');
        insert myLead;
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(myLead.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

        org_Application__c app = new org_Application__c(Name = 'Mia OrgApplication Test', lead__c = myLead.ID);
        insert app;
        
        Test.startTest();
            orgApplicationUpdateBatch obj = new orgApplicationUpdateBatch();
            DataBase.executeBatch(obj);
        Test.stopTest();
        
        Lead mylead1 = [Select ConvertedContactId from lead where id =: mylead.Id];
        org_Application__c app1 = [select lead__c, contact__c from org_Application__c where id =: app.Id];
        System.assert(app1.lead__c == NULL);
        System.assert(app1.contact__c == mylead1.ConvertedContactId);

    }
    
    static testmethod void bulktest(){

        List<Lead> leadLst = new List<Lead>();
        for(integer i = 0; i<10; i++) {
            leadLst.add(new lead(lastname = 'Cui'+i, Company = 'Mia Test Co', status = 'Contacted'));
        }
        insert leadLst;
        
        list<Database.LeadConvert> converts = new list<Database.LeadConvert>();

        LeadStatus convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        for(Lead record: leadLst) { 
            Database.LeadConvert convert = new Database.LeadConvert();
            convert.setLeadId(record.Id); 
            convert.setConvertedStatus(convertedStatus.MasterLabel);
            converts.add(convert);
        }
        Database.convertLead(converts);
        
        
        List<org_Application__c> orgApplitionLst = new List<org_Application__c>();
        for(integer i = 0; i<10; i++) {
            orgApplitionLst.add(new org_Application__c(Name = 'Mia OrgApplication Test', lead__c = leadLst[i].ID));
        }
        insert orgApplitionLst;
        
        
        Test.startTest();
            orgApplicationUpdateBatch obj = new orgApplicationUpdateBatch();
            DataBase.executeBatch(obj);
        Test.stopTest();
        
        List<org_Application__c> appLst = [SELECT lead__c, contact__c 
                                           FROM org_Application__c 
                                   		   WHERE Name = 'Mia OrgApplication Test'];
        
        List<Lead> leadLst1 = [Select ConvertedContactId from lead where company = 'Mia Test Co'];
        

        
        for(integer i = 0; i<10; i++) {
            System.assert(appLst[i].lead__c == NULL);
            System.assert(appLst[i].Contact__c == leadLst1[i].ConvertedContactId);
        }
        

    }
    
    static testmethod void negativetest(){
        lead mylead = new lead(lastname = 'Cui', Company = 'Mia Test Co', status = 'Contacted');
        insert myLead;

        org_Application__c app = new org_Application__c(Name = 'Mia OrgApplication Test', lead__c = myLead.ID);
        insert app;
        
        Test.startTest();
            orgApplicationUpdateBatch obj = new orgApplicationUpdateBatch();
            DataBase.executeBatch(obj);
        Test.stopTest();
        
        System.assert(app.lead__c == mylead.Id);
        System.assert(app.contact__c == NULL);
        

    }
    
    static testMethod void testScheduler(){
        String CRON_EXP = '0 0 * * * ?';
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest',
                                            CRON_EXP,
                                            new orgApplicationUpdateBatch());
        Test.stopTest();
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'orgApplicationUpdateBatch') LIMIT 1].Status);
    }

}