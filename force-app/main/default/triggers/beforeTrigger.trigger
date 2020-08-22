trigger beforeTrigger on Partner_Forecast__c (before update, before insert) {

    List<Partner_Forecast__c> partnerForecasts = Trigger.new;
    List<String> fiscalPeriods = new List<String>();
    List<String> oppIds = new List<String>();
    
    // get Opp IDs & add previous FY Qtr of each forecast to a list
    for (Partner_Forecast__c pf : partnerForecasts) {
        String fiscalPeriod = pf.Fiscal_Period_Revenue__c;
        if (fiscalPeriod != null) {
            String year = fiscalPeriod.substring(0,4);
            // get the previous year
            String yearNum = String.valueOf(Integer.valueOf(year.substring(2)) - 1);
            String quarter = fiscalPeriod.substring(5);
            fiscalPeriods.add('FY' + yearNum + ' ' + quarter);
        }
        oppIds.add(pf.Opportunity__c);
    }
    
    // Retrieve the partner forecast records from the previous FY Qtr (one year ago)
    // Only retrieve *REVENUE* forecasts
    Id RevenueType = [SELECT Id FROM RecordType WHERE sobjecttype = 'Partner_Forecast__c' AND DeveloperName = 'Revenue' LIMIT 1].Id;
    
    List<Partner_Forecast__c> oldForecasts = [SELECT Commit__c, Opportunity__c FROM Partner_Forecast__c WHERE Fiscal_Period_Revenue__c IN :fiscalPeriods AND Opportunity__c IN :oppIds AND RecordTypeId = :RevenueType];
    
    // Update the new forecast 
    for (Partner_Forecast__c pf : partnerForecasts) {
        for (Partner_Forecast__c oldpf : oldForecasts) {
            if (pf.Opportunity__c == oldpf.Opportunity__c) {
                pf.Previous_FY_Qtr_Forecast__c = oldpf.Commit__c;
                break;
            }
        }
    }

}