/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  AttachmentTriggerHandler
*
* @description 	  TriggerHandler Class for the Attachment Trigger.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-11-05
* @modified       2019-11-05
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  Not created by @jayu.  Updated on 2019-11-05.
*
**/
public without sharing class AttachmentTriggerHandler {
    
    public static Boolean bypassTrigger = false;
    public static String WRONG_PDF_TYPE = '.pdf';
    public static String RIGHT_PDF_TYPE = 'application/pdf';
    
    public static void afterInsertAgreement(List<Attachment> attachments){
        List<Agreement_Attachment_Mapping__c> fieldMapping = Agreement_Attachment_Mapping__c.getAll().values();
        Map<Id, Attachment> agreementMap = new Map<Id, Attachment>();
        
        Map<String, String> agreementFieldMapping = new Map<String, String>();
        
        for(Agreement_Attachment_Mapping__c fieldMap: Agreement_Attachment_Mapping__c.getAll().values()){
            agreementFieldMapping.put(fieldMap.Agreement_Field_Name__c, fieldMap.Attachment_Field_Name__c);
        }
         
        for(Attachment att: attachments){
            if(att.ParentId.getSobjectType() == Apttus__APTS_Agreement__c.SobjectType && att.Name.contains('Order Form')){
                agreementMap.put(att.ParentId, att);
            }
        }
        
        if(bypassTrigger) return;
        if(agreementMap.isEmpty()) return;
        
        String queryString = 'SELECT Needs_Approval__c, Only_Manager_Approval__c, Commit_Approval_Required__c, Only_2nd_Manager_Approval__c, ';
        queryString += String.join((new List<String>(agreementFieldMapping.keySet())), ', ');
        if(!agreementFieldMapping.isEmpty()) queryString += ', ';
        Set<Id> agreementIds = agreementMap.keySet();
        queryString += ' (SELECT Id, Flat_Price__c, Percent_Off__c, Discount_Type__c FROM Single_BI_Discounts__r WHERE Needs_Approval_Number__c > 0 OR Needs_Manager_Approval__c = true OR Needs_2nd_Tier_Manager_Approval__c = true) FROM Apttus__APTS_Agreement__c WHERE Id = :agreementIds';
        //List<Apttus__APTS_Agreement__c> agreements = [SELECT Needs_Approval__c, Only_Manager_Approval__c, (SELECT Id, Flat_Price__c, Percent_Off__c, Discount_Type__c FROM Single_BI_Discounts__r WHERE Needs_Approval_Number__c > 0 OR Needs_Manager_Approval__c = true) FROM Apttus__APTS_Agreement__c WHERE Id = :agreementMap.keySet()];
        
        List<Apttus__APTS_Agreement__c> agreements = (List<Apttus__APTS_Agreement__c>) Database.query(queryString);
        Map<Id, Apttus__APTS_Agreement__c> agreementFieldMap = new Map<Id, Apttus__APTS_Agreement__c>();
        
        for(Apttus__APTS_Agreement__c agreement: agreements){
            if(agreement.Needs_Approval__c || agreement.Only_Manager_Approval__c || agreement.Commit_Approval_Required__c || agreement.Only_2nd_Manager_Approval__c){
                agreementMap.remove(agreement.Id);
            }
            else{
                agreementFieldMap.put(agreement.Id, agreement);
            }
        }
        if(agreementMap.isEmpty()) return;
        AgreementAttachmentTriggerHandler.bypassTrigger = true; 
        Map<Id, Agreement_Attachment__c> customAttachmentMap = new Map <Id, Agreement_Attachment__c>();
        
        for(Id agreementId: agreementMap.keySet()){
            Agreement_Attachment__c customAttachment = new Agreement_Attachment__c(
                Name = agreementMap.get(agreementId).Name.left(80), Agreement__c = agreementId, Accounting_Approval_Status__c = 'Approved', Legal_Approval_Status__c = 'Approved',Deal_Desk_Approval_Status__c = 'Approved',Manager_Approval_Status__c = 'Approved',X2nd_Tier_Manager_Approval_Status__c = 'Approved',Attachment_Id__c = agreementMap.get(agreementId).Id);Apttus__APTS_Agreement__c agreementObject =  agreementFieldMap.get(agreementId);
            for(String agreementField: agreementFieldMapping.keySet()){
                if(agreementObject.get(agreementField) != null){customAttachment.put(agreementFieldMapping.get(agreementField), agreementObject.get(agreementField));}
            }
            system.debug('+++customAttachment11 '+customAttachment);
            customAttachmentMap.put(agreementId, customAttachment);
        }
        
        insert customAttachmentMap.values();
        
    }
    
    public static void beforeInsertAgreement(List<Attachment> attachments){
        if(bypassTrigger) return;
        Map<Id, Attachment> agreementMap = new Map<Id, Attachment>();
        Map<Id, List<Single_BI_Discount__c>> biMap = new Map<Id, List<Single_BI_Discount__c>>();
        Map<Id, Boolean> managerApprovalMap = new Map<Id, Boolean>();
        Map<Id, Boolean> secondManagerApprovalMap = new Map<Id, Boolean>();
        Map<String, String> agreementFieldMapping = new Map<String, String>();
        
        for(Agreement_Attachment_Mapping__c fieldMap: Agreement_Attachment_Mapping__c.getAll().values()){
            agreementFieldMapping.put(fieldMap.Agreement_Field_Name__c, fieldMap.Attachment_Field_Name__c);
        }
        
        
        for(Attachment att: attachments){
            if(att.ParentId.getSobjectType() == Apttus__APTS_Agreement__c.SobjectType && att.Name.contains('Order Form')){
                agreementMap.put(att.ParentId, att);
            } 
        }
        
        if(agreementMap.isEmpty()) return;
        
        String queryString = 'SELECT Commit_Type__c, Number_of_SendGrid_Products__c, Needs_Approval__c, Only_Manager_Approval__c, Commit_Approval_Required__c, Only_2nd_Manager_Approval__c, ';
        queryString += String.join((new List<String>(agreementFieldMapping.keySet())), ', ');
        if(!agreementFieldMapping.isEmpty()) queryString += ', ';
        Set<Id> agreementIds = agreementMap.keySet();
        queryString += ' (SELECT Id, Flat_Price__c, Percent_Off__c, Discount_Type__c FROM Single_BI_Discounts__r WHERE Needs_Approval_Number__c > 0 OR Needs_Manager_Approval__c = true OR Needs_2nd_Tier_Manager_Approval__c = true) FROM Apttus__APTS_Agreement__c WHERE Id = :agreementIds';
        //List<Apttus__APTS_Agreement__c> agreements = [SELECT Needs_Approval__c, Only_Manager_Approval__c, (SELECT Id, Flat_Price__c, Percent_Off__c, Discount_Type__c FROM Single_BI_Discounts__r WHERE Needs_Approval_Number__c > 0 OR Needs_Manager_Approval__c = true) FROM Apttus__APTS_Agreement__c WHERE Id = :agreementMap.keySet()];
        List<Apttus__APTS_Agreement__c> agreements = (List<Apttus__APTS_Agreement__c>) Database.query(queryString);
        Map<Id, Apttus__APTS_Agreement__c> agreementFieldMap = new Map<Id, Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agreement: agreements){
            if((agreement.Number_of_SendGrid_Products__c == 0 || agreement.Number_of_SendGrid_Products__c == null) && !agreement.Needs_Approval__c && agreement.Commit_Type__c != 'Product' && !agreement.Only_Manager_Approval__c && !agreement.Commit_Approval_Required__c && !agreement.Only_2nd_Manager_Approval__c){
                agreementMap.remove(agreement.Id);
            }
            else {
                managerApprovalMap.put(agreement.Id, agreement.Only_Manager_Approval__c);
                secondManagerApprovalMap.put(agreement.Id, agreement.Only_2nd_Manager_Approval__c);
                agreementFieldMap.put(agreement.Id, agreement);
                if(agreement.Single_BI_Discounts__r != null && !agreement.Single_BI_Discounts__r.isEmpty()){
                    biMap.put(agreement.Id, agreement.Single_BI_Discounts__r);
                }
            }
        }
        
        if(agreementMap.isEmpty()) return;
        
        Map<Id, Agreement_Attachment__c> customAttachmentMap = new Map <Id, Agreement_Attachment__c>();
        
        for(Id agreementId: agreementMap.keySet()){
            Agreement_Attachment__c customAttachment = new Agreement_Attachment__c(Name = agreementMap.get(agreementId).Name.left(80), Agreement__c = agreementId, /*Needs_Approval__c = true,*/ X2nd_Tier_Manager_Approval_Required__c	 = secondManagerApprovalMap.get(agreementId), Needs_Manager_Approval__c = managerApprovalMap.get(agreementId), Exception_Reason__c = 'Deal Desk Price Approval', Accounting_Approval_Status__c = 'Approved', Legal_Approval_Status__c = 'Approved');
            Apttus__APTS_Agreement__c agreementObject =  agreementFieldMap.get(agreementId);
            for(String agreementField: agreementFieldMapping.keySet()){
                if(agreementObject.get(agreementField) != null){
                    customAttachment.put(agreementFieldMapping.get(agreementField), agreementObject.get(agreementField));
                }
            }
            customAttachment.Deal_Desk_Approval_Status__c = agreementObject.Needs_Approval__c == false ? 'Approved' : 'Not Started';
            customAttachment.Manager_Approval_Status__c = customAttachment.Needs_Manager_Approval__c == true ? 'Not Started' : 'Approved';
            customAttachment.X2nd_Tier_Manager_Approval_Status__c = customAttachment.X2nd_Tier_Manager_Approval_Required__c == true ? 'Not Started' : 'Approved';
            customAttachmentMap.put(agreementId, customAttachment);
            system.debug('+++customAttachment22 '+customAttachment);
        }
        
        insert customAttachmentMap.values();
        
        List<Exception_BI__c> exceptionBis = new List<Exception_BI__c>();
        for(Id agreementId: agreementMap.keySet()){
           Attachment att = agreementMap.get(agreementId);
           Id customObjId = customAttachmentMap.get(agreementId).Id;
           if(att != null){
               att.ParentId = customObjId;
           }
           
           List<Single_BI_Discount__c> bis = biMap.get(agreementId);
           if(bis != null){
               for(Single_BI_Discount__c bi : bis){
                   Exception_BI__c newBi = new Exception_BI__c(
                           Single_BI_Discount__c = bi.Id, 
                           Agreement_Attachment__c = customObjId);
                   if(bi.Discount_Type__c == 'Flat') newBi.Deal_Desk_Flat_Price__c = bi.Flat_Price__c;
                   else newBi.Deal_Desk_Percent_Off__c = bi.Percent_Off__c;
                   exceptionBis.add(newBi);
               }
           }
        }
        
        insert exceptionBis;
    }
    
    //If the attachment is created with a Content Type of '.pdf', then set the Content Type to
    //'application/pdf' before insert.
    public static void setContentTypeToPDF(List<Attachment> attachments){
        for(Attachment attRec: attachments){
            if(attRec.ContentType != null && attRec.ContentType == WRONG_PDF_TYPE){
            	attRec.ContentType = RIGHT_PDF_TYPE;
            	attRec.Body = attRec.Body;    
            }
        }
    }
    
    public static void afterInsertDocVersionDetail(List<Attachment> attachments){
        Map<Id, Attachment> attachmentMap = new Map<Id, Attachment>();
		for(Attachment att: attachments){
            if(att.ParentId.getSobjectType() == Apttus__DocumentVersionDetail__c.SobjectType){
                attachmentMap.put(att.ParentId, att);
            }
        }
        if(attachmentMap.isEmpty()) return;
        
        Map<String, String> agreementFieldMapping = new Map<String, String>();
        //get custom setting field mapping
        for(Agreement_Attachment_Mapping__c fieldMap: Agreement_Attachment_Mapping__c.getAll().values()){
            agreementFieldMapping.put(fieldMap.Agreement_Field_Name__c, fieldMap.Attachment_Field_Name__c);
        }
        List<Id> docVerIds= new List<Id>();
        docVerIds.addAll(attachmentMap.keyset());
        //query on document version detail to get fields along with document detail and agreement related fields
		String queryString = 'Select Id,Apttus__Title__c ,Apttus__DocumentInfo__c,Apttus__Action2__c,Apttus__DocumentVersionId__r.Name';
        String whereCon = ' from Apttus__DocumentVersionDetail__c Where Id =:docVerIds';
        for(Agreement_Attachment_Mapping__c setting : Agreement_Attachment_Mapping__c.getAll().values()){
            queryString += ' ,Apttus__DocumentVersionId__r.Apttus__AgreementId__r.' + setting.Agreement_Field_Name__c ;
        }
        queryString = queryString + whereCon;
        List<Apttus__DocumentVersionDetail__c> lstDocVersionDetail = database.query(queryString);
        
        Map<Id,Agreement_Attachment__c> mapAgrtAttachment = new Map<Id,Agreement_Attachment__c>();
        //create agreement attachments for each document version detail
        for(Apttus__DocumentVersionDetail__c docVer : lstDocVersionDetail){
            Agreement_Attachment__c attach = new Agreement_Attachment__c(Name = attachmentMap.get(docVer.Id).Name.left(80), Agreement__c = docVer.Apttus__DocumentVersionId__r.Apttus__AgreementId__c,
                                                                         Document_Version_Detail__c=docVer.id);
            
            for(String agreementField: agreementFieldMapping.keySet()){
                if(docVer.getSobject('Apttus__DocumentVersionId__r').getSobject('Apttus__AgreementId__r').get(agreementField) != null){
                    attach.put(agreementFieldMapping.get(agreementField), docVer.getSobject('Apttus__DocumentVersionId__r').getSobject('Apttus__AgreementId__r').get(agreementField) );
                }
            }
            if((docVer.Apttus__Action2__c=='Generate Agreement' || docVer.Apttus__Action2__c=='Regenerate Agreement') && docVer.Apttus__DocumentInfo__c!='Redlines'){
                attach.Deal_Desk_Approval_Status__c='Approved';
                attach.Accounting_Approval_Status__c='Approved';
                attach.Legal_Approval_Status__c='Approved';
                attach.Commit_Approval_Status__c='Approved';
            }
            if(docVer.Apttus__DocumentInfo__c=='Final' && docVer.Apttus__Action2__c=='Check In'){
                attach.Legal_Approval_Status__c='Approved';
            }
            mapAgrtAttachment.put(docVer.Id,attach);
            system.debug('+++customAttachment33 '+attach);
        }
        insert mapAgrtAttachment.values();
        
        List<Attachment> insertAttachments = new List<Attachment>();
        
        for(Apttus__DocumentVersionDetail__c rec: lstDocVersionDetail){
            Attachment att = attachmentMap.get(rec.Id);
            if(att != null){
                Attachment newAtt = new Attachment(
                    Body = att.Body,
                    Description = att.Description,
                    ContentType = att.ContentType,
                    Name = att.Name.left(80),
                    OwnerId = att.OwnerId,
                    ParentId = mapAgrtAttachment.get(rec.Id).Id
                );
                insertAttachments.add(newAtt);
            }
        }
        insert insertAttachments;
        List<Agreement_Attachment__c> approvedRecords = [Select Id, Docusign_Ready__c, Agreement__c,Contract_Ops_Approval_Status__c from Agreement_Attachment__c where Id =:mapAgrtAttachment.values()];
        AgreementAttachmentTriggerHandler.afterUpsert(approvedRecords,new Map<Id, Agreement_Attachment__c>());
    }
    
}