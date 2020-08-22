trigger CommitScheduleTrigger on Commit_Schedule__c (before insert, before update, after insert, after update) {
    public static Map<String, String> SKUIdMapping{
        get{
            if(SKUIdMapping == null){
                skuIdMapping = new Map<String, String>();
                for(Product_Min_Commit_Mapping__mdt mapping: [SELECT Agreement_Field__c, MasterLabel, SKU_ID__c FROM Product_Min_Commit_Mapping__mdt]){SKUIdMapping.put(mapping.MasterLabel, mapping.SKU_ID__c);if(AgreementFieldMapping == null) AgreementFieldMapping = new Map<String, String>();AgreementFieldMapping.put(mapping.MasterLabel, mapping.Agreement_Field__c);
                }
            }
            return SKUIdMapping;
        }
        set;
    }
    public static Map<String, String> AgreementFieldMapping {get; set;}
    if(trigger.isBefore){
        for(Commit_Schedule__c schedule: trigger.new){
            if(schedule.Product_Group__c != null){String skuId = SKUIdMapping.get(schedule.Product_Group__c);schedule.Product_SKU_Group_Key__c = skuId;}
        }

    }
    else if(trigger.isAfter){
        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<String, String> idMapping = SKUIdMapping; 
        Set<Id> agreementIds = new Set<Id>();
        for(Commit_Schedule__c schedule: trigger.new){
            agreementIds.add(schedule.Agreement__c);
        }
        
        for(Commit_Schedule__c schedule: [SELECT Product_Group__c, Agreement__c, Commit_Amount__c FROM Commit_Schedule__c WHERE Agreement__c =: agreementIds AND RecordType.DeveloperName = 'Product_Commit']){
            Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Id = schedule.Agreement__c);if(agreementMap.containsKey(schedule.Agreement__c)){agreement = agreementMap.get(schedule.Agreement__c);}String agreementField = AgreementFieldMapping.get(schedule.Product_Group__c);
            if(agreementField != null){Decimal existingField = agreement.get(agreementField) == null ? 0 : (Decimal) agreement.get(agreementField);existingField += schedule.Commit_Amount__c;agreement.put(agreementField, existingField);}
            agreementMap.put(schedule.Agreement__c, agreement);
        }
        
        for(Apttus__APTS_Agreement__c agreement: agreementMap.values()){for(String agreementField: AgreementFieldMapping.values()){if(agreement.get(agreementField) == null || agreement.get(agreementField) == 0){agreement.put(agreementField, null); }}}
        
        update agreementMap.values();
    }
}