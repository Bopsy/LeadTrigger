/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CTAInfluenceServicesTest
*
* @description 	  Test class tests the CTAInfluenceServices and BatchUpdateRecordsWithCTAInfluence class.  
*			      Ensures that the Related CTA fields are populated.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-11-20
* @modified       
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class CTAInfluenceServicesTest {

    //Setup test data.
    
    @testSetup static void setup(){
        Integer numberOfRecords = 5;
        Integer dayMultiplier = 20;
        DateTime todaysDate = Date.today();
        List<String> pbNames = new List<String>{'Increase in Usage', 'WoW Decliner', 'WoW Usage Increase'};
        
        CTADigestRecipientRoles__c ctaDigRole = new CTADigestRecipientRoles__c(Name = 'AE - Customer - West III');
        insert ctaDigRole;
        
        CTA_Digest_Valid_Types__c ctaDigValidTypes = new CTA_Digest_Valid_Types__c(Name = 'Event - Usage Increase');
        insert ctaDigValidTypes;
        
        CTADigestURL__c ctaDigSandboxURL = new CTADigestURL__c(Name = 'Full Sandbox Site', URL__c = 'randomUrl.com');
        CTADigestURL__c ctaDigProductionURL = new CTADigestURL__c(Name = 'Production Site', URL__c = 'randomUrl.com');
        CTADigestURL__c ctaDigThumbsUpURL = new CTADigestURL__c(Name = 'ThumbsUp', URL__c = 'ThumbsUpUrl.com');
        CTADigestURL__c ctaDigThumbsDownURL = new CTADigestURL__c(Name = 'ThumbsDown', URL__c = 'ThumbsDownUrl.com');
        List<CTADigestURL__c> ctaDigsURLList = new List<CTADigestURL__c>();
        ctaDigsURLList.add(ctaDigSandboxURL);
        ctaDigsURLList.add(ctaDigProductionURL);
        ctaDigsURLList.add(ctaDigThumbsUpURL);
        ctaDigsURLList.add(ctaDigThumbsDownURL);
        insert ctaDigsURLList;
        
        Profile AEProfile = [Select Id from Profile where name = '**Global AM'];
        List<UserRole> userRoles = [SELECT Id, Name FROM UserRole WHERE Name IN ('AE - Customer - West III', 'AE - Commercial - APAC')];
        Map<String, Id> userRoleNameToIdMap = new Map<String, Id>();
        for(UserRole uRole : userRoles){
            userRoleNameToIdMap.put(uRole.Name, uRole.Id);
        }
        List<User> validUserRecs = [SELECT Id, Name FROM User WHERE UserROle.Name = 'AE - Customer - West III'];
        /*
        User salesUserCustomerWest = new User(Alias = 'standt', Email='ncui11101@twilio.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = AEProfile.Id, UserRoleId = userRoleNameToIdMap.get('AE - Customer - West III'),
            TimeZoneSidKey='America/Los_Angeles', UserName='ramdonguy@123.com');
        
        User salesUserCommAPAC = new User(Alias = 'standt', Email='ncui11102@twilio.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = AEProfile.Id, UserRoleId = userRoleNameToIdMap.get('AE - Commercial - APAC'),
            TimeZoneSidKey='America/Los_Angeles', UserName='ramdonguy@123xxx.com');
        */
        UserPermissionAutoService.bypassTrigger = true;
        
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Account_SID__c sid = new Account_SID__c(Name = 'Test SID');
        insert sid;
        
        Use_Case__c u = new Use_Case__c(Use_Case_Notes__c = 'Test Use Case',
                                        Account__c = testAcc.Id);
        insert u;
        
        Number_of_Days_Back__c n = new Number_of_Days_Back__c(Name = 'CTA Association',
                                                              Historical_Days_Back__c = 14,
                                                              Association_Day_Range__c = 14);
        insert n;
        
        List<Valid_Playbook_Names__c> vpns = new List<Valid_Playbook_Names__c>();
        List<JBCXM__Playbook__c> pbs = new List<JBCXM__Playbook__c>();
        for(String s : pbNames){
        	Valid_Playbook_Names__c v = new Valid_Playbook_Names__c(Name = s);
			JBCXM__Playbook__c pb = new JBCXM__Playbook__c(Name = s);  
            vpns.add(v);
            pbs.add(pb);
        }
        
        insert vpns;
        insert pbs;
        
        JBCXM__PickList__c plRec = new JBCXM__PickList__c(Name = 'Event - Usage Increase',
                                                          JBCXM__SystemName__c = 'Event - Usage Increases');
        insert plRec;
        
        List<JBCXM__CTA__c> ctasForInsert = new List<JBCXM__CTA__c>();
        Date ctaCreatedDate = Date.today().addDays(-3);
        for(User validUser : validUserRecs){
        	for(Integer i = 0; i < 3; i++){
                JBCXM__CTA__c testCTA = new JBCXM__CTA__c(Name = 'Test ' + String.valueOf(i),
                                                          JBCXM__Account__c = testAcc.Id,
                                                          JBCXM__Playbook__c = pbs[0].Id,
                                                          JBCXM__Reason__c = plRec.Id,
                                                          JBCXM__Assignee__c = validUser.Id,
                                                          JBCXM__CreatedDate__c = ctaCreatedDate,
                                                          JBCXM__DueDate__c = ctaCreatedDate.addDays(5));  
                ctasForInsert.add(testCTA);
            }    
        }
        
        //Test negative
        User invalidUserRec = [SELECT Id FROM User WHERE UserRole.Name = 'AE - Commercial - West I' LIMIT 1];
        JBCXM__CTA__c testCTACommercial = new JBCXM__CTA__c(Name = 'Test negative',
                                                   	  JBCXM__Account__c = testAcc.Id,
                                                   	  JBCXM__Playbook__c = pbs[0].Id,
                                                      JBCXM__Assignee__c = invalidUserRec.Id,
                                                      JBCXM__DueDate__c = ctaCreatedDate.addDays(5));  
        //ctasForInsert.add(testCTACommercial);
        insert ctasForInsert;
        
        for(Integer i = 0; i < ctasForInsert.size(); i++){
            Integer tempDaysBack = 1 + (i * dayMultiplier);
            Test.setCreatedDate(ctasForInsert[i].Id, todaysDate.addDays(-tempDaysBack));
        }
        
        List<Opportunity> oppsForInsert = new List<Opportunity>();
        List<Risk__c> risksForInsert = new List<Risk__c>();
        
        for(Integer i = 0; i < numberOfRecords; i++){
            Opportunity testOpp = new Opportunity(Name = 'Test Opp ' + String.valueOf(i), 
                                                  AccountId = testAcc.Id,
                                                  Amount = 10000, 
                                                  FY_16_Primary_Product__c = 'Programmable Messaging',
                                                  FY_16_Primary_Sub_Product__c = 'SMS',
                                                  Solution__c = 'SMS Support', 
                                                  Solution_Category__c = 'Contact Center',
                                                  CloseDate = Date.today(), 
                                                  Launch_Date__c = Date.today().addMonths(1),
                                                  Primary_Competitor__c = 'AWS',
                                                  StageName = 'Closed Won',
                                                  New_Business_Account_SID_Lookup__c = sid.Id); 
            
            Risk__c testRisk = new Risk__c(Name = 'Test RR ' + String.valueOf(i),
                                           Account__c = testAcc.Id,
                                           Resolution_Date__c = Date.today(),
                                           ARR_at_Risk__c = 1,
                                           Risk_Source__c = 'Customer Reached Out',
                                           Risk_Type__c = 'Product Churn',
                                           Risk_Status__c = 'Saved',
                                           Reason_for_Risk__c = 'Product',
                                           Likelihood_of_Save__c = '4',
                                           Use_Case__c = u.Id);
            oppsForInsert.add(testOpp);
            risksForInsert.add(testRisk);
        }
        insert oppsForInsert;
        insert risksForInsert;
        
        //Set the created date for Opportunties and Risk Reports.
        for(Integer i = 0; i < numberOfRecords; i++){
            Integer tempDaysBack = i * dayMultiplier;
            Test.setCreatedDate(oppsForInsert[i].Id, todaysDate.addDays(-tempDaysBack));
            Test.setCreatedDate(risksForInsert[i].Id, todaysDate.addDays(-tempDaysBack));
        }
    }
    
    /*
     * Test method to ensure relevant CTAs are being associated to Opportunities.
     */
    private static testMethod void ensure_CTAs_Are_Associated_to_Opportunities() {
        List<JBCXM__CTA__c> ctasForInsert = [SELECT Id, CreatedDate, Name FROM JBCXM__CTA__c];
        Map<Id, JBCXM__CTA__c> ctaMap = new Map<Id, JBCXM__CTA__c>(ctasForInsert);
        Test.startTest();
        BatchUpdateRecordsWithCTAInfluence b = new BatchUpdateRecordsWithCTAInfluence();
        Database.executeBatch(b);
        Test.stopTest();
        
        List<Opportunity> oppsForReview = [SELECT Id, Name, CreatedDate, Related_CTA__c FROM Opportunity];
        for(Opportunity o : oppsForReview){
            
            if(o.Related_CTA__c != null){
                //System.debug('Opportunity Created Date -> ' + o.CreatedDate + ' | CTA Created Date -> ' + ctaMap.get(o.Related_CTA__c).CreatedDate);
            	System.assert(o.CreatedDate > ctaMap.get(o.Related_CTA__c).CreatedDate);    
            } else {
                System.assert(!o.Name.Contains('0'));
                //System.assert(!o.Name.Contains('1'));
                //System.assert(!o.Name.Contains('2'));
            }
        }
        for(JBCXM__CTA__c c : ctasForInsert){
            System.debug('CTA - ' + c);
        }
    }
    
    /*
     * Test method to ensure relevant CTAs are being associated to Risk Reports.
     */
    private static testMethod void ensure_CTAs_Are_Associated_to_Risk_Reports() {
        List<JBCXM__CTA__c> ctasForInsert = [SELECT Id, CreatedDate, Name FROM JBCXM__CTA__c];
        Map<Id, JBCXM__CTA__c> ctaMap = new Map<Id, JBCXM__CTA__c>(ctasForInsert);
        Test.startTest();
        BatchUpdateRecordsWithCTAInfluence b = new BatchUpdateRecordsWithCTAInfluence();
        Database.executeBatch(b);
        Test.stopTest();
        
        List<Risk__c> risksForReview = [SELECT Id, Name, CreatedDate, Related_CTA__c FROM Risk__c];
        for(Risk__c r : risksForReview){
            if(r.Related_CTA__c != null){
                System.assert(r.CreatedDate > ctaMap.get(r.Related_CTA__c).CreatedDate);    
            } else {
                System.assert(!r.Name.Contains('0'));
                System.assert(!r.Name.Contains('1'));
                System.assert(!r.Name.Contains('2'));
            }
        }
    }
    
	/*
     * Test method to ensure relevant recipients are receiving a CTA Digest email.
     */    
    private static testMethod void ensure_Digests_Are_Created_For_CTAs_with_valid_Recipient(){
        List<JBCXM__CTA__c> ctasForInsert = [SELECT Id, CreatedDate, Name FROM JBCXM__CTA__c];
        List<JBCXM__CTA__c> ctasForUpdate = new List<JBCXM__CTA__c>();
        for(JBCXM__CTA__c ctaRec : ctasForInsert){
            ctaRec.JBCXM__CreatedDate__c = Date.today().addDays(-3);
            ctasForUpdate.add(ctaRec);
        }
		update ctasForUpdate;
        
        test.startTest();
        BatchSendCIAEmails b = new BatchSendCIAEmails();
		Database.executeBatch(b, 200);
        test.stopTest();
        List<User> validUserRecs = [SELECT Id, Name, Email FROM User WHERE UserRole.Name = 'AE - Customer - West III'];
        
        
        List<CTA_Digest__c> ctaDigForReview = [SELECT Id, Owner.Name FROM CTA_Digest__c];
        for(CTA_Digest__c ctaDig : ctaDigForReview){
            //System.assertEquals('AE - Customer - West III', ctaDig.Owner.UserRole.Name);
            System.debug('UserRole Name -->' + ctaDig.Owner.Name);
        }
        System.assertEquals(validUserRecs.size(), ctaDigForReview.size());
        
        List<JBCXM__CTA__c> ctasForReview = [SELECT Id, JBCXM__Assignee__r.UserRole.Name, JBCXM__Assignee__r.Name, JBCXM__Assignee__c, CreatedDate, Name, CTA_Digest__c FROM JBCXM__CTA__c];
        Set<id> digestIds = new Set<Id>();
        for(JBCXM__CTA__c ctaRec : ctasForReview){
            if(ctaRec.JBCXM__Assignee__r.UserRole.Name == 'AE - Commercial - West I'){
                System.assertEquals(null, ctaRec.CTA_Digest__c);
            }
            digestIds.add(ctaRec.CTA_Digest__c);
        }
        System.assertEquals(validUserRecs.size(), digestIds.size());
    }
    
    /*
     * Test method to ensure certain Salespeople are NOT receiving a CTA Digest email.
     */    
    private static testMethod void ensure_Digests_Are_NOT_Created_For_Invalid_Recipient(){
        List<JBCXM__CTA__c> ctasForInsert = [SELECT Id, CreatedDate, Name FROM JBCXM__CTA__c];
        List<JBCXM__CTA__c> ctasForUpdate = new List<JBCXM__CTA__c>();
        for(JBCXM__CTA__c ctaRec : ctasForInsert){
            ctaRec.JBCXM__CreatedDate__c = Date.today().addDays(-3);
            ctasForUpdate.add(ctaRec);
        }
		update ctasForUpdate;
        
        test.startTest();
        BatchSendCIAEmails b = new BatchSendCIAEmails();
		Database.executeBatch(b, 200);
        test.stopTest();
        
        List<CTA_Digest__c> ctaDigsForReview = new List<CTA_Digest__c>();
        ctaDigsForReview = [SELECT Id FROM CTA_Digest__c WHERE Owner.UserRole.Name != 'AE - Customer - West III'];
        
        System.assertEquals(0, ctaDigsForReview.size());
    }
    
}