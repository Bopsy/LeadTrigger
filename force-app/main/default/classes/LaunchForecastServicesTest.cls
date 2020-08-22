/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  LaunchForecastServicesTest
*
* @description 	  Test class tests the LaunchForecastServices and BatchUpdateLaunchPlanForecast class.  
*			      Ensures that the Launch Plan Forecasts are created.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-09-05
* @modified       
* @systemLayer    Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
public class LaunchForecastServicesTest {
	private static Integer numberOfForecastScheds = 12;
    private static Integer numberOfLaunchPlanRecs = 2;
    private static Date todaysDate = Date.today();
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    @testSetup static void setup(){
        Account testAcc = new Account(Name = 'Test Acc');
        insert testAcc;
        
        Account_SID__c sid = new Account_SID__c(Name = 'Test SID');
        insert sid;
        
        Opportunity testOpp = new Opportunity(Name = 'Test opp', 
                                              AccountId = testAcc.Id,
                                              Amount = 10000, 
                                              FY_16_Primary_Product__c = 'Programmable Messaging',
                                              FY_16_Primary_Sub_Product__c = 'SMS',
                                              Solution__c = 'SMS Support', 
                                              Solution_Category__c = 'Contact Center',
                                              CloseDate = Date.today(), 
                                              Launch_Date__c = Date.today().addMonths(1),
                                              StageName = 'Closed Won',
                                              New_Business_Account_SID_Lookup__c = sid.Id);
        insert testOpp;
        
        LeadTriggerHandler.runOnce = true;
        List<Forecast_Schedule__c> fsRecs = new List<Forecast_Schedule__c>();
        for(Integer i = 0; i < numberOfForecastScheds; i++){
            Forecast_Schedule__c f = new Forecast_Schedule__c(Forecast_Amount__c = 1000 + i,
                                                              Opportunity__c = testOpp.Id);
            fsRecs.add(f);
        }
        System.debug('Number of FS Recs for Insert -> ' + fsRecs.size());
        insert fsRecs;
        
        List<Launch_Plan__c> lpRecs = new List<Launch_Plan__c>();
        for(Integer i = 0; i < numberOfLaunchPlanRecs; i++){
            Launch_Plan__c l = new Launch_Plan__c(Name = 'LP ' + i,
                                                  Opportunity__c = testOpp.Id);
            lpRecs.add(l);
        }
        System.debug('Number of LP Recs for Insert -> ' + lpRecs.size());
        insert lpRecs;
        
        List<Launch_Plan_Forecast_Mapping__c> lpfmList = new List<Launch_Plan_Forecast_Mapping__c>();
        lpfmList.add(new Launch_Plan_Forecast_Mapping__c(Name = 'Fiscal Year',
                                                         Source_Field_API_Name__c = 'Fiscal_Year__c',
                                                         Target_Field_API_Name__c = 'Fiscal_Year__c'));
        lpfmList.add(new Launch_Plan_Forecast_Mapping__c(Name = 'Forecast Amount',
                                                         Source_Field_API_Name__c = 'Forecast_Amount__c',
                                                         Target_Field_API_Name__c = 'Forecast_Amount__c'));
		insert lpfmList;
    }
    
    private static testMethod void ensure_Launch_Plan_Forecasts_are_Created() {
        Map<Id, Forecast_Schedule__c> fsMap = new Map<Id, Forecast_Schedule__c>();
        List<Forecast_Schedule__c> fsRecs = [SELECT Id, Opportunity__c, Fiscal_Year__c, Forecast_Amount__c FROM FOrecast_Schedule__c];
        List<Launch_Plan__c> lpRecs = [SELECT Id FROM Launch_Plan__c];
        
        for(Forecast_Schedule__c f : fsRecs){
            fsMap.put(f.Id, f);
        }
        
        test.startTest();
        BatchUpdateLaunchPlanForecast b = new BatchUpdateLaunchPlanForecast();
		Database.executeBatch(b, 100);
        test.stopTest();
                        
        Integer i = fsRecs.size() * lpRecs.size();
        List<Launch_Plan_Forecast__c> lpfRecs = new List<Launch_Plan_Forecast__c>();
        lpfRecs = [SELECT Id, Fiscal_Year__c, Forecast_Amount__c, Forecast_Schedule__c FROM Launch_Plan_Forecast__c];
        System.assertEquals(i, lpfRecs.size());
        
        for(Launch_Plan_Forecast__c lpf : lpfRecs){
            Forecast_Schedule__c fs = fsMap.get(lpf.Forecast_Schedule__c);
            System.assertEquals(fs.Forecast_Amount__c, lpf.Forecast_Amount__c);
            System.assertEquals(fs.Fiscal_Year__c, lpf.Fiscal_Year__c);
        }
    }
    
    private static testMethod void ensure_Schedule_Class_Runs(){
        
        test.startTest();
        // Schedule the test job
        String jobId = System.schedule('BatchUpdateLaunchPlanForecast',
                        CRON_EXP, 
                        new BatchUpdateLaunchPlanForecast());
         
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, 
         ct.CronExpression);
    }
}