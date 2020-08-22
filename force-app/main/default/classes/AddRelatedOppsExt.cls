public with sharing class AddRelatedOppsExt {
    
    public Id oppId {get; set;}
    
    public AddRelatedOppsExt(ApexPages.standardController ctrl){
        oppId = ctrl.getId();      
    }
    
    public PageReference addNewOpp(){
        List<Deal_Sync_Fields__c> fieldSettings = Deal_Sync_Fields__c.getAll().values();
        String queryString = 'SELECT AccountId, Deal__c';
        
        for(Deal_Sync_Fields__c fieldSetting: fieldSettings){
            if(fieldSetting.Opportunity_Field__c != null){
                queryString += ', ' +  fieldSetting.Opportunity_Field__c;
            }
        }
        
        queryString += ' FROM Opportunity WHERE Id=: oppId';
        Opportunity oldOpp = (Opportunity) Database.query(queryString);
        Id dealId = oldOpp.Deal__c;
        if(dealId == null){
            Deal__c newDeal = new Deal__c(Name = 'New Deal ' + String.valueOf(DateTime.now()), Account__c = oldOpp.AccountId);
            
            for(Deal_Sync_Fields__c fieldSetting: fieldSettings){
                if(fieldSetting.Opportunity_Field__c != null && fieldSetting.Deal_Field__c != null){
                    newDeal.put(fieldSetting.Deal_Field__c, oldOpp.get(fieldSetting.Opportunity_Field__c));
                }    
            }
            insert newDeal;
            dealId = newDeal.Id;
            Opportunity updateOpp = new Opportunity(Id = oldOpp.Id, Deal__c = dealId);
            update updateOpp;
        }
        Opportunity newOpp = new Opportunity(Name = 'New Opp', CloseDate = Date.today(), Deal__c = dealId, AccountId = oldOpp.AccountId, StageName = 'Incubate');
        for(Deal_Sync_Fields__c fieldSetting: fieldSettings){
            if(fieldSetting.Opportunity_Field__c != null){
                newOpp.put(fieldSetting.Opportunity_Field__c, oldOpp.get(fieldSetting.Opportunity_Field__c));
            }    
        }
        insert newOpp;
        return new PageReference('/' + newOpp.Id + '/e?retURL=%2F' + newOpp.Id);
    }
}