public without sharing class QuoteToAgreementController {
    
    public Quote aQuote {get; set;}
    
    public QuoteToAgreementController(ApexPages.StandardController stdCtrl){
        aQuote = (Quote) stdCtrl.getRecord();
    }
    
    public PageReference init(){
        QuoteService.createAgreementsFromQuotes(new List<Quote>{aQuote});
        Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c WHERE Quote__c =: aQuote.Id ORDER BY CreatedDate DESC LIMIT 1];
        PageReference ofPage = new ApexPages.StandardController(agreement).view();
        ofPage.setRedirect(true);
        return ofPage;
    }
}