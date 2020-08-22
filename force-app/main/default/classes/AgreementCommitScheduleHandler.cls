public without sharing class AgreementCommitScheduleHandler {
    
    public static Map<String, Integer> commitMap = new Map<String, Integer>{
        'Monthly' => 1,
        'Quarterly' => 3,
        'Semi-Annual' => 6,
        'Annual' => 12
    };
    public static Map<String, String> AgreementFieldMapping {
        get{
            if(AgreementFieldMapping == null){
                AgreementFieldMapping = new Map<String, String>();
                for(Product_Min_Commit_Mapping__mdt mapping: [SELECT Agreement_Field__c, MasterLabel, SKU_ID__c FROM Product_Min_Commit_Mapping__mdt]){
                    AgreementFieldMapping.put(mapping.MasterLabel, mapping.Agreement_Field__c);
                }
            }
            return AgreementFieldMapping;
        }
        set;
    }
    public static void afterInsert(List<Apttus__APTS_Agreement__c> records){
        
        List<Apttus__APTS_Agreement__c> filteredRec = new List<Apttus__APTS_Agreement__c>();
        
        for(Apttus__APTS_Agreement__c agreement: records){
            if(agreement.Commit_Frequency__c!='No Commit - PAYG' && agreement.Commit_Frequency__c!='No Commit - POC' && agreement.Commit_Frequency__c!='Existing Commit'){
                if(agreement.Commit_Frequency__c != null && agreement.Total_Committed_Revenue_Input__c != null && ((agreement.Apttus__Parent_Agreement__c==null && agreement.Agreement_History__c=='Supplements Existing') || agreement.Agreement_History__c!='Supplements Existing')){
                    filteredRec.add(agreement);
                }
            }
        }
        
        createCommitSchedules(filteredRec, new Set<String>());
    }
    
    public static void beforeUpdate(List<Apttus__APTS_Agreement__c> records, Map<Id, Apttus__APTS_Agreement__c> oldMap){
        for(Apttus__APTS_Agreement__c agreement :records){
            Apttus__APTS_Agreement__c oldRec = oldMap.get(agreement.Id);
            if(agreement.Commit_Type__c != oldRec.Commit_Type__c && oldRec.Commit_Type__c == 'Product'){
                for(String agreementField : AgreementFieldMapping.values()){
                    agreement.put(agreementField, null);
                }
            }
            if(agreement.Apttus__Parent_Agreement__c!=null && agreement.Agreement_History__c=='Supplements Existing'){
                agreement.Commit_Start_Month__c = null;
            }
        }
    }
    
    public static void afterUpdate(List<Apttus__APTS_Agreement__c> records, Map<Id, Apttus__APTS_Agreement__c> oldMap){
        
        List<Apttus__APTS_Agreement__c> filteredRec = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> filteredToDelete = new List<Apttus__APTS_Agreement__c>();
        
        for(Apttus__APTS_Agreement__c agreement :records){
            Apttus__APTS_Agreement__c oldRec = oldMap.get(agreement.Id);
            if(agreement.Commit_Frequency__c!='No Commit - PAYG' && agreement.Commit_Frequency__c!='No Commit - POC' && agreement.Commit_Frequency__c!='Existing Commit'){
                if(agreement.Commit_Frequency__c != null && agreement.Total_Committed_Revenue_Input__c != null && ((agreement.Apttus__Parent_Agreement__c==null && agreement.Agreement_History__c=='Supplements Existing') || agreement.Agreement_History__c!='Supplements Existing') &&
                   ((oldRec.Total_Committed_Revenue_Input__c == null && agreement.Total_Committed_Revenue_Input__c != null) || 
                     (agreement.Commit_Type__c != oldRec.Commit_Type__c) || (agreement.Commit_Start_Month__c != oldRec.Commit_Start_Month__c) || 
                     (agreement.Commit_Frequency__c != oldRec.Commit_Frequency__c)  || (agreement.Term_Range__c != oldRec.Term_Range__c))){
                    filteredRec.add(agreement);
                }
            }
        }
        
        List<Commit_Schedule__c> deleteSchedules = [SELECT Id, Commit_Frequency__c, Agreement__r.Commit_Frequency__c, Agreement__r.Commit_Type__c, Product_Group__c,agreement__r.Apttus__Parent_Agreement__c,agreement__r.Agreement_History__c FROM Commit_Schedule__c WHERE Agreement__c =: filteredRec];
        Set<String> groupNames = new Set<String>();
        for(Integer i = deleteSchedules.size() - 1; i >= 0; i--){
            if(deleteSchedules[i].Agreement__r.Commit_Type__c == 'Product' && deleteSchedules[i].Product_Group__c != null && deleteSchedules[i].Commit_Frequency__c == deleteSchedules[i].Agreement__r.Commit_Frequency__c )
            {
                groupNames.add(deleteSchedules[i].Product_Group__c);
                //deleteSchedules.remove(i);
            }
        }
        delete deleteSchedules;
        
        createCommitSchedules(filteredRec, groupNames);
        
        //Added by Amrutha - delete commit schedules if order form is of type 'Supplements Existing'
        for(Apttus__APTS_Agreement__c agreement :records){
            if((agreement.Apttus__Parent_Agreement__c!=null && agreement.Agreement_History__c=='Supplements Existing') || agreement.Commit_Frequency__c=='No Commit - PAYG' || agreement.Commit_Frequency__c=='No Commit - POC' || agreement.Commit_Frequency__c=='Existing Commit'){
                filteredToDelete.add(agreement);
            }
        }
        List<Commit_Schedule__c> deleteSchedulesSup = [SELECT Id, Commit_Frequency__c, Agreement__r.Commit_Frequency__c, Agreement__r.Commit_Type__c, Product_Group__c FROM Commit_Schedule__c WHERE Agreement__c =: filteredToDelete];
        delete deleteSchedulesSup;
    }
    
    public static void createCommitSchedules(List<Apttus__APTS_Agreement__c> agreements, Set<String> existingProductGroups){
        
        List<Commit_Schedule__c> schedules = new List<Commit_Schedule__c>();
        
        for(Apttus__APTS_Agreement__c agreement: agreements){
            if(agreement.Commit_Type__c != 'Product'){
                Date startDate = agreement.Commit_Start_Month__c == null ? Date.today().toStartOfMonth() : agreement.Commit_Start_Month__c.toStartOfMonth();
                Integer monthInterval = commitMap.get(agreement.Commit_Frequency__c);
                if(monthInterval == null) monthInterval = 1;
                Integer totalMonths = agreement.Term_Range__c == null ? 12 : Integer.valueOf(agreement.Term_Range__c);
                Date endDate = startDate.addMonths(monthInterval).addDays(-1);
                Decimal averageCommit = agreement.Total_Committed_Revenue_Input__c / totalMonths * monthInterval;
                
                for(Integer i = 0; i < totalMonths / monthInterval; i++){
                    schedules.add(new Commit_Schedule__c(
                        Agreement__c = agreement.Id,
                        Start_Date__c = startDate,
                        End_Date__c = endDate,
                        Commit_Frequency__c = agreement.Commit_Frequency__c,
                        Commit_Amount__c = averageCommit,
                        Last_Commit_Schedule__c = (i == totalMonths / monthInterval - 1),
                        Commit_Table_Row_OF_GENERATE__c = i == 0 ? 'Show Last' : 'Hide'
                    ));
                    
                    startDate = startDate.addMonths(monthInterval);
                    endDate = startDate.addMonths(monthInterval).addDays(-1);
                }
            }
            else{
                RecordType clientOnlyRecordType = [
                    SELECT Id FROM RecordType WHERE DeveloperName = 'Product_Commit'
                ];
                Id recordTypeId = (clientOnlyRecordType != null) ? clientOnlyRecordType.Id : null;
                for(String productName: AgreementFieldMapping.keySet()){
                    String agreementField = AgreementFieldMapping.get(productName);
                    Date startDate = agreement.Commit_Start_Month__c == null ? Date.today().toStartOfMonth() : agreement.Commit_Start_Month__c.toStartOfMonth();
                    Integer monthInterval = commitMap.get(agreement.Commit_Frequency__c);
                    if(monthInterval == null) monthInterval = 1;
                    Integer totalMonths = agreement.Term_Range__c == null ? 12 : Integer.valueOf(agreement.Term_Range__c);
                    Date endDate = startDate.addMonths(monthInterval).addDays(-1);
                    if(agreement.get(agreementField) != null && agreement.get(agreementField) != 0 && !existingProductGroups.contains(productName)){
                        Decimal averageCommit = (Decimal) agreement.get(agreementField) / totalMonths * monthInterval;
                        for(Integer i = 0; i < totalMonths / monthInterval; i++){
                            schedules.add(new Commit_Schedule__c(
                                Agreement__c = agreement.Id,
                                Start_Date__c = startDate,
                                End_Date__c = endDate,
                                Commit_Frequency__c = agreement.Commit_Frequency__c,
                                Commit_Amount__c =  averageCommit,
                                Commit_Ramp_Status__c = 'Ramp',
                                Commit_Table_Row_OF_GENERATE__c =  i == 0 ? 'Show Last' : 'Hide',
                                Product_Group__c = productName,
                                RecordTypeId = recordTypeId
                            ));
                            startDate = startDate.addMonths(monthInterval);
                            endDate = startDate.addMonths(monthInterval).addDays(-1);
                        }
                    }
                }
            }
        }
        
        insert schedules;
    }
}