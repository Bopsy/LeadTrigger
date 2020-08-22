public with sharing class CountryPhoneNumTypeBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    //
    // The batch will query back all Country Phone Number Type.
    //
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Generate a list of records to batch process
        return Database.getQueryLocator(
            'SELECT Id, Country_Number_Status__c, Customer_Email__c, Contact__c, Country_Input__c, Type_Input__c, Capability_Input__c, Lead__c, MQL__c, Use_Case_Interest__c, CreatedById, Opportunity_Country__c, Country_Number_Type__c ' +
            'FROM Opportunity_Country_Number__c'
        );
    }

    //
    // Batch will first examine if data has Lead/Contact lookup, if not then try to match by the Customer Email (same function as in trigger)
    // If already has Lead/Contact, query related MQLs, populate the most recent modified and NOT Rejected MQL in Country Phone Number Type MQL lookup field
    // If already has MQL lookup field, and that MQL has a related Use Case Interest, put that Use Case Interest in the Use Case Interest lookup on the object.
    //
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,Opportunity_Country_Number__c> recMap = new Map<Id,Opportunity_Country_Number__c>();
        for (sObject s : scope) {
            Opportunity_Country_Number__c r = (Opportunity_Country_Number__c)s;
            recMap.put(r.Id, r);
        }
        CountryPhoneNumTypeHandler.linkToCountryPhoneNumberType(recMap.values(), true);
        System.debug('CountryPhoneNumTypeBatch LINKING RECORDS TO CONTACT/LEAD');
        
        Map<Id,Opportunity_Country_Number__c> recordsToUpdate = CountryPhoneNumTypeHandler.linkToContactOrLead(recMap.values());
        System.debug('CountryPhoneNumTypeBatch RECORDS TO UPDATE AFTER CONTACT/LEAD: ' + recordsToUpdate);

        Map<Id,Opportunity_Country_Number__c> resultsForRecMap;
        Map<Id,Opportunity_Country_Number__c> resultsForRecordToUpdate;
        
        // To find MQLs for all records that enough information records that are not to be updated after
        // the call to linkToContactOrLead() are processed separately than the ones that did.
        //    Remove Opportunity_Country_Number__c to be updated from the recMap
        //    Execute the linkToMQL for the recMap (without forceUpdate)
        //    Execute the linkToMQL for the recordsToUpdate (with forceUpdate since do not have CreatedBy and should be updated regardless)
        for (Id cId : recordsToUpdate.keySet()) {
            recMap.remove(cId);
        }

        System.debug('CountryPhoneNumTypeBatch LINKING RECORDS-NOT-TO-UPDATE RECORDS TO MQL');
        resultsForRecMap = CountryPhoneNumTypeHandler.linkToMQL(recMap.values());
        System.debug('CountryPhoneNumTypeBatch RECORDS TO UPDATE MQL: ' + resultsForRecMap);
        for (Opportunity_Country_Number__c r : resultsForRecMap.values()) {
            recordsToUpdate.put(r.Id, new Opportunity_Country_Number__c(
                Id = r.Id,
                MQL__c = r.MQL__c
            ));
        }

        System.debug('CountryPhoneNumTypeBatch LINKING RECORDS-TO-UPDATE RECORDS TO MQL');
        resultsForRecordToUpdate = CountryPhoneNumTypeHandler.linkToMQL(recordsToUpdate.values(), true);
        System.debug('CountryPhoneNumTypeBatch RECORDS TO UPDATE MQL: ' + resultsForRecordToUpdate);
        for (Opportunity_Country_Number__c r : resultsForRecordToUpdate.values()) {
            if (recordsToUpdate.containsKey(r.Id)) {
                Opportunity_Country_Number__c x = recordsToUpdate.get(r.Id);
                x.MQL__c = r.MQL__c;
                recordsToUpdate.put(r.Id, x);
            }
        }
        System.debug('CountryPhoneNumTypeBatch RECORDS TO UPDATE AFTER MQL: ' + recordsToUpdate);

        System.debug('CountryPhoneNumTypeBatch LINKING RECORDS TO USE CASE INTEREST');

        // To find UCIs for all records that enough information records that are not to be updated after
        // the call to linkToContactOrLead() are processed separately than the ones that did.
        //    Remove Opportunity_Country_Number__c to be updated from the recMap
        //    Execute the linkToUCI for the recMap (without forceUpdate)
        //    Execute the linkToUCI for the recordsToUpdate (with forceUpdate since do not have CreatedBy and should be updated regardless)
        for (Id cId : recordsToUpdate.keySet()) {
            recMap.remove(cId);
        }

        System.debug('CountryPhoneNumTypeBatch LINKING RECORDS-NOT-TO-UPDATE RECORDS TO USE CASE INTEREST');
        resultsForRecMap = CountryPhoneNumTypeHandler.linkToUCI(recMap.values());
        System.debug('CountryPhoneNumTypeBatch RECORDS TO UPDATE USE CASE INTEREST: ' + resultsForRecMap);
        for (Opportunity_Country_Number__c r : resultsForRecMap.values()) {
            recordsToUpdate.put(r.Id, new Opportunity_Country_Number__c(
                Id = r.Id,
                Use_Case_Interest__c = r.Use_Case_Interest__c
            ));
        }

        System.debug('CountryPhoneNumTypeBatch LINKING RECORDS-TO-UPDATE RECORDS TO USE CASE INTEREST');
        resultsForRecordToUpdate = CountryPhoneNumTypeHandler.linkToUCI(recordsToUpdate.values(), true);
        System.debug('CountryPhoneNumTypeBatch RECORDS TO UPDATE USE CASE INTEREST: ' + resultsForRecordToUpdate);
        for (Opportunity_Country_Number__c r : resultsForRecordToUpdate.values()) {
            if (recordsToUpdate.containsKey(r.Id)) {
                Opportunity_Country_Number__c x = recordsToUpdate.get(r.Id);
                x.Use_Case_Interest__c = r.Use_Case_Interest__c;
                recordsToUpdate.put(r.Id, x);
            }
        }
        System.debug('CountryPhoneNumTypeBatch RECORDS TO UPDATE AFTER USE CASE INTEREST: ' + recordsToUpdate);
        CountryPhoneNumTypeHandler.linkToOpp(scope);
        
        update recordsToUpdate.values();
    }
    
    public void finish(Database.BatchableContext BC) {
        // Actions to perform when batch processing is finished
    }

    // Schedulable Interface Method
    public void execute(SchedulableContext context) {
        // Run the batch with a size of 2000 records instead of the default of 200
        database.executebatch(new CountryPhoneNumTypeBatch(), 2000);
    }
}