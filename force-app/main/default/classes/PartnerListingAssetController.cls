public class PartnerListingAssetController {
    
    @AuraEnabled
    public static List<Partner_Listing_Asset__c> getAssets(String type, Id partnerListingId){
        return [SELECT Caption__c,Display_Order__c,Id,LastModifiedById,LastModifiedDate,Name,Partner_Listing__c,RecordTypeId FROM Partner_Listing_Asset__c where Partner_Listing__c =:partnerListingId and recordTypeId in (SELECT Id FROM RecordType where developerName=:type)];
    }
    
     @AuraEnabled
    public static Id getRecordType(String type){
         return [SELECT Id FROM RecordType where developerName=:type][0].id;       
    }
    @AuraEnabled
    public static Partner_Listing_Asset__c createAsset(Partner_Listing_Asset__c asset){
        insert asset;
        return asset;
    }
    
    
    @AuraEnabled
    public static void deleteAsset(Partner_Listing_Asset__c asset){
        delete asset;
        
    }
    
    
    @AuraEnabled
    public static Id saveFile(Id parentId, String fileName, String base64Data, String contentType, String title) {         
        return saveFile(parentId, fileName, base64Data, contentType, NULL, title);
    }
    
    @AuraEnabled
    public static Id saveFile(Id parentId, String fileName, String base64Data, String contentType, Id contentDocumentId, String title) { 
        
        delete [
            SELECT Id 
            FROM  ContentDocumentLink 
            WHERE LinkedEntityId =: parentId 
            AND ContentDocument.Title =: title
        ];
        
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.ContentDocumentId = contentDocumentId;
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        cv.Title = title;
        cv.PathOnClient = filename;  
        
        insert cv;              
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = parentId;
        cdl.Visibility = 'AllUsers';
        cdl.ShareType = 'I';
        insert cdl;     
        
        return cv.Id;
    }
    
    @AuraEnabled
    public static ContentVersion getContent(Id assetId) {
        Id contentId =null;
        List<ContentDocumentLink> lLink =  [SELECT ContentDocumentId FROM ContentDocumentLink where LinkedEntityId=:assetId];
        System.debug('lLink-->'+lLink);
        if(lLink != null && lLink.size() > 0){
            contentId = lLink[0].ContentDocumentId;
           System.debug('contentId-->'+contentId);
            List<ContentVersion> lCv=  [SELECT Id,Title FROM ContentVersion WHERE ContentDocumentId = :contentId];
            if(lCv.size() > 0){
                 System.debug('lCv-->'+lCv[0]);
                return lCv[0];
            } 
        }
        return null;
    }
}