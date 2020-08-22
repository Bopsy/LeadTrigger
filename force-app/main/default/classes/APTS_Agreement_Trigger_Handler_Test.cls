/*************************************************************************************************
Class     :  APTS_Agreement_Trigger_Handler_Test.cls
Developer :  mmurphy@apttuscom
Created   :  December 07, 2015
Modified  :  December 09, 2015
Objective :  This class provides methods to test APTS_Agreement_Trigger_Handler.cls.
Pages     :  No Visualforce pages consume this class.
Test Class:  not applicable

*************************************************************************************************/

@isTest ( seealldata = false )
private with sharing class APTS_Agreement_Trigger_Handler_Test
{
    //  private variables declared in alphabetical order
    private static Account account = null;
    private static Apttus__APTS_Agreement__c agreement = null;
    private static List <Apttus__APTS_Agreement__c> agreements = new List <Apttus__APTS_Agreement__c> ();
    private static Attachment attachment = null;
    private static List <Attachment> attachments = new List <Attachment> ();
    private static final String NO_PDF_ERROR = 'There are no .PDF documents to activate!';
    private static Opportunity opportunity = null;

    //  private methods listed in alphabetical order
    @testSetup
    private static void setupTestData ()
    {
        try
        {	
            insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(), Opportunity_Validation_Bypass__c =false);
            account = APTS_Testing_Utility.instantiateAccount ();

            insert account;
            
            Product2 newProd = new Product2(Name = 'Forecast Lock');
        	insert newProd;

        	PriceBookEntry pbe = new PriceBookEntry(Product2Id = newProd.Id, PriceBook2Id = Test.getStandardPricebookId(), UnitPrice = 1.0);
        	insert pbe;

            opportunity = APTS_Testing_Utility.instantiateOpportunity (account.Id);

            insert opportunity;

            agreement = APTS_Testing_Utility.instantiateAgreement (opportunity.Id, 1);

            insert agreement;

            attachment = APTS_Testing_Utility.instantiateAttachment (agreement.Id, 'Acrobat');

            attachments.add (attachment);

            attachment = APTS_Testing_Utility.instantiateAttachment (agreement.Id, 'Word');

            attachments.add (attachment);

            insert attachments;

        }   //  try

        catch ( Exception e )
        {
            System.assertEquals (null, e.getMessage ());
      
        }   //  catch

    }   //  setupTestData ()

    private static testMethod void testActivatingSignedPdfAgreement ()
    {
        System.Test.startTest ();

            agreements = [ select apttus__status_category__c
                                , apttus__status__c
                                , id
                             from apttus__apts_agreement__c
                         ];

            System.assertEquals (1, agreements.size ());

            agreements [0].Apttus__Status_Category__c = 'In Signatures';
            agreements [0].Apttus__Status__c          = 'Fully Signed';

            update agreements [0];

        System.Test.stopTest ();

        agreements = [ select apttus__status_category__c
                            , apttus__status__c
                            , id
                         from apttus__apts_agreement__c
                     ];

        //System.assertEquals ('Activated', agreements [0].Apttus__Status__c);

    }   //  testActivatingSignedPdfAgreement ()

    private static testMethod void testActivatingSignedWordAgreement ()
    {
        System.Test.startTest ();

            opportunity = [ select id from opportunity ];
            agreement   = APTS_Testing_Utility.instantiateAgreement (opportunity.Id, 1);

            insert agreement;

            attachment = APTS_Testing_Utility.instantiateAttachment (agreement.Id, 'Word');

            insert attachment;

            agreement.Apttus__Status_Category__c = 'In Signatures';
            agreement.Apttus__Status__c          = 'Fully Signed';

            try
            {
                update agreement;

            }   //  try

            catch ( Exception e )
            {
                System.assert (e.getMessage ().containsIgnoreCase (NO_PDF_ERROR));

            }   //  catch

        System.Test.stopTest ();

        //System.assertEquals ('Fully Signed', agreement.Apttus__Status__c);

    }   //  testSignedAgreement ()
    
    private static testMethod void testAgreementOpptyMapping_postive() {
        
		
        Account acc = new Account(name = 'bean bag Test');
        insert acc;
        Opportunity opp = new Opportunity(name = 'bean bag OPP1', 
                                          stagename = 'Incubate',recordTypeID = '012400000009mZ9AAI',
                                          AccountID = acc.ID, CloseDate=Date.today()+100);
        insert opp;
        
        Apttus__APTS_Agreement__c agreement = APTS_Testing_Utility.instantiateAgreement (opp.Id, 1);
        agreement.recordTypeID = '01240000000Yc7PAAS';
        agreement.Related_Opportunity_APTS__c = opp.ID;
        agreement.Apttus__Account__c = acc.ID;
        insert agreement;
        
        agreement.Commit_Frequency__c = 'Monthly';
        agreement.Payment_Type__c  = 'Invoice';
        agreement.Prepay_Frequency__c = 'One-time';
        agreement.Renewal_Term_Range__c = '12';
        agreement.Term_Range__c = '12';
        agreement.Total_Committed_Revenue_Input__c = 999.00;
        agreement.Prepayment_Amount_Input__c = 99;
        Test.startTest();
        update agreement;
        
        Opportunity oppty = [SELECT ID, Contract_Terms_Months__c ,Total_Committed_Revenue__c, Contract_Type__c 
                             FROM opportunity Where ID =: opp.ID];
        System.debug('This is the Oppty --> ' + oppty);
        //System.assert(oppty.Contract_Terms_Months__c == 12);
        //System.assert(oppty.Total_Committed_Revenue__c == 999.00);
        //System.assert(oppty.Contract_Type__c == 'Contract - Commit - Monthly - Invoice');
        Test.stopTest();
	}
    
    private static testMethod void testAgreementOpptyMapping_negative() {
        
		
        Account acc = new Account(name = 'bean bag Test');
        insert acc;
        Opportunity opp = new Opportunity(name = 'bean bag OPP1', 
                                          stagename = 'Incubate',recordTypeID = '01240000000QKKJ',
                                          AccountID = acc.ID, CloseDate=Date.today()+100);
        insert opp;

        Apttus__APTS_Agreement__c agreement = APTS_Testing_Utility.instantiateAgreement (opp.Id, 1);
        agreement.recordTypeID = '01240000000Yc7PAAS';
        agreement.Related_Opportunity_APTS__c = opp.ID;
        agreement.Apttus__Account__c = acc.ID;
        insert agreement;
        
        agreement.Commit_Frequency__c = 'Monthly';
        agreement.Payment_Type__c  = 'Invoice';
        agreement.Prepay_Frequency__c = 'One-time';
        agreement.Renewal_Term_Range__c = '12';
        agreement.Term_Range__c = '30';
        agreement.Total_Committed_Revenue_Input__c = 999.00;
        agreement.Prepayment_Amount_Input__c = 99;
        Test.startTest();
        update agreement;
        
        Opportunity oppty = [SELECT ID, Contract_Terms_Months__c ,Total_Committed_Revenue__c, Contract_Type__c 
                             FROM opportunity Where ID =: opp.ID];
        System.assert(oppty.Contract_Terms_Months__c != 30);
        System.assert(oppty.Total_Committed_Revenue__c != 999.00);
        System.assert(oppty.Contract_Type__c != 'Contract - Commit - Monthly - Invoice');
        Test.stopTest();
	}

	
 
}