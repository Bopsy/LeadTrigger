/* * * * * * * * * * * * *
 *  Class Name:   BaseForecastControllerTest
 *  Purpose:      This is test class for the BaseForecastController controller.
 *  Author:       Purushottam Bhaigade
 *  Company:      GoNimbly
 *  Created Date: 12-July-2016
 *
 * * * * * * * * * * * * */
@isTest
public class BaseForecastControllerTest {


    private static List<Account>  accountList = new List<Account>();
    private static List<Account_Forecast__c> accountForeCastList = new List<Account_Forecast__c>();
    private static Integer counter = 2;
    private static List<String> fieldNameList = new List<String>{BaseForecastController.USAGE,BaseForecastController.BASE_FORECAST};
    private static List<String> totalForecastFieldNameList = null;
    private static List<String> usageFieldNameList = null;
    private static List<String> baseForecastFieldNameList = null;
    private static List<String> growthAssumptionFieldNameList = null;
    private static Map<Id, Double> accountAndTotalForecastMap = new Map<Id, Double>();

    /* * * * * * * * * * * * *
    *  Method Name:  setup
    *  Purpose:      This method is used to create the test data.
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 12-July-2016
    * * * * * * * * * * * * */
    static  void setup()
    {
        BaseForecastController.UserData testUserData = new BaseForecastController.UserData('test', 'testName', new List<BaseForecastController.AccountForecastWrapper>(), false);
        try
        {
            for(Integer i = 0;i < counter;i++)
            {
                Account accountObj = new Account();
                accountObj.Name ='TestAccount'+i;
                accountObj.Needs_Base_Forecasting__c = true;
                accountObj.OwnerId = UserInfo.getUserId();
                accountList.add(accountObj);
            }
            // insert account list
            insert accountList;

            Map<String, String> fieldNameAndQueryStringMap = BaseForecastController.getQueryStringFormFields(fieldNameList);
            String fieldNameString = fieldNameAndQueryStringMap.get(BaseForecastController.USAGE);
            usageFieldNameList = fieldNameString.split(',');
            fieldNameString = fieldNameAndQueryStringMap.get(BaseForecastController.BASE_FORECAST);
            baseForecastFieldNameList = fieldNameString.split(',');
            fieldNameString = fieldNameAndQueryStringMap.get(BaseForecastController.BASE_FORECAST);
            growthAssumptionFieldNameList = fieldNameString.split(',');


            for(Integer i = 0;i < counter;i++)
            {
                Account_Forecast__c accountForecastRec = new Account_Forecast__c();
                accountForecastRec.Account__c=accountList[i].Id;
                accountForecastRec.Name = 'TestAccountForecast'+i;
                Double baseUsageVal = 100.00;
                for(Integer j=0; j < usageFieldNameList.size(); j++)
                {
                    if(usageFieldNameList[j] != ''){
                        accountForecastRec.put(usageFieldNameList[j], baseUsageVal);
                     }
                }
                baseUsageVal = 120;
                for(Integer j=0; j < baseForecastFieldNameList.size(); j++)
                {
                    accountForecastRec.put(baseForecastFieldNameList[j], baseUsageVal);
                }
                Double growthAssumptionPercent = 5;
                for(Integer j=0; j < growthAssumptionFieldNameList.size(); j++)
                {
                    accountForecastRec.put(growthAssumptionFieldNameList[j], growthAssumptionPercent);
                }
                accountForecastRec.Start_Date__c=System.today().addDays(-2);
                accountForecastRec.End_Date__c=System.today().addDays(2);
                accountForeCastList.add(accountForecastRec);
          }
          insert accountForeCastList;
        }
        catch(DmlException ex)
        {
          throw ex;
        }
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testUpdateAccountForecastPositive
    *  Purpose:      This method is used to do test for the updateAccountForecast
    *  Author:       Purushottam Bhaigade
    *  Company:      BaseForecast
    *  Created Date: 21-July-2016
    * * * * * * * * * * * * */

    static testMethod void testUpdateAccountForecastPositive()
    {
        setup();
        List<Account_Forecast__c> toUpdateAccountForecastList = new List<Account_Forecast__c>();

        for(Integer i = 0;i < accountForeCastList.size();i++)
        {
            accountForeCastList[i].January_Base_Forecast__c=100;
            accountForeCastList[i].February_Base_Forecast__c=110;
            accountForeCastList[i].March_Base_Forecast__c=120;
            toUpdateAccountForecastList.add(accountForeCastList[i]);
        }

        Test.startTest();
          Map<String, Object> mapToReturn = BaseForecastController.updateAccountForecast(toUpdateAccountForecastList);
        Test.stopTest();

        system.assertEquals(mapToReturn.get(BaseForecastController.ERRORS), '');
        List<Account_Forecast__c> updatedAccountForecastList = new List<Account_Forecast__c>();
        updatedAccountForecastList = [select id,January_Base_Forecast__c,February_Base_Forecast__c,March_Base_Forecast__c from account_forecast__c  where ID IN : toUpdateAccountForecastList];

        for(Integer i = 0;i < accountForeCastList.size();i++)
        {
            System.assertEquals(updatedAccountForecastList[i].January_Base_Forecast__c,toUpdateAccountForecastList[i].January_Base_Forecast__c);
            //System.assertEquals(updatedAccountForecastList[i].February_Base_Forecast__c,toUpdateAccountForecastList[i].February_Base_Forecast__c);
            //System.assertEquals(updatedAccountForecastList[i].March_Base_Forecast__c,toUpdateAccountForecastList[i].March_Base_Forecast__c);
        }
    }


    /* * * * * * * * * * * * *
    *  Method Name:  testUpdateAccountForecastNegative
    *  Purpose:      This method is used to do test for the updateAccountForecast
    *  Author:       Purushottam Bhaigade
    *  Company:      BaseForecast
    *  Created Date: 21-July-2016
    * * * * * * * * * * * * */

    static testMethod void testUpdateAccountForecastNegative()
    {
        List<Account_Forecast__c> toUpdateAccountForecastList = new List<Account_Forecast__c>();
        String errorMessage = '';
        String actualErrorMessage = 'Update failed. First exception on row 0; first error: MISSING_ARGUMENT, Id not specified in an update call: []';

        Account_Forecast__c accountForecastRec = new Account_Forecast__c(Name='TestAccountForecast');
        toUpdateAccountForecastList.add(accountForecastRec);
        Test.startTest();
           Map<String, Object> mapToReturn = BaseForecastController.updateAccountForecast(toUpdateAccountForecastList);
        Test.stopTest();
        errorMessage = String.valueOf(mapToReturn.get('errors'));
        System.assertEquals(errorMessage, actualErrorMessage);
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testGetAllOwnedAccounts
    *  Purpose:      This method is used to do test for the getAllOwnedAccounts
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 14-July-2016
    * * * * * * * * * * * * */
    static testMethod void testGetAllOwnedAccounts()
    {
      setup();
      List<BaseForecastController.UserData> userDataList = new List<BaseForecastController.UserData>();
      Map<String,Object> mapreturned = new Map<String,Object>();
      List<String> arguments = new List<String>();
      List<Account_Forecast__c>  allAccountForecastList = new List<Account_Forecast__c>();
      allAccountForecastList = accountForeCastList;

      Test.startTest();
        mapreturned = BaseForecastController.getAllOwnedAccounts();
      Test.stopTest();
      userDataList = (List<BaseForecastController.UserData>)mapreturned.get(BaseForecastController.USER_DATA);

      for(Integer j=0; j < accountForeCastList.size(); j++)
      {
          Double totalForecast = 0.0;
          //for calculation of baseForecast fields
          for(String usageFieldName :usageFieldNameList)
          {
              usageFieldName = usageFieldName.trim();
              if(usageFieldName != '' && accountForeCastList[j].get(usageFieldName) != null)
              {
                  totalForecast += Double.valueOf(accountForeCastList[j].get(usageFieldName));
              }
          }

          // for calculation of forecast fields
          for(String baseForecastFieldName :baseForecastFieldNameList)
          {
              baseForecastFieldName = baseForecastFieldName.trim();
              if(accountForeCastList[j].get(baseForecastFieldName) != null)
              {
                  totalForecast += Double.valueOf(accountForeCastList[j].get(baseForecastFieldName));
              }
          }
          accountAndTotalForecastMap.put(accountForeCastList[j].Id, totalForecast);
      }
      if(userDataList != null){
          for(Integer i = 0;i < userDataList.size() ; i++)
          {
              BaseForecastController.UserData userObj = userDataList.get(i);
              List<BaseForecastController.AccountForecastWrapper> accountWrapperObjList = userObj.accountData;
    
                  for(Integer j=0; j < accountWrapperObjList.size(); j++)
                  {
                      Account_Forecast__c accountForcastRec = allAccountForecastList[j];
                      System.assertEquals(userObj.userId,accountList[j].OwnerId);
        
                      BaseForecastController.AccountForecastWrapper accountData = accountWrapperObjList[j];
        
                      System.assertEquals(accountData.accountForecastId,accountForcastRec.Id);
                      System.assertEquals(accountData.accountName,accountList[j].Name);
                      System.assertEquals(accountData.accountId,accountList[j].Id);
                      System.assertEquals(accountData.totalForecast,accountAndTotalForecastMap.get(accountData.accountForecastId));
        
                      Map<String, Map<String,Object>> monthAndUsageForecastMap = accountData.usageAndForecastData;
                      system.debug('monthAndUsageForecastMap'+monthAndUsageForecastMap);
                      for(String month :monthAndUsageForecastMap.keySet())
                      {
                          if(month != null){
                              for(String usageFieldName :usageFieldNameList)
                              {
                                  if(String.isNotEmpty(usageFieldName)){
                                      if(usageFieldName.startsWith(month))
                                      {
                                          System.assertEquals(Double.valueOf(monthAndUsageForecastMap.get(month).get('usage__c')),Double.valueOf(accountForcastRec.get(usageFieldName)));
                                          break;
                                      }
                                  }
                              }
                              for(String baseForecastFieldName :baseForecastFieldNameList)
                              {
                                  if(String.isNotEmpty(baseForecastFieldName)){
                                      if(baseForecastFieldName.startsWith(month))
                                      {
                                          System.assertEquals(Double.valueOf(monthAndUsageForecastMap.get(month).get('base_forecast__c')),Double.valueOf(accountForcastRec.get(baseForecastFieldName)));
                                          break;
                                      }
                                  }
                              }
            
                              for(String growthAssumptionFieldName :growthAssumptionFieldNameList)
                              {
                                  if(String.isNotEmpty(growthAssumptionFieldName)){
                                      if(growthAssumptionFieldName.startsWith(month))
                                      {
                                          System.assertEquals(Double.valueOf(monthAndUsageForecastMap.get(month).get('growth_assumption__c')),Double.valueOf(accountForcastRec.get(growthAssumptionFieldName)));
                                          break;
                                      }
                                  }
                              }
                          }
                      }
                  }
           }
        }
    }

    /* * * * * * * * * * * * *
    *  Method Name:  testGetQueryStringFormFields
    *  Purpose:      This method is used to do test for the getQueryStringFormFields
    *  Author:       Purushottam Bhaigade
    *  Company:      GoNimbly
    *  Created Date: 15-July-2016
    * * * * * * * * * * * * */
    static testMethod void testGetQueryStringFormFields()
    {
        Map<String, String> fieldNameAndQueryStringMap = new Map<String, String>();
        Integer currentMonth = System.today().month();

        for(String fieldName :fieldNameList)
        {
            String queryStr = '';
            Integer lowerLimit = 1;
            Integer upperLimit = BaseForecastController.monthsMap.size();
            if(fieldName.contains('usage'))
            {
                upperLimit = currentMonth-1;
            }
            if(fieldName.contains('base_forecast'))
            {
                lowerLimit = currentMonth;
            }

            for(Integer month = lowerLimit; month <= upperLimit; month++)
            {
                String monthName = BaseForecastController.monthsMap.get(month);
                if(!fieldName.endsWith('__c'))
                {
                    fieldName += '__c';
                }
                String fieldNameToRetrive = monthName+'_'+fieldName;
                fieldNameToRetrive = fieldNameToRetrive.toLowerCase();
                if(BaseForecastController.fieldMap.containsKey(fieldNameToRetrive))
                {
                    queryStr += ',' + BaseForecastController.fieldMap.get(fieldNameToRetrive);
                }
            }
            if(queryStr.startsWith(','))
            {
                queryStr = queryStr.subString(1);
                queryStr = queryStr.trim();
                queryStr = queryStr.toLowerCase();
            }
            fieldNameAndQueryStringMap.put(fieldName, queryStr);
        }

        Test.startTest();
            Map<String, String> returnFieldNameAndQueryStringMap = BaseForecastController.getQueryStringFormFields(fieldNameList);
        Test.stopTest();
        for(String fieldType :fieldNameList)
        {
            //System.assertEquals(returnFieldNameAndQueryStringMap.get(fieldType), fieldNameAndQueryStringMap.get(fieldType));
        }

        
    }
}