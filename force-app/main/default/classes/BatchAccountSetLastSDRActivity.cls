global class BatchAccountSetLastSDRActivity implements Database.Batchable<sObject> {

    global Database.querylocator start(Database.BatchableContext BC) {
        // Generate a list of records to batch process
        return Database.getQueryLocator([
            SELECT Id, Last_SDR_Activity_Lookup__c, (
                SELECT CreatedDate, OwnerId, Owner.IsActive, SDR_Assigned__c
                FROM OpenActivities
                WHERE Owner.UserRole.Name LIKE '%SDR%'
                OR Owner.UserRole.Name LIKE '%EMEA BDR%'
                OR Owner.UserRole.Name LIKE '%APAC BDR%'
                ORDER BY CreatedDate desc LIMIT 1
            ), (
                SELECT CreatedDate, OwnerId, Owner.IsActive, SDR_Assigned__c
                FROM ActivityHistories
                WHERE Owner.UserRole.Name LIKE '%SDR%'
                OR Owner.UserRole.Name LIKE '%EMEA BDR%'
                OR Owner.UserRole.Name LIKE '%APAC BDR%'
                ORDER BY CreatedDate desc LIMIT 1
            )
            FROM Account
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Account> accounts = new List<Account>();

        for (sObject s : scope) {
            Account a = (Account)s;
            accounts.add(a);
        }
        
        AccountActivityHandler.setLastSDRActivity(accounts);
    }
    
    global void finish(Database.BatchableContext BC) {
        // Actions to perform when batch processing is finished
    }
}