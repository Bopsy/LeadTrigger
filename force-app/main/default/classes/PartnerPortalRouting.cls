//
// This class abstracts the Partner Portal Routing that is stored in the
// Opp_Owner_Partner_Portal_Routing_Rules__c custom setting.
//
// Routing is determined by the combination of the Country Code, State,
// Employee Size, and Use Case.
//
// If no match is found then a fallback rule named "DEFAULT" is used.
// The "DEFAULT" record fields can be any value as they will be all ignored
// except for the Owner_ID__c.
//
// If the "DEFAULT" record does not exist an error message will be generated.
//

public with sharing class PartnerPortalRouting {

  // Data structure of the routingMap is a nest map where the key
  // is the combining of all fields with the delimitor "/"
  private Map<String,Opp_Owner_Partner_Portal_Routing_Rules__c> routingMap;
  private Opp_Owner_Partner_Portal_Routing_Rules__c fallbackRule;

  public PartnerPortalRouting() {
    // Initialize and build the Opp_Owner_Partner_Portal_Routing_Rules__c routing map
    routingMap = new Map<String,Opp_Owner_Partner_Portal_Routing_Rules__c>();
    Map<String,Opp_Owner_Partner_Portal_Routing_Rules__c> rules = Opp_Owner_Partner_Portal_Routing_Rules__c.getAll();
    for (String name : rules.keySet()) {
      Opp_Owner_Partner_Portal_Routing_Rules__c rule = rules.get(name);
      String key = name.toUpperCase() == 'DEFAULT' ? 'DEFAULT' : generateMatchingKey(rule.CountryCode__c, rule.State__c, rule.Employee_Size__c, rule.Use_Case__c);
      routingMap.put(key, rule);
    }

    // Ensure that a fallback rule entry exists in the routing map
    fallbackRule = routingMap.get('DEFAULT');
    if (fallbackRule == null) {
            System.debug('ERROR: Opp_Owner_Partner_Portal_Routing_Rules__c routing map does not have a rule with the name "DEFAULT"'); 
            throw new PartnerPortalRoutingException('Opp_Owner_Partner_Portal_Routing_Rules__c routing map does not have a rule with the name "DEFAULT"');
    }
  }

    public Opp_Owner_Partner_Portal_Routing_Rules__c getRule(String countryCode, String state, String employeeSize, String useCase) {
    String key = generateKey(countryCode, state, employeeSize, useCase);
    for (String ruleKey : routingMap.keySet()) {
      System.debug('Analyzing([' + ruleKey + '] =~ [' + key + '])');
      if (Pattern.matches(ruleKey, key)) {
        System.debug('Match found');
        return routingMap.get(ruleKey);
      }
    }
    System.debug('No match found - using fallback rule.');
      return fallbackRule;
    }

    public Id getOwnerId(String countryCode, String state, String employeeSize, String useCase) {
      Opp_Owner_Partner_Portal_Routing_Rules__c rule = getRule(countryCode, state, employeeSize, useCase);
    return (rule == null) ? null : (Id)rule.Owner_Id__c;
    }
    
    public OpportunityRoutingServices.OppSettingWrapper getOwnerWrapper(Id aeOwner, String country, String state, String zipCode, Decimal Amount, String product, String solutionCategory, String employeeSize){
        OpportunityRoutingServices.OppWrapper wrapper = new OpportunityRoutingServices.OppWrapper();
        Datetime now = Datetime.now();
        wrapper.country = country;
        wrapper.state = state;
        wrapper.zipCode = zipCode;
        wrapper.amount = amount;
        wrapper.product = product;
        wrapper.solutionCategory = solutionCategory;
        wrapper.employeeSize = employeeSize;
        wrapper.aeSwitch = false;
        wrapper.aeOwner = aeOwner;
        OpportunityRoutingServices.OppSettingWrapper oppWrapper = OpportunityRoutingServices.findOppOwner(wrapper);
        if(oppWrapper == null || oppWrapper.oppOwnerId == null){
            oppWrapper = new OpportunityRoutingServices.OppSettingWrapper();
            oppWrapper.oppOwnerId = '00540000002WTJF';
        }
        else{
            OpportunityRoutingServices.getRoundRobinOwnerId(oppWrapper);
            if(oppWrapper.memberId != null) update new Assignment_Groups__c(Id = oppWrapper.memberId, Last_Assignment__c = now, Millisecond__c = now.millisecond());
        }
        return oppWrapper;
    }
    
    public OpportunityRoutingServices.AccountQBWrapper getAccWrapper(String country, String state, String zipCode, String employeeSize){
        OpportunityRoutingServices.OppWrapper wrapper = new OpportunityRoutingServices.OppWrapper();
        wrapper.country = country;
        wrapper.state = state;
        wrapper.zipCode = zipCode;
        //wrapper.amount = amount;
        //wrapper.product = product;
        //wrapper.solutionCategory = solutionCategory;
        wrapper.employeeSize = employeeSize;
        //wrapper.aeSwitch = false;
        OpportunityRoutingServices.AccountQBWrapper accWrapper = OpportunityRoutingServices.findAccountQB(wrapper);
        if(accWrapper == null || accWrapper.quarterBackId == null){
            accWrapper = new OpportunityRoutingServices.AccountQBWrapper();
            accWrapper.quarterBackId = '00540000002WTJF';
        }
        else{
            OpportunityRoutingServices.getRoundRobinAEOwner(accWrapper);
        }
        return accWrapper;
    }
    // Generate the key based on the given inputs
    private String generateKey(String countryCode, String state, String employeeSize, String useCase) {
      return String.join(new List<String> {
      String.isBlank(countryCode)  ? '' : countryCode.toUpperCase(),
      String.isBlank(state)        ? '' : state.toUpperCase(),
      String.isBlank(employeeSize) ? '' : employeeSize.toUpperCase(),
      String.isBlank(useCase)      ? '' : useCase.toUpperCase()
      }, '/');
    }

    // Generate the key for regular expression (regexp) matching based on the given inputs
    private String generateMatchingKey(String countryCode, String state, String employeeSize, String useCase) {
      return '^'
      + String.join(new List<String> {
        String.isBlank(countryCode)  ? '.*' : countryCode.toUpperCase(),
        String.isBlank(state)        ? '.*' : state.toUpperCase(),
        String.isBlank(employeeSize) ? '.*' : employeeSize.toUpperCase(),
        String.isBlank(useCase)      ? '.*' : useCase.toUpperCase()
        }, '/')
      + '$';
    }
}