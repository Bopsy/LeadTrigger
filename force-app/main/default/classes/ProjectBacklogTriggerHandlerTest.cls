/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           ProjectBacklogTriggerHandlerTest
*
* @description    Test class for ProjectBacklogTriggerHandler
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
private class ProjectBacklogTriggerHandlerTest {

    static testmethod void ProjectBacklogTriggerHandlerTest1() {
        GTM_Project_to_Project_Backlog_mappings__c setting1 = new GTM_Project_to_Project_Backlog_mappings__c ();
        setting1.Name = 'Status';
        setting1.GTM_Project_Field_API__c = 'Status__c';
        setting1.Project_Backlog_Field_API__c = 'Status__c';
        insert setting1;
        
        GTM_Project_to_Project_Backlog_mappings__c  setting2 = new GTM_Project_to_Project_Backlog_mappings__c ();
        setting2.Name='Status Category';
        setting2.GTM_Project_Field_API__c ='Status_Category__c';
        setting2.Project_Backlog_Field_API__c='Status_Category__c';
        insert setting2;
        
        test.startTest();
        Workstream__c objGtm = new Workstream__c();
        objGtm.name='test';
        objGtm.Status_Category__c ='Completed';
        objGtm.Status__c = 'Deployed';
        insert objGtm;
        
        Team__c objTeam = new Team__c ();
        objTeam.Team_Category__c ='Legal';
        insert objTeam;
        
        Team__c objTeam1 = new Team__c ();
        objTeam1.Team_Category__c ='Support';
        insert objTeam1;
            
        Project_Team__c objProj = new Project_Team__c();
        objProj.name='test1';
        objProj.GTM_Project__c =objGtm.id;
        objProj.team__c= objTeam.id;
        objProj.Status_Category__c ='Omitted';
        objProj.Status__c = 'Cancelled';
        insert objProj;
        
        system.assertEquals('Omitted', objProj.Status_Category__c);
        
        TriggerRunOnceUtility.ProjectBacklogTrigger=false;
        objProj.team__c = objTeam1.id;
        objProj.Status_Category__c ='Completed';
        objProj.Status__c = 'Deployed';
        update objProj;
        
        system.assertEquals('Completed', objGtm.Status_Category__c);
        delete objProj;
        test.stopTest();
    }
}