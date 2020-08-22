/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  ApexHandlerException
*
* @description 	  Handler to class to create exceptions under Apex error log object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2020-03-05
* @modified       2020-03-05
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  
*
**/
public class ApexHandlerException extends Exception {
    
    // Log Exception in Apex error log object. 
    public static void LogException(Exception e){
        Apex_Error_Log__c exc = new Apex_Error_Log__c();
        exc.Line_Number__c = e.getLineNumber();
        exc.Error_message__c = e.getMessage();
        exc.type__c = e.getTypeName();
        exc.Stack_Trace__c = e.getStackTraceString();
        insert(exc);    
    } 
    
    // Log DML Exception in Apex error log object. 
    public static void LogDMLException(DMLException e){
        Apex_Error_Log__c exc = new Apex_Error_Log__c();
        exc.Line_Number__c = e.getLineNumber();
        exc.Error_message__c = e.getMessage();
        exc.type__c = e.getTypeName();
        exc.Stack_Trace__c = e.getStackTraceString();
        exc.Record_Id__c = (String) e.getDmlId(0);
        insert(exc); 
    } 
}