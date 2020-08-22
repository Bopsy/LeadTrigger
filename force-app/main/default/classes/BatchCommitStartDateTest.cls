/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BatchCommitStartDateTest
*
* @description    Test class for batches BatchCommitStartDateIncludesShortCode and BatchCommitStartDateWithoutShortCode
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-26-12
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes   
* @ChangeLog 
*
**/
@isTest
public class BatchCommitStartDateTest {

    @testSetup static void setup(){
        insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
        Integer numberOfRecords = 5;
        Id orderFormRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Order_Form'].Id;
        
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Account_SID__c sid = new Account_SID__c(Name = 'Test SID');
        insert sid;
        
        List<Opportunity> oppsForInsert = new List<Opportunity>();
        
        for(Integer i = 0; i < numberOfRecords; i++){
            Opportunity newOpp = new Opportunity(Name= 'Test Opp', AccountId = testAcc.Id,
                                                 ForecastCategoryName='Commit', StageName = 'Incubate', 
                                                 CloseDate = Date.today(), Amount = 100, 
                                                 Year_1_Committed_Bookings__c =100);
            
            oppsForInsert.add(newOpp);
        }
        insert oppsForInsert;
                
        List<Apttus__APTS_Agreement__c> agrsForInsert = new List<Apttus__APTS_Agreement__c>();
        for(Integer i = 0; i < numberOfRecords; i++){
            Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c=testAcc.id,
                                                                                    Related_Opportunity_APTS__c= oppsForInsert[i].id,
                                                                                    Total_Committed_Revenue_Input__c = 5000, 
                                                                                    Commit_Frequency__c = 'Monthly', Term_Range__c = '30', 
                                                                                    APTS_Agreement_Effective_Date__c= Date.newInstance(2017,10,3),
                                                                                    Commit_Start_Month__c = Date.newInstance(2017,10,3),
                                                                                    Apttus__Status__c = 'Initiate',Authy_Commit__c = 100,
                                                                                    Programmable_Messaging_Commit__c = 200,Allow_Backdated_Commit__c=false,
                                                                                    recordtypeid=orderFormRecordTypeId);
        	agrsForInsert.add(testAgreement);
        }
        agrsForInsert[0].Commit_Type__c = 'Global';
        agrsForInsert[1].Commit_Type__c = 'Product';
        insert agrsForInsert;
        Billable_Item__c testBI = new Billable_Item__c(Name = 'Short Code', Price__c = 1.0, Status__c = 'Active', Product_Family__c = 'Tester', Product_Group__c = 'Flex');
        insert testBI;
        Single_BI_Discount__c existingDiscount = new Single_BI_Discount__c(Billable_Item__c = testBI.Id, Agreement__c = agrsForInsert[0].Id, Name = 'Short Code');
        insert existingDiscount;
        test.startTest();
    }
    
    static testMethod void testBatch1(){
        test.startTest();
        Database.executeBatch(new BatchCommitStartDateWithoutShortCode());
        Date firstOfThisMonth = Date.today().toStartOfMonth();
        Date newCommitStartDate = firstOfThisMonth.addMonths(1);
        test.stopTest();
        List<Apttus__APTS_Agreement__c> agrsForInsert = [Select Id,RecordType.Name, Commit_Start_Month__c,Apttus__Status__c,Has_Short_Code__c,Allow_Backdated_Commit__c from Apttus__APTS_Agreement__c where Has_Short_Code__c=false];
        for(Apttus__APTS_Agreement__c objAgr: agrsForInsert){
            system.assertEquals(newCommitStartDate, objAgr.Commit_Start_Month__c);
        }
    }
    
    static testMethod void testScheduler1(){
        String CRON_EXP = '0 0 * * * ?';
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest1',
                                       CRON_EXP,
                                       new BatchCommitStartDateWithoutShortCode());
        Test.stopTest();
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchCommitStartDateWithoutShortCode') LIMIT 1].Status);
    }
    
	static testMethod void testBatch2(){
        test.startTest();
        Database.executeBatch(new BatchCommitStartDateIncludesShortCode());
        Date firstOfThisMonth = Date.today().toStartOfMonth();
        test.stopTest();
        List<Apttus__APTS_Agreement__c> agrsForInsert = [Select Id,RecordType.Name, Commit_Start_Month__c,Apttus__Status__c,Has_Short_Code__c,Allow_Backdated_Commit__c from Apttus__APTS_Agreement__c];
        for(Apttus__APTS_Agreement__c objAgr: agrsForInsert){
            system.assertEquals(firstOfThisMonth, objAgr.Commit_Start_Month__c);
        }
    }
    
    static testMethod void testScheduler2(){
        String CRON_EXP = '0 0 * * * ?';
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest2',
                                       CRON_EXP,
                                       new BatchCommitStartDateIncludesShortCode());
        Test.stopTest();
        System.assertEquals('Queued', [SELECT Status
                                       FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'BatchCommitStartDateIncludesShortCode') LIMIT 1].Status);
    }   
}