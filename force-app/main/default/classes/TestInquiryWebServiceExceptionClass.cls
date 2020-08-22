@isTest
private class TestInquiryWebServiceExceptionClass {
    // these test out the InquiryWebServiceExceptionClass code and one of the error statements found in InquiryWebService APEX Class, without passing in the
    // Exception object.
    @isTest static void noCampaignIdValExceptionTest() {
      	List<Map<string,string>> inquiryObjectParam = new List<Map<string,string>>();
      	inquiryObjectParam.add(new Map<string,string>{'Assign MQL Owner' => 'Revenue Pulse Team'});
      	inquiryObjectParam.add(new Map<string,string>{'Campaign ID' => null});
      	inquiryObjectParam.add(new Map<string,string>{'Description' => 'TestDescription'});
      	inquiryObjectParam.add(new Map<string,string>{'Qualification Status' => 'New MQL'});
        inquiryObjectParam.add(new Map<string,string>{'SFDC ID' => 'testSFDCId'});
      	inquiryObjectParam.add(new Map<string,string>{'Support Agent' => 'AgentTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Campaign' => 'utmCampaignAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Content' => 'utmContentAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Medium' => 'utmMediumAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Source' => 'utmSourceAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Term' => 'utmTermAPEXTest'});

        try {
            InquiryWebService.createInquiry(
                inquiryObjectParam
            );
        } catch(Exception ex) {
            InquiryWebServiceExceptionClass.createInquiryException(null,
                new InquiryWebServiceExceptionClass.InquiryWebServiceExceptionContainer('Test using no Campaign Id values'));
        }
    }
 
    // these test out the InquiryWebServiceExceptionClass code and one of the error statements found in InquiryWebService APEX Class, without passing in the
    // Exception object.
    @isTest static void noSFDCIdValExceptionTest() {
      	List<Map<string,string>> inquiryObjectParam = new List<Map<string,string>>();
      	inquiryObjectParam.add(new Map<string,string>{'Assign MQL Owner' => 'Revenue Pulse Team'});
        inquiryObjectParam.add(new Map<string,string>{'Campaign ID' => 'testCampaignId'});
      	inquiryObjectParam.add(new Map<string,string>{'Description' => 'TestDescription'});
      	inquiryObjectParam.add(new Map<string,string>{'Qualification Status' => 'New MQL'});
      	inquiryObjectParam.add(new Map<string,string>{'SFDC ID' => ''});
      	inquiryObjectParam.add(new Map<string,string>{'Support Agent' => 'AgentTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Campaign' => 'utmCampaignAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Content' => 'utmContentAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Medium' => 'utmMediumAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Source' => 'utmSourceAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Term' => 'utmTermAPEXTest'});

        try {
            InquiryWebService.createInquiry(
                inquiryObjectParam
            );
        } catch(Exception ex) {
            InquiryWebServiceExceptionClass.createInquiryException(null,
                new InquiryWebServiceExceptionClass.InquiryWebServiceExceptionContainer('Test using no SFDC (Lead/Contact) Id values'));
        }
    }
    
    // this tests out the InquiryWebServiceExceptionClass code and if there are no Campaign Members found in the SOQL query.
    @isTest static void noCampaignMembersExceptionTest() {
      	List<Map<string,string>> inquiryObjectParam = new List<Map<string,string>>();
      	inquiryObjectParam.add(new Map<string,string>{'Assign MQL Owner' => 'Revenue Pulse Team'});
        inquiryObjectParam.add(new Map<string,string>{'Campaign ID' => '000000000000'});
      	inquiryObjectParam.add(new Map<string,string>{'Description' => 'TestDescription'});
      	inquiryObjectParam.add(new Map<string,string>{'Qualification Status' => 'New MQL'});
      	inquiryObjectParam.add(new Map<string,string>{'SFDC ID' => '000000000000'});
      	inquiryObjectParam.add(new Map<string,string>{'Support Agent' => 'AgentTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Campaign' => 'utmCampaignAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Content' => 'utmContentAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Medium' => 'utmMediumAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Source' => 'utmSourceAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Term' => 'utmTermAPEXTest'});

        try {
            InquiryWebService.createInquiry(
                inquiryObjectParam
            );
        } catch(Exception ex) {
            InquiryWebServiceExceptionClass.createInquiryException(ex,
                new InquiryWebServiceExceptionClass.InquiryWebServiceExceptionContainer('Test using non-existing Id vals'));
        }
    }

    // this tests out the InquiryWebServiceExceptionClass code and if there are no Users found in the SOQL query.
    @isTest static void noUsersExceptionTest() {
      	// setup test data
      	Contact newContact = new Contact(
          	FirstName = 'Contact',
          	LastName = 'Tester',
          	Email = 'evan+contacttester@revenuepulse.com'
      	);
      	insert newContact;
      	System.AssertNotEquals(Null, newContact.Id);
      
      	Campaign newCampaign = new Campaign(
          	Name = 'New Campaign Test'
      	);
      	insert newCampaign;
      	System.AssertNotEquals(Null, newCampaign.Id);
      
      	CampaignMember newCampaignMember = new CampaignMember(
          	//Name='RevPulse Campaign Member Test',
          	ContactId = newContact.Id,
          	CampaignId = newCampaign.Id
      	);
      	insert newCampaignMember;
      	System.AssertNotEquals(Null, newCampaignMember.Id);

      	List<Map<string,string>> inquiryObjectParam = new List<Map<string,string>>();
      	inquiryObjectParam.add(new Map<string,string>{'Assign MQL Owner' => 'The Error Team'});
        inquiryObjectParam.add(new Map<string,string>{'Campaign ID' => newCampaign.Id});
      	inquiryObjectParam.add(new Map<string,string>{'Description' => 'TestDescription'});
      	inquiryObjectParam.add(new Map<string,string>{'Qualification Status' => 'New MQL'});
      	inquiryObjectParam.add(new Map<string,string>{'SFDC ID' => newContact.Id});
      	inquiryObjectParam.add(new Map<string,string>{'Support Agent' => 'AgentTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Campaign' => 'utmCampaignAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Content' => 'utmContentAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Medium' => 'utmMediumAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Source' => 'utmSourceAPEXTest'});
      	inquiryObjectParam.add(new Map<string,string>{'UTM Term' => 'utmTermAPEXTest'});

        try {
            InquiryWebService.createInquiry(
                inquiryObjectParam
            );
        } catch(Exception ex) {
            InquiryWebServiceExceptionClass.createInquiryException(ex,
                new InquiryWebServiceExceptionClass.InquiryWebServiceExceptionContainer('Test using non-existing User name'));
        }
    }

    // this tests if the object record can be created and inserted into the custom object
    @isTest static void testCreateInquiryWebServiceException() {
        Test.startTest();
        InquiryWebService_Exception__c testExceptionObj = new InquiryWebService_Exception__c();
        testExceptionObj.Inquiry_Error_Stack_Trace_Message__c = 'Stack Trace Message - SEGMENTATION FAULT';
        testExceptionObj.Inquiry_Web_Service_Err__c = 'Error Test - Inquiry Web Service Exception insertion';
        testExceptionObj.Inquiry_Message_Log_Time__c = System.Now();
        insert testExceptionObj;
        System.assertEquals('Error Test - Inquiry Web Service Exception insertion', testExceptionObj.Inquiry_Web_Service_Err__c);
        Test.stopTest();
    }
}