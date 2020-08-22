global class BatchGenerateDocusignSigner implements Database.Batchable<sObject>{
    global Database.querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT RecordTypeId, Id, (SELECT Id FROM Apttus_CMDSign__DocuSignDefaultRecipients2__r) FROM Apttus__APTS_Agreement__c]);
    }
    
    global void execute(Database.BatchableContext BC, List<Apttus__APTS_Agreement__c> scope) {
        List<Apttus__APTS_Agreement__c> filteredRecords = new List<Apttus__APTS_Agreement__c>();
        
        for(Apttus__APTS_Agreement__c agreement: scope){
            if(agreement.Apttus_CMDSign__DocuSignDefaultRecipients2__r == null || agreement.Apttus_CMDSign__DocuSignDefaultRecipients2__r.isEmpty()){
                filteredRecords.add(agreement);
            }
        }
        AgreementDocuSignerTriggerHandler.afterInsert(filteredRecords);
    }
    
    global void finish(Database.BatchableContext BC) {
     
    }
}