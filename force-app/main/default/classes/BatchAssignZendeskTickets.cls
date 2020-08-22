global class BatchAssignZendeskTickets implements Database.Batchable<SObject>, Schedulable{
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchAssignZendeskTickets(), 2000);
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id, Email_Domain__c FROM Twilio_Zendesk_Ticket__c');
    }
    
    global void execute(Database.BatchableContext bc, List<Twilio_Zendesk_Ticket__c> tickets){
        TwilioZendeskTicketHandler.setAccount(tickets);
        Database.update(tickets);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}