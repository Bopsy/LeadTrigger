/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  EmailOptOutServicesTest
*
* @description 	  Test class that contains the unit test related to EmailOptOutServices.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu	 <jayu@twilio.com>
* @version        1.0
* @created        2019-03-22
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class EmailOptOutServicesTest {
	private static Map<Integer, String> intEmailMap = new Map<Integer, String>();
    
    //Setup test data.
    @testSetup static void setup(){
    	List<Account> accList = TestDataFactory.createAccountList(2);
        List<Contact> contList = TestDataFactory.createContactList(100);
        List<Lead> leadList = TestDataFactory.createLeadList(100);
        
        insert accList;
        
        for(Integer i = 0; i < contList.size(); i++){
            String tempString = 'test'+i+'@test.com';
            
            contList[i].Email = tempString;
            contList[i].HasOptedOutOfEmail = FALSE;
            contList[i].AccountId = accList[0].Id;
            leadList[i].Email = tempString;
            leadList[i].HasOptedOutOfEmail = FALSE;
        }
        
        insert contList;
        insert leadList;
    }
    
    static testMethod void ensure_New_Leads_Are_Opted_Out_When_Appropriate(){
        Map<String, Contact> emailToContactMap = new Map<String, Contact>();
        Map<String, Lead> emailToLeadMap = new Map<String, Lead>();
        Map<Integer, String> intEmailMap = new Map<Integer, String>();
        List<Contact> allConts = [SELECT Id, Email FROM Contact];
        List<Lead> allLeads = [SELECT Id, Email FROM Lead];
        
        for(Integer i = 0; i < allConts.size(); i++){
            intEmailMap.put(i, allConts[i].Email);
        }
        
        for(Contact contRec : allConts){
            emailToContactMap.put(contRec.Email, contRec);
        }
        
        for(Lead leadRec : allLeads){
            emailToLeadMap.put(leadRec.Email, leadRec);
        }
        
        //Generate some random numbers to decide which Emails to opt out.
        List<Integer> intList = new List<Integer>();	
        for(Integer i = 0; i < 5 ; i++){
            Integer randomNumber = Integer.valueof((Math.random() * 100));  
            intList.add(randomNumber);
        }
        intList.sort();
        
        //Update Contacts or Leads for opt out;
        List<Contact> contsForUpdate = new List<Contact>();
        List<Lead> leadsForUpdate = new List<Lead>();
        List<Lead> testLeadsForInsert = new List<Lead>();
        Map<String, Boolean> emailToOptOut = new Map<String, Boolean>();
        Integer arrayPosition = 0;
		for(Integer intRec : intList){
            String randomlySelectedEmail = intEmailMap.get(intRec);
            if(arrayPosition == 0 || arrayPosition == 1){
                Contact tempCont = emailToContactMap.get(randomlySelectedEmail);
                tempCont.HasOptedOutOfEmail = TRUE;
                contsForUpdate.add(tempCont);
                emailToOptOut.put(randomlySelectedEmail, TRUE);
            } else if (arrayPosition == 2 || arrayPosition == 3){
                Lead tempLead = emailToLeadMap.get(randomlySelectedEmail);
                tempLead.HasOptedOutOfEmail = TRUE;
                leadsForUpdate.add(tempLead);
                emailToOptOut.put(randomlySelectedEmail, TRUE);
            } else {
                emailToOptOut.put(randomlySelectedEmail, FALSE);
            }
            
            //Create records to test.
            Lead leadRec = new Lead();
            leadRec.firstname = 'lead' + intRec + ' ';
            leadRec.lastname = 'test' + intRec ;
            leadRec.Title = 'CFO';
            leadRec.Email = randomlySelectedEmail;
            leadRec.Company = 'test';
            leadRec.HasOptedOutOfEmail = false;
            testLeadsForInsert.add(leadRec);
            
            arrayPosition++;
        }
        
        update contsForUpdate;
        update leadsForUpdate;
        
        //Insert records to test
        insert testLeadsForInsert;
        
        List<Lead> leadsForReview = [SELECT Id, Email, HasOptedOutOfEmail FROM Lead WHERE Id IN :testLeadsForInsert];
        Set<String> optedOutEmails = new Set<String>();
        Set<String> nonOptedOutEmails = new Set<String>();
        
        //Validate opt outs for new leads.
        for(Lead leadRec : leadsForReview){
            System.assertEquals(emailToOptOut.get(leadRec.Email), leadRec.HasOptedOutOfEmail);
            if(leadRec.HasOptedOutOfEmail){
                optedOutEmails.add(leadRec.email);
            } else {
                nonOptedOutEmails.add(leadRec.email);
            }
        }
        
        System.assertEquals(4, optedOutEmails.size());
        System.assertEquals(1, nonOptedOutEmails.size());
    }
    
    static testMethod void ensure_Updated_Opt_Outs_Also_Opt_Out_Existing_Contacts(){
        Map<String, Contact> emailToContactMap = new Map<String, Contact>();
        Map<String, Lead> emailToLeadMap = new Map<String, Lead>();
        Map<Integer, String> intEmailMap = new Map<Integer, String>();
        List<Contact> allConts = [SELECT Id, Email FROM Contact];
        List<Lead> allLeads = [SELECT Id, Email FROM Lead];
        
        for(Integer i = 0; i < allConts.size(); i++){
            intEmailMap.put(i, allConts[i].Email);
        }
        
        for(Contact contRec : allConts){
            emailToContactMap.put(contRec.Email, contRec);
        }
        
        for(Lead leadRec : allLeads){
            emailToLeadMap.put(leadRec.Email, leadRec);
        }
        
        //Generate some random numbers to decide which Emails to opt out.
        List<Integer> intList = new List<Integer>();	
        for(Integer i = 0; i < 5 ; i++){
            Integer randomNumber = Integer.valueof((Math.random() * 100));  
            intList.add(randomNumber);
        }
        intList.sort();
        
        //Get leads tied to those emails.
        Set<String> emailSetForTest = new Set<String>();
        for(Integer testInt : intList){
            emailSetForTest.add(intEmailMap.get(testInt));
        }
        
        List<Lead> leadsForTest = [SELECT Id FROM Lead WHERE Email IN :emailSetForTest];
        List<Lead> leadsForUpdate = new List<Lead>();
        
        for(Lead leadRec : leadsForTest){
            leadRec.HasOptedOutOfEmail = TRUE;
            leadsForUpdate.add(leadRec);
        }
        
        update leadsForUpdate;
        
        //Ensure that the Contacts with a matching email are also opted out.
        List<Contact> contsForReview = [SELECT Id, HasOptedOutOfEmail, Email FROM Contact];
        Integer numberOfContactEmailOptOuts = 0;
        Integer numberOfContactEmailOptIns = 0;
        for(Contact contRec : contsForReview){
            if(contRec.HasOptedOutOfEmail == TRUE){
            	for(String emailStr : emailSetForTest){
                    if(emailStr == contRec.Email){
                    	numberOfContactEmailOptOuts++;
                        break;
                    }
                }    
            } else {
            	numberOfContactEmailOptIns++;    
            }
        }
        
        System.assertEquals(5, numberOfContactEmailOptOuts);
        System.assertEquals(95, numberOfContactEmailOptIns);
    }
    
    static testMethod void ensure_Third_Party_Data_Source_is_Checked_On_Lead(){
        Map<String, Id> profMap = new Map<String, Id>();
        List<Profile> profList = [Select Id, Name from Profile];
        for(Profile prof : profList){
            profMap.put(prof.Name, prof.Id);
        }
        User testUser = TestDataFactory.createUser();
        testUser.ProfileId = profMap.get('**Global AM');
        List<Lead> leadList = TestDataFactory.createLeadList(5);
        
        Third_Party_Data_Source__c tpds = new Third_Party_Data_Source__c();
        insert new Third_Party_Data_Source__c(SetupOwnerId = UserInfo.getOrganizationId(), Third_Party_Data_Source__c = TRUE);
        insert new Third_Party_Data_Source__c(SetupOwnerId = profMap.get('System Administrator'), Third_Party_Data_Source__c = FALSE);
        
        //Inserting as a Sales rep to see if Third Party Data Source is checked.
        System.runAs(testUser){
            insert leadList;
            
            List<Lead> leadsForReview = [SELECT Third_Party_Data_Source__c FROM Lead WHERE Id IN :leadList];
            Integer tpdsIsTrue = 0;
            for(Lead leadRec : leadsForReview){
                if(leadRec.Third_Party_Data_Source__c == TRUE){
                    tpdsIsTrue++;
                }
            }
            
            System.assertEquals(5, tpdsIsTrue);
        }
        
        
    }
    
    static testMethod void ensure_Third_Party_Data_Source_is_UnChecked_On_Lead(){
        Map<String, Id> profMap = new Map<String, Id>();
        List<Profile> profList = [Select Id, Name from Profile];
        for(Profile prof : profList){
            profMap.put(prof.Name, prof.Id);
        }
        User testUser = TestDataFactory.createUser();
        testUser.ProfileId = profMap.get('**Marketing');
        List<Lead> leadList = TestDataFactory.createLeadList(5);
        
        insert new Third_Party_Data_Source__c(SetupOwnerId = UserInfo.getOrganizationId(), Third_Party_Data_Source__c = TRUE);
        insert new Third_Party_Data_Source__c(SetupOwnerId = profMap.get('**Marketing'), Third_Party_Data_Source__c = FALSE);
        
        //Inserting as a Marketing User to see if Third Party Data Source is unchecked.
        System.runAs(testUser){
            insert leadList;
            
            List<Lead> leadsForReview = [SELECT Third_Party_Data_Source__c FROM Lead WHERE Id IN :leadList];
            Integer tpdsIsFalse = 0;
            for(Lead leadRec : leadsForReview){
                if(leadRec.Third_Party_Data_Source__c == FALSE){
                    tpdsIsFalse++;
                }
            }
            
            System.assertEquals(5, tpdsIsFalse);
        }
    }
    static testMethod void ensure_New_Contacts_Are_Opted_Out_When_Appropriate(){
        Map<String, Contact> emailToContactMap = new Map<String, Contact>();
        Map<String, Lead> emailToLeadMap = new Map<String, Lead>();
        Map<Integer, String> intEmailMap = new Map<Integer, String>();
        List<Contact> allConts = [SELECT Id, Email FROM Contact];
        List<Lead> allLeads = [SELECT Id, Email FROM Lead];
        
        for(Integer i = 0; i < allConts.size(); i++){
            intEmailMap.put(i, allConts[i].Email);
        }
        
        for(Contact contRec : allConts){
            emailToContactMap.put(contRec.Email, contRec);
        }
        
        for(Lead leadRec : allLeads){
            emailToLeadMap.put(leadRec.Email, leadRec);
        }
        
        //Generate some random numbers to decide which Emails to opt out.
        List<Integer> intList = new List<Integer>();	
        for(Integer i = 0; i < 5 ; i++){
            Integer randomNumber = Integer.valueof((Math.random() * 100));  
            intList.add(randomNumber);
        }
        intList.sort();
        
        //Update Contacts or Leads for opt out;
        List<Contact> contsForUpdate = new List<Contact>();
        List<Lead> leadsForUpdate = new List<Lead>();
        List<Contact> testContactsForInsert = new List<Contact>();
        Map<String, Boolean> emailToOptOut = new Map<String, Boolean>();
        Integer arrayPosition = 0;
		for(Integer intRec : intList){
            String randomlySelectedEmail = intEmailMap.get(intRec);
            if(arrayPosition == 0 || arrayPosition == 1){
                Contact tempCont = emailToContactMap.get(randomlySelectedEmail);
                tempCont.HasOptedOutOfEmail = TRUE;
                contsForUpdate.add(tempCont);
                emailToOptOut.put(randomlySelectedEmail, TRUE);
            } else if (arrayPosition == 2 || arrayPosition == 3){
                Lead tempLead = emailToLeadMap.get(randomlySelectedEmail);
                tempLead.HasOptedOutOfEmail = TRUE;
                leadsForUpdate.add(tempLead);
                emailToOptOut.put(randomlySelectedEmail, TRUE);
            } else {
                emailToOptOut.put(randomlySelectedEmail, FALSE);
            }
            
            //Create records to test.
            Contact con = new contact();
            con.firstname = 'con' + intRec + ' ';
            con.lastname = 'test' + intRec ;
            con.Title = 'CFO';
            con.Email = randomlySelectedEmail;
            con.Preferred_Email__c = randomlySelectedEmail;
            con.Eloqua_Lead_Rating__c = 'A'+intRec ;
            con.HasOptedOutOfEmail = false;
            testContactsForInsert.add(con);
            
            arrayPosition++;
        }		
        
        update contsForUpdate;
        update leadsForUpdate;
        
        //Insert records to test
        insert testContactsForInsert;
        
        List<Contact> contsForReview = [SELECT Id, Email, HasOptedOutOfEmail FROM Contact WHERE Id IN :testContactsForInsert];
        Set<String> optedOutEmails = new Set<String>();
        Set<String> nonOptedOutEmails = new Set<String>();
        for(Contact contRec : contsForReview){
            System.assertEquals(emailToOptOut.get(contRec.Email), contRec.HasOptedOutOfEmail);
            if(contRec.HasOptedOutOfEmail){
                optedOutEmails.add(contRec.email);
            } else {
                nonOptedOutEmails.add(contRec.email);
            }
        }
        
        System.assertEquals(4, optedOutEmails.size());
        System.assertEquals(1, nonOptedOutEmails.size());
    }
    
    static testMethod void ensure_Updated_Opt_Outs_Also_Opt_Out_Leads(){
        Map<String, Contact> emailToContactMap = new Map<String, Contact>();
        Map<String, Lead> emailToLeadMap = new Map<String, Lead>();
        Map<Integer, String> intEmailMap = new Map<Integer, String>();
        List<Contact> allConts = [SELECT Id, Email FROM Contact];
        List<Lead> allLeads = [SELECT Id, Email FROM Lead];
        
        for(Integer i = 0; i < allConts.size(); i++){
            intEmailMap.put(i, allConts[i].Email);
        }
        
        for(Contact contRec : allConts){
            emailToContactMap.put(contRec.Email, contRec);
        }
        
        for(Lead leadRec : allLeads){
            emailToLeadMap.put(leadRec.Email, leadRec);
        }
        
        //Generate some random numbers to decide which Emails to opt out.
        List<Integer> intList = new List<Integer>();	
        for(Integer i = 0; i < 5 ; i++){
            Integer randomNumber = Integer.valueof((Math.random() * 100));  
            intList.add(randomNumber);
        }
        intList.sort();
        
        //Get contacts tied to those emails.
        Set<String> emailSetForTest = new Set<String>();
        for(Integer testInt : intList){
            emailSetForTest.add(intEmailMap.get(testInt));
        }
        
        List<Contact> contsForTest = [SELECT Id FROM Contact WHERE Email IN :emailSetForTest];
        List<Contact> contsForUpdate = new List<Contact>();
        
        for(Contact cont : contsForTest){
            cont.HasOptedOutOfEmail = TRUE;
            contsForUpdate.add(cont);
        }
        System.assertEquals(5, contsForUpdate.size());
        update contsForUpdate;
        
        //Ensure that the leads with a matching email are also opted out.
        List<Lead> leadsForReview = [SELECT Id, HasOptedOutOfEmail, Email FROM Lead];
        Integer numberOfLeadEmailOptOuts = 0;
        Integer numberOfLeadEmailOptIns = 0;
        for(Lead leadRec : leadsForReview){
            if(leadRec.HasOptedOutOfEmail == TRUE){
            	for(String emailStr : emailSetForTest){
                    if(emailStr == leadRec.Email){
                    	numberOfLeadEmailOptOuts++;
                        break;
                    }
                }    
            } else {
            	numberOfLeadEmailOptIns++;    
            }
        }
        
        System.assertEquals(5, numberOfLeadEmailOptOuts);
        System.assertEquals(95, numberOfLeadEmailOptIns);
    }
    
    static testMethod void ensure_Third_Party_Data_Source_is_Checked_on_Contact(){
        Map<String, Id> profMap = new Map<String, Id>();
        List<Profile> profList = [Select Id, Name from Profile];
        for(Profile prof : profList){
            profMap.put(prof.Name, prof.Id);
        }
        User testUser = TestDataFactory.createUser();
        testUser.ProfileId = profMap.get('**Global AM');
        List<Contact> contList = TestDataFactory.createContactList(5);
        
        Third_Party_Data_Source__c tpds = new Third_Party_Data_Source__c();
        insert new Third_Party_Data_Source__c(SetupOwnerId = UserInfo.getOrganizationId(), Third_Party_Data_Source__c = TRUE);
        insert new Third_Party_Data_Source__c(SetupOwnerId = profMap.get('System Administrator'), Third_Party_Data_Source__c = FALSE);
        
        //Inserting as a Sales rep to see if Third Party Data Source is checked.
        System.runAs(testUser){
            insert contList;
            
            List<Contact> contactsForReview = [SELECT Third_Party_Data_Source__c FROM Contact WHERE Id IN :contList];
            Integer tpdsIsTrue = 0;
            for(Contact cont : contactsForReview){
                if(cont.Third_Party_Data_Source__c == TRUE){
                    tpdsIsTrue++;
                }
            }
            
            System.assertEquals(5, tpdsIsTrue);
        }
        
        
    }
    
    static testMethod void ensure_Third_Party_Data_Source_is_UnChecked_On_Contact(){
        Map<String, Id> profMap = new Map<String, Id>();
        List<Profile> profList = [Select Id, Name from Profile];
        for(Profile prof : profList){
            profMap.put(prof.Name, prof.Id);
        }
        User testUser = TestDataFactory.createUser();
        testUser.ProfileId = profMap.get('**Marketing');
        List<Contact> contList = TestDataFactory.createContactList(5);
        
        insert new Third_Party_Data_Source__c(SetupOwnerId = UserInfo.getOrganizationId(), Third_Party_Data_Source__c = TRUE);
        insert new Third_Party_Data_Source__c(SetupOwnerId = profMap.get('**Marketing'), Third_Party_Data_Source__c = FALSE);
        
        //Inserting as a Marketing User to see if Third Party Data Source is unchecked.
        System.runAs(testUser){
            insert contList;
            
            List<Contact> contactsForReview = [SELECT Third_Party_Data_Source__c FROM Contact WHERE Id IN :contList];
            Integer tpdsIsFalse = 0;
            for(Contact cont : contactsForReview){
                if(cont.Third_Party_Data_Source__c == FALSE){
                    tpdsIsFalse++;
                }
            }
            
            System.assertEquals(5, tpdsIsFalse);
        }
    }
    
    /*
     * Test method to ensure relevant records are being opted out based on opted out Leads.
     */
    private static testMethod void ensure_Records_Are_Opted_Out_Based_On_Leads(){
        //Create the opted out leads.
        List<Lead> leadsToUpdate = new List<Lead>();
		List<Lead> leadsToOptOut = [SELECT Id FROM Lead];
        for(Lead leadRec : leadsToOptOut){
            leadRec.HasOptedOutOfEmail = TRUE;
            leadsToUpdate.add(leadRec);
        }
		update leadsToUpdate;        
        
        //Create the new data for update.
        List<Contact> contList = TestDataFactory.createContactList(100);
        
        for(Integer i = 0; i < contList.size(); i++){
            String tempString = 'test'+i+'@test.com';
            
            contList[i].Email = tempString;
        }
        
        insert contList;
        
        //I have to reupdate the Email Opt Outs to False because of the trigger that will set it to true.
        List<Contact> contsForOptIn = [SELECT Id FROM Contact WHERE Id IN :contList];
        List<Contact> contactsForUpdate = new List<Contact>();
        
        for(Contact contRec : contsForOptIn){
            contRec.HasOptedOutOfEmail = FALSE;
            contactsForUpdate.add(contRec);
        }
        
        update contactsForUpdate;
        
        //Confirm before batch values.
        List<Contact> contsForReviewBeforeBatch = [SELECT Id, HasOptedOutOfEmail FROM Contact WHERE Id IN :contList];
        
        Integer numberOfContactRecords = 0;
        for(Contact contRec : contsForReviewBeforeBatch){
            System.assertEquals(FALSE, contRec.HasOptedOutOfEmail);
            numberOfContactRecords++;
        }
        System.assertEquals(100, numberOfContactRecords);
        
        Test.startTest();
        BatchUpdateRecordsWithLeadEmailOptOut b = new BatchUpdateRecordsWithLeadEmailOptOut();
        Database.executeBatch(b);
        Test.stopTest();
        
        //Confirm after batch values.
        List<Contact> contsForReviewAfterBatch = [SELECT Id, HasOptedOutOfEmail FROM Contact WHERE Id IN :contList];
        
        Integer numberOfContactRecordsAfter = 0;
        Integer numberOfLeadRecordsAfter = 0;
        for(Contact contRec : contsForReviewAfterBatch){
            System.assertEquals(TRUE, contRec.HasOptedOutOfEmail);
            numberOfContactRecordsAfter++;    
        }
        System.assertEquals(100, numberOfContactRecordsAfter);
    }
    
    /*
     * Test method to ensure relevant records are being opted out based on opted out Contacts.
     */
    private static testMethod void ensure_Records_Are_Opted_Out_Based_On_Contacts(){
        //Create the opted out leads.
        List<Contact> contsToUpdate = new List<Contact>();
		List<Contact> contsToOptOut = [SELECT Id FROM Contact];
        for(Contact contRec : contsToOptOut){
            contRec.HasOptedOutOfEmail = TRUE;
            contsToUpdate.add(contRec);
        }
		update contsToUpdate;        
        
        //Create the new data for update.
        List<Contact> contList = TestDataFactory.createContactList(100);
        
        for(Integer i = 0; i < contList.size(); i++){
            String tempString = 'test'+i+'@test.com';
            
            contList[i].Email = tempString;
        }
        
        insert contList;
        
        //I have to reupdate the Email Opt Outs to False because of the trigger that will set it to true.
        List<Contact> contsForOptIn = [SELECT Id FROM Contact WHERE Id IN :contList];
        List<Contact> contactsForUpdate = new List<Contact>();
        
        for(Contact contRec : contsForOptIn){
            contRec.HasOptedOutOfEmail = FALSE;
            contactsForUpdate.add(contRec);
        }
        
        update contactsForUpdate;
        
        //Confirm before batch values.
        List<Contact> contsForReviewBeforeBatch = [SELECT Id, HasOptedOutOfEmail FROM Contact WHERE Id IN :contList];
        
        Integer numberOfContactRecords = 0;
        for(Contact contRec : contsForReviewBeforeBatch){
            System.assertEquals(FALSE, contRec.HasOptedOutOfEmail);
            numberOfContactRecords++;
        }
        System.assertEquals(100, numberOfContactRecords);
        
        Test.startTest();
        BatchUpdateRecordsWithContactEmailOptOut b = new BatchUpdateRecordsWithContactEmailOptOut();
        Database.executeBatch(b);
        Test.stopTest();
        
        //Confirm after batch values.
        List<Contact> contsForReviewAfterBatch = [SELECT Id, HasOptedOutOfEmail FROM Contact WHERE Id IN :contList];
        
        Integer numberOfContactRecordsAfter = 0;
        Integer numberOfLeadRecordsAfter = 0;
        for(Contact contRec : contsForReviewAfterBatch){
            System.assertEquals(TRUE, contRec.HasOptedOutOfEmail);
            numberOfContactRecordsAfter++;    
        }
        
        System.assertEquals(100, numberOfContactRecordsAfter);
    }
}