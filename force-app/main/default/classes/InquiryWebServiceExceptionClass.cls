public class InquiryWebServiceExceptionClass {
    public static void createInquiryException(Exception ex, InquiryWebServiceExceptionContainer exceptionData) {
        InquiryWebService_Exception__c newExceptionLog = new InquiryWebService_Exception__c();
        
        if(ex != null) {
            newExceptionLog.Inquiry_Web_Service_Err__c = ex.getMessage();
            newExceptionLog.Inquiry_Error_Stack_Trace_Message__c = ex.getStackTraceString();
        } else {
            newExceptionLog.Inquiry_Web_Service_Err__c = exceptionData.exceptionMessage;
        }
        
        newExceptionLog.Inquiry_Message_Log_Time__c = System.Now();
        insert newExceptionLog;
    }
    
    public class InquiryWebServiceExceptionContainer {
        public String exceptionMessage;
        
        public InquiryWebServiceExceptionContainer(string exceptionMessage) {
            this.exceptionMessage = exceptionMessage;
        }
    }
}