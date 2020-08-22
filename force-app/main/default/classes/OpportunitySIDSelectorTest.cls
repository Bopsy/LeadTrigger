@istest
public class OpportunitySIDSelectorTest {

	static testMethod void shortCodeSelecorTest() {
        Account acc = new Account(name = 'testAcc');
        insert acc;
        
        Opportunity oppty = new Opportunity(Account = acc, name = 'testOpp', stagename = 'Incubate', closeDate = Date.today());
        insert oppty;
        
        Account_SID__c sid = new Account_SID__c(name ='testsid');
        insert sid;
        
        List<Account_SID__c> sidList = OpportunitySIDSelectorController.getAccountSIDList(sid.name, Oppty.ID);
        
        
        OpportunitySIDSelectorController.linksid(sid, Oppty.ID);
        List<Opp_SID_SKU__c> skus = OpportunitySIDSelectorController.getExistAccountSIDList(Oppty.ID);
        System.assert(skus.size()==1);
        
        OpportunitySIDSelectorController.checkAccount(sid.ID, Oppty.ID);
    }
}