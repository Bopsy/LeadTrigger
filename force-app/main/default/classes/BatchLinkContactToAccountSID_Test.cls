/** * * * * * * * * * * * *
 * 
 *  Class Name:   BatchLinkContactToAccountSID_Test
 *  Purpose:      Test class for BatchLinkContactToAccountSID
 *  Author:       Ashwani Soni
 *  Company:      GoNimbly, Ian and Zack
 *  Created Date: 12-Nov-2015
 *  Changes:      18-February-2016 : updated as per new specification in "Twilio Multi-User Code Update Project v2.1", Ashwani
 *  Changes II:   18-March-2016 : test class refactored as per new set of guidelines in "Clean Up Unit Tests", Divesh Bafna 
 *  Type:         Batch class
 *
** * * * * * * * * * * * */

@isTest
private class BatchLinkContactToAccountSID_Test{ 
    
    static final Integer NUM_RECORDS = 5;
    static list<account> acclist ;
    static list<contact> conlist  ;
    static list<Account_SID__c> SIDlist ;
    static boolean withContacts = false;
    static boolean noContacts = false;
    static boolean noAccount = false;
    static boolean noAccountChange = false;
    
    static void createdata()
    {    
        if(!noAccount){
            acclist = TestDataFactory.createAccountList(NUM_RECORDS);
            insert acclist ;
        }        
        
        
        conlist = TestDataFactory.createContactList(NUM_RECORDS);        
        for(Integer index = 0; index < NUM_RECORDS; index++)
        {       
            if(noAccountChange){
                conlist[index].accountid= acclist[0].id; 
            }       
            else if(!noaccount){
                conlist[index].accountid= acclist[index].id;
            }                       
            conlist[index].Email= 'cont'+index+'@xyz.com';
            conlist[index].FY15_User_ID__c = '1234567'+index;            
        }
        insert conlist; 
        
        SIDlist = TestDataFactory.createAccSIDList(NUM_RECORDS);        
        for( Integer index = 0; index < NUM_RECORDS; index++ )
        {
            if(noAccountChange)
            {
                SIDlist[index].Account__c =  acclist[0].id;
            }               
            if(withContacts){
                SIDlist[index].Contact__c =  conlist[0].id;
            }              
        }
        insert SIDlist;
    }
    
    static testMethod void ValidatetestNoContact()
    {
        createdata();
        Map<Id,Id> expectedContactIdResult = new Map<Id,Id>();
        for(integer index=0; index<conlist.size(); index++)
        {
            expectedContactIdResult.put(conlist[index].id,conlist[index].id);
        }
        
        Map<Id,Id> expectedAccSIdResult = new Map<Id,Id>();
        for(integer index=0; index<conlist.size(); index++)
        {
            expectedAccSIdResult.put(conlist[index].Accountid,conlist[index].Accountid);
        }
        
        Test.startTest();
            BatchLinkContactToAccountSID bat = new BatchLinkContactToAccountSID(); 
            database.executebatch(bat);            
            System.schedule('Sync Contact - Hourly', '0 0 * * * ?', new BatchLinkContactToAccountSID());
        Test.stopTest();
        
        list<contact> newconlist = [select id,FY15_User_ID__c,accountid,email from contact where id in: conlist];
        system.assertequals(NUM_RECORDS,newconlist.size());
        
        map<string,contact> emailcon = new Map<string,contact>();
        for(contact con : newconlist){
            emailcon.put(con.email,con);
        }        
        
        list<Account_SID__c > newSIDlist = [select id,OwnerUser_SID__c,Account__c,Contact__c,OwnerUser_Email_Address__c from Account_SID__c where id in:SIDlist];
        system.assertequals(NUM_RECORDS,newSIDlist.size());
        
        map<string,Account_SID__c> emailAccSID = new Map<string,Account_SID__c>();
        for(Account_SID__c accSID : newSIDlist){
            emailAccSID.put(accSID.OwnerUser_Email_Address__c,accSID);
        }
        
        for(string email : emailAccSID.keyset() )
        {
            system.assertequals(emailcon.get(email).id,emailAccSID.get(email).contact__c);
            system.assertequals(emailcon.get(email).accountid,emailAccSID.get(email).account__c);
        }
    }   
    
    static testMethod void ValidatetestMultipleContacts()
    {
        withContacts = true ;
        createdata();        
        Map<Id,Id> expectedContactIdResult = new Map<Id,Id>();
        for(integer index=0; index<conlist.size(); index++)
        {
            expectedContactIdResult.put(conlist[index].id,conlist[index].id);
        }
        
        Map<Id,Id> expectedAccSIdResult = new Map<Id,Id>();
        for(integer index=0; index<conlist.size(); index++)
        {
            expectedAccSIdResult.put(conlist[index].Accountid,conlist[index].Accountid);
        }
        
        test.startTest();
            BatchLinkContactToAccountSID bat = new BatchLinkContactToAccountSID(); 
            database.executebatch(bat);
        test.stopTest();
        
        list<contact> newconlist = [select id,FY15_User_ID__c,accountid,email from contact where id in: conlist];
        system.assertequals(NUM_RECORDS,newconlist.size());
        
        map<string,contact> emailcon = new Map<string,contact>();
        for(contact con : newconlist){
            emailcon.put(con.email,con);
        }        
        
        list<Account_SID__c > newSIDlist = [select id,OwnerUser_SID__c,Account__c,Contact__c,OwnerUser_Email_Address__c from Account_SID__c where id in:SIDlist];
        system.assertequals(NUM_RECORDS,newSIDlist.size());
        
        map<string,Account_SID__c> emailAccSID = new Map<string,Account_SID__c>();
        for(Account_SID__c accSID : newSIDlist){
            emailAccSID.put(accSID.OwnerUser_Email_Address__c,accSID);
        }
        
        for(string email : emailAccSID.keyset() )
        {
            system.assertequals(emailcon.get(email).id,emailAccSID.get(email).contact__c);
            system.assertequals(emailcon.get(email).accountid,emailAccSID.get(email).account__c);
        }
    }
    
    static testMethod void ValidatetestContactsWithoutAccount()
    {        
        noAccount = true;
        createdata();
        
        Map<Id,Id> expectedContactIdResult = new Map<Id,Id>();
        for(integer index=0; index<conlist.size(); index++)
        {
            expectedContactIdResult.put(conlist[index].id,conlist[index].id);
        }
        
        Map<Id,Id> expectedAccSIdResult = new Map<Id,Id>();
        for(integer index=0; index<conlist.size(); index++)
        {
            expectedAccSIdResult.put(conlist[index].Accountid,conlist[index].Accountid);
        }
        
        test.startTest();
            BatchLinkContactToAccountSID bat = new BatchLinkContactToAccountSID(); 
            database.executebatch(bat);
        test.stopTest();
        list<contact> newconlist = [select id,FY15_User_ID__c,accountid,email from contact where id in: conlist];
        system.assertequals(NUM_RECORDS,newconlist.size());
        
        map<string,contact> emailcon = new Map<string,contact>();
        for(contact con : newconlist){
            emailcon.put(con.email,con);
        }        
        
        list<Account_SID__c > newSIDlist = [select id,OwnerUser_SID__c,Account__c,Contact__c,OwnerUser_Email_Address__c from Account_SID__c where id in:SIDlist];
        system.assertequals(NUM_RECORDS,newSIDlist.size());
        
        map<string,Account_SID__c> emailAccSID = new Map<string,Account_SID__c>();
        for(Account_SID__c accSID : newSIDlist){
            emailAccSID.put(accSID.OwnerUser_Email_Address__c,accSID);
        }
        
        for(string email : emailAccSID.keyset() )
        {
            system.assertequals(emailcon.get(email).id,emailAccSID.get(email).contact__c);
            system.assertequals(emailcon.get(email).accountid,emailAccSID.get(email).account__c);
        }
    }
    
    static testMethod void ValidatetestContactsButNoAccountChange()
    {
        noAccountChange = true;
        createdata();
        Map<Id,Id> expectedContactIdResult = new Map<Id,Id>();
        for(integer index=0; index<conlist.size(); index++)
        {
            expectedContactIdResult.put(conlist[index].id,conlist[index].id);
        }
        
        test.startTest();
            BatchLinkContactToAccountSID bat = new BatchLinkContactToAccountSID(); 
            database.executebatch(bat);
        test.stopTest();
        list<contact> newconlist = [select id,FY15_User_ID__c,accountid,email from contact where id in: conlist];
        system.assertequals(NUM_RECORDS,newconlist.size());
        
        map<string,contact> emailcon = new Map<string,contact>();
        for(contact con : newconlist){
            emailcon.put(con.email,con);
        }        
        
        list<Account_SID__c > newSIDlist = [select id,OwnerUser_SID__c,Account__c,Contact__c,OwnerUser_Email_Address__c from Account_SID__c where id in:SIDlist];
        system.assertequals(NUM_RECORDS,newSIDlist.size());
        
        map<string,Account_SID__c> emailAccSID = new Map<string,Account_SID__c>();
        for(Account_SID__c accSID : newSIDlist){
            emailAccSID.put(accSID.OwnerUser_Email_Address__c,accSID);
        }
        
        for(string email : emailAccSID.keyset() )
        {
            system.assertequals(emailcon.get(email).id,emailAccSID.get(email).contact__c);
            system.assertequals(emailcon.get(email).accountid,emailAccSID.get(email).account__c);
        }
    }
    
    static testMethod void ValidateContactsCustomSetting()
    {
        Account_Sid_Mapping__c asm = new Account_Sid_Mapping__c();
        asm.Object_API_Name__c = 'Contact';
        asm.Source_Field_API_Name__c = 'OwnerUser_SID__c';
        asm.Target_Field_API_Name__c = 'OwnerUser_SID__c';
        asm.name = 'Test Field Map';
        insert asm;
        
        withContacts = true;
        createdata();
        Map<Id,Id> expectedContactIdResult = new Map<Id,Id>();
        for(integer index=0; index<conlist.size(); index++)
        {
            expectedContactIdResult.put(conlist[index].id,conlist[index].id);
        }
        
        Map<Id,Id> expectedAccSIdResult = new Map<Id,Id>();
        for(integer index=0; index<conlist.size(); index++)
        {
            expectedAccSIdResult.put(conlist[index].Accountid,conlist[index].Accountid);
        }
        
        Map<String,String> expectedEmailResult = new Map<String,String>();
        for(integer index=0; index<SIDlist.size(); index++)
        {
            expectedEmailResult.put(SIDlist[index].OwnerUser_Email_Address__c,SIDlist[index].OwnerUser_Email_Address__c);
        }
        
        test.startTest();
            BatchLinkContactToAccountSID bat = new BatchLinkContactToAccountSID(); 
            database.executebatch(bat);
        test.stopTest();
        
        list<contact> newconlist = [select id,FY15_User_ID__c,accountid,email from contact where id in: conlist];
        system.assertequals(NUM_RECORDS,newconlist.size());
        
        map<string,contact> emailcon = new Map<string,contact>();
        for(contact con : newconlist){
            emailcon.put(con.email,con);
        }        
        
        list<Account_SID__c > newSIDlist = [select id,OwnerUser_SID__c,Account__c,Contact__c,OwnerUser_Email_Address__c from Account_SID__c where id in:SIDlist];
        system.assertequals(NUM_RECORDS,newSIDlist.size());
        
        map<string,Account_SID__c> emailAccSID = new Map<string,Account_SID__c>();
        for(Account_SID__c accSID : newSIDlist){
            emailAccSID.put(accSID.OwnerUser_Email_Address__c,accSID);
        }
        
        for(string email : emailAccSID.keyset() )
        {
            system.assertequals(emailcon.get(email).id,emailAccSID.get(email).contact__c);
            system.assertequals(emailcon.get(email).accountid,emailAccSID.get(email).account__c);
        }
    }
    
    static testMethod void testSchedule()
    {   
        Test.startTest();
          Id scehduleJobId =  System.schedule('Sync Contact - Hourly', '0 0 * * * ?', new BatchLinkContactToAccountSID());
        Test.stopTest();
        
        System.assertNotEquals( scehduleJobId, null, 'Schedule Job Id in null' );
    } 
}