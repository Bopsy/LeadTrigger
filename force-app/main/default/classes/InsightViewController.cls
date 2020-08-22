/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  InsightViewController
*
* @description 	  Controller class for the Insight_View.vfp
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2020-04-17
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class InsightViewController {
	public Account currentAccountRecord{ get; set; }
    
    public InsightViewController(ApexPages.StandardController stdController){
        currentAccountRecord = [SELECT Id FROM Account WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }
    
    public void onLoad(){
        //String dateTimeTemp = DateTime.now().format();
        
        Insight_View__c insightViewForInsert = new Insight_View__c(Account__c = currentAccountRecord.Id,
                                                                   Viewed_By__c = UserInfo.getUserId(),
                                                                   Viewed_Date__c = DateTime.now());
        
        try{
        	insert insightViewForInsert;    	
        } catch (DmlException e) {
            System.debug('The following exception has occurred when inserting the Insight_View__c record: ' + e.getMessage());
            ApexHandlerException.LogDMLException(e);
        }
    }
}