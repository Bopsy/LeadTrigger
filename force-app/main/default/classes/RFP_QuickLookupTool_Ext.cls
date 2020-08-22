public with sharing class RFP_QuickLookupTool_Ext {
    public RFP_QuickLookupTool_Ext(ApexPages.StandardController stdController) {


        //this.acct = (Account)stdController.getRecord();
    }

    public List<Schema.PicklistEntry> getCategories()
	{
	
    	Schema.DescribeFieldResult fieldResult = Response__c.Category__c.getDescribe();
    	List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	        
	   return ple;
	}
}