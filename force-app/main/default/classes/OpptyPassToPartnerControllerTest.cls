@isTest
private class OpptyPassToPartnerControllerTest{
    @testSetup 
    static void setup() {
        // Create An Account
        Account acc = new Account(
            Name = 'TestOpptyPassTo'
        );
        insert acc;  
        //Create Partner Profile Record
         Company_Profile__c cp = new Company_Profile__c(
            Account__c = acc.id,
            Name = acc.Name
        );
        insert cp;
        
        Sobject listingRecordType = [Select Id ,DeveloperName FROM RecordType WHERE sobjecttype ='Partner_Listing__c' 
                                   and DeveloperName ='App_Listing'];

        //Insert Partner Listing Records
        Partner_Listing__c pListing = new Partner_Listing__c(
            Approved_For_Marketplace__c = true,
            Category__c = 'Analytics;Market Intelligence',
            Support_Email__c = 'twilio@test.com',
            Highlight_Text_1__c = 'Test text',
            Highlight_Text_2__c = 'Test text2',
            Highlight_Text_3__c = 'Test text3',
            Key_Search_Terms__c = 'Search Term',
            Highlight_Title_1__c = 'Test text',
            Highlight_Title_2__c = 'Test text 2',
            Highlight_Title_3__c = 'Test text 3',
            Partner_Profile__c = cp.Id,
            recordTypeId=listingRecordType.Id,
            PTP_Enabled__c = true
        );
        insert pListing;
        
    }
    
    static testMethod void  OpptyPassToPartnerController() {
        OpptyPassToPartnerController testOppPassController = new OpptyPassToPartnerController ();
        testOppPassController.clearSearchResults();
        List < Partner_Listing__c > pListingRecordList = [Select Id from Partner_Listing__c limit 1];
        Partner_Listing__c partnerListRecord = pListingRecordList[0];
        System.debug(' Test' + pListingRecordList.size());
        testOppPassController.searchResults =  pListingRecordList;
        testOppPassController.selectedPartnerListing = partnerListRecord;
        Account accountRec = [Select Id from Account Where Name = 'TestOpptyPassTo'];
        
        Contact contactRecord = new Contact();
        contactRecord.FirstName = 'Opp';
        contactRecord.LastName  = 'Test';
        contactRecord.AccountId = accountRec.id;
       
        insert contactRecord;
        
        testOppPassController.first();
        testOppPassController.last();
        testOppPassController.previous();
        testOppPassController.next();        
        testOppPassController.refresh();   
        testOppPassController.clearSearchResults();
        List<selectOption> partnerListingTypeOptionsList =  testOppPassController.partnerListingTypeOptions ;
        List<selectOption> productOptions =  testOppPassController.productOptions ;
        List<selectOption> partnerCategoryOptions =  testOppPassController.partnerCategoryOptions ;
        List<selectOption> regionsOptions =  testOppPassController.regionsOptions ;
        List<selectOption> marketSegmentOptions =  testOppPassController.marketSegmentOptions ;
        List<selectOption> solutionOptions =  testOppPassController.solutionOptions ;
        List<selectOption> IndistriesOptions =  testOppPassController.IndistriesOptions ;
        
        
        testOppPassController.selectItem();
        testOppPassController.toggleSort();
        testOppPassController.selectedListingType = '';
            
   testOppPassController.selectedPartnerCategory ='';
   testOppPassController.selectedProducts  ='';
   testOppPassController.selectedRegions  ='';
   testOppPassController.selectedMarketSegment  ='';
   testOppPassController.selectedSolutions  ='';
   testOppPassController.selectedIndistries  ='';
        
        
        String searchText = testOppPassController.searchText ;
        
        Opportunity testOpp = new Opportunity();
        testOpp.AccountId   = accountRec.Id;
        testOpp.Name        = 'TEST OPPORTUNITY';
        testOpp.CloseDate   = System.now().date();
        testOpp.StageName   ='Closed Won';
        try { 
            insert testOpp;
          } catch(DmlException ex) {
                System.Assert(ex.getMessage().contains('Insert Failed'), 'Insertion failed check validation rules'+ex);
          }
        
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = contactRecord.Id;
        ocr.OpportunityId = testOpp.Id;
        ocr.IsPrimary = TRUE;
        ocr.Role = 'Decision Maker';
        insert ocr;
                
        testOppPassController.save();
        Pass_to_Partner__c partnerPass = new Pass_to_Partner__c();
        partnerPass.Partner_Status__c = 'Open';
        partnerPass.Opportunity__c = testOpp.Id;
        insert partnerPass;
        testOppPassController.recordId = partnerListRecord.Id;
        Pagereference testPage1 =  Page.PassOpptyToPartner; 
        test.setCurrentPage(testPage1);
        testPage1.getParameters().put('id', testOpp.Id);
        
        testOppPassController = new OpptyPassToPartnerController ();
        testOppPassController.recordId = partnerListRecord.Id;
        testOppPassController.selectItem();
        testOppPassController.save();
        
        ApexPages.StandardController testOppExt = new ApexPages.StandardController(testOpp);
        OpptyPassToPartnerController opptyPartnerController = new OpptyPassToPartnerController (testOppExt);
        opptyPartnerController.save();
        Pagereference testPage =  Page.PassOpptyToPartner; 
        test.setCurrentPage(testPage);
        testPage.getParameters().put('Partner_Listing_Type__c', null);
        testPage.getParameters().put('Partner_Category__c', null);
        testPage.getParameters().put('products__c', null);
        testPage.getParameters().put('Regions__c', null);
        testPage.getParameters().put('Market_Segment__c', null);
        testPage.getParameters().put('Solutions__c', null);
        testPage.getParameters().put('Industries__c', null);
        testPage.getParameters().put('searchText', 'Test');
        testPage.getParameters().put('h', 'full');
        testPage.getParameters().put('s', '5');
        opptyPartnerController.selectItem();
        
        opptyPartnerController.selectedPartnerCategory ='';
   opptyPartnerController.selectedProducts  ='';
   opptyPartnerController.selectedRegions  ='';
   opptyPartnerController.selectedMarketSegment  ='';
   opptyPartnerController.selectedSolutions  ='';
   opptyPartnerController.selectedIndistries  ='';
        
        opptyPartnerController = new OpptyPassToPartnerController (testOppExt);
        
        testPage.getParameters().put('h', 'small');
        opptyPartnerController.selectItem();
        opptyPartnerController = new OpptyPassToPartnerController (testOppExt);
        
        opptyPartnerController.recordId = partnerListRecord.Id;
        List < SelectOption > opportunityContactOptionsList =  opptyPartnerController.opportunityContactOptions;
        Boolean test1 = opptyPartnerController.isLocked;
        opptyPartnerController.searchResults =  null;
        opptyPartnerController = new OpptyPassToPartnerController (testOppExt);
        
        opptyPartnerController.searchResults =  pListingRecordList;
        opptyPartnerController = new OpptyPassToPartnerController (testOppExt);
        
        Boolean testNext =  opptyPartnerController.hasNext;
        Boolean testPrev =  opptyPartnerController.hasPrevious;
        
        opptyPartnerController.selectedListingType = '';
            
       opptyPartnerController.selectedPartnerCategory ='test';
       opptyPartnerController.selectedProducts  ='Test';
       opptyPartnerController.selectedRegions  ='Test';
       opptyPartnerController.selectedMarketSegment  ='Test';
       opptyPartnerController.selectedSolutions  ='Test';
       opptyPartnerController.selectedIndistries  ='Test';
        opptyPartnerController = new OpptyPassToPartnerController (testOppExt);
        
    }

}