@isTest
private class PartnerListingAssetController_Test {
    @testSetup 
    static void setup() {
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;  
        
        //Create Partner Profile Record
        Company_Profile__c cp = new Company_Profile__c();
        cp.Account__c = acc.id;
        cp.Name = acc.Name;
        insert cp;
         
         
         //Insert Partner Listing Records
         List < Partner_Listing__c > pListingRecordList = new List < Partner_Listing__c > ();
         Partner_Listing__c pListingRecord = new Partner_Listing__c();
        
        
            pListingRecord.Approved_For_Marketplace__c = true;
            pListingRecord.Category__c = 'Analytics;Market Intelligence';
            pListingRecord.Support_Email__c = 'twilio@test.com';
            pListingRecord.Highlight_Text_1__c = 'Test text';
            pListingRecord.Highlight_Text_2__c = 'Test text2';
            pListingRecord.Highlight_Text_3__c = 'Test text3';
            pListingRecord.Key_Search_Terms__c = 'Search Term';
            pListingRecord.Highlight_Title_1__c = 'Test text';
            pListingRecord.Highlight_Title_2__c = 'Test text 2';
            pListingRecord.Highlight_Title_3__c = 'Test text 3';
            pListingRecord.Partner_Profile__c = cp.Id;
            
        
            pListingRecordList.add ( pListingRecord );
            insert pListingRecord;
        // Add Partner Asset Records
        List < Partner_Listing_Asset__c>  partnerAssetList = new List < Partner_Listing_Asset__c>();
            Partner_Listing_Asset__c plAssetRecord = new Partner_Listing_Asset__c();
            plAssetRecord.Display_Name__c = 'Tile';
            plAssetRecord.Display_Order__c = 1;
            plAssetRecord.Partner_Listing__c = pListingRecord.Id;
            partnerAssetList.add ( plAssetRecord );
            
            Partner_Listing_Asset__c pAssetCarouselRecord = new Partner_Listing_Asset__c();
            Sobject assetRecordType = [Select Id ,DeveloperName FROM RecordType WHERE sobjecttype ='Partner_Listing_Asset__c' and Name =:PartnerLisitingDetailController.CAROUSEL];

            pAssetCarouselRecord.Display_Name__c = 'Carousel';
            pAssetCarouselRecord.Display_Order__c = 1;
            pAssetCarouselRecord.Partner_Listing__c = pListingRecord.Id;
            pAssetCarouselRecord.RecordTypeId = assetRecordType.Id;
            
            partnerAssetList.add ( pAssetCarouselRecord);
            insert partnerAssetList;
    }
    
    static testMethod void getPartnerListingDetailTest(){
        Test.startTest();
            Partner_Listing__c pListingRecord = [Select Id from Partner_Listing__c limit 1];
            List<Partner_Listing_Asset__c> partnerAssetList = PartnerListingAssetController.getAssets('Carousel',pListingRecord.Id);
            PartnerListingAssetController.getRecordType('Carousel');
            Partner_Listing_Asset__c pAssetCarouselRecord = new Partner_Listing_Asset__c();
            Sobject assetRecordType = [Select Id ,DeveloperName FROM RecordType WHERE sobjecttype ='Partner_Listing_Asset__c' and Name =:PartnerLisitingDetailController.CAROUSEL];

            pAssetCarouselRecord.Display_Name__c = 'Carousel';
            pAssetCarouselRecord.Display_Order__c = 1;
            pAssetCarouselRecord.Partner_Listing__c = pListingRecord.Id;
            pAssetCarouselRecord.RecordTypeId = assetRecordType.Id;
        
        PartnerListingAssetController.createAsset(pAssetCarouselRecord);
        PartnerListingAssetController.deleteAsset(pAssetCarouselRecord);
        PartnerListingAssetController.saveFile(''+partnerAssetList [0].Id, 'Preview', 'TestData', 'Image', 'New Pic');
        PartnerListingAssetController.getContent( partnerAssetList [0].Id);
        PartnerListingAssetController.getContent( pAssetCarouselRecord.Id);
        Test.stopTest();
        System.assertEquals(partnerAssetList.size(), 1);
    }
    
}