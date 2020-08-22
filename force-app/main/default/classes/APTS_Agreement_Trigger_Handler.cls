/*************************************************************************************************
Class     :  APTS_Agreement_Trigger_Handler.cls
Developer :  mmurphy@apttuscom
Created   :  December 04, 2015
Modified  :  feb 27, 2020
Objective :  This class provides methods to service collections of agreeement records.
Pages     :  No Visualforce pages consume this class.
Test Class:  APTS_Agreement_Trigger_Handler_Test.cls

*************************************************************************************************/

public without sharing class APTS_Agreement_Trigger_Handler
{
    //  private constants declared in alphabetical order
    private static final Id AGREEMENTS_FOLDER_ID = [ select id from contentworkspace where name = 'Agreements'].Id;
    private static final Id AGREEMENTS_RECORDTYPE_ID = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName ().get ('Agreements').getRecordTypeId ();
    private static final Id ORDER_FORM_RECORDTYPE_ID = [SELECT Id FROM RecordType WHERE DeveloperName = 'Order_Form' LIMIT 1].Id;
    private static final String DOC_1_TYPE  = 'application/msword';
    private static final String DOC_2_TYPE  = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    private static final String PDF         = 'PDF';
    private static final String PDF_1_TYPE  = 'application/pdf';
    private static final String PDF_2_TYPE  = '.pdf';
    private static final String SIGNED      = 'signed';

    //  private properties declared in alphabetical order
    private static Id orgWideEmailAddressId
    {
        get
        {        
            return [ select id from orgwideemailaddress
                      where displayname = 'donotreply@twilio.com'
                   ].Id;

        }

    }   //  orgWideEmailAddressId

    private static Set <Id> processedAgreementIdSet = new Set <Id> ();

    //  public inner classes declared in alphabetical order
    public class AgreementException extends Exception
    {


    }   //  AgreementException {}

    //  public methods listed in alphabetical order
    public static void processAfterUpdate
    ( Map <Id, Apttus__APTS_Agreement__c> oldAgreementMap
    , Map <Id, Apttus__APTS_Agreement__c> newAgreementMap
    )
    {
        try
        {
            activateAgreements (oldAgreementMap, newAgreementMap);

        }   //  try

        catch ( AgreementException ae )
        {
            addError (newAgreementMap.values () [0], ae.getMessage ());

        }

        catch ( Exception e )
        {
            addError ( newAgreementMap.values () [0]
                     , e.getMessage () + '; ' + e.getStackTraceString ());

        }   //  catch

    }   //  processAfterUpdate ()

    //  private methods listed in alphabetical order
    private static void addError
    ( Apttus__APTS_Agreement__c agreement
    , String errorMessage
    )
    {
        if ( ! System.Test.isRunningTest () )
            agreement.addError (errorMessage);         

        System.debug (Logginglevel.ERROR, errorMessage);

    }   //  addError ()

    private static void activateAgreements
    ( Map <Id, Apttus__APTS_Agreement__c> oldAgreementMap
    , Map <Id, Apttus__APTS_Agreement__c> newAgreementMap
    )
    {
        //  variables declared in alphabetical order
        Set <Id> agreementIdSet = new Set <Id> ();
        List <Apttus__APTS_Agreement__c> agreements = new List <Apttus__APTS_Agreement__c> ();
        Map <Id, Attachment> attachmentPdfMap = new Map <Id, Attachment> ();
        List <Id> attachmentsToBeRemoved = new List <Id> ();
        List <Id> attachmentsToBeSelected = new List <Id> ();
        Map <Id, Blob> attachmentToBodyMap = null;
        ContentVersion contentVersion = null;
        List <ContentVersion> contentVersions = new List <ContentVersion> ();
        List <Apttus__APTS_Agreement__c> failedAgreements = new List <Apttus__APTS_Agreement__c> ();
        Apttus__APTS_Agreement__c newAgreement = null;
        Apttus__APTS_Agreement__c oldAgreement = null;

        for ( Id newAgreementId : newAgreementMap.keySet () )
        {
            if ( processedAgreementIdSet.contains (newAgreementId) )
                continue;

            if ( ! System.Test.isRunningTest () )
            {
                System.debug (Logginglevel.INFO, 'newAgreementId:  ' + newAgreementId);

            }   //  not in test mode

            if ( oldAgreementMap.containsKey (newAgreementId) )
            {
                newAgreement = newAgreementMap.get (newAgreementId);
                oldAgreement = oldAgreementMap.get (newAgreementId);

                if ( oldAgreement.Apttus__Status__c != newAgreement.Apttus__Status__c
                &&   newAgreement.Apttus__Status__c == 'Fully Signed'
                   )
                {
                    agreementIdSet.add (newAgreementId);

                    break;

                }   //  process only one agreement record

            }   //  agreement is updated

            processedAgreementIdSet.add (newAgreementId);

        }   //  each key in set

        System.debug (Logginglevel.INFO, 'agreementIdSet:  ' + agreementIdSet);

        if ( ! agreementIdSet.isEmpty () )
        {
            agreements = getAgreements (agreementIdSet);
            attachmentToBodyMap = getAttachmentToBodyMap (agreementIdSet);

            for ( Apttus__APTS_Agreement__c agreement : agreements )
            {
                for ( Attachment attachment : agreement.Attachments )
                {
                    if (   attachment.Name.containsIgnoreCase (SIGNED)
                    &&   ( attachment.ContentType == PDF_1_TYPE
                    ||     attachment.ContentType == PDF_2_TYPE
                         )
                       )
                    {
                        //  this is the attachment to publish to content
                        attachmentPdfMap.put (attachment.ParentId, attachment);

                        contentVersion = new ContentVersion
                        ( 
                            Agreement__c           = attachment.ParentId
                        ,   Description            = 'Created from attachment (' + attachment.Name  + ')'
                        ,   FirstPublishLocationId = AGREEMENTS_FOLDER_ID
                        ,   OwnerId                = UserInfo.getUserId ()
                        ,   PathOnClient           = attachment.Name
                        ,   RecordTypeId           = AGREEMENTS_RECORDTYPE_ID
                        ,   TagCsv                 = attachment.Name + ', ' + agreement.Apttus__FF_Agreement_Number__c
                        ,   Title                  = attachment.Name
                        ,   VersionData            = attachmentToBodyMap.get (attachment.Id)

                        );

                        contentVersions.add (contentVersion);

                        break;

                    }   //  attachment is the latest Acrobat file

                }   //  each attachment in list

                if ( ! attachmentPdfMap.isEmpty () )
                {
                    attachmentsToBeSelected.add (attachmentPdfMap.get (agreement.Id).Id);

                    Apttus.AgreementWebService.activateAgreement (agreement.Id, attachmentsToBeSelected, attachmentsToBeRemoved);

                }

                else
                {
                    if ( Url.getCurrentRequestUrl().toExternalForm ().contains ('a1v') )
                        throw (new AgreementException ('There are no .PDF documents to activate!'));

                }   //  there exists an Acrobat document to activate  

            }   //  each agreement in list

        }   //  there exist agreements to activate

        System.debug (Logginglevel.INFO, 'contentVersions:  ' + contentVersions);

        if ( ! contentVersions.isEmpty () )
            insert contentVersions;

    }   //  activateAgreements ()

    private static List <Apttus__APTS_Agreement__c> getAgreements
    ( Set <Id> agreementIdSet )
    {
        //  variables declared in alphabetical order
        List <Apttus__APTS_Agreement__c> agreements = new List <Apttus__APTS_Agreement__c> ();

        agreements = [ select apttus__account__c
                            , apttus__ff_agreement_number__c
                            , apttus__status__c
                            , apttus__status_category__c
                            , id
                            , ownerid
                            , owner.email
                            , twilio_legal_contact__c
                            , twilio_legal_contact__r.email
                            , (   select contenttype
                                       , id
                                       , name
                                       , parentid
                                    from attachments
                                order by createddate desc 
                              )
                         from apttus__apts_agreement__c
                        where id in : agreementIdSet
                     ];

        return agreements;

    }   //  getAgreements ()

    private static Map <Id, Blob> getAttachmentToBodyMap
    ( Set <Id> agreementIdSet )
    {
        //  variables declared in alphabetical order
        List <Attachment> attachments = new List <Attachment> ();
        Map <Id, Blob>    attachmentToBodyMap = new Map <Id, Blob> ();

        attachments = [ select body
                             , id
                          from attachment
                         where parentid in : agreementIdSet
                      ];

        for ( Attachment attachment : attachments )
            attachmentToBodyMap.put (attachment.Id, attachment.Body);

        return attachmentToBodyMap;

    }   //  getAttachmentToBodyMap ()
    
    
    //Added by Amrutha - Update single BI tiers on agreement effective date or commit start date update
    public Static List<Single_BI_Tier__c> lstSingleTier = new List<Single_BI_Tier__c>();
    public Static Set<Id> setAgreementIds = new Set<Id>();
    
    public static void updateSingleBITiersOnInsert(List<Apttus__APTS_Agreement__c> lstAgreement){
        for(Apttus__APTS_Agreement__c objAgreement: lstAgreement){
            setAgreementIds.add(objAgreement.Id);
        }
        lstSingleTier = [Select Id,Last_Additional_Schedule__c,Flex_Tier_Duration__c,Discount_Rate_Start_Date__c,Discount_Rate_End_Date__c,Agreement__c,Product_Group__c 
                         From Single_BI_Tier__c Where Agreement__c In: setAgreementIds and Last_Additional_Schedule__c=false and Product_Group__c='Flex'];
        if(lstSingleTier.size()>0){
            SingleBITierTriggerHandler.updateFlexTierDuration(lstSingleTier,setAgreementIds,true);
        }
    }
    
    public static void updateSingleBITiersOnUpdate(List<Apttus__APTS_Agreement__c> lstAgreement,Map <Id,Apttus__APTS_Agreement__c> oldAgreementMap, Map <Id,Apttus__APTS_Agreement__c> newAgreementMap){
        for(Apttus__APTS_Agreement__c objAgreement: lstAgreement){
            if(oldAgreementMap.get(objAgreement.Id).Commit_Start_Month__c != newAgreementMap.get(objAgreement.Id).Commit_Start_Month__c || 
               oldAgreementMap.get(objAgreement.Id).APTS_Agreement_Effective_Date__c != newAgreementMap.get(objAgreement.Id).APTS_Agreement_Effective_Date__c ||
               oldAgreementMap.get(objAgreement.Id).Term_Range__c!= newAgreementMap.get(objAgreement.Id).Term_Range__c ||
               oldAgreementMap.get(objAgreement.Id).Commit_Frequency__c != newAgreementMap.get(objAgreement.Id).Commit_Frequency__c ||
               oldAgreementMap.get(objAgreement.Id).Apttus__Contract_End_Date__c != newAgreementMap.get(objAgreement.Id).Apttus__Contract_End_Date__c ||
               oldAgreementMap.get(objAgreement.Id).Apttus__Status__c != newAgreementMap.get(objAgreement.Id).Apttus__Status__c){
                setAgreementIds.add(objAgreement.Id);
            }
        }
        lstSingleTier = [Select Id,Last_Additional_Schedule__c,Flex_Tier_Duration__c,Discount_Rate_Start_Date__c,Discount_Rate_End_Date__c,Agreement__c,Product_Group__c 
                         From Single_BI_Tier__c Where Agreement__c In: setAgreementIds and Last_Additional_Schedule__c=false and Product_Group__c='Flex'];
        if(lstSingleTier.size()>0){
            SingleBITierTriggerHandler.updateFlexTierDuration(lstSingleTier,setAgreementIds,true);
        }
        
        Set<Id> setOppIds = new Set<Id>();
        List<Opportunity> lstUpdateOpp = new List<Opportunity>();
        List<Apttus__APTS_Agreement__c> lstAgree = new List<Apttus__APTS_Agreement__c>();
        
        for(Apttus__APTS_Agreement__c objAgreement: lstAgreement){
            if(objAgreement.APTS_Agreement_Effective_Date__c==null || objAgreement.Commit_Frequency__c=='No Commit - PAYG' || objAgreement.Commit_Frequency__c=='No Commit - POC' ||
               objAgreement.Apttus__Status__c!='Activated'){
                setOppIds.add(objAgreement.Related_Opportunity_APTS__c);
                lstAgree.add(objAgreement);
            }
        }
        Map<ID, Opportunity> mapOpp = new Map<ID, Opportunity>([SELECT Id,Software_Validation__c,Y1_Software_Committed_Bookings_Validated__c,
                                                                Y2_Software_Committed_Bookings_Validated__c ,Y3_Software_Committed_Bookings_Validated__c 
                                                                FROM Opportunity where id IN: setOppIds]);
        if(mapOpp.size()>0){
            for(Apttus__APTS_Agreement__c objAgreement: lstAgree){
                if(mapOpp.get(objAgreement.Related_Opportunity_APTS__c)!=null && 
                   (!lstUpdateOpp.contains(mapOpp.get(objAgreement.Related_Opportunity_APTS__c)))){
                    mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Y1_Software_Committed_Bookings_Validated__c=null;
                    mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Y2_Software_Committed_Bookings_Validated__c=null;
                    mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Y3_Software_Committed_Bookings_Validated__c=null;
                    mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Software_Validation__c = 'NA';
                    if(!lstUpdateOpp.contains(mapOpp.get(objAgreement.Related_Opportunity_APTS__c)))
                    lstUpdateOpp.add(mapOpp.get(objAgreement.Related_Opportunity_APTS__c));
                }
            }
            
            Database.update(lstUpdateOpp, false);
        }
    }
    
    //Added by Jason 2020-01-03
    public static void processAgreementActivation(List<Apttus__APTS_Agreement__c> lstAgreement, Map <Id,Apttus__APTS_Agreement__c> oldAgreementMap, Map <Id,Apttus__APTS_Agreement__c> newAgreementMap){
        List<Apttus__APTS_Agreement__c> agreementsForReview = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agrRec : lstAgreement){
            if(oldAgreementMap.get(agrRec.Id).Apttus__Status__c != 'Activated' && newAgreementMap.get(agrRec.Id).Apttus__Status__c == 'Activated'
               && agrRec.RecordTypeId == ORDER_FORM_RECORDTYPE_ID){
                   agreementsForReview.add(agrRec);
               }
        }                                
        
        if(!agreementsForReview.isEmpty()){
            CommitBookingHelper.getCommitBookings(agreementsForReview);
            SignalTicketHelper.createSignalTicketAttribution(agreementsForReview);
        }
    }


    //Added by Jason 2019-06-24
   /* public static void createCommitBookingsRecords(List<Apttus__APTS_Agreement__c> lstAgreement, Map <Id,Apttus__APTS_Agreement__c> oldAgreementMap, Map <Id,Apttus__APTS_Agreement__c> newAgreementMap){
        List<Apttus__APTS_Agreement__c> agreementsForReview = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agrRec : lstAgreement){
            
            if(oldAgreementMap.get(agrRec.Id).Apttus__Status__c != 'Activated' && newAgreementMap.get(agrRec.Id).Apttus__Status__c == 'Activated'){
                agreementsForReview.add(agrRec);
            }
        }                                 
        
        if(!agreementsForReview.isEmpty()){
            CommitBookingHelper.getCommitBookings(agreementsForReview);
        }
    }*/
    
    //built for tracking deals for customers driving COVID relief efforts. 
    //Logic is used to flag Contract Ops approval on the Agreement Attachment.
    public static void prepareQuoteData(List<Apttus__APTS_Agreement__c> lstAgreement,Map <Id,Apttus__APTS_Agreement__c> oldAgreementMap){
        List<Apttus__APTS_Agreement__c> agreementsForReview = new List<Apttus__APTS_Agreement__c>();
        Set<Id> quoteIds = new Set<Id>();
        for(Apttus__APTS_Agreement__c agrRec : lstAgreement){
            if(oldAgreementMap.get(agrRec.Id).Commit_Frequency__c != agrRec.Commit_Frequency__c  
               && agrRec.Commit_Frequency__c=='No Commit - PAYG'){
                agreementsForReview.add(agrRec);
                quoteIds.add(agrRec.Apttus_QPComply__RelatedProposalId__c);
            }
        }                                 
        
        if(!agreementsForReview.isEmpty()){
            getQuoteData(agreementsForReview,quoteIds);
        }
    }
    
    //built for tracking deals for customers driving COVID relief efforts. 
    //Logic is used to flag Contract Ops approval on the Agreement Attachment.
    public static void getQuoteData(List<Apttus__APTS_Agreement__c> lstAgreement,Set<Id> quoteIds){
        if(quoteIds!=null && quoteIds.size()>0){
        	Map<Id,Apttus_Proposal__Proposal__c> mapQuotes = new Map<Id,Apttus_Proposal__Proposal__c>(
                											 [Select Id,Applied_Commit_Discount__c, Total_Committed_Revenue__c, Commit_Frequency__c  from
                                                        	  Apttus_Proposal__Proposal__c where ID IN:quoteIds]);
            for(Apttus__APTS_Agreement__c objAgr: lstAgreement){
                objAgr.X6th_tier_discount_with_TCR_0__c = false;
                if(mapQuotes.get(objAgr.Apttus_QPComply__RelatedProposalId__c)!=null && mapQuotes.get(objAgr.Apttus_QPComply__RelatedProposalId__c).Applied_Commit_Discount__c==100000
                   && mapQuotes.get(objAgr.Apttus_QPComply__RelatedProposalId__c).Total_Committed_Revenue__c==0 
                   && objAgr.Commit_Frequency__c =='No Commit - PAYG'){
                       objAgr.X6th_tier_discount_with_TCR_0__c = true;
                   }
            }
            
        }
    }
    
     /*
     * add by Mia on 10/29
     * agreement -> Oppty field mapping function
     */
    public static void agreementOpptyMapping(List<Apttus__APTS_Agreement__c> agreementRec, 
                                             Map<id,Apttus__APTS_Agreement__c> oldAgreementRec) {
        
        //get mapping logic from metadata
        Agreement_to_Opp_Mapping__mdt[] mappingData = [ SELECT Filter_Type__c, Reference_Field__c,
                                                               Target_Field__c, Trigger_Field__c 
                                                        FROM Agreement_to_Opp_Mapping__mdt
                                                        WHERE Active__c = true
                                                        AND Filter_Type__c != NULL];
        if(mappingData == NULL || mappingData.isEmpty()) return;  
        
        //grouping mapping logic by filter_type
        //filter_type is align with formula field in agreement 
        Map<String, List<Agreement_to_Opp_Mapping__mdt>> groupMap = new Map<String, List<Agreement_to_Opp_Mapping__mdt>>();

        for(Agreement_to_Opp_Mapping__mdt aom: mappingData) {
            String groupTpye = aom.Filter_Type__c;
            if(groupTpye == NULL) continue;
            if(groupMap.get(groupTpye) == NULL) groupMap.put(groupTpye, new List<Agreement_to_Opp_Mapping__mdt>());
            groupMap.get(groupTpye).add(aom);
        }
        
        List<Apttus__APTS_Agreement__c> filterAgreement = filterHelper(agreementRec, oldAgreementRec, groupMap);
        if(filterAgreement.isEmpty()){
            system.debug('====>Mia log: no agreement need to map to oppty');
            return;
        }
                                                 
        
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        Set<Id> setOppIds = new Set<Id>();
        for(Apttus__APTS_Agreement__c agr: filterAgreement) {
            if(agr.Opportunity_Mapping_Filter__c == NULL) continue;
            
            //checking filter type
            List<Agreement_to_Opp_Mapping__mdt> mapping = groupMap.get(agr.Opportunity_Mapping_Filter__c);
            if(mapping == NULL) continue;//skip if agreement record does not have qualified mapping filter type

            //grab the parent oppotunity that we want to mapping data to
            Opportunity opp = new Opportunity(ID = agr.Related_Opportunity_APTS__c);
            
            //map data from agreement to oppty
            for(Agreement_to_Opp_Mapping__mdt AgrOppData : mapping) {
                //converterHelper: convert field type to align with field type on oppty
                if(AgrOppData.Trigger_Field__c != NULL && AgrOppData.Target_Field__c != NULL) {
                    object convertedField = converterHelper(agr.get(AgrOppData.Trigger_Field__c), String.valueof(Schema.SObjectType.Opportunity.fields.getMap().get(AgrOppData.Target_Field__c).getDescribe().getType()));
                    opp.put(AgrOppData.Target_Field__c, convertedField);
                }
            }
            //findContractType
            String contractType = freqTypeHelper(agr.Commit_Frequency__c, agr.Payment_Type__c);
            if(contractType != NULL) opp.Contract_Type__c = contractType;
            //opp.Contract_Type__c = contractType == null ? opp.Contract_Type__c : contractType;
            if(!setOppIds.contains(opp.id)){
                oppToUpdate.add(opp);
                setOppIds.add(opp.id);
            }
            
        }
        //bypass oppty validation rule
        if(Test.isRunningTest() && Validation_Bypass_Trigger__c.getOrgDefaults().Id == null){
            insert new Validation_Bypass_Trigger__c(SetupOwnerId=UserInfo.getOrganizationId(),Opportunity_Validation_Bypass__c =false);
        }
        
        Validation_Bypass_Trigger__c bypass = Validation_Bypass_Trigger__c.getOrgDefaults();
               
        //if(bypass == NULL) return;
        bypass.put('Opportunity_Validation_Bypass__c',true);
        update bypass;
            
        database.update(oppToUpdate,false);
                                                 
        bypass.put('Opportunity_Validation_Bypass__c',false);
        update bypass;
        
    }
    
    public static List<Apttus__APTS_Agreement__c> filterHelper(List<Apttus__APTS_Agreement__c> agreementRec, 
                                                               Map<id,Apttus__APTS_Agreement__c> oldAgreementRec, 
                                                               Map<String, List<Agreement_to_Opp_Mapping__mdt>> metaGroupMap) {
        
        List<Apttus__APTS_Agreement__c> filteredAgreement = new List<Apttus__APTS_Agreement__c>();
        
        for(Apttus__APTS_Agreement__c agr: agreementRec) {
            if(agr.Opportunity_Mapping_Filter__c == NULL) continue;
            
            List<Agreement_to_Opp_Mapping__mdt> mapping = metaGroupMap.get(agr.Opportunity_Mapping_Filter__c);
            if(mapping == NULL) continue;
            
            //Boolean isDifferent = false;
            for(Agreement_to_Opp_Mapping__mdt AgrOppData : mapping) {
                Apttus__APTS_Agreement__c oldAgr = oldAgreementRec.get(agr.Id);
                if(agr.get(AgrOppData.Trigger_Field__c) != oldAgr.get(AgrOppData.Trigger_Field__c)){
                    filteredAgreement.add(agr);
                    break;
                }
            }
            //if(isDifferent) filteredAgreement.add(agr);
        }
        return filteredAgreement;                                
                                        
    }
    
    /*
     * helper function for agreementOppMapping that map frequency and payment_type to contract_type
     * add by Mia on 10/29
	 */
    public static String freqTypeHelper(String frequency, String payment) {
        String  contractType = NULL;
        List<Contract_Type_Mapping__mdt> contratTypeMapping = [SELECT Commit_Freq__c, Contract_Type__c, Payment_Type__c 
                                                         	   FROM Contract_Type_Mapping__mdt];
        if(contratTypeMapping == NULL || contratTypeMapping.isEmpty()) return contractType;
        
        
        for(Contract_Type_Mapping__mdt mapping: contratTypeMapping) {
            if(frequency == mapping.Commit_Freq__c && payment == mapping.Payment_Type__c) {
                contractType = mapping.Contract_Type__c;
                break;
            }
        }

        return contractType;
    }
    
    /*
     * helper function for agreementOppMapping that convert field type
     * add by Mia on 10/29
	 */
    private static object converterHelper(object input, string fieldtype) {
        System.debug('Mia===>input:'+input+'  Mia===>type:'+fieldtype);
        if(fieldtype == 'Double') return Double.valueOf(input);
        if(fieldtype == 'String') return String.valueOf(input);
        if(fieldtype == 'Integer') return Integer.valueOf(input);
        return input;
    }
    
    public static void UpdateRelatedAccounts(List<Apttus__APTS_Agreement__c> theAggrmntList) {
        Id theBOBOId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('BOBO Addendum').getRecordTypeId();
        Id theInfluenceId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Influence Addendum').getRecordTypeId();
        Id theResellerId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Reseller Addendum').getRecordTypeId();
        Id theAddOnId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Add-On Addendum').getRecordTypeId();
        
        List<Id> theAccntUpdateListIds = new List<Id>();
        for(Apttus__APTS_Agreement__c theAgrmnt : theAggrmntList){
            if((theAgrmnt.RecordTypeId == theBOBOId || theAgrmnt.RecordTypeId == theInfluenceId ||
               theAgrmnt.RecordTypeId == theResellerId || theAgrmnt.RecordTypeId == theAddOnId) &&
               (theAgrmnt.Apttus__Status__c == 'Activated' || theAgrmnt.Apttus__Status__c == 'Fully Signed') && theAgrmnt.Apttus__Status_Category__c == 'In Effect') {
                   theAccntUpdateListIds.add(theAgrmnt.Apttus__Account__c);
               }
        }
        if(theAccntUpdateListIds.size() > 0){
            List<Account> theRelatedAccounts = [SELECT Id, Partner_Tier__c FROM Account WHERE Id IN: theAccntUpdateListIds];
            update theRelatedAccounts;
        } 
    }
}