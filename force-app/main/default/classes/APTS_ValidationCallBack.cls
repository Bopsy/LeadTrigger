/*****************************************************************************************
     Added by Apttus Managed Service Team
     Case: CAS-09086-J4T4D4
     Date: 18-12-2018
     Desc: To Prevent Duplicate Product (standalone or option product). BI_SID__c is unique field to identify the products.
******************************************************************************************/

global class APTS_ValidationCallBack implements Apttus_Config2.CustomClass.IValidationCallback3 {

/**
* Callback to validate the line items in the cart
* @param cart the cart object to validate
* @return the validation result
**/ 
    global Apttus_Config2.CustomClass.ValidationResult validateCart(Apttus_Config2.CustomClass.ActionParams ac,Apttus_Config2.ProductConfiguration cart) {
        
        System.debug(LoggingLevel.Error, 'My Text lineItem productCosdsdsdsdgdferernfiguration >>>>>>>>>'); 
        Apttus_Config2__ProductConfiguration__c productConfiguration = cart.getConfigSO();
         
        List<Apttus_Config2__LineItem__C> allLineItems = [SELECT Id,name,Apttus_Config2__LineType__c,Apttus_Config2__OptionId__r.Name,Apttus_Config2__ProductId__r.Name,Apttus_Config2__LineNumber__c,Apttus_Config2__OptionId__C,Apttus_Config2__ProductId__C,
        Apttus_Config2__Quantity__c FROM Apttus_Config2__LineItem__C WHERE Apttus_Config2__ConfigurationId__c =: productConfiguration.Id and Apttus_Config2__IsPrimaryLine__c = true];

        Apttus_Config2.CustomClass.ValidationResult result = new Apttus_Config2.CustomClass.ValidationResult(true);
        Boolean validateChk = false;
        result.isSuccess=  true;
        
        set<string> pset2 = new set<string>();
        System.debug(LoggingLevel.INFO, 'My Text lineItem productConfiguration >>>>>>>>>'+productConfiguration); 
        
        for(Apttus_Config2__LineItem__C lineItem : allLineItems){
            System.debug(LoggingLevel.INFO, 'My Text lineItem  >>>>>>>>>'+lineItem ); 
            string prodName='';
            
            if(pset2.size()>0 && ((lineItem.Apttus_Config2__LineType__c=='Option' && pset2.contains(lineItem.Apttus_Config2__OptionId__C)) || (lineItem.Apttus_Config2__LineType__c=='Product/Service' && pset2.contains(lineItem.Apttus_Config2__ProductId__C)))){
                
                prodName = lineItem.Apttus_Config2__LineType__c=='Option' ? lineItem.Apttus_Config2__OptionId__r.name : lineItem.Apttus_Config2__ProductId__r.Name;
                result.isSuccess = false;
                result.Messages.add(new ApexPages.Message(ApexPages.Severity.Error,'There is a duplicate product - '+prodName+' in the cart, Please remove the duplicate !'));
            }
            else{
                if(lineItem.Apttus_Config2__LineType__c=='Option' && lineItem.Apttus_Config2__OptionId__C!=null)
                {
                    pset2.add(lineItem.Apttus_Config2__OptionId__C);
                    System.debug(LoggingLevel.INFO, 'My Text Option pset2>>>>>>>>>'+pset2); 
                }                   
                else if(lineItem.Apttus_Config2__LineType__c=='Product/Service' && lineItem.Apttus_Config2__ProductId__c!=null && lineItem.Apttus_Config2__ProductId__C!=null)
                {
                    pset2.add(lineItem.Apttus_Config2__ProductId__C);
                    System.debug(LoggingLevel.INFO, 'My Text PRODUCT pset2>>>>>>>>>'+pset2); 
                }
                System.debug(LoggingLevel.INFO, 'My Text pset2>>>>>>>>>'+pset2); 
            } 
      }
        //Added by Amrutha 
        Map<String, String> mapValues = Apttus_Config2.RuntimeContext.getParameters();
        String PageAction = mapValues.get('pageAction');
        List<Apttus_Config2__LineItem__C> lstLineItems = [SELECT Id,Tier_Changed_Number__c,Apttus_Config2__ConfigurationId__r.Apttus_CQApprov__Approval_Status__c FROM Apttus_Config2__LineItem__C 
                                                          WHERE Apttus_Config2__ConfigurationId__c =: productConfiguration.Id 
                                                          and Apttus_Config2__ProductId__r.name='Voice CPS Capacity'];
        for(Apttus_Config2__LineItem__C lineItem : lstLineItems){
            if(PageAction =='Finalize' && lineItem.Tier_Changed_Number__c==1 && 
               lineItem.Apttus_Config2__ConfigurationId__r.Apttus_CQApprov__Approval_Status__c!='Approval Required' && 
               lineItem.Apttus_Config2__ConfigurationId__r.Apttus_CQApprov__Approval_Status__c!='Approved'){
                   result.isSuccess = false;
                   result.Messages.add(new ApexPages.Message(ApexPages.Severity.Error,'Customized Voice CPS Product Tier needs Approval. Please click "Reprice" and then "Submit for Approval"'));
               }
        }
        
         System.debug(LoggingLevel.INFO, 'Done Result>>>>>>>>>'+result); 
         return result;
    }
    
    /**
    * Callback to validate the given list ramp line items
    * @param cart the cart object associated with the ramp line items
    * @param rampLineItems the list of ramp line items
    * @return the validation result
    */
    global Apttus_Config2.CustomClass.ValidationResult validateRampLineItems(Apttus_Config2.CustomClass.ActionParams ap,Apttus_Config2.ProductConfiguration cart, List<Apttus_Config2.LineItem> rampLineItems) {
        Apttus_Config2.CustomClass.ValidationResult result = new Apttus_Config2.CustomClass.ValidationResult(true);
        System.debug(LoggingLevel.INFO, 'rampLineItems >>>>>>>>>'+rampLineItems); 
        return result;        
    }   
}