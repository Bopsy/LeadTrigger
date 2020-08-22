/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  BatchSendCIAEmailsTest
*
* @description 	  Test class tests the BatchSendCIAEmails class.  
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2020-01-13
* @modified       
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class BatchSendCIAEmailsTest {

    //Setup test data.
    
    @testSetup static void setup(){
        Integer numberOfRecords = 5;
        Integer dayMultiplier = 20;
        DateTime todaysDate = Date.today();
        List<String> pbNames = new List<String>{'Increase in Usage', 'WoW Decliner', 'WoW Usage Increase'};
        
        CTADigestRecipientRoles__c ctaDigRole = new CTADigestRecipientRoles__c(Name = 'AE - Enterprise - West I');
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
        List<UserRole> userRoles = [SELECT Id, Name FROM UserRole WHERE Name IN ('AE - Enterprise - West I', 'AE - Commercial - APAC')];
        Map<String, Id> userRoleNameToIdMap = new Map<String, Id>();
        for(UserRole uRole : userRoles){
            userRoleNameToIdMap.put(uRole.Name, uRole.Id);
        }
        List<User> validUserRecs = [SELECT Id, Name FROM User WHERE UserROle.Name = 'AE - Enterprise - West I' AND IsActive = TRUE];
        
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
        User invalidUserRec = [SELECT Id FROM User WHERE UserRole.Name = 'AE - Commercial - West I' AND IsActive = TRUE LIMIT 1];
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
        List<User> validUserRecs = [SELECT Id, Name, Email FROM User WHERE UserRole.Name = 'AE - Enterprise - West I' AND IsActive = TRUE];
        
        
        List<CTA_Digest__c> ctaDigForReview = [SELECT Id, Owner.Name FROM CTA_Digest__c];
        for(CTA_Digest__c ctaDig : ctaDigForReview){
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
        ctaDigsForReview = [SELECT Id FROM CTA_Digest__c WHERE Owner.UserRole.Name != 'AE - Enterprise - West I'];
        
        System.assertEquals(0, ctaDigsForReview.size());
    }
    
    
    // CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    static testmethod void scheduleBatchJob() {

      Test.startTest();

      // Schedule the test job
      String jobId = System.schedule('BatchSendCIAEmailsTestClass', CRON_EXP, new BatchSendCIAEmails());

      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId ];

      // Verify the expressions are the same
      System.assertEquals(CRON_EXP, ct.CronExpression);

      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the next time the job will run
      System.assertEquals('2022-03-15 00:00:00',
      String.valueOf(ct.NextFireTime));

      Test.stopTest();
   }
}