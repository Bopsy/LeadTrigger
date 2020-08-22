global without sharing class ManagerForecastController {
    
    private static final Set<String> adminUserNames = new Set<String> {'Davis Dong', 'Kevin Louie', 'Brittany Blecher', 'Renu Asuti'};
    public Boolean readOnly {get; set;}
    public String forecasts {get; set;}
    public String subManagers {get; set;}
    public String userForecastMap {get; set;}
    public Id currentUserId {get; set;}
    public String currentUserName {get; set;}
    
    public ManagerForecastController(){
       
       currentUserId = ApexPages.currentPage().getParameters().get('uid'); 
       String readOnlyFlag = ApexPages.currentPage().getParameters().get('all');
       if(currentUserId == null){
           currentUserId = UserInfo.getUserId();
           readOnly = false;
       }
       else{
           Set<Id> peerUserIds = getPeerUsers(new Set<Id>{UserInfo.getUserId()});
           if(peerUserIds.contains(currentUserId) || currentUserId == UserInfo.getUserId() || (adminUserNames.contains(UserInfo.getName()) && readOnlyFlag != null)){
               readOnly = false;
           }
           else{
               readOnly = true;
           }
       }
       currentUserName = [SELECT Name FROM User WHERE Id=:currentUserId LIMIT 1].Name;
       forecasts = getForecasts(currentUserId);
       subManagers = getSubmanagers(currentUserId);
       userForecastMap = getUserForecastMap(currentUserId);
    }
    
    public String getAvailableUsers(){
        List<AggregateResult> fieldSalesForecasets = [SELECT Forecast_Owner__c FROM Field_Sales_Forecast__c GROUP BY Forecast_Owner__c];
        Set<Id> userIds = new Set<Id>();
        
        for(AggregateResult ar: fieldSalesForecasets){
            userIds.add((Id) ar.get('Forecast_Owner__c'));
        }
        
        List<User> users = [SELECT Name, ManagerId FROM User WHERE Id =: userIds ORDER BY Name];
        
        return JSON.serialize(users);
    }
    
    public String getForecasts(Id userId){
        Date startDate = Date.newInstance(Date.today().year(), 1, 1).addYears(-1);
        Date endDate = startDate.addYears(2).addDays(-1);
        return JSON.serialize([SELECT Notes__c, Manager_Final_eARR_Override__c, Manager_Final_Contract_Override__c, Manager_Final_Forecast_Override__c, Raw_Quota_Forecast_Rollup__c, Raw_Revenue_Forecast_Rollup__c,
                               Manager_Modified_Contract_Rollup__c, Manager_Modified_Forecast_Rollup__c, Manager_Raw_Contract_Rollup__c, Manager_Raw_Forecast_Rollup__c, Start_Date__c, Forecast_Owner__c,
                               (SELECT Contract_Value_Amount__c, Contract_Value_Override__c, Forecast_Owner__c, Forecast_Owner__r.Name, Sales_Forecast_Override__c, Sales_Forecast_Amount__c,
                                Sales_Current_Quarter__c, Sales_Forecast_Previous_Quarter_Override__c, Submanager_Contract_Total__c, Submanager_Forecast_Total__c, Submanager_Modified_Contract__c, 
                                Submanager_Modified_Forecast__c, Submanager_Sales_Current_Quarter__c, Submanager_Modified_Previous_Quarter__c, Stage__c, Start_Date__c, Deal_Forecast_Override__c,
                                Manager_Modified_Deal__c, Submanager_Modified_Deal__c, Opp_Forecast_Override__c, Manager_Modified_Opp__c, Submanager_Modified_Opp__c, Total_Opp_Value__c
                                FROM Override_Forecasts__r)
                               FROM Field_Sales_Forecast__c
                               WHERE Start_Date__c >= : startDate AND Start_Date__c <= :endDate AND Forecast_Owner__c =: userId AND Stage__c = null
                               ORDER BY Start_Date__c]);
    }
    
    
    public String getRelatedOpps(){
        Set<Id> userIds = new Set<Id>{currentUserId};
        userIds.addAll(getPeerUsers(userIds));
        Date startDate = Date.newInstance(Date.today().year(), 1, 1).addYears(-1).addMonths(-3);
        Date endDate = startDate.addYears(2).addDays(-1).addMonths(3);
        
        List<Opportunity> resultOpps = [SELECT Name, Bookings_Opportunity__c, ForecastCategory, OwnerId, Amount, CloseDate, Contract_Type__c, StageName, E_ARR__c,
                                               Launch_Date__c, Scheduled__c, FY_16_Use_Case__c, FY_16_Primary_Product__c, Deal__r.OwnerId, Owner.Name,
                                               (SELECT Name, Amount__c FROM Opportunity_Products__r)
                                               FROM Opportunity WHERE (Field_Sales_Forecast__r.Forecast_Owner__c =: userIds)
                                               AND CloseDate >=: startDate AND CloseDate <=: endDate AND ForecastCategory != 'Omitted'];
        return JSON.serialize(resultOpps);
    }
    
    /*public static List<User> getManagerUsers(Set<Id> managerIds){
        List<User> managerUsers = new List<User>();
        
        while(!managerIds.isEmpty()){
            List<User> users = [SELECT Name, ManagerId FROM User WHERE Id = :managerIds AND IsActive = true];
            
            managerIds.clear();
            
            for(User user: users){
                managerUsers.add(user);
                
                if(user.ManagerId != null) managerIds.add(user.ManagerId);
            }
        }
        return managerUsers;
    }*/
    
    public String getSubmanagers(Id userId){
         List<User> users = [SELECT Name, ManagerId FROM User WHERE ManagerId = :userId /*AND IsActive = true*/];
         
         return JSON.serialize(users);
    }
    
    public String getUserForecastMap(Id userId){
         List<User> users = [SELECT Name, ManagerId FROM User WHERE ManagerId = :userId /*AND IsActive = true*/];
         Set<Id> submanagerIds = new Set<Id>{userId};
         for(User user: users){
             submanagerIds.add(user.Id);
         }
        Date startDate = Date.newInstance(Date.today().year(), 1, 1).addYears(-1);
        Date endDate = startDate.addYears(3).addDays(-1);
        List<Field_Sales_Forecast__c> forecasts = [SELECT Forecast_Owner__c, Forecast_Owner__r.Name, Manager_Final_Contract_Override__c, Manager_Final_Forecast_Override__c, Raw_Quota_Forecast_Rollup__c, Raw_Revenue_Forecast_Rollup__c,
                               Manager_Modified_Contract_Rollup__c, Manager_Modified_Forecast_Rollup__c, Manager_Raw_Contract_Rollup__c, Manager_Raw_Forecast_Rollup__c, Start_Date__c,
                               (SELECT Contract_Value_Amount__c, Contract_Value_Override__c, Forecast_Owner__c, Forecast_Owner__r.Name, Sales_Forecast_Override__c, Sales_Forecast_Amount__c,
                                Sales_Current_Quarter__c, Sales_Forecast_Previous_Quarter_Override__c, Submanager_Contract_Total__c, Submanager_Forecast_Total__c, Submanager_Modified_Contract__c, 
                                Submanager_Modified_Forecast__c, Submanager_Sales_Current_Quarter__c, Submanager_Modified_Previous_Quarter__c, Stage__c, Start_Date__c, Deal_Forecast_Override__c,
                                Manager_Modified_Deal__c, Submanager_Modified_Deal__c, Opp_Forecast_Override__c, Manager_Modified_Opp__c, Submanager_Modified_Opp__c, Total_Opp_Value__c, Total_Deal_Forecast__c,
                                Submanager_Deal_Forecast_Total__c, Total_Bookings_Forecast__c, Submanager_Booking_Total__c, Submanager_Booking_eARR_Total__c, Submanager_eARR_Total__c, Total_Booking_eARR__c, 
                                Total_eARR__c, Booking_eARR_Override__c, Booking_eARR_Notes__c, Booking_Forecast_Override__c, Booking_Notes__c, Carryover_Notes__c, Deal_Forecast_Amount_Override__c, Deal_Notes__c,
                                eARR_Notes__c, eARR_Override__c, Manager_Modified_Deal_Forecast__c, Manager_Modified_Booking__c, Manager_Modified_Booking_eARR__c, Manager_Modified_eARR__c,
                                Total_Deal_eARR__c, Deal_eARR_Notes__c, Manager_Modified_Deal_eARR__c, Deal_eARR_Override__c, Total_Booking_Deal__c, Booking_Deal_Notes__c, Manager_Modified_Booking_Deal__c,
                                Booking_Deal_Override__c, Total_Booking_Deal_eARR__c, Booking_Deal_eARR_Notes__c, Manager_Modified_Booking_Deal_eARR__c, Booking_Deal_eARR_Override__c, Raw_Revenue_Forecast_Rollup__c, 
                                Opp_Notes__c, Submanager_Opp_Total__c, Submanager_Booking_Deal_Total__c, Submanager_Deal_eARR_Total__c, Submanager_Booking_Deal_eARR_Total__c
                                FROM Override_Forecasts__r WHERE Stage__c != 'Omitted')
                               FROM Field_Sales_Forecast__c
                               WHERE Start_Date__c >= : startDate AND Start_Date__c <= :endDate AND Forecast_Owner__c = :submanagerIds AND Stage__c = null
                               ORDER BY Start_Date__c];
        
        Map<Id, List<Field_Sales_Forecast__c>> resultMap = new Map<Id, List<Field_Sales_Forecast__c>>();
        for(Field_Sales_Forecast__c forecast: forecasts){
            List<Field_Sales_Forecast__c> userForecasts = new List<Field_Sales_Forecast__c>();
            
            if(resultMap.containsKey(forecast.Forecast_Owner__c)){
                userForecasts = resultMap.get(forecast.Forecast_Owner__c);
            }
            
            userForecasts.add(forecast);
            resultMap.put(forecast.Forecast_Owner__c, userForecasts);
        }
        
        return JSON.serialize(resultMap);
    }
    
    public static Set<Id> getPeerUsers(Set<Id> peerManagerIds){
        Set<Id> peerUsers = new Set<Id>();
        
        List<User> users = [SELECT Name, ManagerId FROM User WHERE ManagerId = :peerManagerIds /*AND IsActive = true*/];
        
        while(!users.isEmpty()){
            
            peerManagerIds.clear();
            
            for(User user: users){
                peerUsers.add(user.Id);
                
                peerManagerIds.add(user.Id);
            }
            
            users = [SELECT Name, ManagerId FROM User WHERE ManagerId = :peerManagerIds /*AND IsActive = true*/];
        }
        
        return peerUsers;
    }
    
    public String getSubManagerUserMap(){
        List<User> users = [SELECT Name, ManagerId FROM User WHERE ManagerId = :currentUserId /*AND IsActive = true*/];
        Set<Id> userIds = new Set<Id>{currentUserId};
        for(User aUser: users){
            userIds.add(aUser.Id);
        }
        Map<Id, Set<Id>> resultMap = new Map<Id, Set<Id>>();
        for(Id userId: userIds){
            resultMap.put(userId, getPeerUsers(new Set<Id>{userId}));
        }
        return JSON.serialize(resultMap);
    }
    
    @RemoteAction
    public static void saveForecasts(String forecastStrings){
        List<Field_Sales_Forecast__c> forecasts = (List<Field_Sales_Forecast__c>) JSON.deserialize(forecastStrings, List<Field_Sales_Forecast__c>.class);
        update forecasts;
    }
}