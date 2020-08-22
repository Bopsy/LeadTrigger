/*************************************************************************************************
Class     :  APTS_Testing_Utility.cls
Developer :  mmurphy@apttuscom
Created   :  December 07, 2015
Modified  :
Objective :  This class provides methods to service other test classes.
Pages     :  No Visualforce pages consume this class.
Test Class:  not applicable

*************************************************************************************************/

@isTest ( seealldata = false )
public with sharing class APTS_Testing_Utility
{
    //  public constants declared in alphabetical order
    public static final Id MASTER_SERVICE_AGREEMENT_RECORDTYPE_ID =
            [ select id from recordtype
               where developername = 'Master_Sales_Agreement'
                 and sobjecttype   = 'Apttus__APTS_Agreement__c'
            ].Id;

    public static final Id NEW_BUSINESS_OPPORTUNITY_RECORDTYPE_ID =
            [ select id from recordtype
               where developername = 'Outbound_Opportunity'
                 and sobjecttype   = 'Opportunity'
            ].Id;

    public static final String ACROBAT_FORMAT = 'application/pdf';
    public static final String WORD_FORMAT    = 'application/vnd.openxmlformats-'
                                              + 'officedocument.wordprocessingml.document';

    //  public methods listed in alphabetical order
    public static Account instantiateAccount ()
    {
        //  variables declared in alphabetical order
        Account account = new Account
        (   //  fields set in alphabetical order
            BillingCity       = 'Boulder'
        ,   BillingCountry    = 'United States'
        ,   BillingPostalCode = '80302'
        ,   BillingState      = 'Colorado'
        ,   BillingStreet     = '1600 Canyon Blvd'
        ,   Name              = 'Test Account'

        );

        return account;

    }   //  instantiateAccount ()

    public static Apttus__APTS_Agreement__c instantiateAgreement
    ( Id opportunityId
    , Integer suffix
    )
    {
        //  variables declared in alphabetical order
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c
        (   //  fields set in alphabetical order
            Apttus__Contract_End_Date__c   = Date.today ().addDays (735)
        ,   Apttus__Contract_Start_Date__c = Date.today ().addDays (6)
        ,   Apttus__Related_Opportunity__c = opportunityId
        ,   Name                           = 'Test Agreement ' + suffix
        ,   RecordTypeId                   = MASTER_SERVICE_AGREEMENT_RECORDTYPE_ID

        );

        return agreement;

    }   //  instantiateAgreement ()

    public static List <Apttus__APTS_Agreement__c> instantiateAgreements
    ( Id opportunityId
    , Integer count
    )
    {
        //  variables declared in alphabetical order
        List <Apttus__APTS_Agreement__c> agreements = new List <Apttus__APTS_Agreement__c> ();

        if ( count > 200 ) count = 200;

        for ( Integer suffix = 0 ; suffix < count ; suffix ++ )
            agreements.add (instantiateAgreement (opportunityId, suffix));

        return agreements;

    }   //  instantiateAgreements ()

    public static Attachment instantiateAttachment
    ( Id     agreementId
    , String fileType
    )
    {
        //  variables declared in alphabetical order
        Attachment attachment  = null;
        String     contentType = null;
        String     fileName    = null;

        if ( fileType.equalsIgnoreCase ('Acrobat') )
        {
            contentType = ACROBAT_FORMAT;
            fileName    = 'This is a signed Acrobat document.';

        }

        else
        {
            contentType = WORD_FORMAT;
            fileName    = 'This is a Word document.';

        }   //  attachment is an Adobe Acrobat file

        attachment = new Attachment
        (   //  fields set in alphabetical order
            Body        = Blob.valueOf ('This is only a test.')
        ,   ContentType = contentType
        ,   Name        = fileName
        ,   ParentId    = agreementId

        );

        return attachment;

    }   //  instantiateAttachment ()

    public static List <Attachment> instantiateAttachments
    ( List <Apttus__APTS_Agreement__c> agreements )
    {
        //  variables declared in alphabetical order
        List <Attachment> attachments = new List <Attachment> ();

        for ( Apttus__APTS_Agreement__c agreement : agreements )
        {
            attachments.add (instantiateAttachment (agreement.Id, 'Acrobat'));
            attachments.add (instantiateAttachment (agreement.Id, 'Word'));

        }   //  each agreement in list

        return attachments;

    }   //  instantiateAttachments ()

    public static Opportunity instantiateOpportunity
    ( Id accountId )
    {
        //  variables declared in alphabetical order
        Opportunity opportunity = new Opportunity
        (   //  fields set in alphabetical order

            AccountId      = accountId
        ,   Amount         = 1500.75
        ,   CloseDate      = Date.today ().addDays (45)
        ,   Launch_Date__c = Date.today ().addDays (61)
        ,   Name           = 'Test Opportunity'
        ,   RecordTypeId   = NEW_BUSINESS_OPPORTUNITY_RECORDTYPE_ID
        ,   StageName      = 'Scope'

        );

        return opportunity;

    }   //  instantiateOpportunity ()

}