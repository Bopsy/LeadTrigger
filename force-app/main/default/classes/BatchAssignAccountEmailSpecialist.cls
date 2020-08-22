global class BatchAssignAccountEmailSpecialist implements Database.Batchable<SObject>{
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT FY_16_Role_Team__c FROM Account WHERE SendGrid_Specialist__c = null AND FY_16_Role_Team__c != null]);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accounts){
        for(Account acc: accounts){
            Id ownerId = SendGridOwnerServices.getSendGridOwner(acc);
            if(ownerId != null) acc.SendGrid_Specialist__c = ownerId;
        }
        update accounts;
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}