/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  ApexHandlerExceptionTest
*
* @description 	  Test class for ApexHandlerException class
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2020-04-23
* @modified       2020-04-23
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*
**/
@isTest ( seealldata = false )
private class ApexHandlerExceptionTest {

    private static testMethod void ApexHandlerExceptionTest1(){
        try{
            insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
            Account account = APTS_Testing_Utility.instantiateAccount ();

            insert account;
            
            List<Opportunity> lstOpp = new List<Opportunity>();
            for(integer i=0;i<100;i++){
            	Opportunity opportunity = APTS_Testing_Utility.instantiateOpportunity (null);
                lstOpp.add(opportunity);
            }
            insert lstOpp;
        }catch(DMLException e){
            ApexHandlerException.LogDMLException(e);
            List<Apex_Error_Log__c> log=[Select id from Apex_Error_Log__c];
            system.assert(log!=null);
        }
    }
    
    private static testMethod void ApexHandlerExceptionTest2(){
        try{
            List<Opportunity> lstOpp = new List<Opportunity>();
            for(integer i=0;i<100;i++){
            	Opportunity opportunity = APTS_Testing_Utility.instantiateOpportunity (null);
                lstOpp.add(opportunity);
            }
            insert lstOpp;
        }catch(Exception e){
            ApexHandlerException.LogException(e);
            List<Apex_Error_Log__c> log=[Select id from Apex_Error_Log__c];
            system.assert(log!=null);
        }
    }
}