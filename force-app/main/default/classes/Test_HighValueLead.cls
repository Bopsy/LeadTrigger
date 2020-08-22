/*
 * Class:   Test_HighValueLead
 * Purpose: Provide test coverage for the trigger SetHighValueLead
 */
@isTest
private class Test_HighValueLead {

    static testMethod void insertLowValueLead() {
        High_Value_Domain__c hvd = new High_Value_Domain__c();
        hvd.Name = 'mytestdomain.com';
        insert hvd;
        
        Test.startTest();
        
        Lead low = new Lead();
        low.LastName = 'Smith';
        low.Company = 'SmithCo';
        low.Email = 'joesmith@smithco.com';
        insert low;
        Lead lowQueried = [SELECT High_Value_Lead__c FROM Lead WHERE Id = :low.Id];
        System.assertEquals(false, lowQueried.High_Value_Lead__c);
        
        Lead noemail = new Lead();
        noemail.LastName = 'Smith';
        noemail.Company = 'SmithCo';
        insert noemail;
        Lead noemailQueried = [SELECT High_Value_Lead__c FROM Lead WHERE Id = :noemail.Id];
        System.assertEquals(false, noemailQueried.High_Value_Lead__c);
    }
    
    static testMethod void insertHighValueLead() {
        High_Value_Domain__c hvd = new High_Value_Domain__c();
        hvd.Name = 'mytestdomain.com';
        insert hvd;
        
        Test.startTest();
        
        Lead high = new Lead();
        high.LastName = 'Smith';
        high.Company = 'SmithCo';
        high.Email = 'joesmith@mytestdomain.com';
        insert high;
        
        Lead highQueried = [SELECT High_Value_Lead__c FROM Lead WHERE Id = :high.Id];
        System.assertEquals(true, highQueried.High_Value_Lead__c);
    }
    
    static testMethod void updateHighValueLead() {
        High_Value_Domain__c hvd = new High_Value_Domain__c();
        hvd.Name = 'mytestdomain.com';
        insert hvd;
        
        Lead high = new Lead();
        high.LastName = 'Smith';
        high.Company = 'SmithCo';
        high.Email = 'joesmith@smithco.com';
        insert high;
        
        Test.startTest();
        
        high.email = 'joesmith@mytestdomain.com';
        update high;
        
        Lead highQueried = [SELECT High_Value_Lead__c FROM Lead WHERE Id = :high.Id];
        System.assertEquals(true, highQueried.High_Value_Lead__c);
    }
    
    static testMethod void updateLowValueLead() {
        High_Value_Domain__c hvd = new High_Value_Domain__c();
        hvd.Name = 'mytestdomain.com';
        insert hvd;
        
        Lead low = new Lead();
        low.LastName = 'Smith';
        low.Company = 'SmithCo';
        low.Email = 'joesmith@mytestdomain.com';
        insert low;
        
        Lead noemail = new Lead();
        noemail.LastName = 'Smith';
        noemail.Company = 'SmithCo';
        insert noemail;
        
        Test.startTest();
        
        low.email = 'joesmith@smithco.com';
        update low;
        Lead lowQueried = [SELECT High_Value_Lead__c FROM Lead WHERE Id = :low.Id];
        System.assertEquals(false, lowQueried.High_Value_Lead__c);
        
        noemail.LastName = 'Smith2';
        update noemail;
        Lead noemailQueried = [SELECT High_Value_Lead__c FROM Lead WHERE Id = :noemail.Id];
        System.assertEquals(false, noemailQueried.High_Value_Lead__c);
    }
    
    static testMethod void insertLeads_Bulk() {
        List<High_Value_Domain__c> hvds = new List<High_Value_Domain__c>();
        hvds.add(new High_Value_Domain__c());
        hvds.get(0).Name = 'mytestdomain.com';
        insert hvds;
        
        Test.startTest();
        
        List<Lead> leads = new List<Lead>();
        for (Integer i=0; i<100; i++) {
        	Lead high = new Lead();
        	high.LastName = 'High';
	        high.Company = 'SmithCo'+i;
	        high.Email = 'joesmith'+i+'@mytestdomain.com';
	        leads.add(high);
	        
	        Lead low = new Lead();
	        low.LastName = 'Low';
	        low.Company = 'SmithCo'+i;
	        low.Email = 'joesmith'+i+'@smithco.com';
	        leads.add(low);
        }
		insert leads;
		
		List<Id> leadIds = new List<Id>();
		for (Lead l : leads) {
			leadIds.add(l.Id);
		}       
        
        List<Lead> leadsQueried = [SELECT LastName,High_Value_Lead__c FROM Lead WHERE Id IN :leadIds];
        for (Lead l : leadsQueried) {
        	System.assertEquals((l.LastName=='High'), l.High_Value_Lead__c);
        }
        
    }
    
}