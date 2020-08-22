@isTest
private class TestAttachmentDealDesk {

    static testMethod void basicTestCase() {

		Account testAcct = new Account( Name = 'Nimbly Test Acct' );
		insert testAcct;

		Opportunity testOpp = new Opportunity( Name = 'Nimbly test opp', AccountId = testAcct.Id,
											   CloseDate = Date.today(), StageName = 'Pilot', Use_Case1__c = 'Call Tracking',
											   Authy_Use_Case__c = 'Call Tracking', Product__c = 'Client',
											   Primary_Competitor__c = 'Agendi',
											   Contract_Type__c = 'Commited' );
		insert testOpp;

		Deal_Desk_Request__c testDealDeskReq = new Deal_Desk_Request__c( Requester__c = UserInfo.getUserId(),
																		 Opportunity__c = testOpp.Id, Account_SID__c = '23456789' );
		insert testDealDeskReq;

		Deal_Desk_Request__c requeried = [ SELECT Id, Quote_Pricing_Sheet_Attached__c 
										   FROM Deal_Desk_Request__c WHERE id = :testDealDeskReq.Id ];

		System.assertEquals( false, requeried.Quote_Pricing_Sheet_Attached__c );

        Attachment attach = new Attachment();    
		attach.Name = 'Unit Test Attachment';
		Blob bodyBlob = Blob.valueOf( 'Unit Test Attachment Body' );
		attach.body = bodyBlob;
		attach.parentId = testDealDeskReq.id;
        insert attach;

        Deal_Desk_Request__c lastQueried = [ SELECT Id, Quote_Pricing_Sheet_Attached__c 
											 FROM Deal_Desk_Request__c WHERE id = :testDealDeskReq.Id ];

		System.assertEquals( true, lastQueried.Quote_Pricing_Sheet_Attached__c );

    }

}