//----------------------------------------------------------------------------------------------------------
// Utility class OpportunityDealHandler 
//----------------------------------------------------------------------------------------------------------
public without sharing class OpportunityDealHandler {
    public static Boolean alreadyRun = false;
    
    public static Map<Id, Opportunity> filterOpps(List<Opportunity> records, Map<Id, Opportunity> oldMap){
        List<Opportunity_To_Deal__c> settings = Opportunity_To_Deal__c.getAll().values();
        Map<Id,Opportunity> resultMap = new Map<Id, Opportunity>();
        if(settings.isEmpty()) return resultMap;
        
        for(Opportunity opp: records){
            Opportunity oldOpp = oldMap.get(opp.Id);
            for(Opportunity_To_Deal__c setting: settings){
                if(oldOpp.get(setting.Opportunity_Field__c) != opp.get(setting.Opportunity_Field__c)){
                    resultMap.put(opp.Id, opp);
                    break;
                }
            }
        }
        return resultMap;
    }
    
    public static Map<Id, Deal__c> filterDeals(List<Deal__c> records, Map<Id, Deal__c> oldMap){
        List<Deal_Sync_Fields__c> settings = Deal_Sync_Fields__c.getAll().values();
        Map<Id,Deal__c> resultMap = new Map<Id, Deal__c>();
        if(settings.isEmpty()) return resultMap;
        
        for(Deal__c deal: records){
            Deal__c oldDeal = oldMap.get(deal.Id);
            for(Deal_Sync_Fields__c setting: settings){
                if(oldDeal.get(setting.Deal_Field__c) != deal.get(setting.Deal_Field__c)){
                    resultMap.put(deal.Id, deal);
                    break;
                }
            }
        }
        return resultMap;
    }
    
    public static void updateTeamMembers(Map<Id, Deal__c> oldMap, List<Deal__c> records){
        if(alreadyRun) return;       
        List<Deal__c> filteredDeals = new List<Deal__c>();
       
        /*for(Deal__c deal: records){
            Deal__c oldDeal = oldMap.get(deal.Id);
            if(oldDeal != null){
                if(oldDeal.OwnerId != deal.OwnerId){
                    filteredDeals.add(deal);
                }
            }
        }
        
        if(filteredDeals.isEmpty()) return;*/
        filteredDeals = [SELECT OwnerId, (SELECT Id, OwnerId FROM Opportunities__r) FROM Deal__c WHERE Id =: records];
        List<OpportunityTeamMember> members = [SELECT Opportunity.Deal__c, OpportunityId FROM OpportunityTeamMember WHERE TeamMemberRole = 'Account Quarterback' AND Opportunity.Deal__c = :filteredDeals];
        
        Map<Id, OpportunityTeamMember> dealMemberMap = new Map<Id, OpportunityTeamMember>();
        
        for(OpportunityTeamMember member: members){
            dealMemberMap.put(member.OpportunityId, member);
        }
        
        List<OpportunityTeamMember> deleteMembers = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> insertMembers = new List<OpportunityTeamMember>();
        
        for(Deal__c deal: filteredDeals){
            if(deal.Opportunities__r != null && !deal.Opportunities__r.isEmpty())
            for(Opportunity opp: deal.Opportunities__r){
                if(dealMemberMap.get(opp.Id) != null){
                    deleteMembers.add(dealMemberMap.get(opp.Id));
                }
                if(deal.OwnerId != opp.OwnerId){
                    insertMembers.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = deal.OwnerId, OpportunityAccessLevel = 'Edit', TeamMemberRole = 'Account Quarterback'));
                }
            }
        }
        
        delete deleteMembers;
        insert insertMembers;
        
        alreadyRun = true;
        
    }
    
    // Copy Deal__c fields to related Opportunities as defined in Deal_Sync_Fields__c custom setting
    //    Deal_Field__c
    //    Opportunity_Field__c
    public static void copyFieldsToOpportunity(Map<Id,Deal__c> deals) {
    if (runOnce('For Copy Deal Fields To Opportunity')) {
      // If no Deals given no need to proceed
          if (deals.isEmpty()) { return; }
          System.debug('OpportunityDealHandler.copyFieldsToOpportunity(): Processing deals:  ' + deals.size());
      System.debug('OpportunityDealHandler.copyFieldsToOpportunity(): Deal IDs:  ' + deals.keySet());
  
      // Get the field settings
          Map<String, Deal_Sync_Fields__c> settings = Deal_Sync_Fields__c.getAll();
          if(settings.isEmpty()) return;
          // Query all Opportunities related to the Deals.
          Map<Id,Opportunity> oppsToUpdate = new Map<Id,Opportunity>();

      for (Opportunity o : [ SELECT Id, Deal__c FROM Opportunity WHERE Deal__c IN :deals.keySet() AND (ForecastCategory != 'Omitted' OR IsClosed = false)]) {
            System.debug('OpportunityDealHandler.copyFieldsToOpportunity(): Processing Opportunity:  ' + o.Id);
        Opportunity opp = new Opportunity(Id = o.Id);
            Deal__c relatedDeal = deals.get(o.Deal__c);
  
            // Copy the fields as defined in the custom setting from the related Deal to the Opportunity.
            for(String key : settings.keySet()){
              Deal_Sync_Fields__c setting = settings.get(key);
                opp.put(setting.Opportunity_Field__c, relatedDeal.get(setting.Deal_Field__c));
                System.debug('OpportunityDealHandler.copyFieldsToOpportunity(): Setting field:  ' + setting.Opportunity_Field__c + ' = ' + relatedDeal.get(setting.Deal_Field__c));
            }
            oppsToUpdate.put(o.Id, opp);
            System.debug('OpportunityDealHandler.copyFieldsToOpportunity(): Opportunity to update:  ' + opp);
      }
      
          try {   
              // Update the Opportunity records that were changed
              Database.SaveResult[] srList = Database.update(oppsToUpdate.values(), false);
              System.debug('OpportunityDealHandler.copyFieldsToOpportunity(): Updated ' + oppsToUpdate.size() + ' opportunities');
  
              // Iterate through each returned result
              for (Database.SaveResult sr : srList) {
                  // Operation failed, so get all errors and add error to related records
                  if (!sr.isSuccess()) {
                    Opportunity o = oppsToUpdate.get(sr.getId());
                      if (o != null && o.Deal__c != null && deals.containsKey(o.Deal__c)) {
                          for(Database.Error err : sr.getErrors()) {
                              deals.get(o.Deal__c).addError(err.getMessage());
                              System.debug('OpportunityDealHandler.copyFieldsToOpportunity(): The following error has occurred.');    
                              System.debug(err.getStatusCode() + ': ' + err.getMessage());
                              System.debug('Opportunity fields that affected this error: ' + err.getFields());
                          }   
                      }   
                  }   
              }   
          } catch (Exception e) {
              System.debug('An error occurred updating OpportunityDealHandler.copyFieldsToOpportunity(): ' +  e.getTypeName() + ' - ' + e.getCause() + ': ' + e.getMessage());
          }  
    }       
    }

    // Calculate Deal__c fields from related Opportunities as defined in Opportunity_To_Deal__c custom setting
    //    Deal_Field__c
    //    Operator__c (SUM, MAX, MIN, AVG, COUNT)
    //    Opportunity_Field__c
    public static void recalcutateDealFields(Map<Id,Opportunity> opps) {
    // If no Deals given no need to proceed
        if (opps.isEmpty()) { return; }
        
        // Build a map of Deal__c IDs to Opportunities just in case an exception occurs
        // while updating the Deal__c so that it can be related to its Opportunities
        Map<Id,List<Opportunity>> dealOpptyMap = new Map<Id,List<Opportunity>>();
        for (Opportunity o : opps.values()) {
          if (o.Deal__c != null) {
            List<Opportunity> opptyList = dealOpptyMap.containsKey(o.Deal__c) ? dealOpptyMap.get(o.Deal__c) : new List<Opportunity>();
            opptyList.add(o);
            dealOpptyMap.put(o.Deal__c, opptyList);
          }
        }

        Map<String, Opportunity_To_Deal__c> settings = Opportunity_To_Deal__c.getAll();
        if(settings.isEmpty()) return;
    // Construct aggregate query from custom setting information
    // We are specifying the aggregate functions alias to be the Deal_Field__c value
    // since there may be definitions that aggregate the same Opportunity_Field__c value
        Set<String> fieldSet = new Set<String>{'Deal__c'};
        Set<String> noAggregatedFieldSet = new Set<String>{'Deal__c'};
        for(String key : settings.keySet()){
      Opportunity_To_Deal__c setting = settings.get(key);
        if(setting.Operator__c == 'SYNC'){
            noAggregatedFieldSet.add(setting.Opportunity_Field__c);
            noAggregatedFieldSet.add('Deal__r.'+setting.Deal_Field__c);
        }
        else{
            fieldSet.add(setting.Operator__c + '(' + setting.Opportunity_Field__c + ')' + setting.Deal_Field__c);
        }
      }
        String fieldString = String.join(new List<String>(fieldSet), ', ');
        String noAggregatedFieldString = String.join(new List<String>(noAggregatedFieldSet), ', ');

    Set<Id> dealIds = dealOpptyMap.keySet();
    if(dealIds != null && !dealIds.isEmpty()){
          String queryString = 'SELECT ' + fieldString + ' FROM Opportunity WHERE Deal__c IN :dealIds AND (ForecastCategory != \'Omitted\' OR IsClosed = false) GROUP BY Deal__c ';
            System.debug('OpportunityDealHandler.recalcutateDealFields():Query: ' + queryString);
            AggregateResult[] results = Database.query(queryString);
             String noAggregaedQueryString = 'SELECT ' + noAggregatedFieldString + ' FROM Opportunity WHERE Deal__c IN :dealIds';
             List<Opportunity> queryOpps = Database.query(noAggregaedQueryString);
        System.debug('OpportunityDealHandler.recalcutateDealFields():Results returned:  ' + results.size());
    
        Map<Id,Deal__c> deals = new Map<Id,Deal__c>();
        for (Id dealId : dealOpptyMap.keySet()) {
          Deal__c deal = new Deal__c(Id = dealId);
          for(String key : settings.keySet()){
            Opportunity_To_Deal__c setting = settings.get(key);
              deal.put(setting.Deal_Field__c, null);
          }
          deals.put(dealId, deal);
        }
        for (AggregateResult ar : results)  {
            Id dealId = (Id)ar.get('Deal__c');
            System.debug('OpportunityDealHandler.recalcutateDealFields():Deal:  ' + dealId);
            Deal__c d = new Deal__c(Id = dealId);
          for(String key : settings.keySet()){
              Opportunity_To_Deal__c setting = settings.get(key);
              if(setting.Operator__c != 'SYNC'){
                  System.debug(setting.Operator__c + '(' + setting.Opportunity_Field__c + '):  ' + ar.get(setting.Deal_Field__c));
                  d.put(setting.Deal_Field__c, ar.get(setting.Deal_Field__c));
              }
            }
            deals.put(dealId, d);
        }
        
        Set<Id> syncedDealids = new Set<Id>();
        for(Opportunity opp: queryOpps){
            Id dealId = opp.Deal__c;
            if(dealId != null && !syncedDealids.contains(dealId)){
                Deal__c d = new Deal__c(Id = dealId);
                if(deals.containsKey(dealId)) d = deals.get(dealId);
                for(String key : settings.keySet()){
                  Opportunity_To_Deal__c setting = settings.get(key);
                  if(setting.Operator__c == 'SYNC' && opp.getSobject('Deal__r').get(setting.Deal_Field__c) != opp.get(setting.Opportunity_Field__c)){
                      d.put(setting.Deal_Field__c, opp.get(setting.Opportunity_Field__c));
                      syncedDealids.add(dealId);
                  }
                }
            }
        }
       
            try {   
                // Update the Deal__c records that were changed
                Database.SaveResult[] srList = Database.update(deals.values(), false);
                System.debug('OpportunityDealHandler.recalcutateDealFields(): Updated ' + deals.size() + ' deals');

                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    // Operation failed, so get all errors and add error to related records
                    if (!sr.isSuccess()) {
                      Deal__c d = deals.get(sr.getId());
                        if (d != null && dealOpptyMap.containsKey(d.Id)) {
                            for(Database.Error err : sr.getErrors()) {
                                for (Opportunity o : dealOpptyMap.get(d.Id)) {
                                  o.addError(err.getMessage());
                              }
                                System.debug('OpportunityDealHandler.recalcutateDealFields(): The following error has occurred.');    
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                System.debug('Deal__c fields that affected this error: ' + err.getFields());
                            }   
                        }   
                    }   
                }   
            } catch (Exception e) {
                System.debug('An error occurred updating OpportunityDealHandler.recalcutateDealFields(): ' +  e.getTypeName() + ' - ' + e.getCause() + ': ' + e.getMessage());
            }
        }
    }

    //  
    // This is check used to ensure that if the trigger is called recursively it will only be ran once.
    // Use it by specifying a "key" for the code segment it is being used for.  Each code segment should
    // have its own unique key.  For instance,
    //  
    //    if (runOnce('For Copy Deal Fields To Opportunity')) {
    //       ... 
    //    }   
    //  
    public static Set<String> run = new Set<String>();
    public static boolean runOnce(String key) { if (run.contains(key)) { return false; } else { run.add(key); return true; } } 
}