global class BatchCreateSplits implements Database.Batchable<SObject>{
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Opportunity WHERE Solution_Sales_Specialist__c != null');
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> opportunities){
        OpportunityFSFSplitServices.createSplits(opportunities);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}