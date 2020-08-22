public class QuoteSOPDataStampService {
    public static void stampQuote(List<Apttus_Proposal__Proposal__c> quotes) {
        for(Apttus_Proposal__Proposal__c quote: quotes){
           if(quote.Apttus_QPConfig__Configurations__r != null && !quote.Apttus_QPConfig__Configurations__r.isEmpty()){
               
               //IF quote's first LI created date is not populdated, and Config HAS First_LI_created_date__c populated
               if(quote.First_LI_created_date__c == NULL && quote.Apttus_QPConfig__Configurations__r[0].First_LI_created_date__c != NULL) {
                   quote.First_LI_created_date__c = DateTime.parse(quote.Apttus_QPConfig__Configurations__r[0].First_LI_created_date__c.format());
                   
                   
                   
               }

               for(Apttus_Config2__ProductConfiguration__c config : quote.Apttus_QPConfig__Configurations__r){

                   if(config.Apttus_Config2__FinalizedDate__c != NULL){
                       if(quote.First_Configuration_Finalized_Date__c == NULL || (config.Apttus_Config2__FinalizedDate__c < quote.First_Configuration_Finalized_Date__c)) {

                           quote.First_Configuration_Finalized_Date__c = DateTime.parse(config.Apttus_Config2__FinalizedDate__c.format());
                           quote.First_Configuration_Approval_Time__c = config.Total_Hours_to_Approve_Request__c ;
                               
                       } 
                   }
                }
               
           } 
        }
        
        update quotes;
    }

}