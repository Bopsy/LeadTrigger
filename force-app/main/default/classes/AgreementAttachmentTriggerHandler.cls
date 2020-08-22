public without sharing class AgreementAttachmentTriggerHandler {
    public final static String APPROVED_STATUS = 'Approved';
    public static Boolean bypassTrigger = false;
    
    public static void beforeInsert(List<Agreement_Attachment__c> records){
        Map<Id, List<Agreement_Attachment__c>> agreementMap = new Map<Id, List<Agreement_Attachment__c>>();
        
        for(Agreement_Attachment__c att: records){
            List<Agreement_Attachment__c> attachments = agreementMap.get(att.Agreement__c);
            if(attachments == null) attachments = new List<Agreement_Attachment__c>();
            attachments.add(att);
            agreementMap.put(att.Agreement__c, attachments);
        }
        
        Map<Id, Apttus__APTS_Agreement__c> agreements = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id, (SELECT Status__c FROM Special_Terms__r) FROM Apttus__APTS_Agreement__c WHERE Id =: agreementMap.keySet()]);
        
        for(Id agreementId: agreements.keySet()){
            List<Agreement_Attachment__c> attachments = agreementMap.get(agreementId);
            List<Special_Term__c> terms = agreements.get(agreementId).Special_Terms__r;
            if(attachments != null && !attachments.isEmpty() && terms != null && !terms.isEmpty()){
                String overallStatus = '';
                Integer approvalCount = 0;
                Integer rejectCount = 0;
                Integer pendingCount = 0;
                Integer rejectOmitCount = 0;
                Integer totalSize = terms.size();
                for(Special_Term__c term: terms){
                    if(term.Status__c == 'Rejected'){rejectCount++;}
                    else if(term.Status__c == 'Pending Approval'){pendingCount++;}
                    else if(term.Status__c == 'Approved'){approvalCount++;}
                    else{rejectOmitCount++;}
                }
                if(totalSize == approvalCount + rejectOmitCount){overallStatus = 'Approved';}
                else if(totalSize == rejectOmitCount){overallStatus = 'Rejected';}
                else if(pendingCount > 0){overallStatus = 'Pending';}
                else if(totalSize == rejectOmitCount + rejectCount + approvalCount){overallStatus = 'Pending';}
                
                for(Agreement_Attachment__c att: attachments){
                    att.Overall_Special_Terms_Status__c = overallStatus;
                }
            }
        }
    }
    
    //As for attchment record, this trigger function could only process one record at a time;
    public static void afterUpsert(List<Agreement_Attachment__c> records, Map<Id, Agreement_Attachment__c> oldMap){
        if(bypassTrigger) return;
        AttachmentTriggerHandler.bypassTrigger = true;
        List<Agreement_Attachment__c> approvedRecords = new List<Agreement_Attachment__c>();
        for(Agreement_Attachment__c rec: records){
            Agreement_Attachment__c oldRec = oldMap.get(rec.Id);
            if(oldRec == null){
                if(rec.Docusign_Ready__c == true && rec.Contract_Ops_Approval_Status__c=='Approved'){//rec.Accounting_Approval_Status__c == APPROVED_STATUS && rec.Deal_Desk_Approval_Status__c == APPROVED_STATUS && rec.Legal_Approval_Status__c == APPROVED_STATUS){
                    approvedRecords.add(rec);
                }
            }
            else{
                if(rec.Docusign_Ready__c == true && rec.Docusign_Ready__c != oldRec.Docusign_Ready__c && rec.Contract_Ops_Approval_Status__c=='Approved'){//rec.Accounting_Approval_Status__c == APPROVED_STATUS && rec.Deal_Desk_Approval_Status__c == APPROVED_STATUS && rec.Legal_Approval_Status__c == APPROVED_STATUS 
                    //&& ((rec.Accounting_Approval_Status__c != oldRec.Accounting_Approval_Status__c) || (rec.Deal_Desk_Approval_Status__c != oldRec.Deal_Desk_Approval_Status__c) 
                    //|| (rec.Legal_Approval_Status__c != oldRec.Legal_Approval_Status__c))){
                    approvedRecords.add(rec);        
                }
            }
        }
        
        if(approvedRecords.isEmpty()) return;
        List<Attachment> relatedAttachment = [SELECT ParentId, Body, BodyLength, Description, ContentType, Name, OwnerId FROM Attachment WHERE ParentId =: approvedRecords];
        List<Exception_BI__c> relatedExceptionalBis = [SELECT Single_BI_Discount__c, Deal_Desk_Flat_Price__c, Deal_Desk_Percent_Off__c, Agreement_Attachment__r.Agreement__r.Term_Range__c, Agreement_Attachment__r.Agreement__c, Agreement_Attachment__r.Agreement__r.Total_Committed_Revenue__c FROM Exception_BI__c WHERE Agreement_Attachment__c =: approvedRecords AND (Deal_Desk_Flat_Price__c != null OR Deal_Desk_Percent_Off__c != null)];
        Map<Id, Attachment> attachmentMap = new Map<Id, Attachment>();
        
        for(Attachment att: relatedAttachment){
            attachmentMap.put(att.ParentId, att);
        }
        
        if(relatedExceptionalBis != null && !relatedExceptionalBis.isEmpty()){
            Decimal commitedRevenue = relatedExceptionalBis[0].Agreement_Attachment__r.Agreement__r.Total_Committed_Revenue__c;
            Decimal months = 12;
            if(relatedExceptionalBis[0].Agreement_Attachment__r.Agreement__r.Term_Range__c != null) months = Decimal.valueOf(relatedExceptionalBis[0].Agreement_Attachment__r.Agreement__r.Term_Range__c);
            commitedRevenue = commitedRevenue / months;
            Id agreementId = relatedExceptionalBis[0].Agreement_Attachment__r.Agreement__c;
            List<Approved_BI_Commit_Price__c> existingPrice = [SELECT Commit_Min__c, Flat_Price__c, Percent_Off__c, Discount_Type__c, Single_BI_Discount__c FROM Approved_BI_Commit_Price__c WHERE Single_BI_Discount__r.Agreement__c =: agreementId];
            List<Approved_BI_Commit_Price__c> upsertPrice = new List<Approved_BI_Commit_Price__c>();
            List<Single_BI_Discount__c> discounts = new List<Single_BI_Discount__c>();
            for(Exception_BI__c exceptionBi: relatedExceptionalBis){
                String discountType = exceptionBi.Deal_Desk_Flat_Price__c == null ? 'Percent' : 'Flat';
                Boolean alreadyFound = false;
                if(existingPrice != null && !existingPrice.isEmpty()){
                    for(Approved_BI_Commit_Price__c price: existingPrice){
                        if(price.Discount_Type__c == discountType && price.Single_BI_Discount__c == exceptionBi.Single_BI_Discount__c){
                            if(discountType == 'Percent') price.Percent_Off__c = exceptionBi.Deal_Desk_Percent_Off__c;
                            else price.Flat_Price__c = exceptionBi.Deal_Desk_Flat_Price__c;
                            upsertPrice.add(price);
                            alreadyFound = true;
                            break;
                        }
                    }
                }
                if(!alreadyFound){
                    Approved_BI_Commit_Price__c newPrice = new Approved_BI_Commit_Price__c(
                                Single_BI_Discount__c = exceptionBi.Single_BI_Discount__c,
                                Commit_Min__c = commitedRevenue,
                                Discount_Type__c = discountType,
                                Exception_BI__c = exceptionBi.Id
                    );
                    if(discountType == 'Percent') newPrice.Percent_Off__c = exceptionBi.Deal_Desk_Percent_Off__c;
                    else newPrice.Flat_Price__c = exceptionBi.Deal_Desk_Flat_Price__c;
                    upsertPrice.add(newPrice);
                }
                discounts.add(new Single_BI_Discount__c(Id = exceptionBi.Single_BI_Discount__c, Needs_Approval_Number__c = 0, Needs_Manager_Approval__c = false, Tier_Approval__c = false));
            }
            List<Single_BI_Tier__c> tiers = [SELECT Id FROM Single_BI_Tier__c WHERE Agreement__c =: agreementId];
            List<Single_GTM_Group_Tier__c> groupTiers = [SELECT Id FROM Single_GTM_Group_Tier__c WHERE Agreement__c =: agreementId];
            for(Single_BI_Tier__c tier: tiers){
                tier.Needs_Approval__c = false;
            }
            for(Single_GTM_Group_Tier__c tier: groupTiers){
                tier.Needs_Approval__c = false;
            }
            update tiers;
            update groupTiers;
            upsert upsertPrice;
            update discounts;
        }
        
        
        Map<Id, Attachment> insertAttachments = new Map<Id, Attachment>();
        List<Attachment> deleteAttachments = new List<Attachment>();
        
        for(Agreement_Attachment__c rec: approvedRecords){
            Attachment att = attachmentMap.get(rec.Id);
            if(att != null){
                Attachment newAtt = new Attachment(
                    Body = att.Body,
                    Description = att.Description,
                    ContentType = att.ContentType,
                    Name = att.Name.left(80),
                    OwnerId = att.OwnerId,
                    ParentId = rec.Agreement__c
                );
                insertAttachments.put(rec.Id, newAtt);
                deleteAttachments.add(new Attachment(Id = att.Id));
            }
        }
        
        List<Agreement_Attachment__c> deleteRecords = approvedRecords.deepClone(true, true);
        
        insert insertAttachments.values();
        delete deleteAttachments;
        
        for(Agreement_Attachment__c obj: deleteRecords){
            if(insertAttachments.get(obj.Id) != null)
                obj.Attachment_Id__c = insertAttachments.get(obj.Id).Id;
        }
        
        update deleteRecords;
        //Do we need to delete these records?Or keep it with data integrity/report?
        //delete deleteRecords;
    }
    
    public static void afterInsert(List<Agreement_Attachment__c> records){
        Map<Id,Agreement_Attachment__c> mapAgrIdWithAtt = new Map<Id,Agreement_Attachment__c>();
        for(Agreement_Attachment__c objAtt: records){
            if(objAtt.Document_Version_Detail__c==null && objAtt.name.contains('.pdf')){
                mapAgrIdWithAtt.put(objAtt.Agreement__c,objAtt);
                system.debug('+++objpdfatt '+objAtt);
            }
        }
        if(mapAgrIdWithAtt.size()>0){
            list<Agreement_Attachment__c> lstAllAtts = [Select Id,name,Agreement__c,createdbyid, createddate,Document_Version_Detail__c,Document_Version_Detail__r.Apttus__Action2__c, Agreement_Attachment_Auto_Number__c   
                                                        from Agreement_Attachment__c where Document_Version_Detail__r.Apttus__Action2__c='Check In' and Agreement__c IN:mapAgrIdWithAtt.keyset() and name like '%.docx'];
            
            if(lstAllAtts!=null && lstAllAtts.size()>0){
                for(Agreement_Attachment__c objAtt: lstAllAtts){
                    Agreement_Attachment__c objpdf = mapAgrIdWithAtt.get(objAtt.Agreement__c);
                    if(objpdf.Name.substringBeforeLast('.pdf')==objAtt.name.substringBeforeLast('.docx') && date.valueOf(system.now())== date.valueOf(objAtt.CreatedDate)
                       && userinfo.getUserId()==objAtt.createdbyid && objpdf.Agreement__c==objAtt.Agreement__c){
                           objpdf.Document_Version_Detail__c = objAtt.Document_Version_Detail__c;
                       }
                }
            }
        }
    }
    
}