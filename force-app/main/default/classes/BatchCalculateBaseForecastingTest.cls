@isTest
private class BatchCalculateBaseForecastingTest {

    private static testMethod void test() {
        Account testAcc = new Account(Total_Amortized_Twilio_Usage_This_Month__c = 8000, July_2019_Base_Forecast_Batch__c = 8000, July_2019_Target_Revenue__c = 8000, August_2019_Target_Revenue__c = 9000, 
                                      October_2019_Target_Revenue__c = 11000, September_2019_Target_Revenue__c = 10000,
                                      Name = 'Test Acc', September_2019_Base_Forecast_SOPS__c = 10000, 
                                      October_2019_Base_Forecast_Override__c = 12000, November_2019_Target_Revenue__c = 12000,
                                      December_2019_Target_Revenue__c = 13000/*, January_2019_Target_Revenue__c = 14000,
                                      February_2019_Target_Revenue__c = 15000, March_2019_Target_Revenue__c = 16000,
                                      April_2019_Target_Revenue__c = 17000, May_2019_Target_Revenue__c = 18000, June_2019_Target_Revenue__c = 19000*/);
        insert testAcc;
        
        Account_Base_Forecast_Mapping__c setting1 = new Account_Base_Forecast_Mapping__c(Name = 'July', Month__c = 7, Year__c = 2019, Forecast_Target_Field__c = 'July_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'July_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'July_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'July_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting2 = new Account_Base_Forecast_Mapping__c(Name = 'August', Month__c = 8, Year__c = 2019, Forecast_Target_Field__c = 'August_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'August_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'August_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'August_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting3 = new Account_Base_Forecast_Mapping__c(Name = 'September', Month__c = 9, Year__c = 2019, Forecast_Target_Field__c = 'September_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'September_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'September_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'September_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting4 = new Account_Base_Forecast_Mapping__c(Name = 'October', Month__c = 10, Year__c = 2019, Forecast_Target_Field__c = 'October_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'October_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'October_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'October_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting5 = new Account_Base_Forecast_Mapping__c(Name = 'November', Month__c = 11, Year__c = 2019, Forecast_Target_Field__c = 'November_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'November_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'November_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'November_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting6 = new Account_Base_Forecast_Mapping__c(Name = 'December', Month__c = 12, Year__c = 2019, Forecast_Target_Field__c = 'December_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'December_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'December_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'December_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting7 = new Account_Base_Forecast_Mapping__c(Name = '18 January', Month__c = 1, Year__c = 2019, Forecast_Target_Field__c = 'January_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'January_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'January_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'January_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting8 = new Account_Base_Forecast_Mapping__c(Name = '18 Fen', Month__c = 2, Year__c = 2019, Forecast_Target_Field__c = 'February_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'February_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'February_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'February_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting9 = new Account_Base_Forecast_Mapping__c(Name = '18 Mar', Month__c = 3, Year__c = 2019, Forecast_Target_Field__c = 'March_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'March_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'March_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'March_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting10 = new Account_Base_Forecast_Mapping__c(Name = '18 April', Month__c = 4, Year__c = 2019, Forecast_Target_Field__c = 'April_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'April_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'April_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'April_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting11 = new Account_Base_Forecast_Mapping__c(Name = '18 May', Month__c = 5, Year__c = 2019, Forecast_Target_Field__c = 'May_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'May_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'May_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'May_2019_Base_Forecast_Override__c');
        Account_Base_Forecast_Mapping__c setting12 = new Account_Base_Forecast_Mapping__c(Name = '18 June', Month__c = 6, Year__c = 2019, Forecast_Target_Field__c = 'June_2019_Target_Revenue__c', 
                                                     Forecast_Batch_Field__c = 'June_2019_Base_Forecast_Batch__c',
                                                     Forecast_SOPS_Field__c = 'June_2019_Base_Forecast_SOPS__c',
                                                     Forecast_Override_Field__c = 'June_2019_Base_Forecast_Override__c');
        insert new List<Account_Base_Forecast_Mapping__c>{setting1, setting2, setting3, setting4, setting5, setting6, setting7, setting8, setting9, setting10, setting11, setting12};
                                                    
        
        Test.startTest();
            Database.executeBatch(new BatchCalculateBaseForecasting());
        Test.stopTest();
    }

}