global class BatchReassignAccountSIDs implements Database.Batchable<SObject>, Schedulable{
   global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchReassignAccountSIDs(), 5);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Twilio_org_Pricing_Model__c, ISO_Country_Code__c, NPC_Date_5__c, Average_Amortized_Usage_Last_3_Months__c, Total_Amortized_Twilio_Usage_This_Month__c, Total_Amortized_Twilio_Usage_Last_Month__c, Lead__c, Email_Domain__c, Contact__c, Contact__r.AccountId 
                                         FROM Account_SID__c 
                                         WHERE ISO_Country_Code__c != null
                                         AND Account__c = null
                                         AND Parent_Account_SID__c = null
                                         AND (NPC_Date_5__c != null OR Average_Amortized_Usage_Last_3_Months__c >= 5 OR Total_Amortized_Twilio_Usage_This_Month__c >= 5 OR Total_Amortized_Twilio_Usage_Last_Month__c >= 5)]);
    }
    
    global void execute(Database.BatchableContext bc, List<Account_SID__c> accountSIDs){
        AccountReassignmentServices.reassignOwnerAccountSID(accountSIDs);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}