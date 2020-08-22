trigger LaunchPlanTrigger on Launch_Plan__c (after insert, after update) {
    Set<Id> oppIds = new Set<Id>();
    
    for(Launch_Plan__c launchPlan: trigger.new){
        oppIds.add(launchPlan.Opportunity__c);
    }
    
    List<Opportunity> opps = [SELECT Id, No_of_Launch_Plans__c, (SELECT Id FROM Customer_Opp_Projects__r ) FROM Opportunity WHERE Id =: oppIds];
    List<Opportunity> updateOpps = new List<Opportunity>();
    for(Opportunity opp: opps){
        if(opp.Customer_Opp_Projects__r  != null && opp.No_of_Launch_Plans__c != opp.Customer_Opp_Projects__r.size()){
            opp.No_of_Launch_Plans__c = opp.Customer_Opp_Projects__r.size();
            updateOpps.add(opp);
        }
    }
    
    update updateOpps;
}