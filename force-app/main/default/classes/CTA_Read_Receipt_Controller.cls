/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CTA_Read_Receipt_Controller
*
* @description 	  Controller class for the CTA_Read_Receipt.vfp
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
public class CTA_Read_Receipt_Controller {
    
    public JBCXM__CTA__c currentRecord{ get; set; }
    
    public CTA_Read_Receipt_Controller(ApexPages.StandardController stdController){
        currentRecord = [SELECT Id, CTA_Digest__c FROM JBCXM__CTA__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }
    
    public void onLoad(){
        if(currentRecord.CTA_Digest__c != null){
            List<JBCXM__CTA__c> allCTAsForUpdate = new List<JBCXM__CTA__c>();
        	List<JBCXM__CTA__c> allCTAsForReview = [SELECT Id, 
                                                    	   CTA_Digest__c 
                                                    FROM JBCXM__CTA__c 
                                                    WHERE CTA_Digest__c = :currentRecord.CTA_Digest__c];
            for(JBCXM__CTA__c ctaRec : allCTAsForReview){
                ctaRec.Is_Read__c = TRUE;
                ctaRec.Last_User_Read__c = UserInfo.getUserId();
                allCTAsForUpdate.add(ctaRec);
            }
            
            update allCTAsForUpdate;
            
            CTA_Digest__c digestForReview = [SELECT Id, 
                                                    Is_Child_CTA_Read__c 
                                             FROM CTA_Digest__c 
                                             WHERE Id = :currentRecord.CTA_Digest__c];
            if(digestForReview != null && digestForReview.Is_Child_CTA_Read__c == FALSE){
                digestForReview.Is_Child_CTA_Read__c = TRUE;
                String dateTimeTemp = DateTime.now().format();
                digestForReview.Child_CTA_read_Date_Time__c = DateTime.parse(dateTimeTemp);
                digestForReview.CTA_Read__c = currentRecord.Id;
                update digestForReview;
            }
        } else {
        	currentRecord.Is_Read__c = TRUE;
            currentRecord.Last_User_Read__c = UserInfo.getUserId();
            update currentRecord;    
        }
    }
}