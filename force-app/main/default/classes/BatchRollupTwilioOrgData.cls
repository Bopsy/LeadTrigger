global class BatchRollupTwilioOrgData implements Database.Batchable<SObject>, Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchRollupTwilioOrgData());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accounts){
        BatchAccountSIDServices.rollupTwilioOrgData(accounts);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}