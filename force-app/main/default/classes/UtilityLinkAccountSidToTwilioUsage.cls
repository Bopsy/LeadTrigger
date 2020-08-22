/** * * * * * * * * * * * *
 * 
 *  Class Name:   UtilityLinkAccountSidToTwilioUsage
 *  Purpose:      This is a utility class which link AccountSid with TwilioUsage object's records.
 *                AccountSid field on AccountSid object is used to link contact,lead and accountsid lookup on TwilioUsage. 
 *                It has common methods which are beig used from Batch (BatchLinkAccountSidToTwilioUsage) and Trigger on Twilio_Usage__c
 *                Part of "Twilio Multi-User Code Update Project v2.1"
 *  Change:       Lookup and Populate Twilio_Usage.AccountLookup__c based on Account_Sid.Account__c
						Always overwritten based on Account_SID.Account__c lookup
 *				  Ashwani Soni @GoNimbly Ian
 *  Author:       Ashwani Soni
 *  Company:      GoNimbly, Zack
 *  Created Date: 10-Feb-2016
 *  Changes:      none
 *  Type:         Apex Utility class
 *
** * * * * * * * * * * * */

public with sharing class UtilityLinkAccountSidToTwilioUsage 
{
	/* * * * *
	 * Find AccountSid records matching the twilio usage field "Account Sid"
	 * if match found, link the AccountSid record id into Twilio Usage Related_Account_SID__c.
	 * 
	 * NOTE: This method is used by batch BatchLinkAccountSidToTwilioUsage and Trigger on Twilio_Usage__c named NimblyLinkUsages
	 *
	 * @param: List of Twilio Usage records which need to be linked with Acccount Sid records
	 * @return: List of Twilio Usage recordspopulated with AccountSid records Id
	**/
    public static List<Twilio_Usage__c> LinkAccountSidToTwilioUsage(List<Twilio_Usage__c> twilioUsages)
    {
    	// Collect all Account_SID__c.Account_SID__c values in Set
		Set<string> accountSidSet = new Set<string>();  
		for(Twilio_Usage__c twilioUsage : twilioUsages)
		{
			if(twilioUsage.AccountSid__c!=null && 
			   !twilioUsage.isDeleted &&
			   ( !twilioUsage.Usage_Account_SID_Match_AccountSID_SID__c || 
			   	 !twilioUsage.Usage_Account_Match_AccountSID_Account__c ||
			   	 twilioUsage.Related_Account_Sid__c == null ) )
			{
		    	accountSidSet.add(twilioUsage.AccountSid__c);
			}
		}
		
		// Create mapped collection using collected Account_SID__c.Account_SID__c values in Set previously
		Map<String,Account_SID__c> accountSidMapToupdate = new Map<String,Account_SID__c>();
		if(accountSidSet.size() > 0)
		{
		    accountSidMapToupdate = linkAccountSid(accountSidSet);           
		}
		
		// Perform linking over passed list as argument
		if(accountSidMapToupdate.size() > 0)
		{
		    for(Twilio_Usage__c twilioUsage : twilioUsages)
		    {
		        if(accountSidMapToupdate.containskey(twilioUsage.AccountSid__c))
		        {
		            twilioUsage.Related_Account_SID__c = accountSIDmapToupdate.get(twilioUsage.AccountSid__c).id;
                    // Added on 25-Feb-2016. Req. Always overwritten based on Account_SID.Account__c lookup
                    twilioUsage.AccountLookup__c  = accountSIDmapToupdate.get(twilioUsage.AccountSid__c).Account__c;
		        }
		    }
		}
		
		return twilioUsages;
    }
    
    /****
     * Create map having Key:Account_SID__c.Account_SID__c and value Account_SID__c record instance.
     * @param: List of Account Sid records Id which are used a filter in querying only relevent records.
     * @return: Map, having Key:Account_SID__c.Account_SID__c and value Account_SID__c record instance.
    ***/
    public static Map<string,Account_SID__c> linkAccountSid(set<string> accountSids)
    {
        Map<string,Account_SID__c> accountSidMap = new Map<string,Account_SID__c>();
        for(Account_SID__c accountSidrec : [SELECT id,name,Account_SID__c,Lead__c,contact__c, Account__c FROM Account_SID__c WHERE Account_SID__c IN : accountSids])
        {
            accountSidMap.put(accountSidrec.Account_SID__c,accountSidrec);
        }
        
        return accountSIDmap;
    }
}