public without sharing class PartnerSettingsController {

    @AuraEnabled
    public static String initializeFormSettings(){

        Map<String,String> leadFormSettings = new map<String,String>();

        Partner_Lead_Form_Settings__mdt[] partnerLeadSettings = [SELECT CampaignId__c, Partner_Queue_Name__c FROM Partner_Lead_Form_Settings__mdt limit 1];

        if(partnerLeadSettings.size() > 0){
            List<Group> partnerLeadQueue = [select Id from Group where DeveloperName =: partnerLeadSettings[0].Partner_Queue_Name__c and Type = 'Queue' limit 1];
            if(partnerLeadQueue.size() > 0) {
                leadFormSettings.put('queueId',partnerLeadQueue[0].Id);
            }
        }

        RecordType[] lstRecordTypes = [Select Id FROM RecordType WHERE SobjectType='Lead' and DeveloperName ='Become_A_Partner'];

        if(lstRecordTypes.size() >0 ){
            leadFormSettings.put('recordTypeId',lstRecordTypes[0].Id);
        }

        return JSON.serialize(leadFormSettings);
    }

    @AuraEnabled
    public static String createLead(String leadRec){

        String leadId ;

        try{
            Lead leadRecord = (Lead)JSON.deserialize(leadRec, Lead.class);
            insert leadRecord;
            Partner_Lead_Form_Settings__mdt[] partnerLeadSettings = [SELECT CampaignId__c, Partner_Queue_Name__c FROM Partner_Lead_Form_Settings__mdt limit 1];
            if(partnerLeadSettings.size() > 0){
                list<Campaign> lstCampaign = [Select Id from Campaign WHERE ID=:partnerLeadSettings[0].CampaignId__c];
                if(lstCampaign.size() >0 ){
                    CampaignMember cm = new CampaignMember();
                    cm.LeadId = leadRecord.Id;
                    cm.CampaignId = partnerLeadSettings[0].CampaignId__c;
                    insert cm;
                }
            }
            leadId = leadRecord.Id;
        }catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return leadId;
    }
}