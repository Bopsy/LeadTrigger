/******************************************
//Created By: Davis Dong
//Last Modified by: Gram Bischof {02/11/2019}
//Description: This class is aiming to roll up Amortized Usage to Account for current, previous, last 2 and last 3 months
//
*******************************************/
global class BatchCalculateAccountSIDUsage implements Database.Batchable<SObject>, Schedulable{
    
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCalculateAccountSIDUsage());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Account_SID__c WHERE SystemModStamp >= LAST_N_DAYS:1');
    }
    
    global void execute(Database.BatchableContext bc, List<Account_SID__c> accountSIDs){
        AccountUsageService.calculateUsage(accountSIDs);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}