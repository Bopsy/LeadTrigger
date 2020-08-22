/** * * * * * * * * * * * *
 *  Purpose:      For SLA Hours calculation for any SObject
 *                The better version of BatchSLAHoursCalculation.cls
 *  Author:       Philip Choi
 *  Company:      GoNimbly
 *  Created Date: 08-14-2018
 *  Updated Date: 08-14-2018 - Philip Choi
 *  Unit Test:    SLAHoursCalculationTest.cls
** * * * * * * * * * * * */
public class SLAHoursCalculation {

  @InvocableMethod(label='Calculate SLA Hours' description='Updates records\' SLA fields')
  public static void calculateSlaHours(List<Id> incomingRecordIds) {
    final DateTime HISTORIC_MONDAY = DateTime.newInstanceGMT(1996, 1, 8); // any monday in the past. needed by a formula
    List<SObject> incomingRecords = getRecords(incomingRecordIds);
    Map<Id, String> ownerIdToTimeZone = getOwnerIdToTimeZoneMap(incomingRecords);

    Map<String, BusinessHours> timeZoneToBusinessHoursMap = BatchUtils.getBusinessHours(ownerIdToTimeZone.values());

    for (SObject aRecord : incomingRecords) {
      Id ownerId = (Id)aRecord.get('OwnerId');

      if (ownerIdToTimeZone.get(ownerId) == null) {
        continue;
      }

      String timeZoneSid = ownerIdToTimeZone.get(ownerId);
      BusinessHours bHours = timeZoneToBusinessHoursMap.get(timeZoneSid);

      aRecord.put('SLA_8am_User_Timezone__c', BusinessHours.nextStartDate(bHours.Id, HISTORIC_MONDAY));
        
      if (aRecord.get('SLA_Start_Time__c') == null) {
        Datetime createdTime = (DateTime)aRecord.get('CreatedDate');
        DateTime nextStartTime = BusinessHours.nextStartDate(bHours.Id, createdTime) > createdTime ? 
          BusinessHours.nextStartDate(bHours.Id, createdTime) : createdTime;
        aRecord.put('SLA_Start_Time__c', nextStartTime);
      }
      else if (aRecord.get('Dispositioned_Date__c') != null) {
        Double numOfHours = ((Double)BusinessHours.diff(bHours.Id, (DateTime)aRecord.get('SLA_Start_Time__c'), (DateTime)aRecord.get('Dispositioned_Date__c')) / 3600000);
        aRecord.put('SLA_Time_in_Hours_Batch__c', numOfHours);
      }
    }

    update incomingRecords;
  }

  private static Map<Id, String> getOwnerIdToTimeZoneMap(List<SObject> incomingRecords) {
    Set<Id> ownerIdSet = new Set<Id>();
    Map<Id, String> ownerIdToTimeZone = new Map<Id, String>();
    
    for (SObject aRecord : incomingRecords) {
      ownerIdSet.add((Id)aRecord.get('OwnerId'));
    }

    List<User> ownerList = [SELECT UserRole.Name, TimeZoneSidKey, Time_Zone_SLA__c FROM User WHERE Id IN :ownerIdSet];
    for (User anOwner : ownerList) {
      if (anOwner.Time_Zone_SLA__c != null) {
        ownerIdToTimeZone.put(anOwner.Id, anOwner.Time_Zone_SLA__c);
      }
      else {
        String sidKey = (anOwner.UserRole.Name != null && anOwner.UserRole.Name.contains('East')) ? 
          'America/New_York' : anOwner.TimeZoneSidKey;
        ownerIdToTimeZone.put(anOwner.Id, sidKey);
      }
    }

    return ownerIdToTimeZone;
  }

  private static List<SObject> getRecords(List<Id> incomingRecordIds) {
    String objectType = incomingRecordIds[0].getSObjectType().getDescribe().getName();
    String query = 'SELECT OwnerId, CreatedDate, SLA_Start_Time__c, Dispositioned_Date__c,'
        +' SLA_8am_User_Timezone__c, SLA_Time_in_Hours_Batch__c'
      +' FROM ' + objectType
      +' WHERE Id IN :incomingRecordIds';
    return Database.query(query);
  }
    
}