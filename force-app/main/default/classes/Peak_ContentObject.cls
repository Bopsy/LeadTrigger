public virtual with sharing class Peak_ContentObject {
    @AuraEnabled public Id contentID{get;set;}
    @AuraEnabled public String title{get;set;}
    @AuraEnabled public String description{get;set;}
    @AuraEnabled public String fullDescription{get;set;}
    @AuraEnabled public List<Attachment> attachments{get;set;}
    @AuraEnabled public String url{get;set;}
    @AuraEnabled public Boolean featured{get;set;}
    @AuraEnabled public String bannerImage{get;set;}
    @AuraEnabled public String avatar{get;set;}
    @AuraEnabled public Integer commentCount {get; set;}
    @AuraEnabled public String commentUrl {get; set;}
    @AuraEnabled public DateTime dateTimeField {get; set;}
    @AuraEnabled public Date dateField {get; set;}
}