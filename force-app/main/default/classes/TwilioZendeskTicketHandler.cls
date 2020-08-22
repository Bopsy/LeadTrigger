//----------------------------------------------------------------------------------------------------------
// Utility class TwilioZendeskTicketHandler 
//----------------------------------------------------------------------------------------------------------
public without sharing class TwilioZendeskTicketHandler {

    // Set Twilio_Zendesk_Ticket__c.Account__c based on Twilio_Zendesk_Ticket__c.Email_Domain__c (formula field)
    // If Twilio Zendesk Ticket.Email_Domain__c matches Email_Domain__c.Unique_Name__c
    // set Twilio_Zendesk_Ticket__c.Account__c to Email_Domain__c.Account__c
    public static void setAccount(List<Twilio_Zendesk_Ticket__c> tickets) {
        if (!tickets.isEmpty()) {

            // Collect all of the email domains from the tickets
            Set<String> ticketDomains = new Set<String>();
            for (Twilio_Zendesk_Ticket__c t : tickets) {
                if (String.isNotBlank(t.Email_Domain__c))
                    ticketDomains.add(t.Email_Domain__c);
            }

            // Query matching email domains and load into a map with the domain as the key
            // and Account ID has the value
            Map<String,Id> domainToAccountIdMap = new Map<String,Id>();
            for (Email_Domain__c d : [
            	SELECT Unique_Name__c, Account__c
            	FROM Email_Domain__c
            	WHERE Unique_Name__c IN :ticketDomains
            	AND Approved__c = true
           	]) {
           		System.debug('MATCHING DOMAIN > ' + d);
                domainToAccountIdMap.put(d.Unique_Name__c, d.Account__c);
            }

            for (Twilio_Zendesk_Ticket__c t : tickets) {
            	t.Account__c = domainToAccountIdMap.get(t.Email_Domain__c);
            }
        }
    }
}