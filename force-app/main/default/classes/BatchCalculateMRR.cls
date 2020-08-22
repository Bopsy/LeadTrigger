global class BatchCalculateMRR implements Database.Batchable<SObject>, Schedulable{
    
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCalculateMRR());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        Date qualifiedDate = Date.newInstance(2017, 1, 1);
        return Database.getQueryLocator([SELECT New_Business_Account_SID_Lookup__c, New_Business_Account_SID_Added_Date__c FROM Opportunity WHERE CloseDate >= :qualifiedDate AND New_Business_Account_SID_Lookup__c != null]);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> opps){
        calculateMRR(opps);
    }
    
    global static void calculateMRR(List<Opportunity> opps){
        Map<Id, Id> oppToAccountSIDMap = new Map<Id, Id>();
        
        for(Opportunity opp: opps){
            oppToAccountSIDMap.put(opp.Id, opp.New_Business_Account_SID_Lookup__c);
        }
        
        List<Id> sidIDs = oppToAccountSIDMap.values();
        String queryString = 'SELECT Id, (SELECT ';
        
        Map<String, String> fieldToUsageFieldName = new Map<String, String>();
        for(AccountSID_to_SKU_Mappings__c setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
            if(setting.Usage_Field__c != null){
                queryString += setting.Usage_Field__c + ', ';
                fieldToUsageFieldName.put(setting.Account_SID_API_Name__c, setting.Usage_Field__c);
            }
        }
        
        queryString += 'Usage_Date__c FROM Twilio_Usages__r ORDER BY Usage_Date__c) FROM Account_SID__c WHERE Id =: sidIDs';
        
        List<Account_SID__c> sids = (List<Account_SID__c>) Database.query(queryString);
        
        Map<Id, Account_SID__c> accountSIDMap = new Map<Id, Account_SID__c>();
        
        for(Account_SID__c sid: sids){
            accountSIDMap.put(sid.Id, sid);
        }
        
        for(Opportunity opp: opps){
            
            Account_SID__c sid = accountSIDMap.get(oppToAccountSIDMap.get(opp.Id));
            Date startDate = opp.New_Business_Account_SID_Added_Date__c.toStartOfMonth();
            Set<Date> startDates = new Set<Date>{startDate.addMonths(-1), startDate.addMonths(-2), startDate.addMonths(-3), startDate.addMonths(-4), startDate.addMonths(-5), startDate.addMonths(-6)};
            Map<String, Decimal> oppFieldValue = new Map<String, Decimal>();
            
            for(String fieldName: fieldToUsageFieldName.keySet()){
                oppFieldValue.put(fieldName, 0);
            }
            
            if(sid != null && sid.Twilio_Usages__r != null && !sid.Twilio_Usages__r.isEmpty()){
                for(Twilio_Usage__c usage: sid.Twilio_Usages__r){
                    if(startDates.contains(usage.Usage_Date__c)){
                        for(String fieldName: oppFieldValue.keySet()){
                            String usageFieldName = fieldToUsageFieldName.get(fieldName);
                            Object result = usage.get(usageFieldName);
                            if(result != null){
                                Decimal numbers = (Decimal) result;
                                numbers += oppFieldValue.get(fieldName);
                                oppFieldValue.put(fieldName, numbers);
                            }
                        }
                    }    
                }
            }
            
            for(String fieldName: fieldToUsageFieldName.keySet()){
                Decimal result = oppFieldValue.get(fieldName);
                result = result / 6;
                opp.put(fieldName, result);
            }
            
        }
        Database.update(opps, false);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}