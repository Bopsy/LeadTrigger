/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  BatchSendCIAEmails
*
* @description 	  Batch class that sends CIA Emails to reps if they have a CTA created in the last 
*				  2 weeks.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-07-10
* @modified       2019-09-13
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  2019-09-13	Added functionality to allow admins to filter batch by CTA Reason/Type.
*				  2020-01-13	Added new criteria to only send emails to Active Users.
*			
**/
global class BatchSendCIAEmails implements Database.Batchable<SObject>, Schedulable{
    private static Date startDate = Date.today().addDays(-8);
    private static Date endDate = Date.today().addDays(-1);
    
	global void execute(SchedulableContext sc) {
        //Set scheduler action
        Database.executeBatch(new BatchSendCIAEmails(), 1000);
    }
	
    global Database.queryLocator start(Database.BatchableContext bc){
        Id customerSuccessId = [SELECT Id FROM User WHERE Name = 'Customer Success Team'].Id;
        
        //Get whitelist of Recipient Role Names.
        Set<String> roleNames = new Set<String>();
        List<CTADigestRecipientRoles__c> ctaDigRoles = CTADigestRecipientRoles__c.getAll().values();
        
        for(CTADigestRecipientRoles__c roleName : ctaDigRoles){
            roleNames.add(roleName.Name);
        }
        
        //Get whitelist of CTA Reason names.
        Set<String> validCTAReasons = new Set<String>();
        List<CTA_Digest_Valid_Types__c> ctaDigTypes = CTA_Digest_Valid_Types__c.getAll().values();
        
        for(CTA_Digest_Valid_Types__c reasonName : ctaDigTypes){
            validCTAReasons.add(reasonName.Name);
        }
        
        //if(CTAInfluenceServices.IsProductionOrg() == TRUE){
        	return Database.getQueryLocator([SELECT JBCXM__Assignee__r.Name, 
                                         	    JBCXM__Assignee__c, 
                                         		JBCXM__Account__r.Name,
                                                Id, 
                                                Name, 
                                                CTA_Status__c, 
                                                CreatedDate,
                                         		JBCXM__CreatedDate__c,
                                         		JBCXM__DueDate__c
                                         FROM JBCXM__CTA__c 
                                         WHERE JBCXM__CreatedDate__c >= :startDate 
                                         	AND JBCXM__CreatedDate__c <= :endDate
                                         	//AND JBCXM__Assignee__c != :customerSuccessId//'00540000003cyEkAAI'
                                         	AND JBCXM__Assignee__r.UserRole.Name IN :roleNames
                                            AND JBCXM__Assignee__r.IsActive = TRUE
                                            AND CTA_Digest__c = NULL
                                            AND CTA_Reason_Text__c IN :validCTAReasons
                                         ORDER BY JBCXM__Assignee__r.Name, JBCXM__Account__r.Name ASC 
                                         ]);    
        /*} else {
            return Database.getQueryLocator([SELECT JBCXM__Assignee__r.Name, 
                                         	    JBCXM__Assignee__c, 
                                         		JBCXM__Account__r.Name,
                                                Id, 
                                                Name, 
                                                CTA_Status__c, 
                                                CreatedDate,
                                         		JBCXM__CreatedDate__c,
                                         		JBCXM__DueDate__c
                                         FROM JBCXM__CTA__c 
                                         WHERE 
                                         	JBCXM__CreatedDate__c >= :startDate 
                                         	AND JBCXM__CreatedDate__c <= :endDate
                                            AND JBCXM__Assignee__r.UserRole.Name IN :roleNames
                                            AND JBCXM__Assignee__r.IsActive = TRUE
                                            AND CTA_Reason_Text__c IN :validCTAReasons
                                         	//AND JBCXM__Assignee__c != :customerSuccessId//'00540000003cyEkAAI'
                                         ORDER BY JBCXM__Assignee__r.Name, CTA_Reason_Text__c, JBCXM__Account__r.Name ASC 
                                         ]);
        }*/
        
    }
    
    global void execute(Database.BatchableContext bc, List<JBCXM__CTA__c> ctaRecs){
        //Get the list of CTA Digest records and insert them.
        List<CTA_Digest__c> ctaDigestsForInsert = CTAInfluenceServices.getCTADigestList(ctaRecs, startDate, endDate);
        insert ctaDigestsForInsert;
        
        //Put the CTA Digests into a map as a the key and the list of Child CTAs as the value.
        List<CTA_Digest__c> newDigests = CTAInfluenceServices.getNewDigestRecords(ctaDigestsForInsert);
        
        Map<CTA_Digest__c, List<JBCXM__CTA__c>> ctaDigestToCTAListMap = CTAInfluenceServices.getCTADigestMap(newDigests, ctaRecs);
        List<JBCXM__CTA__c> ctasForUpdate = CTAInfluenceServices.getAllCTAsFromMap(ctaDigestToCTAListMap);
        update ctasForUpdate;
        
        //Generate the emails and send them out to the proper reps.
        List<Messaging.SingleEmailMessage> ctaDigestsToEmail = CTAInfluenceServices.getAllCTADigestEmails(ctaDigestToCTAListMap);
        Messaging.sendEmail(ctaDigestsToEmail);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}