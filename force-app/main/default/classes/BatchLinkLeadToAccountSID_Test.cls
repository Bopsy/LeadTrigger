/* * * * * *
*
* Name:        BatchLinkLeadToAccountSID_Test (Test class)
* Description: Unit test class for BatchLinkLeadToAccountSID
* Created:     Feb 16, 2016 1:50:57 PM
* Author:      Ashwani Soni
* Company:     GoNimbly, Zack
* Changes:     18-March-2016 : test class refactored as per new set of guidelines in "Clean Up Unit Tests", Divesh Bafna
* * * */
@isTest
private class BatchLinkLeadToAccountSID_Test 
{
    static List<Account_Sid_Mapping__c> asmList ;
    static List<Account_SID__c> aSIDList ;
    static List<Lead> ldList;
    static List<Account_SID__c> aSIDList2 ;
    static List<Lead> ldList2;
    static boolean noMatch = false ;
    static boolean reMatch = false ;
    static integer NUM_RECORDS = 5;
    
    static void createData()
    {
        asmList = TestDataFactory.createAccSIDmappingList(NUM_RECORDS);
        insert asmList ;
        
        aSIDList = TestDataFactory.createAccSIDList(NUM_RECORDS);
        for( Integer index = 0; index < NUM_RECORDS; index++ )
        {
            if(noMatch){
                aSIDList[index].OwnerUser_Email_Address__c = 'cont@xyz.com';
            }
            else{
                aSIDList[index].OwnerUser_Email_Address__c = 'conteffort@xyz.com';
            }            
            aSIDList[index].OwnerUser_SID__c = 'ousidelead';  
            aSIDList[index].Lead__c = null;
        }             
        insert aSIDList;
        
        ldList = TestDataFactory.createLeadList(NUM_RECORDS);
        for( Integer index = 0; index < NUM_RECORDS; index++ )
        {
            ldList[index].Email= 'conteffort@xyz.com';
        }            
        insert ldList;
        
        if(reMatch){
            ldList2 = TestDataFactory.createLeadList(NUM_RECORDS);
                for( Integer index = 0; index < NUM_RECORDS; index++ )
                {
                    ldList2[index].Email= 'conteffort'+ index +'@xyz.com';
                }                 
            insert ldList2;
            
            aSIDList2 = TestDataFactory.createAccSIDList(NUM_RECORDS);  
                for( Integer index = 0; index < NUM_RECORDS; index++ )
                {
                    aSIDList2[index].OwnerUser_SID__c = 'USAe1234567eFAecAAse2';
                    aSIDList2[index].OwnerUser_Email_Address__c = 'conteffort'+ index +'@xyz2.com';
                    aSIDList2[index].Lead__c = ldList2[index].id; 
                }
            insert aSIDList2 ;
        }
    }
    
    static testMethod void ValidateLeadLinkNoMatch()
    {
        noMatch = true;
        createData();
        test.startTest();
            database.executebatch(new BatchLinkLeadToAccountSID ());     
        test.stopTest();
        
        List<Account_SID__c> accSIDList = [SELECT Lead__c FROM Account_SID__c WHERE id IN :aSIDList];
        System.assertEquals(accSIDList.size(),NUM_RECORDS);
        
        for(Account_SID__c accSID : accSIDList ){
            System.assertEquals(accSID.Lead__c,null);
        }
        
        List<lead> leadList = [SELECT OwnerUser_SID__c FROM lead WHERE id IN :ldList];
         System.assertEquals(leadList.size(),NUM_RECORDS);
        for(lead ld : leadList ){
            System.assertEquals(ld.OwnerUser_SID__c,null);
        }
    } 
    
    static testMethod void ValidateLeadLinkMatch()
    {
        createData();        
        test.startTest();
            Database.executeBatch( new BatchLinkLeadToAccountSID () );
        test.stopTest();
        
        map<string,id> emailAccSIDLeadmap = new map<string,id>();
        map<string,id> ownerSIDAccSIDLeadmap = new map<string,id>();
        
        List<Account_SID__c> accSIDList = [SELECT Lead__c,OwnerUser_Email_Address__c,OwnerUser_SID__c  FROM Account_SID__c WHERE id IN : aSIDList];
        System.assertEquals(accSIDList.size(),NUM_RECORDS);
        
        for(Account_SID__c accSID : accSIDList ){
            emailAccSIDLeadmap.put(accSID.OwnerUser_Email_Address__c , accSID.Lead__c);
            emailAccSIDLeadmap.put(accSID.OwnerUser_SID__c , accSID.Lead__c);
        }
        
        map<string,id> emailLeadIDmap = new map<string,id>();
        map<string,id> ownerSIDLeadIDmap = new map<string,id>();
        
        List<lead> leadList = [SELECT OwnerUser_SID__c,email FROM lead WHERE id IN :ldList];
         System.assertEquals(leadList.size(),NUM_RECORDS);
         
        for(Lead ld : leadList ){
            emailLeadIDmap.put(ld.email,ld.id);
            emailLeadIDmap.put(ld.OwnerUser_SID__c,ld.id);
        }
        
        for(string email : emailAccSIDLeadmap.keyset()){
            System.assertEquals(emailAccSIDLeadmap.get(email),emailLeadIDmap.get(email));
        }
        
        for(string owneruserSID : emailAccSIDLeadmap.keyset()){
            System.assertEquals(emailAccSIDLeadmap.get(owneruserSID),emailLeadIDmap.get(owneruserSID));
        }
    }
    
    static testMethod void ValidateLeadLinkMatchSchedule()
    {
        test.startTest();
           Id scehduleJobId = System.schedule('Sync Lead - Hourly', '0 0 * * * ?', new BatchLinkLeadToAccountSID());    
        test.stopTest();
        System.assertNotEquals( scehduleJobId, null, 'Schedule Job Id in null' );
    } 
    
    static testMethod void ValidateLeadHasNoMAtchNow()
    {
        createData();
        for( Integer index = 0; index < NUM_RECORDS; index++ )
        {
            ldList[index].Email= 'emailchanges@lead.com';
        }    
        update ldList;
        
        test.startTest();
            BatchLinkLeadToAccountSID bat = new BatchLinkLeadToAccountSID(); 
            database.executebatch(bat); 
        test.stopTest();
        
        List<Account_SID__c> accSIDList = [SELECT Lead__c FROM Account_SID__c WHERE id IN :aSIDList];
        System.assertEquals(accSIDList.size(),NUM_RECORDS);
        
        for(Account_SID__c accSID : accSIDList){
            System.assertEquals(accSID.lead__c , null);
        }
    }
    
    static testMethod void ValidateAsidReMatchToEmpty()
    {
        reMatch = true;      
        createData();
        for( Integer index = 0; index < NUM_RECORDS; index++ )
        {
            ldList2[index].Email= 'emailchanges@lead.com';
        }    
        update ldList2;
        
        test.startTest();
            BatchLinkLeadToAccountSID bat = new BatchLinkLeadToAccountSID(); 
            database.executebatch(bat); 
        test.stopTest();
        
        map<string,id> emailAccSIDLeadmap = new map<string,id>();
        List<Account_SID__c> accSIDList1 = [SELECT Lead__c,OwnerUser_Email_Address__c FROM Account_SID__c WHERE id IN : aSIDList];
        System.assertEquals(accSIDList1.size(),NUM_RECORDS);
        for(Account_SID__c accSID : accSIDList1 ){
            emailAccSIDLeadmap.put(accSID.OwnerUser_Email_Address__c , accSID.Lead__c);
        }
        
        map<string,id> emailLeadIDmap = new map<string,id>();
        
        List<lead> leadList = [SELECT OwnerUser_SID__c,email FROM lead WHERE id IN :ldList];
        System.assertEquals(leadList.size(),NUM_RECORDS);
        for(Lead ld : leadList ){
            emailLeadIDmap.put(ld.email,ld.id);
        }
        
        for(string email : emailAccSIDLeadmap.keyset()){
            System.assertEquals(emailAccSIDLeadmap.get(email),emailLeadIDmap.get(email));
        }
        
        List<Account_SID__c> accSIDList2 = [SELECT Lead__c,OwnerUser_Email_Address__c  FROM Account_SID__c WHERE id IN :aSIDList2];
        System.assertEquals(accSIDList2.size(),NUM_RECORDS);
        
        for(Account_SID__c accSID : accSIDList2 ){
            System.assertEquals(accSID.Lead__c,null);
        }        
    }
    
    static testMethod void ValidateLeadReMatch()
    {
        reMatch = true;
        createData();
        
        test.startTest();
            BatchLinkLeadToAccountSID bat = new BatchLinkLeadToAccountSID(); 
            database.executebatch(bat); 
        test.stopTest();
        map<string,id> emailAccSIDLeadmap = new map<string,id>();
        List<Account_SID__c> accSIDList = [SELECT Lead__c,OwnerUser_Email_Address__c FROM Account_SID__c WHERE id IN : aSIDList];
        System.assertEquals(accSIDList.size(),NUM_RECORDS);
        
        for(Account_SID__c accSID : accSIDList){
            emailAccSIDLeadmap.put(accSID.OwnerUser_Email_Address__c , accSID.Lead__c);
        }
        
        map<string,id> emailLeadIDmap = new map<string,id>();
        List<lead> leadList = [SELECT id,email FROM lead WHERE id IN : ldList];
        System.assertEquals(leadList.size(),NUM_RECORDS);
        for(Lead ld : leadList ){
            emailLeadIDmap.put(ld.email,ld.id);
        }
        
        for(string email : emailAccSIDLeadmap.keyset()){
            System.assertEquals(emailAccSIDLeadmap.get(email),emailLeadIDmap.get(email));
        }
    } 
    
}