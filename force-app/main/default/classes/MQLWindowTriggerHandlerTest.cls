/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  MQLWindowTriggerHandlerTest
*
* @description 	  Test class tests the MQLWindowTrigger and MQLWindowTriggerHandler class.  
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-11-05
* @modified       
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class MQLWindowTriggerHandlerTest {
    @testSetup static void setupTestData(){
        List<Lead> leadsForInsert = new List<Lead>();
        List<Contact> contactsForInsert = new List<Contact>();
        
        for(Integer i = 0; i < 2; i++){
            Lead testLead = new Lead(LastName = 'Test ' + i, 
                                 Email = 'test@test-lead-autoconvert-12345.com' + String.valueOf(i), 
                                 Company = 'Test Function');
            leadsForInsert.add(testLead);
            
            Contact testContact = new Contact(LastName = 'Test ' + i, 
                                 Email = 'test@test-lead-autoconvert-12345.com' + String.valueOf(i));
            contactsForInsert.add(testContact);
        }
        
        insert leadsForInsert;
        insert contactsForInsert;
        
        List<MQL_Window__c> mqlWindowsForInsert = new List<MQL_Window__c>();
        for(Integer i = 0; i < 5; i++){
            Date tempDate = Date.today().addMonths(i);
            MQL_Window__c newMQLWindow = new MQL_Window__c(Name = 'Test MQL Window ' + i,
                                                           MQL_Window_Open_Date__c = tempDate,
                                                           MQL_Window_Status__c = 'Open');
            if(i == 2){
                newMQLWindow.Lead__c = leadsForInsert[1].Id;
                newMQLWindow.Contact__c = contactsForInsert[1].Id;
            } else {
                newMQLWindow.Lead__c = leadsForInsert[0].Id;
                newMQLWindow.Contact__c = contactsForInsert[0].Id;
            }
            mqlWindowsForInsert.add(newMQLWindow);
        }
        insert mqlWindowsForInsert;
    }
    
    private static testMethod void ensure_MQL_Windows_Are_Merged_and_Closed_On_Lead_Lookup_Update(){
        List<MQL_Window__c> mqlWindowsForUpdate = new List<MQL_Window__c>();
        List<MQL_Window__c> mqlWindowsForReview = new List<MQL_Window__c>();
        Lead testLead = [SELECT Id FROM Lead WHERE Name = 'Test 1'];
        mqlWindowsForReview = [SELECT Id, 
                              		  MQL_Window_Open_Date__c,
                              		  MQL_Window_Status__c,
                                	  Lead__c
                               FROM MQL_Window__c];
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReview){
            System.assertEquals('Open', mqlWindowRec.MQL_Window_Status__c);
            if(mqlWindowRec.Lead__c != testLead.Id){
                mqlWindowRec.Contact__c = null;
                mqlWindowRec.Lead__c = testLead.Id;
                mqlWindowsForUpdate.add(mqlWindowRec);
            }
        }
        
        for(MQL_Window__c leadMQLWindow : mqlWindowsForUpdate){
         	System.debug('*** Lead MQL Window For Update ---> ' + leadMQLWindow);   
        }
        
        Test.startTest();
        update mqlWindowsForUpdate;
        Test.stopTest();
        
        List<MQL_Window__c> mqlWindowsForReviewPostUpdate = [SELECT Id, 
                                                                    MQL_Window_Open_Date__c,
                                                                    MQL_Window_Status__c,
                                                                    Lead__c
                                                             FROM MQL_Window__c];
        System.debug('MQL Windows for Review Post Update Lead --> ' + mqlWindowsForReview);
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReviewPostUpdate){
            System.debug('MQL Window Record Post Update Lead --> ' + mqlWindowRec);
        }
    }
    private static testMethod void ensure_MQL_Windows_Are_Merged_and_Closed_On_Contact_Lookup_Update(){
        List<MQL_Window__c> mqlWindowsForUpdate = new List<MQL_Window__c>();
        List<MQL_Window__c> mqlWindowsForReview = new List<MQL_Window__c>();
        Contact testContact = [SELECT Id FROM Contact WHERE Name = 'Test 1'];
        mqlWindowsForReview = [SELECT Id, 
                              		  MQL_Window_Open_Date__c,
                              		  MQL_Window_Status__c,
                                	  Contact__c
                               FROM MQL_Window__c];
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReview){
            System.assertEquals('Open', mqlWindowRec.MQL_Window_Status__c);
            if(mqlWindowRec.Contact__c != testContact.Id){
                mqlWindowRec.Lead__c = null;
                mqlWindowRec.Contact__c = testContact.Id;
                mqlWindowsForUpdate.add(mqlWindowRec);
            }
        }
        
        for(MQL_Window__c contactMQLWindow : mqlWindowsForUpdate){
         	System.debug('*** Contact MQL Window For Update ---> ' + contactMQLWindow);   
        }
        
        Test.startTest();
        update mqlWindowsForUpdate;
        Test.stopTest();
        
        List<MQL_Window__c> mqlWindowsForReviewPostUpdate = [SELECT Id, 
                                                                    MQL_Window_Open_Date__c,
                                                                    MQL_Window_Status__c,
                                                                    Contact__c
                                                             FROM MQL_Window__c];
        System.debug('MQL Windows for Review Post Update Contact --> ' + mqlWindowsForReview);
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReviewPostUpdate){
            System.debug('MQL Window Record Post Update Contact --> ' + mqlWindowRec);
        }
    }
    
    private static testMethod void ensure_MQL_Windows_Are_Merged_and_Closed_On_Lead_Merge() {
        List<MQL_Window__c> mqlWindowsForUpdate = new List<MQL_Window__c>();
        List<MQL_Window__c> mqlWindowsForReview = new List<MQL_Window__c>();
        Lead masterLead = new Lead();
        List<Lead> leadsForMerge = new List<Lead>();
        List<Lead> testLeads = [SELECT Id, LastName FROM Lead];
        
        for(Lead leadRec : testLeads){
            if(leadRec.LastName == 'Test 1'){
                masterLead = leadRec;
            } else {
                leadsForMerge.add(leadRec);
            }
        }
        
        Integer numberOfMasterLeadMQLWindows = 0;
        Integer numberOfMergeLeadMQLWindows = 0;
        mqlWindowsForReview = [SELECT Id, 
                              		  MQL_Window_Open_Date__c,
                              		  MQL_Window_Status__c,
                                	  Lead__c
                               FROM MQL_Window__c];
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReview){
            System.assertEquals('Open', mqlWindowRec.MQL_Window_Status__c);
            mqlWindowRec.Contact__c = null;
            mqlWindowsForUpdate.add(mqlWindowRec);
            System.debug('MQL Window Lead Id ---> ' + mqlWindowRec.Lead__c);
            if(mqlWindowRec.Lead__c == masterLead.Id){
                numberOfMasterLeadMQLWindows++;
            } else {
                numberOfMergeLeadMQLWindows++;
            }
        }
        
        System.assertEquals(1, numberOfMasterLeadMQLWindows);
        System.assertEquals(4, numberOfMergeLeadMQLWindows);
        
        test.startTest();
        List<Database.MergeResult> mergedResults = Database.merge(masterLead, leadsForMerge);
        test.stopTest();
        
        for(Database.MergeResult mergeResultRec : mergedResults){
            System.assertEquals(true, mergeResultRec.isSuccess());
        }
        
        Integer numberOfOpenMQLWindows = 0;
        Integer numberOfMergeClosedMQLWindows = 0;
        List<MQL_Window__c> mqlWindowsForReviewPostUpdate = [SELECT Id,
                                                            		MQL_Window_Open_Date__c,
                                                                    MQL_Window_Status__c,
                                                                    Lead__c,
                                                            		Contact__c
                                                             FROM MQL_Window__c];
        
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReviewPostUpdate){
            System.assertEquals(masterLead.Id, mqlWindowRec.Lead__c);
            if(mqlWindowRec.MQL_Window_Status__c == 'Open'){
                numberOfOpenMQLWindows++;
                System.assertEquals(Date.today(), mqlWindowRec.MQL_Window_Open_Date__c);
            } else if (mqlWindowRec.MQL_Window_Status__c == 'Merged and Closed'){
                numberOfMergeClosedMQLWindows++;
            }
            
        }
        
        System.assertEquals(1, numberOfOpenMQLWindows);
        System.assertEquals(4, numberOfMergeClosedMQLWindows);
    }
    
    private static testMethod void ensure_MQL_Windows_Are_Merged_and_Closed_On_Contact_Merge() {
        List<MQL_Window__c> mqlWindowsForUpdate = new List<MQL_Window__c>();
        List<MQL_Window__c> mqlWindowsForReview = new List<MQL_Window__c>();
        Contact masterContact = new Contact();
        List<Contact> contactsForMerge = new List<Contact>();
        List<Contact> testContacts = [SELECT Id, LastName FROM Contact];
        
        for(Contact contactRec : testContacts){
            if(contactRec.LastName == 'Test 1'){
                masterContact = contactRec;
            } else {
                contactsForMerge.add(contactRec);
            }
        }
        
        Integer numberOfMasterContactMQLWindows = 0;
        Integer numberOfMergeContactMQLWindows = 0;
        mqlWindowsForReview = [SELECT Id, 
                              		  MQL_Window_Open_Date__c,
                              		  MQL_Window_Status__c,
                                	  Contact__c
                               FROM MQL_Window__c];
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReview){
            System.assertEquals('Open', mqlWindowRec.MQL_Window_Status__c);
            mqlWindowRec.Lead__c = null;
            mqlWindowsForUpdate.add(mqlWindowRec);
            System.debug('MQL Window Contact Id ---> ' + mqlWindowRec.Contact__c);
            if(mqlWindowRec.Contact__c == masterContact.Id){
                numberOfMasterContactMQLWindows++;
            } else {
                numberOfMergeContactMQLWindows++;
            }
        }
        
        System.assertEquals(1, numberOfMasterContactMQLWindows);
        System.assertEquals(4, numberOfMergeContactMQLWindows);
        
        MQL_Window__c testMQLWindowOpen = new MQL_Window__c();
        List<MQL_Window__c> testMQLWindowsOpen = [SELECT Id,
                                                  		 MQL_Window_Open_Date__c
                                                  FROM MQL_Window__c 
                                                  WHERE Contact__c != :masterContact.Id 
                                                  	AND MQL_Window_Status__c = 'Open' 
                                                  ORDER BY MQL_Window_Open_Date__c DESC];
        
        Date oldestMQLWindowDate = Date.today().addMonths(-4);
        testMQLWindowOpen = testMQLWindowsOpen[0];
        testMQLWindowOpen.MQL_Window_Open_Date__c = oldestMQLWindowDate;
        update testMQLWindowOpen;
        
        test.startTest();
        List<Database.MergeResult> mergedResults = Database.merge(masterContact, contactsForMerge);
        test.stopTest();
        
        for(Database.MergeResult mergeResultRec : mergedResults){
            System.assertEquals(true, mergeResultRec.isSuccess());
        }
        
        Integer numberOfOpenMQLWindows = 0;
        Integer numberOfMergeClosedMQLWindows = 0;
        List<MQL_Window__c> mqlWindowsForReviewPostUpdate = [SELECT Id,
                                                            		MQL_Window_Open_Date__c,
                                                                    MQL_Window_Status__c,
                                                                    Lead__c,
                                                            		Contact__c
                                                             FROM MQL_Window__c];
        
        for(MQL_Window__c mqlWindowRec : mqlWindowsForReviewPostUpdate){
            System.assertEquals(masterContact.Id, mqlWindowRec.Contact__c);
            if(mqlWindowRec.MQL_Window_Status__c == 'Open'){
                numberOfOpenMQLWindows++;
                //System.assertEquals(Date.today(), mqlWindowRec.MQL_Window_Open_Date__c);
                System.assertEquals(oldestMQLWindowDate, mqlWindowRec.MQL_Window_Open_Date__c);
            } else if (mqlWindowRec.MQL_Window_Status__c == 'Merged and Closed'){
                numberOfMergeClosedMQLWindows++;
            }
            
        }
        
        System.assertEquals(1, numberOfOpenMQLWindows);
        System.assertEquals(4, numberOfMergeClosedMQLWindows);
    }
}