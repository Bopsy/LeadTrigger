/* * * * * *
*
* Name:        TwilioUsageTriggerHandler_Test (Test class)
* Description: Unit test class for CLASS_NAME
* Created:    Feb 16, 2016 6:15:43 PM
* Author:      Ashwani Soni via ashwani
* Company:     
*
* * * */
@isTest
private class TwilioUsageTriggerHandler_Test 
{
    static void createData()
    {
        final Integer recordsCount = 5;
        
        List<account> acclist = new list<account>();
        List<contact> conlist = new list<contact>();
        List<Account_SID__c> SIDlist = new list<Account_SID__c>();
        List<Twilio_Usage__c> twlist = new list<Twilio_Usage__c>();
        
        for(integer i=0; i<recordsCount; i++)
        {
            account acc = new account();
            acc.name = 'AccountTest' + i;
            acc.Channel_Account_Status__c = 'Inactive';
            acclist.add(acc);   
        } 
        insert acclist;
        
        for(integer i=0; i<recordsCount; i++)
        {    
            Account_SID__c aSID = new Account_SID__c();
            aSID.name = 'SID'+i;
            aSID.OwnerUser_SID__c = '1234567'+i;
            aSID.Account_SID__c = '1234567SID'+i;
            aSID.OwnerUser_Email_Address__c = 'cont'+i+'@xyz.com';
            SIDlist.add(aSID);     
        } 
        insert SIDlist;
        
         
        for(integer i=0; i<recordsCount; i++)
        {
            Twilio_Usage__c twRecord = new Twilio_Usage__c();
            twRecord.CounterKey__c='test'+i;
            twRecord.Product__c='hello'+i;
            twRecord.AccountSid__c='1234567SID'+i;
            twRecord.Total__c=12.34;
            twRecord.Volume__c=44;
            twRecord.Volume__c=44;
            twRecord.Currency__c='USD';
            twRecord.Year__c= date.today().year();
            twRecord.month__c = date.today().month();
            twlist.add(twRecord);
        }

        insert twlist;
         
        for(integer i=0; i<recordsCount; i++)
        {    
            Account_SID__c aSID = SIDlist[i];
            aSID.Account__c = acclist[i].id;
        } 
        update SIDlist;
    }
    
    static void createDataSecond()
    {
        final Integer recordsCount = 5;
        
        List<account> acclist = new list<account>();
        List<contact> conlist = new list<contact>();
        List<Account_SID__c> SIDlist = new list<Account_SID__c>();
        List<Twilio_Usage__c> twlist = new list<Twilio_Usage__c>();
        
        for(integer i=0; i<recordsCount; i++)
        {
            account acc = new account();
            acc.name = 'AccountTest' + i;
            acc.Channel_Account_Status__c = 'Inactive';
            acclist.add(acc);   
        } 
        insert acclist;
        
        for(integer i=0; i<recordsCount; i++)
        {    
            Account_SID__c aSID = new Account_SID__c();
            aSID.name = 'SID'+i;
            aSID.OwnerUser_SID__c = '1234567'+i;
            aSID.Account_SID__c = '1234567SID'+i;
            aSID.OwnerUser_Email_Address__c = 'cont'+i+'@xyz.com';
            SIDlist.add(aSID);     
        } 
        insert SIDlist;
        
         
        for(integer i=0; i<recordsCount; i++)
        {
            Twilio_Usage__c twRecord = new Twilio_Usage__c();
            twRecord.CounterKey__c='test'+i;
            twRecord.Product__c='hello'+i;
            twRecord.AccountSid__c='1234567SID'+i;
            twRecord.Total__c=12.34;
            twRecord.Volume__c=44;
            twRecord.Volume__c=44;
            twRecord.Currency__c='USD';
            twRecord.Year__c= date.today().year();
            twRecord.month__c = date.today().month();
            twlist.add(twRecord);
        }

        insert twlist;
         
        for(integer i=0; i<recordsCount; i++)
        {    
            Account_SID__c aSID = SIDlist[i];
            aSID.Account__c = acclist[i].id;
        } 
        update SIDlist;
        
        for(integer i=0; i<recordsCount; i++)
        {
            Twilio_Usage__c tw = twlist[i];
            tw.Related_Account_SID__c = null;
        }
        update twlist;
    }
    
    static testMethod void testTwilioLinkingTest1() 
    {
    	Test.startTest();
        createData();
        Test.stopTest();
    }
    
    static testMethod void testTwilioLinkingTest2() 
    {
    	Test.startTest();
        createData();
        Test.stopTest();
    }
}