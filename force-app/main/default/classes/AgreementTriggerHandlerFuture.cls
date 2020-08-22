public class AgreementTriggerHandlerFuture {
    
    @future
    public static void agreementFutureOnInsert(Set<Id> theagrmntIds) {
        List<Apttus__APTS_Agreement__c> theNewAgrementList = getNewAgreementList(theagrmntIds);
        
        AgreementDocuSignerTriggerHandler.afterInsert(theNewAgrementList);
        List< Apttus_Proposal__Proposal__c> quotes = new List< Apttus_Proposal__Proposal__c>();
        for(Apttus__APTS_Agreement__c agreement: theNewAgrementList){
            if(agreement.Apttus_QPComply__RelatedProposalId__c != null && agreement.Id != null) {
                quotes.add(new Apttus_Proposal__Proposal__c(Id = agreement.Apttus_QPComply__RelatedProposalId__c, Related_Order_Form__c = agreement.Id));
            }
        }
        update quotes;
        
        APTS_Agreement_Trigger_Handler.updateSingleBITiersOnInsert(theNewAgrementList);
        APTS_Agreement_Trigger_Handler.UpdateRelatedAccounts(theNewAgrementList);
        AgreementHandlerForAfterTrigger.afterInsertOrUpdateTrigger(theNewAgrementList, null);
        AgreementHandlerForAfterTrigger.processBuilderIntoCodeForAfterEvent(theNewAgrementList, null);
    }
    
    @future
    public static void agreementFutureOnUpdate(Set<Id> theagrmntIds, String theOldAgrmnt, Boolean isRunOnce) {
        Map<Id, Apttus__APTS_Agreement__c> theAgrmntOldMap = (Map<Id, Apttus__APTS_Agreement__c>)Json.deserialize(theOldAgrmnt,Map<ID, Apttus__APTS_Agreement__c>.class);
        List<Apttus__APTS_Agreement__c> theNewAgrmntList = getNewAgreementList(theagrmntIds);
        Map<Id, Apttus__APTS_Agreement__c> theAgmntNewMap = new Map<Id, Apttus__APTS_Agreement__c>(theNewAgrmntList);
        if(!isRunOnce){
            APTS_Agreement_Trigger_Handler.agreementOpptyMapping(theNewAgrmntList, theAgrmntOldMap);
            APTS_Agreement_Trigger_Handler.processAfterUpdate (theAgrmntOldMap, theAgmntNewMap);
            AgreementDocuSignerTriggerHandler.afterUpdate(theNewAgrmntList, theAgrmntOldMap);
            APTS_Agreement_Trigger_Handler.UpdateRelatedAccounts(theNewAgrmntList);
            AgreementHandlerForAfterTrigger.afterInsertOrUpdateTrigger(theNewAgrmntList, theAgrmntOldMap);
            AgreementHandlerForAfterTrigger.processBuilderIntoCodeForAfterEvent(theNewAgrmntList, theAgrmntOldMap);
        }else{
            APTS_Agreement_Trigger_Handler.updateSingleBITiersOnUpdate(theNewAgrmntList, theAgrmntOldMap, theAgmntNewMap);
            APTS_Agreement_Trigger_Handler.processAgreementActivation(theNewAgrmntList, theAgrmntOldMap, theAgmntNewMap);  
        }
    }
    
    @future
    public static void agreementFutureOnDelete(String thenewAgrmnt) {
        List<Apttus__APTS_Agreement__c> theNewAgrmntList = (List<Apttus__APTS_Agreement__c>)Json.deserialize(thenewAgrmnt,List<Apttus__APTS_Agreement__c>.class);
        APTS_Agreement_Trigger_Handler.UpdateRelatedAccounts(theNewAgrmntList);
    }  
    
    public static List<Apttus__APTS_Agreement__c> getNewAgreementList(Set<Id> theIds) {
        Map<String, Schema.SObjectField> mapObjField = Apttus__APTS_Agreement__c.sObjectType.getDescribe().fields.getMap();
        
        String strfieldName = '';
        
        for(Schema.SObjectField field : mapObjField.Values()) {
            Schema.DescribeFieldResult fieldRes = field.getDescribe();
            if(fieldRes.getName() != 'MasterRecordId'){
                strfieldName += fieldRes.getName() + ',';
            }
        }
        
        strfieldName = strfieldName.substring(0, strfieldName.length()-1);
        List<Apttus__APTS_Agreement__c> theNewAgrementList = Database.query('select ' + strfieldName + ' from Apttus__APTS_Agreement__c WHERE Id IN: theIds');
        return theNewAgrementList;
    }
    
}