/* * * * * * * * * * * * *
*  Class Name:   BaseForecastController
*  Purpose:      This is javascript remoting controller for BaseForecastUI VF page.
*  Author:       Purushottam Bhaigade
*  Company:      GoNimbly
*  Created Date: 08-July-2016
*
* * * * * * * * * * * * */
public without sharing class BaseForecastController
{

    public static Map<Integer,String> monthsMap = new Map<Integer,String>{
            1 => 'January',
            2 => 'February',
            3 => 'March',
            4 => 'April',
            5 => 'May',
            6 => 'June',
            7 => 'July',
            8 => 'August',
            9 => 'September',
            10 =>'October',
            11 => 'November',
            12 => 'December',
            13 => 'NextJan',
            14 => 'NextFeb',
            15 => 'NextMar'
            };

    public static Map<String, Schema.SObjectField> fieldMap;
    static{
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType ObjectSchema = schemaMap.get('Account_Forecast__c');
        fieldMap = ObjectSchema.getDescribe().fields.getMap();
    }
    static Integer level = 1;
    static Set<Id> userIds = new Set<Id>();
    static{
        userIds = getAllSubordinateUsers(Userinfo.getUserId());
    }
    public static String USER_DATA = 'userData';
    public static String ERRORS = 'errors';
    public static String USAGE = 'usage__c';
    public static String BASE_FORECAST = 'base_forecast__c';
    public static String GROWTH_ASSUMPTION = 'growth_assumption__c';
    public static String WEEK_NUMBER = 'weekNumber';
    public static String START_DATE = 'startDate';


    /* * * * * * * * * * * * *
    *  Method Name:  getAllOwnedAccounts
    *  Purpose:      This method returns all accounts related to logged in user
    *  Param:        none
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 08-July-2016
    * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> getAllOwnedAccounts()
    {
        List<Account_Forecast__c>  allAccountForecastList = new List<Account_Forecast__c>();
        Map<Id, Map<Id, List<Account_Forecast__c>>> ownerAndAccountForecastMap = new Map<Id, Map<Id, List<Account_Forecast__c>>>();
        Map<String, Object> mapToReturn = new Map<String, Object>{USER_DATA => null, ERRORS => ''};

        try
        {
          // get Account_Forecast__c details from database.
          allAccountForecastList = getAccountForecastRecords();

          if(allAccountForecastList.size() > 0){

            // get AccountForecast records with there respective OwnerId
            ownerAndAccountForecastMap = getOwnerAccountForecastMap(allAccountForecastList);

            //get Usage and Forecast details. This is final result which returns from API call.
            mapToReturn = getUsageAndForecastDetails(ownerAndAccountForecastMap);
          }
        }catch(Exception ex){
          mapToReturn.put(ERRORS,ex.getMessage());
        }
        return mapToReturn;
    }

    /* * * * * * * * * * * * *
    *  Method Name:  getAccountForecastRecords
    *  Purpose:      This method returns the list of AccountForecast Records.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 27-July-2016
    * * * * * * * * * * * * */
    private static List<Account_Forecast__c> getAccountForecastRecords(){

        List<Account_Forecast__c>  allAccountForecastList = new List<Account_Forecast__c>();
        List<String> fieldNameList = new List<String>{USAGE, BASE_FORECAST, GROWTH_ASSUMPTION};
        List<String> arguments = new List<String>();

        Map<String, String> fieldNameAndQueryStringMap = getQueryStringFormFields(fieldNameList);
        for(String fieldName :fieldNameList){
            if(fieldNameAndQueryStringMap.containsKey(fieldName)){
                arguments.add(fieldNameAndQueryStringMap.get(fieldName));
            }
        }

        Date todaysDate = System.today();

        String soqlQuery = 'select id,name,Account__c,Week_Number__c,Start_Date__c,Account__r.Name, Account__r.FY_17_AE_Owner_Preliminary__c, Account__r.FY_17_AE_Owner_Preliminary__r.Name, Account__r.OwnerId, Account__r.Owner.Name,{0},{1},{2} '
                           +'from Account_Forecast__c '
                           +'where (Account__r.OwnerId in :userIds OR Account__r.FY_17_AE_Owner_Preliminary__c in: userIds)'
                           +'AND Account__r.Needs_Base_Forecasting__c = true '
                           +'AND Start_Date__c < :todaysDate '
                           +'AND End_Date__c > :todaysDate '
                           +'order by createddate DESC';

        /*
         * Here we are replacing {0} and {1} from soqlQuery string with values from arguments list with respective index.
         * {0} => Will contain fields of usage__c type according to current month. For example if current month is July then
         *        It will contains comma separated fields January_usage__c, February_usage__c like till June_usage__c.
         * {1} => Will contain fields of base_forecast__c type according to current month. For example if current month is July then
         *        It will contains comma separated fields July_Base_Forecast__c, August_Base_Forecast__c like till December_Base_Forecast__c.
         */
        
        soqlQuery = String.format(soqlQuery, arguments);
        soqlQuery = soqlQuery.replace(',,', ',');
        system.debug(soqlQuery);
        try
        {
            allAccountForecastList = Database.query(soqlQuery);
            system.debug(JSON.serialize(allAccountForecastList));
        }
        catch(Exception ex)
        {
            throw ex;
        }
        return allAccountForecastList;
    }

    /* * * * * * * * * * * * *
    *  Method Name:  getOwnerAccountForecastMap
    *  Purpose:      This method returns the Map of Owner and its respective AccountForecast.
    *  Param:        List<Account_Forecast__c>
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 27-July-2016
    * * * * * * * * * * * * */
    private static Map<Id, Map<Id, List<Account_Forecast__c>>>  getOwnerAccountForecastMap(List<Account_Forecast__c> allAccountForecastList)
    {
        Map<Id, List<Account_Forecast__c>> accountIdAndAccountForCstMap = new Map<Id, List<Account_Forecast__c>>();
        Map<Id, Map<Id, List<Account_Forecast__c>>> ownerAndAccountForecastMap = new Map<Id, Map<Id, List<Account_Forecast__c>>>();
        List<Account_Forecast__c> accountForeCstList = new List<Account_Forecast__c>();

        for(Account_Forecast__c accountForecast : allAccountForecastList)
        {
            Id ownerId = accountForecast.Account__r.FY_17_AE_Owner_Preliminary__c == null ? accountForecast.Account__r.OwnerId : accountForecast.Account__r.FY_17_AE_Owner_Preliminary__c;
            if(!ownerAndAccountForecastMap.containsKey(ownerId))
            {
                accountIdAndAccountForCstMap = new Map<Id, List<Account_Forecast__c>>();
            }
            else
            {
                accountIdAndAccountForCstMap = ownerAndAccountForecastMap.get(ownerId);
            }
            if(!accountIdAndAccountForCstMap.containsKey(accountForecast.Account__c))
            {
                accountForeCstList = new List<Account_Forecast__c>();
            }
            else
            {
                accountForeCstList = accountIdAndAccountForCstMap.get(accountForecast.Account__c);
            }
            accountForeCstList.add(accountForecast);
            accountIdAndAccountForCstMap.put(accountForecast.Account__c, accountForeCstList);
            ownerAndAccountForecastMap.put(ownerId, accountIdAndAccountForCstMap);
        }
        return ownerAndAccountForecastMap;
    }

    /* * * * * * * * * * * * *
    *  Method Name:  getUsageAndForecastDetails
    *  Purpose:      This method returns the account forecast usage and forecast details
    *  Param:        Map<Id, Map<Id, List<Account_Forecast__c>>>
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 27-July-2016
    * * * * * * * * * * * * */
    private static Map<String, Object>  getUsageAndForecastDetails(Map<Id, Map<Id, List<Account_Forecast__c>>> ownerAndAccountForecastMap)
    {
          Map<String, Object> mapToReturn = new Map<String, Object>{USER_DATA => null, ERRORS => '',WEEK_NUMBER => '',START_DATE => ''};
          List<String> fieldNameList = new List<String>{USAGE, BASE_FORECAST, GROWTH_ASSUMPTION};
          Map<String, String> fieldNameAndQueryStringMap = getQueryStringFormFields(fieldNameList);

          String weeknumber='';
          String startDate='';

          String fieldNameString = fieldNameAndQueryStringMap.get(USAGE);
          List<String> usageFieldNameList = fieldNameString.split(',');
          if(!usageFieldNameList.isEmpty() && usageFieldNameList.size() == 1 && usageFieldNameList[0] == ''){
              usageFieldNameList = new List<String>();
          }

          fieldNameString = fieldNameAndQueryStringMap.get(BASE_FORECAST);
          List<String> baseForecastFieldNameList = fieldNameString.split(',');

          fieldNameString = fieldNameAndQueryStringMap.get(GROWTH_ASSUMPTION);
          List<String> growthAssumptionFieldNameList = fieldNameString.split(',');

          Map<String, Map<String,Object>> monthAndUsageForecastMap = new Map<String, Map<String,Object>>();
          List<UserData> userDataList = new List<UserData>();

          for(Id userId :ownerAndAccountForecastMap.keySet())
          {
              boolean isLoggedInUser = false;
              Map<Id, List<Account_Forecast__c>> accountIdAndAccountForecastMap = ownerAndAccountForecastMap.get(userId);
              if(accountIdAndAccountForecastMap == null || accountIdAndAccountForecastMap.values() == null)
              {
                  continue;
              }

              String userName = '';
              List<AccountForecastWrapper> accountForecastWrapperList = new List<AccountForecastWrapper>();

              for(Id accountId :accountIdAndAccountForecastMap.keySet())
              {
                  List<Account_Forecast__c> accountForecastList = accountIdAndAccountForecastMap.get(accountId);
                  if(accountForecastList == null)
                  {
                      continue;
                  }
                  String accountName = accountForecastList[0].Account__r.Name;
                  Double totalForecast = 0.0;
                  String accountForecastID = accountForecastList[0].Id;
                  weeknumber = String.valueOf(accountForecastList[0].Week_Number__c);
                  startDate = String.valueOf(accountForecastList[0].Start_Date__c);

                  for(Account_Forecast__c accountForecast :accountForecastList)
                  {
                      userName = accountForecast.Account__r.FY_17_AE_Owner_Preliminary__r.Name == null ? accountForecast.Account__r.Owner.Name : accountForecast.Account__r.FY_17_AE_Owner_Preliminary__r.Name;
                      monthAndUsageForecastMap = new Map<String, Map<String,Object>>();

                      //Calculate Total Usage
                      for(Integer i=0; i < usageFieldNameList.size(); i++)
                      {
                          String usageFieldName = usageFieldNameList.get(i);
                          String monthName = monthsMap.get(i+1);
                          Map<String,Object> usageAndForecastMap = null;
                          Double usageVal = 0.0;
                          if(usageFieldName != '' && accountForecast.get(usageFieldName) != null)
                          {
                              usageVal = Double.valueOf(accountForecast.get(usageFieldName));
                          }
                          totalForecast += usageVal;
                          if(monthAndUsageForecastMap.get(monthName) != null)
                          {
                              usageAndForecastMap = monthAndUsageForecastMap.get(monthName);
                              usageAndForecastMap.put(USAGE, usageVal);
                          }else
                          {
                              usageAndForecastMap = new Map<String,Object>{USAGE => usageVal, BASE_FORECAST => 0.0,GROWTH_ASSUMPTION => 0.0};
                          }
                          monthAndUsageForecastMap.put(monthName, usageAndForecastMap);
                      }

                      //Calculate Total Base Forecast
                      for(Integer i=0; i < baseForecastFieldNameList.size(); i++)
                      {
                          String baseForecastFieldName = baseForecastFieldNameList.get(i);
                          String monthName = monthsMap.get(i+1+usageFieldNameList.size());
                          Map<String,Object> usageAndForecastMap = null;
                          Double forecast = 0.0;
                          if(accountForecast.get(baseForecastFieldName) != null)
                          {
                              forecast = Double.valueOf(accountForecast.get(baseForecastFieldName));
                          }
                          totalForecast += forecast;
                          if(monthAndUsageForecastMap.get(monthName) != null)
                          {
                              usageAndForecastMap = monthAndUsageForecastMap.get(monthName);
                              usageAndForecastMap.put(BASE_FORECAST, forecast);
                          }else
                          {
                              usageAndForecastMap = new Map<String,Object>{USAGE => 0.0, BASE_FORECAST => forecast,GROWTH_ASSUMPTION => 0.0};
                          }
                          monthAndUsageForecastMap.put(monthName, usageAndForecastMap);
                      }

                      //Calculate growth assumption percentage
                      for(Integer i=0; i < growthAssumptionFieldNameList.size(); i++)
                      {
                          String growthAssumptionFieldName = growthAssumptionFieldNameList.get(i);
                          String monthName = monthsMap.get(i+2+usageFieldNameList.size());
                          Map<String,Object> growthAssumptionForecastMap = null;
                          Double growthPercent = 0.0;
                          if(accountForecast.get(growthAssumptionFieldName) != null)
                          {
                              growthPercent = Double.valueOf(accountForecast.get(growthAssumptionFieldName));
                          }
                          if(monthAndUsageForecastMap.get(monthName) != null)
                          {
                              growthAssumptionForecastMap = monthAndUsageForecastMap.get(monthName);
                              growthAssumptionForecastMap.put(GROWTH_ASSUMPTION, growthPercent);
                          }else
                          {
                              growthAssumptionForecastMap = new Map<String,Object>{USAGE => 0.0, BASE_FORECAST => 0.0,GROWTH_ASSUMPTION => growthPercent};
                          }
                          monthAndUsageForecastMap.put(monthName, growthAssumptionForecastMap);
                      }


                  }
                  AccountForecastWrapper accountForecastWrapper = new AccountForecastWrapper();
                  accountForecastWrapper.accountId = accountId;
                  accountForecastWrapper.accountForecastId = accountForecastID;
                  accountForecastWrapper.accountName = accountName;
                  accountForecastWrapper.totalForecast = totalForecast;
                  accountForecastWrapper.usageAndForecastData = monthAndUsageForecastMap;
                  accountForecastWrapperList.add(accountForecastWrapper);
              }
              if(userId.equals(Userinfo.getUserId()))
              {
                  isLoggedInUser = true;
              }
              userDataList.add(new UserData(userId, userName, accountForecastWrapperList, isLoggedInUser));
          }
          mapToReturn.put(USER_DATA, userDataList);
          mapToReturn.put(WEEK_NUMBER, weeknumber);
          mapToReturn.put(START_DATE, startDate);
          return mapToReturn;
    }

    /* * * * * * * * * * * * *
    *  Method Name:  getQueryStringFormFields
    *  Purpose:      This method returns map of type of field(usage__c,base_forecast__c,total_forecast__c) and comma separated fields of that type.
    *  Param:        List<String>
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 08-July-2016
    * * * * * * * * * * * * */
    public static Map<String, String> getQueryStringFormFields(List<String> fieldNameList)
    {
        Map<String, String> fieldNameAndQueryStringMap = new Map<String, String>();
        Integer currentMonth = System.today().month();
        String queryStr;
        for(String fieldName :fieldNameList)
        {
            Integer lowerLimit = 1;
            Integer upperLimit = monthsMap.size();
            if(fieldName.contains('usage'))
            {
                upperLimit = currentMonth-1;
            }
            if(fieldName.contains('base_forecast'))
            {
                lowerLimit = currentMonth;
            }
            if(fieldName.contains('growth_assumption'))
            {
                lowerLimit = currentMonth+1;
            }
            //if(lowerLimit > 12) lowerLimit = 12;
            //if(upperLimit < 1) upperLimit = 1; 

            queryStr = getMonthWiseQueryString(fieldName, lowerLimit, upperLimit);
            fieldNameAndQueryStringMap.put(fieldName, queryStr);
        }
        return fieldNameAndQueryStringMap;
    }

    /* * * * * * * * * * * * *
    *  Method Name:  getMonthWiseQueryString
    *  Purpose:      This method returns comma separated fields of perticuler type(usage__c,base_forecast__c,total_forecast__c).
    *  Param:        String, Integer, Integer
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 08-July-2016
    * * * * * * * * * * * * */
    private static String getMonthWiseQueryString(String fieldName, Integer lowerLimit, Integer upperLimit)
    {
        String stringToReturn = '';
        for(Integer month = lowerLimit; month <= upperLimit; month++)
        {
            String monthName = monthsMap.get(month);
            if(!fieldName.endsWith('__c'))
            {
                fieldName += '__c';
            }
            String fieldNameToRetrive = monthName+'_'+fieldName;
            fieldNameToRetrive = fieldNameToRetrive.toLowerCase();
            if(fieldMap.containsKey(fieldNameToRetrive))
            {
                stringToReturn += ',' + fieldMap.get(fieldNameToRetrive);
            }
        }
        if(stringToReturn.startsWith(','))
        {
            stringToReturn = stringToReturn.subString(1);
            stringToReturn = stringToReturn.trim();
            stringToReturn = stringToReturn.toLowerCase();
        }
        return stringToReturn;
    }

    /* * * * * * * * * * * * *
    *  Method Name:  getAllSubordinateUsers
    *  Purpose:      This method returns set of all user's id including subordinate's ids
    *  Param:        Id
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 13-July-2016
    * * * * * * * * * * * * */
    private static Set<ID> getAllSubordinateUsers(Id userId)
    {
        Set<Id> userIdsSet = new Set<Id>();
        try
        {
            userIdsSet.add(userId);
            User user = [select UserRoleId from User where Id = :userId];
            Id roleId = user.UserRoleId;
            Set<Id> allSubordinateRoleIds = getAllSubordinateRoleIds(new Set<ID>{roleId});
            Map<Id,User> usersMap = new Map<Id, User>([Select Id, Name From User where UserRoleId IN :allSubordinateRoleIds]);
            userIdsSet.addAll(usersMap.keySet());
        }
        catch(Exception e)
        {
            throw e;
        }
        return userIdsSet;
    }

    /* * * * * * * * * * * * *
    *  Method Name:  getAllSubordinateRoleIds
    *  Purpose:      This is recursive method which returns set of all subordinate user's id
    *  Param:        Set
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 13-July-2016
    * * * * * * * * * * * * */
    private static Set<ID> getAllSubordinateRoleIds(Set<ID> roleIds)
    {
        Set<ID> currentRoleIds = new Set<ID>();
        for(UserRole userRole :[select Id from UserRole where ParentRoleId IN :roleIds AND ParentRoleID != null])
        {
            currentRoleIds.add(userRole.Id);
        }
        if(currentRoleIds.size() > 0 && level <=4)
        {
            currentRoleIds.addAll(getAllSubordinateRoleIds(currentRoleIds));
            level++;
        }
        return currentRoleIds;
    }

    /* * * * * * * * * * * * *
     *  Method Name:  updateAccountForecast
     *  Purpose:      Update the record passed in as parameter of Account Forecast
     *  Param:        List<Account_Forecast__c>
     *  Author:       Purushottam Bhaigade
     *  Company:      BaseForecast
     *  Created Date: 21-July-2016
     *
     * * * * * * * * * * * * */
    @RemoteAction
    public static Map<String, Object> updateAccountForecast(List<Account_Forecast__c> accountForecastList)
    {
        system.debug(accountForecastList);
        Map<String, Object> mapToReturn = new Map<String, Object>{ERRORS => ''};
        if( accountForecastList != null )
        {
            try
            {
               Database.update(accountForecastList);
            }catch(Exception e)
            {
              mapToReturn.put(ERRORS,e.getMessage());
            }
        }
        return mapToReturn;
    }



    /* * * * * * * * * * * * *
    *  Class Name:   AccountForecastWrapper
    *  Purpose:      This is wrapper class to hold details for Account Forcast object.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 08-July-2016
    * * * * * * * * * * * * */
    public class AccountForecastWrapper
    {
        public String accountName;
        public String accountId;
        public Double totalForecast;
        public String accountForecastId;
        public Map<String, Map<String,Object>> usageAndForecastData;

        public AccountForecastWrapper()
        {}
    }

    /* * * * * * * * * * * * *
    *  Class Name:   UserData
    *  Purpose:      This is wrapper class to hold details for User and Account Forcast object.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 08-July-2016
    * * * * * * * * * * * * */
    public class UserData
    {
        public String userId;
        public String userName;
        public boolean isLoggedInUser = false;
        public List<AccountForecastWrapper> accountData;

        public UserData(String userIdVar, String userNameVar, List<AccountForecastWrapper> accountForecastWrapperListVar, boolean isLoggedInUserVar)
        {
            this.userId = userIdVar;
            this.userName = userNameVar;
            this.accountData = accountForecastWrapperListVar;
            this.isLoggedInUser = isLoggedInUserVar;
        }
    }
}