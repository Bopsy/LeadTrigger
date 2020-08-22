public without sharing class QuotePricingController {
    public static Id quoteId {get; set;}
    public static Id agreementId {get; set;}
    
    public QuotePricingController(){
        
    }
    
    public PageReference updatePricing(){
        quoteId = ApexPages.currentPage().getParameters().get('quoteId');
        agreementId = ApexPages.currentPage().getParameters().get('agreementId');
        AgreementLineItemServices.updateQuotePricing(quoteId, agreementId);
        return new PageReference('/' + agreementId);
    }
    
    public PageReference cancel(){
        quoteId = ApexPages.currentPage().getParameters().get('quoteId');
        return new PageReference('/' + quoteId);
    }
}