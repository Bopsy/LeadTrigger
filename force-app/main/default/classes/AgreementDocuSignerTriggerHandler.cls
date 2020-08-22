public without sharing class AgreementDocuSignerTriggerHandler {
    
    public static void afterInsert(List<Apttus__APTS_Agreement__c> records){
        List<Agreement_DocuSigner__c> settings = Agreement_DocuSigner__c.getAll().values();
        List<RecordType> recTypes = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Apttus_DocuApi__DocuSignDefaultRecipient2__c' and DeveloperName='Email'];
        if(settings.isEmpty()) return;
        
        Map<Id,Apttus__APTS_Agreement__c> mapAgrIdsQuoteIds = new Map<Id,Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c rec: records){
            if(rec.Apttus_QPComply__RelatedProposalId__c!=null){
                mapAgrIdsQuoteIds.put(rec.Apttus_QPComply__RelatedProposalId__c,rec);
            }
        }
        if(mapAgrIdsQuoteIds!=null && mapAgrIdsQuoteIds.size()>0){
            List<Apttus_Proposal__Proposal__c> lstQuotes = [Select Id,Number_of_Sendgrid_Lineitems__c, Has_SendGrid_LineItems_Only__c from 
                                                            Apttus_Proposal__Proposal__c where Id IN: mapAgrIdsQuoteIds.keyset()];
            List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipients = new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
            for(Apttus_Proposal__Proposal__c rec: lstQuotes){
                for(Agreement_DocuSigner__c setting: settings){
                    if((setting.RecordTypeId__c == null) || setting.RecordTypeId__c == mapAgrIdsQuoteIds.get(rec.Id).RecordTypeId){
                        if(setting.Signing_Order__c!=2 && setting.SendGrid_Only__c==false){
                            recipients.add(new Apttus_DocuApi__DocuSignDefaultRecipient2__c(
                                RecordTypeId = recTypes[0].id,
                                Apttus_DocuApi__IsTransient__c = false,
                                Apttus_DocuApi__FirstName__c = setting.First_Name__c,
                                Apttus_DocuApi__LastName__c = setting.Last_Name__c,
                                Apttus_DocuApi__Email__c = setting.Email__c,
                                Apttus_DocuApi__IsRequired__c = setting.Is_Required__c,
                                Apttus_DocuApi__SigningOrder__c = (setting.Signing_Order__c==3 && rec.Number_of_Sendgrid_Lineitems__c>0 && rec.Has_SendGrid_LineItems_Only__c==false) ? 4 : setting.Signing_Order__c ,
                                Apttus_DocuApi__RecipientType__c = setting.Type__c,
                                Apttus_CMDSign__AgreementId__c = mapAgrIdsQuoteIds.get(rec.Id).Id));
                            
                        }
                        //Greg for twilio
                        if(setting.Signing_Order__c==2 && rec.Has_SendGrid_LineItems_Only__c==false){
                            recipients.add(new Apttus_DocuApi__DocuSignDefaultRecipient2__c(
                                RecordTypeId = recTypes[0].id,
                                Apttus_DocuApi__IsTransient__c = false,
                                Apttus_DocuApi__FirstName__c = setting.First_Name__c,
                                Apttus_DocuApi__LastName__c = setting.Last_Name__c,
                                Apttus_DocuApi__Email__c = setting.Email__c,
                                Apttus_DocuApi__IsRequired__c = setting.Is_Required__c,
                                Apttus_DocuApi__SigningOrder__c = setting.Signing_Order__c,
                                Apttus_DocuApi__RecipientType__c = setting.Type__c,
                                Title__c = setting.Twilio_Title__c,
                                Apttus_CMDSign__AgreementId__c =mapAgrIdsQuoteIds.get(rec.Id).Id));
                        }
                        //Greg for SG
                        system.debug('+++sg '+rec.Number_of_Sendgrid_Lineitems__c);
                        if(setting.Signing_Order__c==2 && rec.Number_of_Sendgrid_Lineitems__c>0){
                            recipients.add(new Apttus_DocuApi__DocuSignDefaultRecipient2__c(
                                RecordTypeId = recTypes[0].id,
                                Apttus_DocuApi__IsTransient__c = false,
                                Apttus_DocuApi__FirstName__c = setting.First_Name__c,
                                Apttus_DocuApi__LastName__c = setting.Last_Name__c,
                                Apttus_DocuApi__Email__c = setting.Email__c,
                                Apttus_DocuApi__IsRequired__c = setting.Is_Required__c,
                                Apttus_DocuApi__SigningOrder__c = rec.Has_SendGrid_LineItems_Only__c==false ? 3:2,
                                Apttus_DocuApi__RecipientType__c = setting.Type__c,
                                Title__c = setting.SG_Title__c,
                                Apttus_CMDSign__AgreementId__c =mapAgrIdsQuoteIds.get(rec.Id).Id));
                        } 
                        //SG dealdesk
                        if(setting.SendGrid_Only__c==true && rec.Number_of_Sendgrid_Lineitems__c>0){
                            recipients.add(new Apttus_DocuApi__DocuSignDefaultRecipient2__c(
                                RecordTypeId = recTypes[0].id,
                                Apttus_DocuApi__IsTransient__c = false,
                                Apttus_DocuApi__FirstName__c = setting.First_Name__c,
                                Apttus_DocuApi__LastName__c = setting.Last_Name__c,
                                Apttus_DocuApi__Email__c = setting.Email__c,
                                Apttus_DocuApi__IsRequired__c = setting.Is_Required__c,
                                Apttus_DocuApi__SigningOrder__c = (rec.Number_of_Sendgrid_Lineitems__c>0 && rec.Has_SendGrid_LineItems_Only__c==false) ? (setting.Signing_Order__c+1) : setting.Signing_Order__c ,
                                Apttus_DocuApi__RecipientType__c = setting.Type__c,
                                Apttus_CMDSign__AgreementId__c = mapAgrIdsQuoteIds.get(rec.Id).Id));
                        }
                    }
                }
            }
            insert recipients;
        }else{
            List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipients = new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
            for(Apttus__APTS_Agreement__c rec: records){
                for(Agreement_DocuSigner__c setting: settings){
                    if(setting.RecordTypeId__c == null || setting.RecordTypeId__c == rec.RecordTypeId){
                        recipients.add(new Apttus_DocuApi__DocuSignDefaultRecipient2__c(
                            RecordTypeId = recTypes[0].id,
                            Apttus_DocuApi__IsTransient__c = false,
                            Apttus_DocuApi__FirstName__c = setting.First_Name__c,
                            Apttus_DocuApi__LastName__c = setting.Last_Name__c,
                            Apttus_DocuApi__Email__c = setting.Email__c,
                            Apttus_DocuApi__IsRequired__c = setting.Is_Required__c,
                            Apttus_DocuApi__SigningOrder__c = setting.Signing_Order__c,
                            Apttus_DocuApi__RecipientType__c = setting.Type__c,
                            Title__c = setting.Twilio_Title__c,
                            Apttus_CMDSign__AgreementId__c = rec.Id
                        ));
                    }
                }
            }
            
            insert recipients;
        }
    }
    
    public static void afterUpdate(List<Apttus__APTS_Agreement__c> newList, Map<Id,Apttus__APTS_Agreement__c> oldMap){
        List<Apttus__APTS_Agreement__c> records = new List<Apttus__APTS_Agreement__c>();
        List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipients = new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
        for(Apttus__APTS_Agreement__c rec: newList){
            if(rec.Signatorys_Email__c!=oldMap.get(rec.id).Signatorys_Email__c || rec.Signatory_s_Name__c!=oldMap.get(rec.id).Signatory_s_Name__c){
                records.add(rec);
            }
        }
           
        if(records.size()>0){
            Map<Id,Apttus__APTS_Agreement__c> mapIdWithRecp = new Map<Id,Apttus__APTS_Agreement__c>([Select id,(Select id, Apttus_DocuApi__SigningOrder__c,Apttus_DocuApi__FirstName__c,
                                                                                                                Apttus_DocuApi__LastName__c,Apttus_DocuApi__Email__c from 
                                                                                                                Apttus_CMDSign__DocuSignDefaultRecipients2__r where Apttus_DocuApi__SigningOrder__c=1 limit 1)
                                                                                                     from Apttus__APTS_Agreement__c where Id IN: records]);
            for(Apttus__APTS_Agreement__c rec: records){
                if(rec.Signatorys_Email__c!=null && rec.Signatory_s_Name__c!=null && mapIdWithRecp.get(rec.id).Apttus_CMDSign__DocuSignDefaultRecipients2__r.size()>0 &&
                   (rec.Signatorys_Email__c!=oldMap.get(rec.id).Signatorys_Email__c || rec.Signatory_s_Name__c!=oldMap.get(rec.id).Signatory_s_Name__c )){
                       if (rec.Signatory_s_Name__c.contains(' ')) {
                           mapIdWithRecp.get(rec.id).Apttus_CMDSign__DocuSignDefaultRecipients2__r[0].Apttus_DocuApi__FirstName__c = rec.Signatory_s_Name__c.Substring(0,rec.Signatory_s_Name__c.indexOf(' '));
                           mapIdWithRecp.get(rec.id).Apttus_CMDSign__DocuSignDefaultRecipients2__r[0].Apttus_DocuApi__LastName__c = rec.Signatory_s_Name__c.Substring(rec.Signatory_s_Name__c.indexOf(' '),rec.Signatory_s_Name__c.length());
                       }else{
                           mapIdWithRecp.get(rec.id).Apttus_CMDSign__DocuSignDefaultRecipients2__r[0].Apttus_DocuApi__FirstName__c = rec.Signatory_s_Name__c;
                           mapIdWithRecp.get(rec.id).Apttus_CMDSign__DocuSignDefaultRecipients2__r[0].Apttus_DocuApi__LastName__c = null;
                       }
                       mapIdWithRecp.get(rec.id).Apttus_CMDSign__DocuSignDefaultRecipients2__r[0].Apttus_DocuApi__Email__c = rec.Signatorys_Email__c;
                       recipients.add(mapIdWithRecp.get(rec.id).Apttus_CMDSign__DocuSignDefaultRecipients2__r[0]);
                   }
            }
        }
        if(recipients.size()!=0){
            database.update(recipients, false);
        }
    }
}