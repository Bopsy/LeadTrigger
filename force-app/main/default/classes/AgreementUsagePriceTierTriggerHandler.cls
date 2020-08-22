public class AgreementUsagePriceTierTriggerHandler {
    
    //Added by Mia on 11/18/19
    //count how many usage price tier records have Product_Min_Commit_Group__c ='Twilio SendGrid'
    public static void countSendGridTier(List<Apttus_CMConfig__AgreementUsagePriceTier__c> newTierList){
        
        Map<String, Decimal> filterTierMap = new Map<String, Decimal>();
        
        for(Apttus_CMConfig__AgreementUsagePriceTier__c tier: newTierList){
            if(!filterTierMap.containsKey(tier.AgreementId__c)) filterTierMap.put(tier.AgreementId__c, 0);
        }
        
        List<Apttus_CMConfig__AgreementUsagePriceTier__c> databaseRec = [SELECT AgreementId__c 
                                                                         FROM Apttus_CMConfig__AgreementUsagePriceTier__c 
                                                                         WHERE Product_Min_Commit_Group__c = 'Twilio SendGrid' 
                                                                         AND AgreementID__c in: filterTierMap.keySet()];
        
        for(Apttus_CMConfig__AgreementUsagePriceTier__c tier: databaseRec) {
           filterTierMap.put(tier.AgreementID__c, filterTierMap.get(tier.AgreementID__c) + 1);
        }
        
        List<Apttus__APTS_Agreement__c> updateAgreements = new List<Apttus__APTS_Agreement__c>();
        
        for(Id agreementId: filterTierMap.keySet()){
            updateAgreements.add(new Apttus__APTS_Agreement__c(Id = agreementId, Number_of_SendGrid_Tiers__c = filterTierMap.get(agreementId) == null ? 0 :  filterTierMap.get(agreementId)));
        }
        
        update updateAgreements;
        
        
    }
}