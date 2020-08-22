@isTest
private class SenderIdFormControllerTest {

	private static testMethod void test() {
        Sender_ID_Application__c testCC = new Sender_ID_Application__c();
        //insert testCC;
        States_Dependent_List__c customSetting = new States_Dependent_List__c(Name = 'Test CS', Country__c = 'United States', State__c = 'California');
        insert customSetting;
        
        PageReference SenderIdForm = Page.SenderId;
        Test.setCurrentPageReference(SenderIdForm);
        Blob fileBody = [SELECT Body FROM StaticResource WHERE Name = 'logo' LIMIT 1].Body;
        SenderIdFormController.FileWrapper file = new SenderIdFormController.FileWrapper();
        file.Name = 'Test';
        file.contentType='img/png';
        file.Body = EncodingUtil.base64Encode(fileBody);
        ApexPages.currentPage().getParameters().put('Id', testCC.Id);
        
        Test.startTest();
            SenderIdFormController cont = new SenderIdFormController();
            SenderIdFormController.saveRecord(JSON.serialize(testCC), JSON.serialize(file));
        Test.stopTest();
	}

}