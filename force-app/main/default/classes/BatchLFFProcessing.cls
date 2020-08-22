/* * * * * * * * * * * * * *
*  Class Name:   BatchLFFProcessing
*  Purpose:      Batch class for processing LFF records to populate LFF_Source_Text__c field
*                based on different conditions
*  Author:       Vivek Somani
*  Company:      GoNimbly
*  Created Date: 1-Mar-2017
*  Type:         Batch Class
* * * * * * * * * * * * */
public class BatchLFFProcessing implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
  public static final Set<String> GROWTH_PREDICTIVE_TYPES = new Set<String>{ 'Growth', 'Predictive' };
  String errors = '';

  // String constants for field names
  private static String SIGNUP = 'signup';
  private static String NPC = 'npc';
  private static String FIRST_TOUCH = 'firstTouch';
  private static String MQL = 'mql';
  private static String SAL = 'sal';
  private static String SQL = 'sql';

  //start method of the batch class
  public Database.QueryLocator start(Database.BatchableContext BC)
  {
    return Database.getQueryLocator([SELECT LFF_Source_Text__c, Builder_Sign_Up_Date__c, Account_First_NPC_5_Date__c,
                                            First_Touch_Associated_Date__c, MQL_Date_Entered__c, Qualified_Role__c,
                                            SAL_Date_Entered__c, Last_Touch_SQL_Associated_Date__c, Use_Case_Interest__c,
                                            Use_Case_Interest__r.Owner.UserRole.Name, SQL_Date_Entered__c
                                      FROM Lifecycle_Field_Funnel__c]);
  }

  //execute method of the batch class
  public void execute(Database.BatchableContext BC, List<Lifecycle_Field_Funnel__c> scope)
  {
    // Fields we use to judge LFF Source and their source
    Map<String, String> fieldToOutputMap = new Map<String, String>{
      SIGNUP => 'INBOUND SELF-SERVE',
      NPC => 'INBOUND SELF-SERVE',
      FIRST_TOUCH => 'INBOUND FIELD',
      MQL => 'INBOUND FIELD',
      SAL => 'OUTBOUND',
      SQL => 'OUTBOUND'
    };
    // Sources that have subgroups and require further processing
    Set<String> hasSubgroup = new Set<String>{ 'OUTBOUND' };

    List<Lifecycle_Field_Funnel__c> lifecycleFieldFunnelListToUpdate = new List<Lifecycle_Field_Funnel__c>();
    for(Lifecycle_Field_Funnel__c lff : scope)
    {
      String intendedSource = 'ERROR';

      Map<String, DateTime> fieldDates = getFieldDates(lff);
      String firstInteraction = getFirstInteraction(fieldDates);
      String newSource =  fieldToOutputMap.get(firstInteraction);
      if(newSource != NULL)
      {
        intendedSource = newSource;

        // Process subgroups if necessary
        if(hasSubgroup.contains(intendedSource))
        {
          intendedSource = getSubgroup(lff, firstInteraction, newSource);
        }
      }

      if(intendedSource != lff.LFF_Source_Text__c)
      {
        lff.LFF_Source_Text__c = intendedSource;
        lifecycleFieldFunnelListToUpdate.add(lff);
      }
    }

    // update the LFF records stamped with LFF Source Text values
    if(lifecycleFieldFunnelListToUpdate.size() > 0)
    {
      List<Database.SaveResult> saveResults = Database.update(lifecycleFieldFunnelListToUpdate, false);
      errors += BatchUtils.processSaveResult(lifecycleFieldFunnelListToUpdate, saveResults);
    }
  }

  // Populate map with dates if field is not null
  private Map<String, DateTime> getFieldDates(Lifecycle_Field_Funnel__c lff)
  {
    Map<String, DateTime> fieldDates = new Map<String, DateTime>();
    if(lff.Builder_Sign_Up_Date__c != NULL)
    {
      fieldDates.put(SIGNUP, lff.Builder_Sign_Up_Date__c);
    }
    if(lff.Account_First_NPC_5_Date__c != NULL)
    {
      fieldDates.put(NPC, lff.Account_First_NPC_5_Date__c);
    }
    if(lff.First_Touch_Associated_Date__c != NULL)
    {
      fieldDates.put(FIRST_TOUCH, lff.First_Touch_Associated_Date__c);
    }
    if(lff.MQL_Date_Entered__c != NULL)
    {
      fieldDates.put(MQL, lff.MQL_Date_Entered__c);
    }
    if(lff.SAL_Date_Entered__c != NULL)
    {
      fieldDates.put(SAL, lff.SAL_Date_Entered__c);
    }
    if(lff.SQL_Date_Entered__c != NULL)
    {
      fieldDates.put(SQL, lff.SQL_Date_Entered__c);
    }
    return fieldDates;
  }

  // Return the key of the earliest date in the fieldDates map
  private String getFirstInteraction(Map<String, DateTime> fieldDates)
  {
    String firstInteraction;
    for(String field : fieldDates.keySet())
    {
      if(firstInteraction == NULL)
      {
        firstInteraction = field;
      }
      Boolean shouldReplace = fieldDates.get(field) < fieldDates.get(firstInteraction);
      if(shouldReplace)
      {
        firstInteraction = field;
      }
    }
    return firstInteraction;
  }

  private String getSubgroup(Lifecycle_Field_Funnel__c lff, String firstInteraction, String newSource)
  {
    String subGroup = newSource;

    if((firstInteraction == SAL || firstInteraction == SQL) && newSource == 'OUTBOUND')
    {
      Boolean lffQualifiedRole = lff.Qualified_Role__c != NULL && (lff.Qualified_Role__c.contains('SDR') || lff.Qualified_Role__c.contains('BDR'));
      Boolean hasUciOwnerRole = lff.Use_Case_Interest__c != NULL && lff.Use_Case_Interest__r.Owner.UserRole.Name != NULL;
      UserRole uciOwnerRole = hasUciOwnerRole ? lff.Use_Case_Interest__r.Owner.UserRole : NULL;
      Boolean uciQualifiedRole = uciOwnerRole != NULL && (uciOwnerRole.Name.contains('SDR') || uciOwnerRole.Name.contains('BDR'));
      if(lffQualifiedRole || uciQualifiedRole)
      {
        subGroup = subGroup + ' XDR';
      }
      else
      {
        subGroup = subGroup + ' SALES';
      }
    }
    return subGroup;
  }

  //finish method of the batch class
  public void finish(Database.BatchableContext BC)
  {
    BatchUtils.finish('BatchLFFProcessing',BC.getJobId(),errors);
  }

  //execute method for scheduling batch class
  public void execute(SchedulableContext sc)
  {
    BatchLFFProcessing theBatch = new BatchLFFProcessing();
    database.executebatch(theBatch);
  }

}