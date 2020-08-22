@isTest
private class CaseTiggerHandlerTest {

	private static testMethod void test() {
        Case_Constants__c csData = new Case_Constants__c(Name = 'COMS', Trigger_Start_Date__c= date.newInstance(2019, 9, 12), Record_Type_ID__c = '0121W0000009pXLQAY');
        insert csData;
        account acc = new account(name = 'caseTEST');
	    insert acc;
	    Account_SID__c aSID = new Account_SID__c(name = 'caseTESTSID', Account__c= acc.Id, OwnerUser_SID__c = '1234567', OwnerUser_Email_Address__c='test@xashjas.com');
	    aSID.Account_SID__c = '1234567SID';
        insert aSID;
        
        Case c = new Case(Whatdoyouneedhelpwith__c = 'Payments', Status = 'Submitted',SIDS_to_add_to_Order_Form__c = '89789gggyg',
                          Request_Category__c = 'Methods', AccountId = acc.Id, Account_SID_in_question__c='sidsidsid', Your_Request_Inquiry__c= 'dsa');
        Test.startTest();
        try {
           insert c;
        }
        catch(Exception e){
           Boolean expectedExceptionThrown =  e.getMessage().contains('does not belong to this account') ? true : false;
           System.AssertEquals(expectedExceptionThrown, true);
        } 
        
        Case c2 = new Case(Whatdoyouneedhelpwith__c = 'Payments', Status = 'Submitted',SIDs_to_add_to_Pricing_Model_if_needed__c = aSID.Name,
                          Request_Category__c = 'Methods', AccountId = acc.Id, Account_SID_in_question__c='sidsidsid', Your_Request_Inquiry__c= 'dsa');
        insert c2;
        System.assert(c2.ID!= NULL);
        
        try {
           
           c2.SIDs_to_add_to_Pricing_Model_if_needed__c = 'dsadsas';
           update c2;
        }
        catch(Exception e){
           Boolean expectedExceptionThrown =  e.getMessage().contains('does not belong to this account') ? true : false;
           System.AssertEquals(expectedExceptionThrown, true);
        }
        
        Case c3 = new Case(Whatdoyouneedhelpwith__c = 'Payments', Status = 'Submitted',SIDS_to_add_to_Order_Form__c = 'fsdsdf',Primary_SID_on_Order_Form__c = 'dsasda',
                          Request_Category__c = 'Methods', AccountId = acc.Id, Account_SID_in_question__c='sidsidsid', Your_Request_Inquiry__c= 'dsa');
        try {
           insert c3;//Primary_SID_on_Order_Form__c
        }//SIDS_to_add_to_Order_Form__c
        catch(Exception e){
           Boolean expectedExceptionThrown =  e.getMessage().contains('does not belong to this account') ? true : false;
           System.AssertEquals(expectedExceptionThrown, true);
        }
        
        Test.stopTest();
        
        
        
	}

}