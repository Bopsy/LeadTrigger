@isTest
public class SendGridConcessionRequestHandlerTest {
    private static testMethod void testSyncStamp() {
        insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
        Account acc = APTS_CPQTestUtility.createAccount('Test Account','Prospect');
        insert acc;
        Contact con = APTS_CPQTestUtility.createContact('Test Contact', acc.Id);
        insert con;
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Incubate');
        insert opp;
        Apttus_Config2__PriceList__c priceList = APTS_CPQTestUtility.createPriceList('Test PriceList', true);
        insert priceList;
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Related_Opportunity_APTS__c = opp.Id, Apttus__Account__c = acc.Id, Apttus_QPComply__RelatedProposalId__c = proposal.Id);
        insert agreement; 
        
        Test.StartTest();
        SendGrid_Concession_Request__c scr = new SendGrid_Concession_Request__c (Account__c = acc.Id, Agreement__c = agreement.Id, Approval_Status__c = 'Pending', Concession_Type__c = 'Payment Terms / Payment Method / Pre-Payment');
        insert scr;
        Apttus__APTS_Agreement__c agr = [SELECT ID,SendGrid_Concession_Approval_Status__c, SendGrid_Concession_Approval_Date_Time__c FROM Apttus__APTS_Agreement__c WHERE ID = :agreement.Id LIMIT 1];
        System.debug('===> MIATEST: '+agr.SendGrid_Concession_Approval_Status__c);
        System.assertEquals(agr.SendGrid_Concession_Approval_Status__c, 'Pending');
        System.assert(agr.SendGrid_Concession_Approval_Date_Time__c == NULL);
        
        scr.Approval_Status__c = 'Approved';
        scr.Requested_Payment_Method__c = 'ACH';
        scr.Requested_Payment_Terms__c = 'Net 30';
        update scr;
        Apttus__APTS_Agreement__c agr2 = [SELECT ID,SendGrid_Concession_Payment_Method__c,SendGrid_Concession_Payment_Terms__c,SendGrid_Concession_Approval_Status__c, SendGrid_Concession_Approval_Date_Time__c FROM Apttus__APTS_Agreement__c WHERE ID = :agreement.Id LIMIT 1];
        System.assertEquals(agr2.SendGrid_Concession_Approval_Status__c, 'Approved');
        System.assertEquals(agr2.SendGrid_Concession_Payment_Terms__c, 'Net 30');
        System.assertEquals(agr2.SendGrid_Concession_Payment_Method__c, 'ACH');
        System.assert(agr2.SendGrid_Concession_Approval_Date_Time__c!=NULL);

        
        delete scr;
        Apttus__APTS_Agreement__c agr3 = [SELECT ID,SendGrid_Concession_Approval_Status__c, SendGrid_Concession_Approval_Date_Time__c FROM Apttus__APTS_Agreement__c WHERE ID = :agreement.Id LIMIT 1];
        System.assertEquals(agr3.SendGrid_Concession_Approval_Status__c, NULL);
        System.assertEquals(agr3.SendGrid_Concession_Approval_Date_Time__c, NULL);
        
        Test.stopTest();
        
    }
    
    private static testMethod void testMassSyncStamp() {
        insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
        Account acc = APTS_CPQTestUtility.createAccount('Test Account','Prospect');
        insert acc;
        
        Contact con = APTS_CPQTestUtility.createContact('Test Contact', acc.Id);
        insert con;
        
        Opportunity opp = APTS_CPQTestUtility.createOpportunity('Test Opportunity', 'New Customer', acc.Id, 'Incubate');
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APTS_CPQTestUtility.createPriceList('Test PriceList', true);
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposal = APTS_CPQTestUtility.createProposal('Test Quote', acc.Id, opp.Id, 'Proposal', priceList.Id);
        insert proposal;
        
        List<Apttus__APTS_Agreement__c> agreementLst = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Related_Opportunity_APTS__c = opp.Id, Apttus__Account__c = acc.Id, Apttus_QPComply__RelatedProposalId__c = proposal.Id);
        insert agreement; 
        //100 agreements mass insert
        //update 100 scr
        //insert 100 scr
    	Test.StartTest();
        List<SendGrid_Concession_Request__c> scrlst = new List<SendGrid_Concession_Request__c>();
        for(integer i = 0; i<10; i++){
        	SendGrid_Concession_Request__c scr = new SendGrid_Concession_Request__c (Account__c = acc.Id, Requested_Payment_Method__c = 'ACH',
                 																	 Requested_Payment_Terms__c = 'Net 30',
                                                                                     Agreement__c = agreement.Id, 
                                                                                     Concession_Type__c = 'Payment Terms / Payment Method / Pre-Payment');
        	scrlst.add(scr);
        }
        insert scrlst;
    
    
    
    }

}