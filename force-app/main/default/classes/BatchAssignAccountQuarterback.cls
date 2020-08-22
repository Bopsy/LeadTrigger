global class BatchAssignAccountQuarterback implements Database.Batchable<SObject> {
    
   
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT SFDC_Country__c, SFDC_State__c, SFDC_ZipCode__c, REF_Employee_Size__c FROM Account WHERE FY_17_AE_Owner_Preliminary__c = null');
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accounts){
        List<Account> updateAccounts = new List<Account>();
        
        for(Account acc: accounts){
            OpportunityRoutingServices.OppWrapper oppWrapper = new OpportunityRoutingServices.OppWrapper();
            oppWrapper.zipCode = acc.SFDC_ZipCode__c;
            oppWrapper.state = acc.SFDC_State__c;
            oppWrapper.country = acc.SFDC_Country__c;
            if(acc.REF_Employee_Size__c != null){
                oppWrapper.employeeSize = acc.REF_Employee_Size__c;
                OpportunityRoutingServices.AccountQBWrapper accWrapper = OpportunityRoutingServices.findAccountQB(oppWrapper);
                
                if(accWrapper != null && accWrapper.quarterBackId != null){
                    acc.FY_17_AE_Owner_Preliminary__c = accWrapper.quarterBackId;
                    updateAccounts.add(acc);
                }
            }
        }
        
        Database.update(updateAccounts, false);
                
    }
    
    global void finish(Database.BatchableContext bc){
        
    }

}