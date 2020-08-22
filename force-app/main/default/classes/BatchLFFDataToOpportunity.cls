/** * * * * * * * * * * * *
*  Class Name:   BatchLFFDataToOpportunity
*  Purpose:      Updates Opportunities with LFF field data if this data
                 hasn't already been added
*  Author:       Mitch Conquer
*  Company:      Go Nimbly
*  Created Date: 27-Sep-2017
*  Type:         Batch Class
** * * * * * * * * * * * */

public class BatchLFFDataToOpportunity implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
  Map<String, String> oppToLffFieldsMap;
  String errors = '';

  @TestVisible
  private static Map<String, String> setupVerifiedOppToLffFields() {
    Map<String, String> verifiedMappings = new Map<String, String>();

    // Get the mappings from custom meta data
    List<LFF_to_Opportunity_Sync__mdt> oppToLffMappings = [
      SELECT Id, LFF_Field__c, Opportunity_Field__c
      FROM LFF_to_Opportunity_Sync__mdt
    ];

    // Get the existing field schema
    Set<String> oppSchemaFields =
      Schema.sObjectType.Opportunity.fields.getMap().keySet();
    Set<String> lffSchemaFields =
      Schema.sObjectType.Lifecycle_Field_Funnel__c.fields.getMap().keySet();

    // If both the LFF and Opp fields are verified, add to verifiedMappings
    for (LFF_to_Opportunity_Sync__mdt mapping : oppToLffMappings) {
      Boolean oppFieldOk =
        oppSchemaFields.contains(mapping.Opportunity_Field__c.toLowerCase());
      Boolean lffFieldOk =
        lffSchemaFields.contains(mapping.LFF_Field__c.toLowerCase());

      if (oppFieldOk && lffFieldOk) {
        verifiedMappings.put(
          mapping.Opportunity_Field__c,
          mapping.LFF_Field__c
        );
      }
    }

    return verifiedMappings;
  }

  private List<String> prefixAllWith(List<String> stringList, String prefix) {
    List<String> prefixedStrings = new List<String>();
    for (String aString : stringList) {
      prefixedStrings.add(prefix + aString);
    }
    return prefixedStrings;
  }

  public Database.QueryLocator start(Database.BatchableContext BC)
  {
    // Get the field mappings from custom meta data
    // Abort batch if no valid mappings
    oppToLffFieldsMap = BatchLFFDataToOpportunity.setupVerifiedOppToLffFields();
    if (oppToLffFieldsMap.keySet().size() < 1) {
      errors += 'No LFF to Opportunity field mappings found. ';
      return null;
    }

    // LFF Fields may have duplicates
    Set<String> lffFields = new Set<String>(oppToLffFieldsMap.values());
    List<String> opportunityFields = prefixAllWith(
      new List<String>(oppToLffFieldsMap.keySet()),
      'Opportunity__r.'
    );

    String query = ' SELECT Id, ' +
      String.join(new List<String>(lffFields), ', ')
      + ', Opportunity__c, LastModifiedDate, CreatedDate, ' +
      String.join(opportunityFields, ', ')
      + ', Opportunity__r.LFF_Batch_Last_Run__c FROM Lifecycle_Field_Funnel__c'
      + ' WHERE Opportunity__c != null ORDER BY LastModifiedDate DESC, CreatedDate DESC';

    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext BC,
    List<Lifecycle_Field_Funnel__c> scope
  ) {
    Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();

    for (Lifecycle_Field_Funnel__c lff : scope) {
      // If many LFFs reference the same Opportunity,
      // we only want to use the most recently modified one
      Boolean lffHasOpportunity = lff.Opportunity__c != null;
      Boolean oppNotYetUpdated = oppsToUpdate.get(lff.Opportunity__c) == null;

      if (lffHasOpportunity && oppNotYetUpdated) {

        Opportunity oppToUpdate = new Opportunity(Id=lff.Opportunity__c);
        // Set the LFF fields on the Opportunity
        for (String oppFieldToUpdate : oppToLffFieldsMap.keySet()) {
          String lffField = oppToLffFieldsMap.get(oppFieldToUpdate);
          oppToUpdate.put(oppFieldToUpdate, lff.get(lffField));
        }
        oppToUpdate.LFF_Batch_Last_Run__c = Date.today();
        oppsToUpdate.put(lff.Opportunity__c, oppToUpdate);
      }
    }
    // update the modified Opportunities
    if (oppsToUpdate.values().size() > 0) {
      List<Database.SaveResult> saveResults = Database.update(oppsToUpdate.values(), false);
      errors += BatchUtils.processSaveResult(oppsToUpdate.values(), saveResults);
    }
  }

  public void execute(SchedulableContext sc) {
    Integer recordsPerBatch = 100;
    BatchLFFDataToOpportunity thisBatch = new BatchLFFDataToOpportunity();
    Database.executebatch(thisBatch, recordsPerBatch);
  }

  public void finish(Database.BatchableContext BC) {
    System.debug(LoggingLevel.ERROR, errors);
    BatchUtils.finish('BatchLFFDataToOpportunity', BC.getJobId(), errors);
  }
}