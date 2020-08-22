/*** * * * * *
*
* Name:        AccountSidTriggerHandler_Test (Test class)
* Description: Unit test class for AccountSidTriggerHandler
* Created:     Feb 16, 2016 12:56:22 PM
* Author:      Ashwani Soni via ashwani
* Company:     
*
* * * */
@isTest
private class AccountSidTriggerHandler_Test 
{
	static final Integer recordsCount = 1;
	static list<contact> conlist ;
	static list<account> acclist ;
	static list<Account_SID__c> SIDlist ;
	static list<Twilio_Usage__c> twlist ;
 	
    static testMethod void verifyAccountLookupSynced() 
    {
        acclist = new list<account>();
	    conlist = new list<contact>();
	    SIDlist = new list<Account_SID__c>();
	    twlist = new list<Twilio_Usage__c>();
	    for(integer recordNumber=0; recordNumber<2; recordNumber++)
	    {
	    	account acc = new account();
	        acc.name = 'AccountTest' + recordNumber;
	        acc.Channel_Account_Status__c = 'Inactive';
	        acclist.add(acc);   
	    } 
	    insert acclist;
	    
	    for(integer recordNumber=0; recordNumber<1; recordNumber++)
	    {    
	        Account_SID__c aSID = new Account_SID__c();
	        aSID.name = 'SID'+recordNumber;
	        aSID.Account__c = acclist[0].id;
	        aSID.OwnerUser_SID__c = '1234567'+recordNumber;
	        aSID.Account_SID__c = '1234567SID'+recordNumber;
	        aSID.OwnerUser_Email_Address__c = 'cont'+recordNumber+'@xyz.com';
	        SIDlist.add(aSID);     
	    } 
	    insert SIDlist;
	    
	    for(integer recordNumber=0; recordNumber<SIDlist.size(); recordNumber++)
		{
		    Twilio_Usage__c twTestRecord = new Twilio_Usage__c();
			twTestRecord.Related_Account_Sid__c=SIDlist[recordNumber].id;
			twTestRecord.Year__c=2014;
			twTestRecord.Month__c=12;
			twTestRecord.Product__c='hello'+recordNumber;
			twTestRecord.CounterKey__c='test'+recordNumber;
			twTestRecord.AccountSid__c='1234567SID'+recordNumber;
			twTestRecord.Total__c=12.34;
			twTestRecord.Volume__c=44;
			twTestRecord.Currency__c='USD';
			twlist.add(twTestRecord);	
		}
		
	    insert twlist;
	    
	    for(integer recordNumber=0; recordNumber<1; recordNumber++)
	    {    
	        Account_SID__c aSID = SIDlist[recordNumber];
	        aSID.Account__c = acclist[1].id; 
	    } 
	    
        Test.startTest();
       	update SIDlist;
        Test.stopTest();
        for(Account_SID__c aSID : SIDlist)
        {
			System.assertEquals(aSID.Account__c,acclist[1].id);
        }
        for(Twilio_Usage__c tw : [SELECT AccountLookup__c FROM Twilio_Usage__c])
        {
       		System.assertNotEquals(tw.AccountLookup__c,null);
			System.assertEquals(tw.AccountLookup__c,acclist[1].id,' Must be '+acclist[1].Name+ 'record');
        }
    }
}