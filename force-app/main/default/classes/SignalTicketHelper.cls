/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name  SignalTicketHelper
*
* @description  Helper class for Signal Ticket attribution functionality.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	<jayu@twilio.com>
* @modifiedBy     Jason Yu  <jayu@twilio.com>
* @version        1.0
* @created        2020-01-03
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*
**/
public with sharing class SignalTicketHelper {
    public static void createSignalTicketAttribution(List<Apttus__APTS_Agreement__c> agrsForReview){
        //Get a set of the Signal Ticket BI SFDC Ids from a custom setting for filtering purposes.
        Set<String> validBISFDCIds = Signal_Ticket_Billable_Item_SFDC_ID__c.getAll().keySet();
        
        //Call method to return a dynamic string query powered by a custom setting.
        String agreementQuery = getAgreementQueryString();
        
        List<Apttus__APTS_Agreement__c> agrsForQuery = Database.query(agreementQuery);
        Map<Apttus__APTS_Agreement__c, Decimal> agreementToQuantityMap = new Map<Apttus__APTS_Agreement__c, Decimal>();
        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
        agreementMap.putAll(agrsForQuery);
        
        //Return a map of Agreements with their values as the quantity sum of Signal Ticket.
        agreementToQuantityMap = getAgreementToQuantityMap(agrsForQuery);
        
        if(!agreementToQuantityMap.keySet().isEmpty()){
            List<Signal_Ticket__c> signalTicketsForInsert = new List<Signal_Ticket__c>();
            signalTicketsForInsert = getSignalTicketsForInsert(agreementToQuantityMap);
            if(!signalTicketsForInsert.isEmpty()){
                insert signalTicketsForInsert;
                
                List<Signal_Ticket_Split__c> signalTicketSplitsForInsert = new List<Signal_Ticket_Split__c>();
                signalTicketSplitsForInsert = getSignalTicketSplitsForInsert(signalTicketsForInsert, agreementMap);
                insert signalTicketSplitsForInsert;
            }
        }
        
    }
    
    //Method to get a string map of Signal Ticket Fields with the Source Field as the key.
    private static Map<String,String> getSignalTicketFieldMapping() {
		Map<String,String> fields = new Map<String,String>();
        for (Signal_Ticket_Attribution_Field_Mapping__c setting : Signal_Ticket_Attribution_Field_Mapping__c.getAll().values()) {
            if(setting.Source_Field_API_Name__c != null && setting.Signal_Ticket_API_Name__c != null){
            	fields.put(setting.Source_Field_API_Name__c, setting.Signal_Ticket_API_Name__c);    
            }
        }
		return fields;
	}
    
    //Method to get a string map of Primary Signal Ticket Split Fields with the Source Field as the key.
    private static Map<String,String> getPrimarySignalTicketSplitFieldMapping() {
		Map<String,String> fields = new Map<String,String>();
        for (Signal_Ticket_Attribution_Field_Mapping__c setting : Signal_Ticket_Attribution_Field_Mapping__c.getAll().values()) {
            if(setting.Signal_Ticket_Split_Type__c == 'Primary'){
            	if(setting.Source_Field_API_Name__c != null && setting.Signal_Ticket_Split_API_Name__c != null){
                    fields.put(setting.Source_Field_API_Name__c, setting.Signal_Ticket_Split_API_Name__c);    
                }    
            }
        }
		return fields;
	}
    
    //Method to get a string map of Secondary Signal Ticket Split Fields with the Source Field as the key.
    private static Map<String,String> getSecondarySignalTicketSplitFieldMapping() {
		Map<String,String> fields = new Map<String,String>();
        for (Signal_Ticket_Attribution_Field_Mapping__c setting : Signal_Ticket_Attribution_Field_Mapping__c.getAll().values()) {
            if(setting.Signal_Ticket_Split_Type__c == 'Secondary'){
            	if(setting.Source_Field_API_Name__c != null && setting.Signal_Ticket_Split_API_Name__c != null){
                    fields.put(setting.Source_Field_API_Name__c, setting.Signal_Ticket_Split_API_Name__c);    
                }    
            }
        }
		return fields;
	}
    
    private static Set<String> getQueryFields(){
        Set<String> fieldSet = new Set<String>();
        for (Signal_Ticket_Attribution_Field_Mapping__c setting : Signal_Ticket_Attribution_Field_Mapping__c.getAll().values()) {
            if(setting.Source_Field_API_Name__c != null){
                fieldSet.add(setting.Source_Field_API_Name__c);
            }
        }
        return fieldSet;
    }
    
    //Method that contructs and returns a string query based on values from a custom setting.
    private static String getAgreementQueryString(){
        String queryString = '';
        String agrFields = String.join(new List<String>(getQueryFields()), ',');
        
        queryString = 'SELECT ' + (String.isBlank(agrFields) ? 'Id' : agrFields) + ',' +
                            '(SELECT Id, ' +
                            ' Quantity__c, ' + 
                            ' Billable_Item__c, ' +
                            ' Billable_Item_Name__c, ' +
                            ' BI_SID__c ' +
                            ' FROM Single_BI_Discounts__r ' +
                            ' WHERE Agreement__c IN :agrsForReview ' +
                            '		AND Billable_Item__c IN :validBISFDCIds), ' +
            				'(SELECT Id, Order_Form__c FROM Signal_Tickets__r)' +
                      'FROM Apttus__APTS_Agreement__c ' + 
                      'WHERE ID IN :agrsForReview';
        
        return queryString;
    }
    
    //Method that returns a map of Agreements with their values as the quantity sum of Signal Ticket
    //from the Single BI Discounts.
    private static Map<Apttus__APTS_Agreement__c, Decimal> getAgreementToQuantityMap(List<Apttus__APTS_Agreement__c> agrsForReview){
        Map<Apttus__APTS_Agreement__c, Decimal> agreementToQuantityMap = new Map<Apttus__APTS_Agreement__c, Decimal>();
        for(Apttus__APTS_Agreement__c agrRec : agrsForReview){
            if(agrRec.Signal_Tickets__r.isEmpty()){
                Decimal quantity = 0;
                for(Single_BI_Discount__c singleBIDiscount : agrRec.Single_BI_Discounts__r){
                    if(singleBIDiscount.Quantity__c != null){
                        quantity += singleBIDiscount.Quantity__c;
                    }
                }
                if(quantity > 0){
                    agreementToQuantityMap.put(agrRec, quantity);
                }    
            }
        }
        return agreementToQuantityMap;
    }
    
    //Method creates and returns a new list of Signal Tickets.
    private static List<Signal_Ticket__c> getSignalTicketsForInsert(Map<Apttus__APTS_Agreement__c, Decimal> agreementToQuantityMap){
        Date todaysDate = Date.today();
        List<Signal_Ticket__c> signalTickets = new List<Signal_Ticket__c>();
        Map<String, String> fieldMap = getSignalTicketFieldMapping();
        
        for(Apttus__APTS_Agreement__c agrRec : agreementToQuantityMap.keySet()){
            Signal_Ticket__c sigTick = new Signal_Ticket__c();
            
            for(String agrFieldName : fieldMap.keySet()){
                String signalTicketFieldName = fieldMap.get(agrFieldName);
                sigTick.put(signalTicketFieldName, lookup(agrRec, agrFieldName));
            }
            
            //can this be better?
            sigTick.put('Date_Sold__c', todaysDate);
            sigTick.put('Quantity__c', agreementToQuantityMap.get(agrRec));
            sigTick.put('Source__c', 'Order Form');
            signalTickets.add(sigTick);
        }
        
        return signalTickets;
    }
    
    //Method creates and returns a new list of Signal Ticket Splits.
    private static List<Signal_Ticket_Split__c> getSignalTicketSplitsForInsert(List<Signal_Ticket__c> signalTickets, Map<Id, Apttus__APTS_Agreement__c> agreementMap){
        Date todaysDate = Date.today();
        String managerTicketCredit = 'Sales_Manager_Ticket_Credit__c';
        List<Signal_Ticket_Split__c> signalTicketSplits = new List<Signal_Ticket_Split__c>();
        Map<String, String> primarySplitFieldMap = getPrimarySignalTicketSplitFieldMapping();
        
        for(Signal_Ticket__c signalTicket : signalTickets){
            Apttus__APTS_Agreement__c tempAgreement = new Apttus__APTS_Agreement__c();
            tempAgreement = agreementMap.get(signalTicket.Order_Form__c);
            Id signalTicketId = signalTicket.Id;
            String splitAttributionSource = 'Order Form Sale';
            String ticketSource = 'Order Form';
            
            Signal_Ticket_Split__c primarySplit = new Signal_Ticket_Split__c();
            for(String agrFieldName : primarySplitFieldMap.keySet()){
                String signalTicketSplitFieldName = primarySplitFieldMap.get(agrFieldName);
                primarySplit.put(signalTicketSplitFieldName, lookup(tempAgreement, agrFieldName));
            }
            primarySplit.put('Signal_Ticket__c', signalTicketId);
            primarySplit.put('Split_Attribution_Source__c', splitAttributionSource);
            primarySplit.put('Ticket_Source__c', ticketSource);
            signalTicketSplits.add(primarySplit);
            
            if(tempAgreement.Related_Opportunity_APTS__r.OwnerId != tempAgreement.Apttus__Account__r.OwnerId){
                Map<String, String> secondarySplitFieldMap = getSecondarySignalTicketSplitFieldMapping();
                Signal_Ticket_Split__c secondarySplit = new Signal_Ticket_Split__c();
                for(String agrFieldName : secondarySplitFieldMap.keySet()){
                    String signalTicketSplitFieldName = secondarySplitFieldMap.get(agrFieldName);
                    secondarySplit.put(signalTicketSplitFieldName, lookup(tempAgreement, agrFieldName));
                }
                secondarySplit.put('Signal_Ticket__c', signalTicketId);
                secondarySplit.put('Split_Attribution_Source__c', splitAttributionSource);
                secondarySplit.put('Ticket_Source__c', ticketSource);
                
                if(primarySplit.get(managerTicketCredit) == secondarySplit.get(managerTicketCredit)){
                    secondarySplit.put(managerTicketCredit, null);
                }
                
                signalTicketSplits.add(secondarySplit);
            }
            
            
        }
        
        return signalTicketSplits;
    }
    
    // Returns the given object field value for the SOQL queried record
	// Traverses the related sObjects returned by the query to get the field value
	private static Object lookup(sObject obj, String fieldName) {
		sObject currentSObject = obj;
		String fieldPath = fieldName;
		
		while (fieldPath.contains('.')) {
			List<String> pathPartList = fieldPath.split ('[.]', 2);
			
			currentSObject = (sObject) currentSObject.getSobject(pathPartList[0]);
			fieldPath = pathPartList[1];
		}
		
		return currentSObject.get(fieldPath);
	}
    
}