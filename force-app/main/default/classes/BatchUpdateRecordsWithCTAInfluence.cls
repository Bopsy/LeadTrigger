/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  BatchUpdateRecordsWithCTAInfluence
*
* @description 	  Batch class that updates Opportunities and Risk Reports with a lookup to a relevant CTA.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-11-13
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
global class BatchUpdateRecordsWithCTAInfluence implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    global Integer daysBack;
    global Integer dateRange;
    global Date todaysDate;
   
    global BatchUpdateRecordsWithCTAInfluence(){
        todaysDate = Date.today();
        
        Number_Of_Days_Back__c ctaAssociationRec = Number_Of_Days_Back__c.getAll().get('CTA Association');
        daysBack = Integer.valueOf(ctaAssociationRec.Historical_Days_Back__c);
        dateRange = Integer.valueOf(ctaAssociationRec.Association_Day_Range__c);
    } 
    
    global void execute(SchedulableContext sc) {
        //Set scheduler action
        Database.executeBatch(new BatchUpdateRecordsWithCTAInfluence(), 100);
    }
	
    global Database.queryLocator start(Database.BatchableContext bc){
        List<String> validPlaybookNames = new List<String>();
        Set<Id> playbookIds = new Set<Id>();
        
        List<Valid_Playbook_Names__c> vpns = Valid_Playbook_Names__c.getAll().values();
        for(Valid_Playbook_Names__c vpn : vpns){
            validPlayBookNames.add(vpn.Name);
        }
        
        List<JBCXM__Playbook__c> validPlaybookCTAs = [SELECT Id
                                                      FROM JBCXM__Playbook__c 
                                                      WHERE Name IN :validPlaybookNames];
        for(JBCXM__Playbook__c p : validPlaybookCTAs){
            playbookIds.add(p.Id);
        }
        
        //Datetime beginningDate = BusinessHours.add(bhId, todaysDate, -msRange);
        Datetime beginningDate = todaysDate.addDays(-daysBack);
        return Database.getQueryLocator([SELECT Id, 
                                               (SELECT Id, 
                                                       CreatedDate
                                                FROM JBCXM__Account__r 
                                                WHERE CreatedDate >= :beginningDate 
                                                 	AND JBCXM__Playbook__c IN :playbookIds
                                                ORDER BY CreatedDate DESC) 
                                         FROM Account
                                         WHERE ID IN (SELECT JBCXM__Account__c 
                                                      FROM JBCXM__CTA__c 
                                                      WHERE CreatedDate >= :beginningDate
                                                      	AND JBCXM__Playbook__c IN :playbookIds
                                                      AND JBCXM__Account__c != null)]);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> acctRecs){
        List<Opportunity> oppsForUpdate = new List<Opportunity>();
        List<Risk__c> risksForUpdate = new List<Risk__c>();
        
        oppsForUpdate = CTAInfluenceServices.getOpportunityInfluence(acctRecs, dateRange);
        risksForUpdate = CTAInfluenceServices.getRiskReportInfluence(acctRecs, dateRange);
        
        if(!oppsForUpdate.isEmpty()){
            update oppsForUpdate;
        }
        
        if(!risksForUpdate.isEmpty()){
            update risksForUpdate;
        }
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}