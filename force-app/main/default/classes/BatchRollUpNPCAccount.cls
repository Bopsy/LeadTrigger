global class BatchRollUpNPCAccount implements Database.Batchable<SObject>, Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchRollUpNPCAccount());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Account__c, NPC_Date_5__c, NPC_Date_50__c, NPC_Date_500__c, Account_SID_Created_Date__c FROM Account_SID__c WHERE Account__c != null]);
    }
    
    global void execute(Database.BatchableContext bc, List<Account_SID__c> accountSids){
        BatchAccountSIDServices.rollupNPC(accountSids);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}