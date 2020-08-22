/******************************************
//Created By: Davis Dong
//Last Modified by: Bopsy {2/24/2020}
//Description: This Class handles By PTPCOnvertor Visualforce Page.
//
*******************************************/
public without sharing class PTPConversionController {
    
    public PTPConversionController(ApexPages.standardController std){
        
    }
    
    public PageReference convert(){
        Id ptpId = ApexPages.currentPage().getParameters().get('Id');
        
        Pass_to_Partner__c ptp = [SELECT Partner_Account__r.PAM__c, Twilio_Estimated_Amount__c, Launch_Date__c, Partner_Deal_Type__c, Contact__r.AccountId, Contact__r.Account.OwnerId, Contact__c, FY_16_Primary_Product_Input__c, Partner_Account__c, Partner_Account__r.OwnerId FROM Pass_to_Partner__c WHERE Id =: ptpId LIMIT 1];
                
        Id idRecordId = Schema.SObjectType.opportunity.getRecordTypeInfosByDeveloperName().get('Outbound_Opportunity').getRecordTypeId();
                
        Opportunity newOpp = new Opportunity();
        if(ptp !=null){
            newOpp.RecordTypeId = idRecordId;
            newOpp.Amount = ptp.Twilio_Estimated_Amount__c;
            newOpp.ForecastCategoryName = 'Pipeline';
            newOpp.SQLStatus__c ='SQL Accepted';
            newOpp.Alliances_Rep__c = ptp.Partner_Account__r.PAM__c;
            if(ptp.Contact__r.Account.OwnerId != null) newOpp.AccountId = ptp.Contact__r.AccountId;
            if(ptp.Partner_Account__r.OwnerId != null) newOpp.OwnerId = ptp.Partner_Account__r.OwnerId;
            newOpp.Name = 'PTP Conversion';
            newOpp.StageName = 'Incubate';
            newOpp.CloseDate = ptp.Launch_Date__c;
            newOpp.Partner_Influencer__c = ptp.Partner_Account__c;
            newOpp.LeadSource = 'Deal Registration';
            newOpp.Opportunity_Short_Name__c = 'Deal Reg - ' +  ptp.Partner_Deal_Type__c;
            newOpp.FY_16_Primary_Product__c = ptp.FY_16_Primary_Product_Input__c;
            newOpp.Launch_Date__c = newOpp.CloseDate;
            insert newOpp;
       }
        if(ptp.Contact__c !=null){
            OpportunityContactRole newRole = new OpportunityContactRole(OpportunityId = newOpp.Id, ContactId = ptp.Contact__c);
            insert newRole;
        }
        if(newOpp.Id !=null){
            ptp.Opportunity__c = newOpp.Id;
            update ptp;
        }
        if(newOpp.Id !=null){
        return new PageReference('/' + newOpp.Id);   
        }
        return null;
    }    
    public PageReference cancel(){
        Id ptpId = ApexPages.currentPage().getParameters().get('Id');
        return new PageReference('/' + ptpId);
    }
}