global without sharing class OpportunityDealViewerExt {
    public String dealString {get; set;}
    public Id accId {get; set;}
    
    public OpportunityDealViewerExt(ApexPages.StandardController stdCtrl){
        Opportunity opp = [SELECT Deal__c, AccountId FROM Opportunity WHERE Id =: stdCtrl.getRecord().Id];
        Id dealId = opp.Deal__c;
        accId = opp.AccountId;
        dealString = JSON.serialize(getDeal(dealId));
    }
    
    private static Deal__c getDeal(Id dealId){
        Deal__c aDeal = [SELECT Name, (SELECT AccountId, Owner.Name, Deal__r.Name, StageName, FY_16_Primary_Product__c, CloseDate, Amount, Launch_Date__c FROM Opportunities__r) FROM Deal__c WHERE Id =: dealId];
        return aDeal;
    }
    
    public String getPrimaryProducts(){
        List<String> result = new List<String>();
        
        List<Schema.PicklistEntry> ple = Opportunity.FY_16_Primary_Product__c.getDescribe().getPicklistValues();
        for(Schema.PicklistEntry f: ple){
            result.add(f.getLabel());
        }
        
        return JSON.serialize(result);
    }
    
    public String getDealNames(){
        List<Deal__c> deals = [SELECT Id, Name, Close_Date__c FROM Deal__c WHERE Account__c =: accId];

        return JSON.serialize(deals);
    }
    @RemoteAction
    global static void changeDeal(String oppString){
        
    }
    @RemoteAction
    global static void addOpp(String oppString){
        Opportunity newOpp = (Opportunity) JSON.deserialize(oppString, Opportunity.class);
        newOpp.StageName = 'Incubate';
        newOpp.Name = 'New Opp';
        insert newOpp;
    }
    
    @RemoteAction
    global static void saveOpp(String oppString){
        List<Opportunity> opps = (List<Opportunity>) JSON.deserialize(oppString, List<Opportunity>.class);
        update opps;
    }
    
    @RemoteAction
    global static void updateOpp(String oppString, String dealString, Id oldDealId){
        Opportunity updateOpp = (Opportunity) JSON.deserialize(oppString, Opportunity.class);
        Deal__c updateDeal = (Deal__c) JSON.deserialize(dealString, Deal__c.class);
        SavePoint sp = Database.setSavepoint();
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Deal__c =: oldDealId];
        if(opps.size() == 1 && opps[0].Id == updateOpp.Id){
            Deal__c deleteDeal = new Deal__c(Id = oldDealId);
            delete deleteDeal;
        }
        try{
            if(updateDeal.Id == null){
                insert updateDeal;
                updateOpp.Deal__c = updateDeal.Id;
            }
            else{
                update updateDeal;
            }
            update updateOpp;
        }
        catch(DMLException e){
            
        }
    }
}