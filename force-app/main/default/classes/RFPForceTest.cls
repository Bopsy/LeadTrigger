@isTest
private class RFPForceTest {
    
    public static RFP__c rfp;
    public static Response__c r1;
    public static Response__c r2;
    public static Question__c q1;
    public static Question__c q2;

    static testmethod void RFPTest() {
        setupRecords();

        Test.startTest();
        try {
            insert q1;
            insert q2;
        } catch (Exception e) {
            // Swallow the exception
        }
        Test.stopTest();
    }
    
    static testmethod void RFP_AJAXInterfaceTest() {
        setupRecords();
        
        // Instantiate a new controller with all parameters in the page
        RFP_AJAXInterface controller = new RFP_AJAXInterface();
        controller.getResponseText();
        controller.deleteStopWords();

        RFP_AJAXInterface.Response resp = new RFP_AJAXInterface.Response();
        resp.Id = 'test';
        resp.Summary = 'test';
        resp.Status = 'test';
        resp.Category = 'test';
        String tid1 = resp.Id;
        String tsummary = resp.Summary;
        String tstatus = resp.Status;
        String tcategory = resp.Category;

        RFP_AJAXInterface.RFP_Document doc = new RFP_AJAXInterface.RFP_Document();
        doc.Id = 'test';
        doc.Name = 'test';
        String tid2 = doc.Id;
        String tname = doc.Name;

        controller.SelectedRFP = 'test';
        String tselectedrfp = controller.SelectedRFP;

        controller.Question = 'test';
        String tquestion = controller.Question;
    }

    static testmethod void RFP_QuickLookupTool_Ext() {
        setupRecords();
        
        // Instantiate a new controller with all parameters in the page
        ApexPages.StandardController controller = new ApexPages.StandardController(rfp);
        RFP_QuickLookupTool_Ext ext = new RFP_QuickLookupTool_Ext(controller);
        List<Schema.PicklistEntry> ple = ext.getCategories();
    }
    
    private static void setupRecords() {
        rfp = new RFP__c(
            Name = 'TestRFP',
            Due_Date__c = DateTime.now(),
            Review_by_Date__c = Date.today().addDays(1)
        );
        insert rfp;
        
        r1 = new Response__c(
            Name = 'This is a test response.',
            Originating_RFP__c = rfp.Id,
            Status__c = 'Draft',
            Periodic_Review_Days__c = 2
        );
        insert r1;
        
        q1 = new Question__c(
            Question__c = 'This is a test question.',
            RFP__c = rfp.Id,
            Response__c = r1.Id
        );

        q2 = new Question__c(
            Question__c = 'This is a test question.',
            RFP__c = rfp.Id,
            Response__c = r1.Id
        );
    }
}