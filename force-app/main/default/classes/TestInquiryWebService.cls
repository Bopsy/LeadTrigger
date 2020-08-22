@isTest
private class TestInquiryWebService {
 
    static testMethod void testCreateInquiryMethod() {
      // setup test data
      Contact newContact = new Contact(
          FirstName='Contact',
          LastName='Tester',
          Email='evan+contacttester@revenuepulse.com'
      );
      insert newContact;
      System.AssertNotEquals(Null, newContact.Id);
      
      Campaign newCampaign = new Campaign(
          Name='New Campaign Test'
      );
      insert newCampaign;
      System.AssertNotEquals(Null, newCampaign.Id);
      
      CampaignMember newCampaignMember = new CampaignMember(
          //Name='RevPulse Campaign Member Test',
          ContactId=newContact.Id,
          CampaignId=newCampaign.Id
      );
      insert newCampaignMember;
      System.AssertNotEquals(Null, newCampaignMember.Id);

      //RestRequest req = new RestRequest(); 
      //RestResponse res = new RestResponse();
     
      //req.requestURI = 'https://revpulse-twiliodoer.cs47.force.com/marketo/services/apexrest/Inquiry';
      
      //req.httpMethod = 'POST';
      //req.requestBody = 
      //RestContext.request = req;
      //RestContext.response = res;
  
      // Call the createInquiry method in the InquiryWebService APEX Class
      List<Map<string,string>> inquiryObjectParam = new List<Map<string,string>>();
      inquiryObjectParam.add(new Map<string,string>{'Assign MQL Owner' => UserInfo.getName()});
      inquiryObjectParam.add(new Map<string,string>{'Campaign ID' => newCampaign.Id});
      inquiryObjectParam.add(new Map<string,string>{'Description' => 'TestDescription'});
      inquiryObjectParam.add(new Map<string,string>{'Is Inquiry' => 'True'});
      inquiryObjectParam.add(new Map<string,string>{'Qualification Status' => 'New MQL'});
      inquiryObjectParam.add(new Map<string,string>{'SFDC ID' => newContact.Id});
      inquiryObjectParam.add(new Map<string,string>{'Support Agent' => 'AgentTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Campaign' => 'utmCampaignAPEXTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Content' => 'utmContentAPEXTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Medium' => 'utmMediumAPEXTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Source' => 'utmSourceAPEXTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Term' => 'utmTermAPEXTest'});

      /*InquiryWebService.createInquiry(
          'Revenue Pulse Team',
          DateTime.now(),
          'utmContentAPEXTest',
          'utmTermAPEXTest',
          'utmCampaignAPEXTest',
          'utmSourceAPEXTest',
          'utmMediumAPEXTest',
          'AgentTest',
          'TestDescription',
          newCampaign.Id,
          'New MQL',
          newContact.Id
      );*/
        
      Test.startTest();  
      InquiryWebService.createInquiry(
          inquiryObjectParam
      );
      Test.stopTest();

      CampaignMember cm = [SELECT Id, UTM_Campaign__c, UTM_Content__c,
                           		UTM_Medium__c, UTM_Term__c, UTM_Source__c,
                           		Support_Agent__c, Qualification_Status__c
                             FROM CampaignMember
                             WHERE CampaignId = :newCampaign.Id
                             AND ContactId = :newContact.Id
                          ];

      // Perform series of assert calls to ensure everything is saved accordingly based on
      // InquiryWebService's createInquiry method.
      System.assertEquals('utmCampaignAPEXTest', cm.UTM_Campaign__c);
      System.assertEquals('utmContentAPEXTest', cm.UTM_Content__c);
      System.assertEquals('utmMediumAPEXTest', cm.UTM_Medium__c);
      System.assertEquals('utmTermAPEXTest', cm.UTM_Term__c);
      System.assertEquals('utmSourceAPEXTest', cm.UTM_Source__c);
      System.assertEquals('AgentTest', cm.Support_Agent__c);
      System.assertEquals('New MQL', cm.Qualification_Status__c);
  }

    static testMethod void testCreateInquiryMethodWithoutOwner() {
      // setup test data
      Contact newContact = new Contact(
          FirstName='Contact',
          LastName='Tester',
          Email='evan+contacttester@revenuepulse.com'
      );
      insert newContact;
      System.AssertNotEquals(Null, newContact.Id);
      
      Campaign newCampaign = new Campaign(
          Name='New Campaign Test'
      );
      insert newCampaign;
      System.AssertNotEquals(Null, newCampaign.Id);
      
      CampaignMember newCampaignMember = new CampaignMember(
          //Name='RevPulse Campaign Member Test',
          ContactId=newContact.Id,
          CampaignId=newCampaign.Id
      );
      insert newCampaignMember;
      System.AssertNotEquals(Null, newCampaignMember.Id);

      //RestRequest req = new RestRequest(); 
      //RestResponse res = new RestResponse();
     
      //req.requestURI = 'https://revpulse-twiliodoer.cs47.force.com/marketo/services/apexrest/Inquiry';
      
      //req.httpMethod = 'POST';
      //req.requestBody = 
      //RestContext.request = req;
      //RestContext.response = res;
  
      // Call the createInquiry method in the InquiryWebService APEX Class
      List<Map<string,string>> inquiryObjectParam = new List<Map<string,string>>();
      inquiryObjectParam.add(new Map<string,string>{'Campaign ID' => newCampaign.Id});
      inquiryObjectParam.add(new Map<string,string>{'Description' => 'TestDescription'});
      inquiryObjectParam.add(new Map<string,string>{'Is Inquiry' => 'False'});
      inquiryObjectParam.add(new Map<string,string>{'Qualification Status' => 'New MQL'});
      inquiryObjectParam.add(new Map<string,string>{'SFDC ID' => newContact.Id});
      inquiryObjectParam.add(new Map<string,string>{'Support Agent' => 'AgentTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Campaign' => 'utmCampaignAPEXTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Content' => 'utmContentAPEXTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Medium' => 'utmMediumAPEXTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Source' => 'utmSourceAPEXTest'});
      inquiryObjectParam.add(new Map<string,string>{'UTM Term' => 'utmTermAPEXTest'});

      /*InquiryWebService.createInquiry(
          'Revenue Pulse Team',
          DateTime.now(),
          'utmContentAPEXTest',
          'utmTermAPEXTest',
          'utmCampaignAPEXTest',
          'utmSourceAPEXTest',
          'utmMediumAPEXTest',
          'AgentTest',
          'TestDescription',
          newCampaign.Id,
          'New MQL',
          newContact.Id
      );*/
        
      Test.startTest();  
      InquiryWebService.createInquiry(
          inquiryObjectParam
      );
      Test.stopTest();

      CampaignMember cm = [SELECT Id, UTM_Campaign__c, UTM_Content__c,
                           		UTM_Medium__c, UTM_Term__c, UTM_Source__c,
                           		Support_Agent__c, Qualification_Status__c
                             FROM CampaignMember
                             WHERE CampaignId = :newCampaign.Id
                             AND ContactId = :newContact.Id
                          ];

      // Perform series of assert calls to ensure everything is saved accordingly based on
      // InquiryWebService's createInquiry method.
      System.assertEquals('utmCampaignAPEXTest', cm.UTM_Campaign__c);
      System.assertEquals('utmContentAPEXTest', cm.UTM_Content__c);
      System.assertEquals('utmMediumAPEXTest', cm.UTM_Medium__c);
      System.assertEquals('utmTermAPEXTest', cm.UTM_Term__c);
      System.assertEquals('utmSourceAPEXTest', cm.UTM_Source__c);
      System.assertEquals('AgentTest', cm.Support_Agent__c);
      System.assertEquals('New MQL', cm.Qualification_Status__c);
  }
}