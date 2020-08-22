public class CountryPhoneNumTypeHandler {
    //
    // Theese properties and methods manage the Created By filter on whether the records should be included
    // in the linking of the Contact/Lead.
    //
    public static Set<String> includeCreatedByUsers = new Set<String> {
        'API-Read Only',
        'Eloqua Marketing',
        'Jonathan Griggs',
        'Davis Dong'
    };
    
    public static Set<Id> includedCreatedByUserIds;
    public static Boolean hasIncludedCreatedByUserId(Id userId) {
        if (includedCreatedByUserIds == null) {
            Map<Id,User> u = new Map<Id,User>([ SELECT Id, Name FROM User WHERE Name IN :includeCreatedByUsers ]);
            includedCreatedByUserIds = u.keySet();
            System.debug('INCLUDE CREATED BY USERS: ' + u);
        }
        System.debug('CHECKING IF ' + userId + ' IS INCLUDE CREATED BY USER IDs: ' + includedCreatedByUserIds);
        return includedCreatedByUserIds.contains(userId);
    }

    //
    // Used in CountryPhoneNumTypeTrigger to only run on insert Country Phone Number Type object.
    // Used in CountryPhoneNumTypeBatch to backfill existing Country Phone Number Type records.
    // Records must be created by certain user in order to be processed.
    // (Let us say Eloqua Marketing for now, I would expect we have kind of custom settings could control this one)
    // We are trying to query back Lead/Contact with exact email match by the Customer_Email__c field.
    // If we find the match, we could populate the Lead/Contact lookup on the Country Phone Number Type
    //
    public static Map<Id,Opportunity_Country_Number__c> linkToContactOrLead(List<Opportunity_Country_Number__c> recList) {
        return linkToContactOrLead(recList, false);
    }

    //
    // forceUpdate will update the Contact__c/Lead__c field regardless of CreatedBy
    //
    public static void linkToCountryPhoneNumberType (List<Opportunity_Country_Number__c> recList, Boolean isDML){
        List<Opportunity_Country_Number__c> filteredRecord = new List<Opportunity_Country_Number__c>();
        
        for(Opportunity_Country_Number__c rec: recList){
            //if(rec.Country_Number_Type__c == null){
                filteredRecord.add(rec);
            //}
        }
        
        if(filteredRecord.isEmpty()) return;
        List<Country_Phone_Number_Type__c> types = [SELECT Country__r.Name, Type__c, Capability__c FROM Country_Phone_Number_Type__c WHERE Origin__c = 'Twilio'];
        
        for(Opportunity_Country_Number__c rec: filteredRecord){
            for(Country_Phone_Number_Type__c cType: types){
                if(rec.Country_Input__c == cType.Country__r.Name && rec.Type_Input__c == cType.Type__c && rec.Capability_Input__c == cType.Capability__c){
                    rec.Country_Number_Type__c = cType.Id;
                    break;
                }
            }
        }
        if(isDML) update filteredRecord;
    }
    
    public static void linkToOpp (List<Opportunity_Country_Number__c> recList){
        List<Opportunity_Country_Number__c> filteredRecord = new List<Opportunity_Country_Number__c>();
        Map<Id, Id> uciIds = new Map<Id, Id>();
        Set<String> queryCountries = new Set<String>();
        
        for(Opportunity_Country_Number__c rec: recList){
            if(rec.Opportunity_Country__c == null && rec.Use_Case_Interest__c != null){
                filteredRecord.add(rec);
                uciIds.put(rec.Use_Case_Interest__c, rec.Id);
                queryCountries.add(rec.Country_Input__c);
            }
        }
        
        if(filteredRecord.isEmpty()) return;
        
        List<Use_Case_Interest__c> ucis = [SELECT Opportunity__c FROM Use_Case_Interest__c WHERE Opportunity__c != null AND Id =: uciIds.keySet()];
        Map<Id, Id> oppIds = new Map<Id, Id>();
        
        for(Use_Case_Interest__c uci: ucis){ oppIds.put(uciIds.get(uci.Id), uci.Opportunity__c);}
        
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([SELECT Id, (SELECT Country__r.Name FROM Opportunity_Countries__r) FROM Opportunity WHERE Id =: oppIds.values()]);
        
        List<Country__c> countries = [SELECT Name FROM Country__c WHERE Name =: queryCountries];
        Map<String, Id> countryIdMap = new Map<String, Id>();
        for(Country__c country: countries){countryIdMap.put(country.Name, country.Id);}
        
        Map<Id, Opportunity_Country__c> upsertCountries = new Map<Id, Opportunity_Country__c>();
        
        for(Opportunity_Country_Number__c rec: filteredRecord){
            Id oppId = oppIds.get(rec.Id);
            if(oppId != null){
                Opportunity opp = opps.get(oppId);
                Boolean existingCountry = false;
                if(opp != null && opp.Opportunity_Countries__r != null && !opp.Opportunity_Countries__r.isEmpty()){
                    for(Opportunity_Country__c country: opp.Opportunity_Countries__r){
                        if(rec.Country_Input__c == country.Country__r.Name){
                            upsertCountries.put(rec.Id, country);
                            existingCountry = true;
                            break;
                        }
                    }
                }
                if(!existingCountry){
                    Opportunity_Country__c newCountry = new Opportunity_Country__c(Opportunity__c = oppId, Country__c = countryIdMap.get(rec.Country_Input__c));
                    upsertCountries.put(rec.Id, newCountry);
                }
            }
        }
        upsert upsertCountries.values();
        for(Opportunity_Country_Number__c rec: filteredRecord){if(upsertCountries.get(rec.Id) != null) rec.Opportunity_Country__c = upsertCountries.get(rec.Id).Id;}
        
        update filteredRecord;
        
    }
    
    public static Map<Id,Opportunity_Country_Number__c> linkToContactOrLead(List<Opportunity_Country_Number__c> recList, Boolean forceUpdate) {
        System.debug('linkToContactOrLead FORCE UPDATE REGARDLESS OF CREATED BY: ' + forceUpdate);

        // Collect the email addresses from the Opportunity_Country_Number__c records
        List<Opportunity_Country_Number__c> recordsToProcess = new List<Opportunity_Country_Number__c>();
        Set<String> emails = new Set<String>();
        for (Opportunity_Country_Number__c r : recList) {
            System.debug('linkToContactOrLead CHECKING RECORD: ' + r);
            if (r.Contact__c == null && r.Lead__c == null && String.isNotBlank(r.Customer_Email__c) && (forceUpdate || hasIncludedCreatedByUserId(r.CreatedById))) {
                emails.add(r.Customer_Email__c);
                recordsToProcess.add(r);
            }
        }

        System.debug('linkToContactOrLead SEARCHING FOR EMAILS: ' + emails);
        
        // Get Contacts with matching email addresses
        Map<String,Contact> contactEmailMap = new Map<String,Contact>();
        for (List<Contact> contactList : [ SELECT Id, Email FROM Contact WHERE Email IN :emails ]) {
            for (Contact c : contactList) {
                contactEmailMap.put (c.Email, c);
            }
        }

        System.debug('linkToContactOrLead MATCHING CONTACTS: ' + contactEmailMap);

        // Get Leads with matching email addresses
        Map<String,Lead> leadEmailMap = new Map<String,Lead>();
        for (List<Lead> leadList : [ SELECT Id, Email FROM Lead WHERE Email IN :emails ]) {
            for (Lead l : leadList) {
                leadEmailMap.put (l.Email, l);
            }
        }

        System.debug('linkToContactOrLead MATCHING LEADS: ' + leadEmailMap);
        
        // Loop through the Opportunity_Country_Number__c records.
        // Look for a Contact with a matching email address
        //   If Contact match found, set Contact__c to Contact.Id and go to next Opportunity_Country_Number__c record
        //   If Contact match not found, look for a Lead with a matching email address
        //   If Lead match found, set Lead__c to Lead.Id and go to next Opportunity_Country_Number__c record
        //   If Lead match not found, do not make any changes go to next Opportunity_Country_Number__c record
        Map<Id,Opportunity_Country_Number__c> recordsToUpdate = new Map<Id,Opportunity_Country_Number__c>();
        for (Opportunity_Country_Number__c r : recordsToProcess) {
            if (contactEmailMap.containsKey(r.Customer_Email__c) && (forceUpdate || hasIncludedCreatedByUserId(r.CreatedById))) {
                recordsToUpdate.put(r.Id, new Opportunity_Country_Number__c(
                    Id = r.Id,
                    Contact__c = contactEmailMap.get(r.Customer_Email__c).Id
                ));
            } else if (leadEmailMap.containsKey(r.Customer_Email__c) && (forceUpdate || hasIncludedCreatedByUserId(r.CreatedById))) {
                recordsToUpdate.put(r.Id, new Opportunity_Country_Number__c(
                    Id = r.Id,
                    Lead__c = leadEmailMap.get(r.Customer_Email__c).Id
                ));
            }
        }
        return recordsToUpdate;
    }

    //
    // Used in CountryPhoneNumTypeBatch to backfill existing Country Phone Number Type records.
    // (Let us say Eloqua Marketing for now, I would expect we have kind of custom settings could control this one)
    // Query MQLs for related Contact/Lead to populate the most recent modified and NOT Rejected MQL in Country Phone Number Type MQL lookup field
    //
    public static Map<Id,Opportunity_Country_Number__c> linkToMQL(List<Opportunity_Country_Number__c> recList) {
        return linkToMQL(recList, false);
    }

    //
    // forceUpdate will update the MQL__c field regardless of CreatedBy
    //
    public static Map<Id,Opportunity_Country_Number__c> linkToMQL(List<Opportunity_Country_Number__c> recList, Boolean forceUpdate) {
        System.debug('linkToMQL FORCE UPDATE REGARDLESS OF CREATED BY: ' + forceUpdate);

        // Collect the email addresses from the Opportunity_Country_Number__c records
        List<Opportunity_Country_Number__c> recordsToProcess = new List<Opportunity_Country_Number__c>();
        Set<Id> contacts = new Set<Id>();
        Set<Id> leads = new Set<Id>();
        for (Opportunity_Country_Number__c r : recList) {
            System.debug('linkToMQL CHECKING RECORD: ' + r);
            if (r.Country_Number_Status__c == 'Preview' && r.MQL__c == null && (forceUpdate || hasIncludedCreatedByUserId(r.CreatedById))) {
                // If both the Contact__c and Lead__c are set Contact__c will be used
                if (r.Contact__c != null) {
                    contacts.add(r.Contact__c);
                    recordsToProcess.add(r);
                } else if (r.Lead__c != null) {
                    leads.add(r.Lead__c);
                    recordsToProcess.add(r);
                }
            }
        }
        
        System.debug('linkToMQL SEARCHING FOR CONTACTS: ' + contacts);
        Map<Id,Contact> contactMQLMap = new Map<Id,Contact>();
        // Get latest MQL record that is not rejected related to Contacts
        if(!Test.isRunningTest()){
            contactMQLMap = new Map<Id,Contact>([
                SELECT Id, (SELECT Id FROM FSRs__r WHERE MQL_Status__c != '3 - Rejected' AND Campaign__c = '7011W000001SqZM' ORDER BY LastModifiedDate DESC LIMIT 1)
                FROM Contact
                WHERE Id IN :contacts
            ]);
        }
        else{
            contactMQLMap = new Map<Id,Contact>([
                SELECT Id, (SELECT Id FROM FSRs__r WHERE MQL_Status__c != '3 - Rejected' ORDER BY LastModifiedDate DESC LIMIT 1)
                FROM Contact
                WHERE Id IN :contacts
            ]);
        }

        System.debug('linkToMQL MATCHING CONTACTS: ' + contactMQLMap);

        System.debug('linkToMQL SEARCHING LEADS: ' + leads);

        Map<Id,Lead> leadMQLMap = new Map<Id,Lead>();
        // Get latest MQL record that is not rejected related to Leads
        if(!Test.isRunningTest()){
            leadMQLMap = new Map<Id,Lead>([
                SELECT Id, (SELECT Id FROM FSRs__r WHERE MQL_Status__c != '3 - Rejected' AND Campaign__c = '7011W000001SqZM' ORDER BY CreatedDate DESC LIMIT 1)
                FROM Lead
                WHERE Id IN :leads
            ]);

        }
        else{
           leadMQLMap = new Map<Id,Lead>([
                SELECT Id, (SELECT Id FROM FSRs__r WHERE MQL_Status__c != '3 - Rejected' ORDER BY CreatedDate DESC LIMIT 1)
                FROM Lead
                WHERE Id IN :leads
            ]); 
        }
    
        System.debug('linkToMQL MATCHING LEADS: ' + leadMQLMap);

        // Loop through the Opportunity_Country_Number__c records.
        // Query related MQLs, populate the most recent modified and NOT Rejected MQL in Country Phone Number Type MQL lookup field
        // If the Opportunity_Country_Number__c is related to a Contact that take precedence if it is also related to a Lead
        Map<Id,Opportunity_Country_Number__c> recordsToUpdate = new Map<Id,Opportunity_Country_Number__c>();
        for (Opportunity_Country_Number__c r : recList) {
            if (forceUpdate || hasIncludedCreatedByUserId(r.CreatedById)) {
                if (r.Contact__c != null) {
                    if (contactMQLMap.containsKey(r.Contact__c)) {
                        Contact c = contactMQLMap.get(r.Contact__c);
                        if (!c.FSRs__r.isEmpty()) {
                            recordsToUpdate.put(r.Id, new Opportunity_Country_Number__c(
                                Id = r.Id,
                                MQL__c = c.FSRs__r[0].Id
                            ));
                        }
                    }
                } else if (r.Lead__c != null) {
                    if (leadMQLMap.containsKey(r.Lead__c)) {
                        Lead l = leadMQLMap.get(r.Lead__c);
                        if (!l.FSRs__r.isEmpty()) {
                            recordsToUpdate.put(r.Id, new Opportunity_Country_Number__c(
                                Id = r.Id,
                                MQL__c = l.FSRs__r[0].Id
                            ));
                        }
                    }
                }
                
            }
        }

        return recordsToUpdate;
    }

    //
    // Used in CountryPhoneNumTypeBatch to backfill existing Country Phone Number Type records.
    // (Let us say Eloqua Marketing for now, I would expect we have kind of custom settings could control this one)
    // Query Use Case Interest for related Contact/Lead to populate the most recent modified and NOT Rejected Use Case Interest in Country Phone Number Type Use Case Interest lookup field
    //
    public static Map<Id,Opportunity_Country_Number__c> linkToUCI(List<Opportunity_Country_Number__c> recList) {
        return linkToUCI(recList, false);
    }

    //
    // forceUpdate will update the Use_Case_Interest__c field regardless of CreatedBy
    //
    public static Map<Id,Opportunity_Country_Number__c> linkToUCI(List<Opportunity_Country_Number__c> recList, Boolean forceUpdate) {
        System.debug('linkToUCI FORCE UPDATE REGARDLESS OF CREATED BY: ' + forceUpdate);

        // Collect the email addresses from the Opportunity_Country_Number__c records
        List<Opportunity_Country_Number__c> recordsToProcess = new List<Opportunity_Country_Number__c>();
        Set<Id> mqls = new Set<Id>();
        for (Opportunity_Country_Number__c r : recList) {
            System.debug('linkToUCI CHECKING RECORD: ' + r);
            if (r.Use_Case_Interest__c == null && (forceUpdate || hasIncludedCreatedByUserId(r.CreatedById))) {
                mqls.add(r.MQL__c);
                recordsToProcess.add(r);
            }
        }
        
        System.debug('linkToUCI SEARCHING FOR MQLS: ' + mqls);

        // Get latest MQL record that is not rejected related to Contacts
        Map<Id,FSR__c> mqlUCIMap = new Map<Id,FSR__c>([
            SELECT Id, (SELECT Id FROM Use_Case_Interests__r WHERE Status__c != 'Rejected' ORDER BY LastModifiedDate DESC LIMIT 1)
            FROM FSR__c
            WHERE Id IN :mqls
        ]);

        System.debug('linkToUCI MATCHING MQL: ' + mqlUCIMap);

        // Loop through the Opportunity_Country_Number__c records.
        // Query related MQLs, populate the most recent modified and NOT Rejected MQL in Country Phone Number Type MQL lookup field
        // If the Opportunity_Country_Number__c is related to a Contact that take precedence if it is also related to a Lead
        Map<Id,Opportunity_Country_Number__c> recordsToUpdate = new Map<Id,Opportunity_Country_Number__c>();
        for (Opportunity_Country_Number__c r : recList) {
            if (forceUpdate || hasIncludedCreatedByUserId(r.CreatedById)) {
                if (r.MQL__c != null) {
                    if (mqlUCIMap.containsKey(r.MQL__c)) {
                        FSR__c mql = mqlUCIMap.get(r.MQL__c);
                        if (!mql.Use_Case_Interests__r.isEmpty()) {
                            recordsToUpdate.put(r.Id, new Opportunity_Country_Number__c(
                                Id = r.Id,
                                Use_Case_Interest__c = mql.Use_Case_Interests__r[0].Id
                            ));
                        }
                    }
                }
            }
        }

        return recordsToUpdate;
    }
}