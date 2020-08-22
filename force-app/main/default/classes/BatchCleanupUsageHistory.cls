global class BatchCleanupUsageHistory implements Database.Batchable<SObject>, Schedulable{
    
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCleanupUsageHistory(), 2000);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        //Date t = Historical_Twilio_Usage__c.getInstance().Timestamp__c;
        Decimal year = Historical_Twilio_Usage__c.getInstance().Year__c;
        Decimal month = Historical_Twilio_Usage__c.getInstance().Month__c;
        //System.debug('Running BatchCleanupUsageHistory with Historical_Twilio_Usage__c.Timestamp__c = ' + t);
        String queryString = 'SELECT Id FROM Twilio_Usage__c WHERE Year__c = :year AND Month__c =:month ';
        if(Historical_Twilio_Usage__c.getInstance().Limit__c) queryString += 'LIMIT 50000';
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext bc, List<Twilio_Usage__c> usage){
        Database.DeleteResult[] drList = Database.delete(usage, false);
        
        // Iterate through each returned result
        for (Database.DeleteResult dr : drList) {
            if (!dr.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : dr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }

        Database.emptyRecycleBin(usage);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}