public class AgreementHandlerForAsync {
    public Static Id theNonDisAgreRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Non Disclosure Agreement').getRecordTypeId();
    public Static Id thePartnerAgrmntRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner Agreement').getRecordTypeId();
    public Static Id theOrderFormRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Order Form').getRecordTypeId();
    public Static Id thePartnershipRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partnership Agreement').getRecordTypeId();
    public Static Id theMergersRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Mergers and Acquisitions').getRecordTypeId();
    public Static Id theMasterSalesRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Sales Agreement').getRecordTypeId();
    public Static Id theAmendentRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Amendment').getRecordTypeId();
    public Static Id theCarrierContractRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Carrier Contract').getRecordTypeId();
    public Static Id thePartnerMSARecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Partner MSA').getRecordTypeId();
    public Static Id theAmendmentAddendumRecordId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Amendment/Addendum').getRecordTypeId();
    
    
    //PB field Update
    public static void processBuilderIntoCodeForBeforeEvent(List<Apttus__APTS_Agreement__c> theNewAgrementList, Map<Id,Apttus__APTS_Agreement__c> theOldAgrmntMap) {
        Set<Id> theParentAgrmntIds = new Set<Id>();
        Set<Id> theProposalIds = new Set<Id>();
        for(Apttus__APTS_Agreement__c theAgremnt : theNewAgrementList) {
            theParentAgrmntIds.add(theAgremnt.Apttus__Parent_Agreement__c);
            theProposalIds.add(theAgremnt.Apttus_QPComply__RelatedProposalId__c);
        }
        Map<Id,Apttus__APTS_Agreement__c> theParentAgrmntMap = new Map<Id,Apttus__APTS_Agreement__c>([SELECT Id, Underlying_Agreement__c, Total_Committed_Revenue_Input__c, Related_MSA__c, Prepay_Frequency__c, Prepayment_Amount_Input__c, Payment_Type__c, Notification_Days_Reqd_to_Change_Price__c FROM Apttus__APTS_Agreement__c WHERE Id IN : theParentAgrmntIds]);
        Map<Id,Apttus_Proposal__Proposal__c> theQuoteProposalMap = new Map<Id,Apttus_Proposal__Proposal__c>([SELECT Id, Parent_Agreement_Superseding__c FROM Apttus_Proposal__Proposal__c WHERE Id IN :theProposalIds]);
        for(Apttus__APTS_Agreement__c theAgremnt : theNewAgrementList) {
            
            //#PB 2 : Agreement update for Supplemental Agreements
            //Creteria 1: Supplement OF
            //Creteria 2: Amendment/Addendum
            if(theOldAgrmntMap == null && theAgremnt.Apttus__Parent_Agreement__c != null && theAgremnt.RecordTypeId == theOrderFormRecordId) {
                theAgremnt.Notification_Days_Reqd_to_Change_Price__c = theParentAgrmntMap.get(theAgremnt.Apttus__Parent_Agreement__c).Notification_Days_Reqd_to_Change_Price__c;
                theAgremnt.Payment_Type__c = theParentAgrmntMap.get(theAgremnt.Apttus__Parent_Agreement__c).Payment_Type__c;
                theAgremnt.Prepay_Frequency__c = theParentAgrmntMap.get(theAgremnt.Apttus__Parent_Agreement__c).Prepay_Frequency__c;
                theAgremnt.Prepayment_Amount_Input__c = theParentAgrmntMap.get(theAgremnt.Apttus__Parent_Agreement__c).Prepayment_Amount_Input__c;
                if(theParentAgrmntMap.get(theAgremnt.Apttus__Parent_Agreement__c).Related_MSA__c != null) {
                    theAgremnt.Related_MSA__c = theParentAgrmntMap.get(theAgremnt.Apttus__Parent_Agreement__c).Related_MSA__c;
                }
                theAgremnt.Total_Committed_Revenue_Input__c = theParentAgrmntMap.get(theAgremnt.Apttus__Parent_Agreement__c).Total_Committed_Revenue_Input__c;
                theAgremnt.Underlying_Agreement__c = theParentAgrmntMap.get(theAgremnt.Apttus__Parent_Agreement__c).Underlying_Agreement__c;
            }else if(theAgremnt.RecordTypeId == theAmendmentAddendumRecordId) {
                theAgremnt.Apttus__Term_Months__c = 0;
            }
            
            //#PB 3 : Agreement - Update parent agreement from quote/proposal
            //Creteria : If quote has parent agreement
            if(theOldAgrmntMap == null && theAgremnt.Apttus_QPComply__RelatedProposalId__c != null) {
                theAgremnt.Apttus__Parent_Agreement__c = theQuoteProposalMap.get(theAgremnt.Apttus_QPComply__RelatedProposalId__c).Parent_Agreement_Superseding__c;
            }
            
        }
    }
}