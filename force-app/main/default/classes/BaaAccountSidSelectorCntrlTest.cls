/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           BaaAccountSidSelectorCntrlTest
*
* @description    Test class for BaaAccountSidSelectorCntrl
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2020-03-31
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
@isTest
private class BaaAccountSidSelectorCntrlTest {
    static Opportunity testOpp;
    static Account testAcc;
    static Apttus__APTS_Agreement__c testAgreement;
    static List<Account_SID__c> testSidList;
    static List<Opp_SID_SKU__c> testSkuList;

    static void setupTestRecords() {
        Account testAcc= new Account(Name = 'TestAcct');
        insert testAcc;
        Profiles_link_trial_account__c setting = new Profiles_link_trial_account__c();
        setting.name='System Administrator';
        insert setting;

        testOpp = new Opportunity(
            Name = 'TestOpp',
            AccountId = testAcc.Id,
            CloseDate = Date.today(),
            StageName = 'Pilot',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi'
        );
        insert testOpp;

        testAgreement = new Apttus__APTS_Agreement__c(
            Related_Opportunity_APTS__c = testOpp.Id,
            Apttus__Account__c = testAcc.Id
        );
        insert testAgreement;
        
        testSidList = new List<Account_SID__c>();
        for (Integer i = 0; i<20; i++) {
            testSidList.add(new Account_SID__c(
                Name = 'TESTACCOUNTSID' + i,
                Account_SID__c = 'TESTACCOUNTSID' + i,
                Account_SID_Status__c = 'ACTIVE',
                Account__c = testAcc.Id,
                Account_SID_Created_Date__c = Date.today()
            ));
        }
        insert testSidList;
    }
    
    static testMethod void noAgreementGivenException() {
        setupTestRecords();
        BaaAccountSidSelectorCntrl obj = new BaaAccountSidSelectorCntrl();
    }

    static testMethod void initialPage() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('id', testAgreement.Id);
        BaaAccountSidSelectorCntrl obj = new BaaAccountSidSelectorCntrl();
        system.assert(obj.agreement!=null);
        system.assert(obj.acntId!=null);
    }
    
    static testMethod void searchPage() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('id', testAgreement.Id);
        BaaAccountSidSelectorCntrl obj = new BaaAccountSidSelectorCntrl();
        obj.runSearch();
        system.assertEquals(20, obj.searchResults.size());
    }
    
    static testMethod void linkAdditionalAccountSID() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('id', testAgreement.Id);
        BaaAccountSidSelectorCntrl obj = new BaaAccountSidSelectorCntrl();
        obj.recordId = testSidList[0].Id;
        obj.accountSID = testSidList[0].Account_SID__c;
        obj.link();
        system.assertEquals(1, obj.existingAgreementSkus.size());

        Agreement_SID__c agreementSID =  [ SELECT Id FROM Agreement_SID__c LIMIT 1 ];       
        obj.recordId = agreementSID.Id;
        obj.unlink();
        system.assertEquals(0, obj.existingAgreementSkus.size());
    }
}