global class BatchCalculateBaseForecasting implements Database.Batchable<SObject>, Schedulable{
    
    global static Map<Integer, String> monthToForecastFieldMap = new Map<Integer, String>();
    
    global static Map<Integer, String> monthToAutoForecastFieldMap = new Map<Integer, String>();
    
    global static Map<Integer, String> monthToAutoSOPSFieldMap = new Map<Integer, String>();
    
    global static Map<Integer, String> monthToAutoOverrideFieldMap = new Map<Integer, String>();
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCalculateBaseForecasting());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        String queryString = 'SELECT Id, Total_Amortized_Twilio_Usage_This_Month__c, Q3_2018_Base_Forecast_Final__c, Q4_2018_Base_Forecast_Final__c';
        
        for(Account_Base_Forecast_Mapping__c setting: Account_Base_Forecast_Mapping__c.getAll().values()){
            queryString += ' ,' + setting.Forecast_Target_Field__c + ' ,' +setting.Forecast_Batch_Field__c + ' ,' + setting.Forecast_SOPS_Field__c + ' ,' + setting.Forecast_Override_Field__c;
        }
        
        queryString += ' FROM Account';
        
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accounts){
        calculateForecasts(accounts);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
    
    global static void initSettings(){
        for(Account_Base_Forecast_Mapping__c setting: Account_Base_Forecast_Mapping__c.getAll().values()){
            monthToForecastFieldMap.put(Integer.valueOf(setting.Year__c) * 100 + Integer.valueOf(setting.Month__c), setting.Forecast_Target_Field__c);
            monthToAutoForecastFieldMap.put(Integer.valueOf(setting.Year__c) * 100 + Integer.valueOf(setting.Month__c), setting.Forecast_Batch_Field__c);
            monthToAutoSOPSFieldMap.put(Integer.valueOf(setting.Year__c) * 100 + Integer.valueOf(setting.Month__c), setting.Forecast_SOPS_Field__c);
            monthToAutoOverrideFieldMap.put(Integer.valueOf(setting.Year__c) * 100 + Integer.valueOf(setting.Month__c), setting.Forecast_Override_Field__c);
        }
    }
    
    global static void calculateForecasts(List<Account> accounts){
        initSettings();
        Integer thisMonth =  Test.isRunningTest() ? 8 : Date.today().month();
        Integer thisYear =   Test.isRunningTest() ? 2018 : Date.today().year();
        Integer totalMonth = Test.isRunningTest() ? 13 : 13;
        for(Account acc: accounts){
            acc.put( monthToAutoForecastFieldMap.get(thisYear * 100 + thisMonth), calculateCurrentMonthForecast(acc));
            for(Integer i = thisMonth + 1; i < totalMonth; i++){
                 acc.put( monthToAutoForecastFieldMap.get(thisYear * 100 + i), cauculateFutureMonthForecast(thisYear, i, acc));
            }
            processReportFields(acc);
        }
        Database.update(accounts, false);
    }
    
    
    global static void processReportFields(Account acc){
        Integer month = Test.isRunningTest() ? 8 : Date.today().month();
        Integer year = Test.isRunningTest() ? 2018 :Date.today().year();
        if(year == 2018){
            if(month == 7 || month == 8 || month == 9){
                acc.Current_Quarter_Base_Forecast__c = acc.Q3_2018_Base_Forecast_Final__c;
            }
            else if(month == 10 || month == 11 || month == 12){
                acc.Current_Quarter_Base_Forecast__c = acc.Q4_2018_Base_Forecast_Final__c;
            }
        }
        else if (year == 2019){
            if(month == 1 || month == 2 || month == 3){
                acc.Current_Quarter_Base_Forecast__c = acc.Q1_2019_Base_Forecast_Final__c;
            }
            else if(month == 4 || month == 5 || month == 6){
                acc.Current_Quarter_Base_Forecast__c = 0; //acc.Q2_2019_Base_Forecast_Final__c;
            }
            else if(month == 7 || month == 8 || month == 9){
                //acc.Current_Quarter_Base_Forecast__c = acc.Q3_2017_Base_Forecast_Final__c;
            }
            else if(month == 10 || month == 11 || month == 12){
                //acc.Current_Quarter_Base_Forecast__c = acc.Q4_2017_Base_Forecast_Final__c;
            }
        }
        Integer previousMonth = month == 1 ? 12 : month - 1;
        Integer yearNumber = month == 1 ? year - 1: year;
        acc.Current_Month_Base_Forecast__c = getFinalBaesForecast(year, month, acc);
        acc.Prior_Month_Base_Forecast__c = getFinalBaesForecast(yearNumber, previousMonth , acc);
    }
    
    
    global static Decimal getFinalBaesForecast(Integer year, Integer month, Account acc){
        Object overrideValue = acc.get(monthToAutoOverrideFieldMap.get(year*100 + month));
        if(overrideValue != null) return (Decimal) overrideValue;
        Object sopsValue = acc.get(monthToAutoSOPSFieldMap.get(year*100 + month));
        if(sopsValue != null) return (Decimal) sopsValue;
        Object forecastValue = acc.get(monthToAutoForecastFieldMap.get(year*100 + month));
        if(forecastValue != null) return (Decimal) forecastValue; else return 0;
    }
    
    global static Decimal getCurrentPercentDays(){
        Date currentDate = Test.isRunningTest() ? Date.newInstance(2018, 1, 1) : Date.today();
        Date startDate = currentDate.toStartOfMonth();
        Date endDate = currentDate.addMonths(1).toStartOfMonth();
        
        Decimal dateInMonths = startDate.daysBetween(endDate);
        Decimal dateDiff = currentDate.daysBetween(endDate);
        //There is a 1 day delay on Usage records
        Decimal result = dateInMonths / (dateInMonths - dateDiff);
    
        return result;
    }
    
    global static Decimal calculateCurrentMonthForecast(Account acc){
        Integer day = Test.isRunningTest()? 1 : Date.today().day();
        Integer year = Test.isRunningTest()? 2018 : Date.today().year();
        Integer month = Test.isRunningTest()? 8 : Date.today().month();
        if(day <= 8) return cauculateFutureMonthForecast(year, month, acc);
        Decimal realUsage = acc.Total_Amortized_Twilio_Usage_This_Month__c;
        if(realUsage == null) return 0;
        return realUsage * getCurrentPercentDays();
    }
    
    global static Decimal cauculateFutureMonthForecast(Integer year, Integer month, Account acc){
        Integer previousMonth = month == 1 ? 12 : month - 1;
        Integer yearNumber = month == 1 ? year - 1: year;
        Object overrideValue = acc.get(monthToAutoOverrideFieldMap.get(yearNumber * 100 + previousMonth));
        if(overrideValue != null) return ((Decimal) overrideValue) * calculateMonthRate(year, month, acc);
        Object sopsValue = acc.get(monthToAutoSOPSFieldMap.get(yearNumber * 100 + previousMonth));
        if(sopsValue != null) return ((Decimal) sopsValue) * calculateMonthRate(year, month, acc);
        Decimal base = (Decimal) acc.get(monthToAutoForecastFieldMap.get(yearNumber * 100 + previousMonth));
        if(base == null) base = 0;
        return base * calculateMonthRate(year, month, acc);
    }
    
    global static Decimal calculateMonthRate(Integer year, Integer month, Account acc){
        Decimal nextMonthForecast = null;
        Integer previousMonth = month == 1 ? 12 : month - 1;
        Integer yearNumber = month == 1 ? year - 1: year;
        Decimal thisMonthForecast = (Decimal) acc.get(monthToForecastFieldMap.get(yearNumber * 100 + previousMonth));
        if(monthToForecastFieldMap.get(year * 100 + month) != null) nextMonthForecast = (Decimal) acc.get(monthToForecastFieldMap.get(year * 100 + Month));
        if(thisMonthForecast == null || thisMonthForecast == 0 || nextMonthForecast == null) return 0;
        return nextMonthForecast / thisMonthForecast;
    }
}