global class BatchReassignAccounts implements Database.Batchable<SObject>, Schedulable{
   global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchReassignAccounts());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        String userIdString = Account_Reassignment_User__c.getOrgDefaults().Current_User_ID__c;
        Set<Id> userIds = new Set<Id>();
        if(userIdString != null){
            for(Id userId: userIdString.split(',')){
                userIds.add(userId);
            }
        }
        return Database.getQueryLocator('SELECT SFDC_Country__c, SFDC_ZipCode__c, SFDC_State__c, OwnerId, Total_Amortized_Twilio_Usage_This_Month__c, Total_Amortized_Twilio_Usage_Last_Month__c, Average_Amortized_Usage_Last_3_Months__c FROM Account WHERE OwnerId =: userIds');
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accounts){
        AccountReassignmentServices.reassignOwner(accounts);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}