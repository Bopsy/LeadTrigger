/** * * * * * * * * * * * *
 *  Purpose:      Test class for SLAHoursCalculation
 *                The better version of BatchSLAHoursCalculation.cls
 *  Author:       Philip Choi
 *  Company:      GoNimbly
 *  Created Date: 08-14-2018
 *  Updated Date: 08-14-2018 - Philip Choi
** * * * * * * * * * * * */
@isTest
public class SLAHoursCalculationTest {

  @isTest
  private static void slaStartTimePopulated() {
    final DateTime OLD_DATE = DateTime.newInstanceGMT(1996, 1, 8);
    Integer numRecords = 10;
    String timeZoneKey = 'America/Los_Angeles';
    User aUser = [SELECT Id, TimeZoneSidKey FROM User WHERE TimeZoneSidKey = :timeZoneKey AND IsActive = true Limit 1];
    Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' And DeveloperName  = 'Customer_Ops_Request_CSM_Support' LIMIT 1].Id;
    
    Case testCase = new Case(RecordTypeId = rtId, OwnerId = aUser.Id);

    Test.startTest();
      insert testCase;
      SLAHoursCalculation.calculateSlaHours(new List<Id>{testCase.Id});
    Test.stopTest();

  }

  private static List<FSR__c> getMQLs() {
    return [SELECT Name, CreatedDate, SLA_Start_Time__c, OwnerId, Dispositioned_Date__c, SLA_Time_in_Hours_Batch__c, FSR__c.SLA_8am_User_Timezone__c FROM FSR__c];
  }

  private static Boolean smallTimeDiff(DateTime expectedTime, DateTime actualTime) {
    return (expectedTime.addMinutes(-1) < actualTime && expectedTime.addMinutes(1) > actualTime);
  }

  @isTest
  private static void slaTimeInHoursReporting() {
    String timeZoneKey = 'America/Los_Angeles';
    User aUser = [SELECT Id, TimeZoneSidKey FROM User WHERE TimeZoneSidKey = :timeZoneKey AND IsActive = true Limit 1];
    Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' And DeveloperName  = 'Customer_Ops_Request_CSM_Support' LIMIT 1].Id;
    
    Blob blobKey = Crypto.GenerateAESKey(128);
    String hexKey = EncodingUtil.ConvertTohex(blobKey);
    String uniqueKey = hexKey.substring(hexKey.length() - (hexKey.length()/4));

    Case testCase = new Case(RecordTypeId = rtId, OwnerId = aUser.Id, SLA_Start_Time__c = DateTime.newInstanceGMT(1996, 1, 8, 9, 0, 0), Dispositioned_Date__c = DateTime.newInstanceGMT(1996, 1, 9, 10, 15, 0));

    Test.startTest();
      insert testCase;
      SLAHoursCalculation.calculateSlaHours(new List<Id>{testCase.Id});
    Test.stopTest();
  }

  // Test to make sure that User.Time_Zone_SLA__c will supsersede User.TimeZoneSidKey
  @isTest
  private static void timeZoneSla_fieldOverride() {
    final DateTime OLD_DATE = DateTime.newInstanceGMT(1996, 1, 8);
    String timeZoneKey = 'America/Los_Angeles';
    String overrideTimeZoneKey = 'America/New_York';
    Integer numRecords = 10;
    
    User aUser = [SELECT Id, TimeZoneSidKey FROM User WHERE TimeZoneSidKey = :timeZoneKey AND IsActive = true Limit 1];
    Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' And DeveloperName  = 'Customer_Ops_Request_CSM_Support' LIMIT 1].Id;
    aUser.Time_Zone_SLA__c = overrideTimeZoneKey;
    update aUser;

    Case testCase = new Case(RecordTypeId = rtId, OwnerId = aUser.Id, SLA_Start_Time__c = DateTime.newInstanceGMT(1996, 1, 8, 9, 0, 0), Dispositioned_Date__c = DateTime.newInstanceGMT(1996, 1, 9, 10, 15, 0));

    Test.startTest();
      insert testCase;
      SLAHoursCalculation.calculateSlaHours(new List<Id>{testCase.Id});
    Test.stopTest();
  }

}