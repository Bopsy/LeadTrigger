@isTest
private class BatchAssignAccountEmailSpecialistTest {

	private static testMethod void testConstructor() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        String ownerRole = [SELECT FY_16_Role_Team__c FROM Account LIMIT 1].FY_16_Role_Team__c;
        
        String userRoleName = [SELECT UserRole.Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1].UserRole.Name;
        
        Account_Quarterback_Routing__c newTestingRule = new Account_Quarterback_Routing__c(Sales_Team__c = ownerRole, SendGrid_User_Role__c = userRoleName, SendGrid_Assignment__c = true);
        
        insert newTestingRule;
        
        Test.startTest();
            Database.executeBatch(new BatchAssignAccountEmailSpecialist());
        Test.stopTest();	
	    
	}

}