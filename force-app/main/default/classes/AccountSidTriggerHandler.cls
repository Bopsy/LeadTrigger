/** * * * * * * * * * * * *
 * 
 *  Class Name:   AccountSidTriggerHandler
 *  Purpose:      Handler for AccountSidTrigger. Update all below Twilio Usage record with Account Id of their Accounr Sid object record
 *  Author:       Ashwani Soni
 *  Company:      GoNimbly
 *  Created Date: 10-Feb-2016
 *  Changes:      none
 *  Type:         Apex class
 *
** * * * * * * * * * * * */
public with sharing class AccountSidTriggerHandler 
{
	public static Boolean leadconversion = false;
    public static void onAfterUpdate(map<id,Account_SID__c> oldMap,map<id,Account_SID__c> newMap)
    {
        List<Twilio_Usage__c> twilioUsageList = new List<Twilio_Usage__c>();
        Set<id> accSidSet = new Set<id>();
                
        for(Account_SID__c accSID : newMap.values())
        {
            if(accSID.Account__c != null && oldMap.get(accSID.id).Account__c != newMap.get(accSID.id).Account__c)
            {
                accSidSet.add(accSID.id);
            }
        }        
        
        if(accSidSet.size()>0)
        {
	        for(Twilio_Usage__c twUsage : [SELECT id,Name,AccountLookup__c,Related_Account_SID__r.Account__c, Related_Account_SID__r.Contact__c FROM Twilio_Usage__c WHERE Related_Account_SID__c IN: accSidSet])
	        {
	            twUsage.AccountLookup__c = twUsage.Related_Account_SID__r.Account__c ;
	            // Sync contact if lead is converting
	            if(leadconversion)
	            {
	            	twUsage.Contact__c = twUsage.Related_Account_SID__r.Contact__c;
	            }
	            twilioUsageList.add(twUsage);
	        }
        }
        
        try
		{
		  	update twilioUsageList;
		}
		catch( System.DmlException dmlEx )
		{
		  	for( Integer errorIndex = 0; errorIndex < dmlEx.getNumDml(); errorIndex++ )
		  	{
		    	Id relatedErrorId = twilioUsageList[ dmlEx.getDmlIndex(errorIndex) ].Related_Account_SID__c;
		    	newMap.get( relatedErrorId ).addError( dmlEx.getDmlMessage(errorIndex) );
		  	}
		}         
    }    
}