@isTest
private class TriggerUtilTest {
    static testMethod void TestLeadSetError() {
       List<Lead> leads = new List<Lead>();
       leads.add(new Lead(LastName='Test', Company='TestCompany'));
       insert leads;
       TriggerUtil.setLeadError(leads, 'This is a test message');
    }
}