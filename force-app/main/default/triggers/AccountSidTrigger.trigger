/** * * * * * * * * * * * *
 * 
 *  Class Name:   AccountSidTrigger
 *  Purpose:      Update all below Twilio Usage record with Account Id of their Accounr Sid object record
 *  Author:       Ashwani Soni
 *  Company:      GoNimbly
 *  Created Date: 10-Feb-2016
 *  Changes:      none
 *  Type:         Trigger
 *
** * * * * * * * * * * * */

trigger AccountSidTrigger on Account_SID__c (after update) 
{
	if(Trigger.isAfter)
	{
	    if(trigger.isupdate)
	    {
	        AccountSidTriggerHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
	    }     
	}       
}