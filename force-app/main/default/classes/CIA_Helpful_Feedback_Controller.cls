/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CIA_Helpful_Feedback_Controller
*
* @description 	  Controller class for the CIA_Helpful_Feedback.vfp
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-08-07
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public without sharing class CIA_Helpful_Feedback_Controller {
    
    public CTA_Digest__c currentRecord{ get; set; }
    
    public String additionalFeedback{ get; set; }
    
    public CIA_Helpful_Feedback_Controller(ApexPages.StandardController stdController){
        currentRecord = [SELECT Id FROM CTA_Digest__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }
    
    public void onLoad(){
        String isHelpful = '';
        isHelpful = ApexPages.currentPage().getParameters().get('isHelpful');
        if(isHelpful != ''){
        	currentRecord.Was_This_Digest_Helpful__c = isHelpful;
            update currentRecord;
        }
    }
    
    public PageReference submit(){
        currentRecord.Additional_Feedback__c = additionalFeedback;
        update currentRecord;
        
        PageReference pageRef = new PageReference(System.URL.getOrgDomainUrl().toExternalForm());
        return pageRef;
    }
}