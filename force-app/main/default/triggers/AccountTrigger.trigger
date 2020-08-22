/* * * * * * * * * * * * * *
*  Trigger Name: AccountTrigger
*  Purpose:      Trigger on Account to update Pre NPC Connect Date
*  Author:       Vivek Somani
*  Company:      GoNimbly
*  Created Date: 07-Feb-2017
*  Type:         Apex Trigger
* * * * * * * * * * * * */
trigger AccountTrigger on Account ( before update, after update )
{
  
  // Method will find latest Task by CreatedDate before First_NPC_500_Date__c and 
  // save Task CreatedDate in Pre_NPC_500_Connect_Date__c
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            AccountServices.processAccountsForPreNpcDate( trigger.new, trigger.oldMap );
        }
    }
     if(Trigger.isAfter){
        if(Trigger.isUpdate){
            AccountTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
  
}