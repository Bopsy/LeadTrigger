@isTest
private class InvoiceFormControllerTest {

	static testMethod void testController() {
        Credit_Check__c testCC = new Credit_Check__c();
        insert testCC;
        States_Dependent_List__c customSetting = new States_Dependent_List__c(Name = 'Test CS', Country__c = 'United States', State__c = 'California');
        insert customSetting;
        
        PageReference invoicePage = Page.InvoiceForm;
        Test.setCurrentPageReference(invoicePage);
        Blob fileBody = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body;
        InvoiceFormController.FileWrapper file = new InvoiceFormController.FileWrapper();
        file.Name = 'Test';
        file.contentType='img/png';
        file.Body = EncodingUtil.base64Encode(fileBody);
        ApexPages.currentPage().getParameters().put('Id', testCC.Id);
        
        Test.startTest();
            InvoiceFormController cont = new InvoiceFormController();
            InvoiceFormController.saveRecord(JSON.serialize(testCC), JSON.serialize(file));
            try{
               CreditCheckRequestServices.submitApprovalRequest(new List<Credit_Check__c>{testCC}); 
            }
            catch (Exception e){
                
            }
        Test.stopTest();
	}

}