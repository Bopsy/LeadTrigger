@isTest
private class OpptyGatesTest {

    static Opportunity genTestOppAllGates( String oppName, Contact testContact, String bizAcctSid ) {
        
        // NOTE: Tests assuming New Customer to be default
        // Opportunity Record Type in Production
        
        Opportunity testOpp = new Opportunity( Name = oppName,
                                                StageName = 'Closed Won',
                                                CloseDate = Date.today(),
                                                Twilio_Team_involved__c = 'Those schwifty guys over there.',
                                                Referenceable_Customer__c = 'No',
                                                Quick_Company_Funding_Description__c = 'Angel investments',
                                                Lessons_Learned__c = 'Learnt some stuff real good.',
                                                How_we_won__c = 'By being harder, better, faster, stronger.', 
                                                Deal_Details__c = 'Wheeling and dealing.',
                                                Signed_Contract__c = 'Yes',
                                                Commercial_Traffic_Live__c = 'No',
                                                Development_Resources_Needed__c = 'No',
                                                POC_Success_Metrics__c = 'success metrics here' );
                                                
        // Incubate Completed
        testOpp.FY_16_Primary_Product__c = 'Programmable Voice';
        testOpp.FY_16_Use_Case__c = 'Call Tracing';
        testOpp.Primary_Competitor__c = 'Avidtrak';
        testOpp.Competitive_Takeout__c = 'NO';
        testOpp.Initiatives__c = 'some inits';
        testOpp.ProjectedVolume__c = 2000000;
        testOpp.Project_Timeframe__c = Date.today();
        testOpp.Projected_Timeframe__c = '3 - 6 Months';
        
        // Qualified Completed
        testOpp.Documented_Decision_Making_Process__c = 'No';
        testOpp.Customer_s_use_case_metrics_identified__c = 'No';
        testOpp.Technical_Champion__c = testContact.Id;
        testOpp.Project_Sponsor__c = testContact.Id;
        testOpp.Is_there_a_compelling_event__c = 'No'; 
        testOpp.Compelling_Event_Details__c = 'Some things went down.';
        testOpp.Use_Case_Requirements__c = 'But they must rise up again.';

        // Scope Completed
        testOpp.Solution_Identification_Overview__c = 'We think they should go with this.';
        testOpp.Buying_Process__c = 'Build';
        testOpp.POC__c = 'No';
        testOpp.RFP_Received__c = 'No';

        // Validate Solution Completed
        testOpp.Architectural_Review_Complete__c = 'Not Required';
        testOpp.Code_Review__c = 'No';
        testOpp.Security_Review__c = 'No';
        testOpp.Customer_Hackathon__c = 'No';
        testOpp.RFP_Answered__c = 'Not Required';
        testOpp.Twilio_Expert_Services_Engaged__c = 'Not Required';
        testOpp.New_Business_Account_SID__c = bizAcctSid;

        // Go / No Go Completed
        testOpp.POC_Outcome_Metrics_Review_with_Champion__c = 'No';
        testOpp.POC_Review__c = Date.today();
        testOpp.Technical_Win__c = 'No';

        // Business Case Completed
        testOpp.Close_Calendar__c = 'No';
        testOpp.Paper_Process__c = 'No';
        testOpp.ROI_Presented_to_Executive_Buyer__c = 'No';
        testOpp.Executive_Buyer__c = testContact.Id;

        // MSA/ Product Launch Stage Completed
        testOpp.Contract_Type__c = 'Commited';
        testOpp.MSA_Order_Form_Signed__c = 'No';
        testOpp.Test_Traffic_Live__c = 'Not Required';
        testOpp.Delivery_Plan_Schedule_Complete__c = 'Not Required';
        testOpp.Delivery_Plan_Resources_Complete__c = 'No';

        return testOpp;
    }

    static testMethod void basicNewBusinessOppNoCheckTest() {

        Contact testContact = new Contact( email = 'sometestemai@email.com', lastName = 'Schmidt' );
        insert testContact;

        Opportunity testOpp = genTestOppAllGates( 'the test oppptunity', testContact ,'236345234' );
        testOpp.Commercial_Traffic_Live__c = '';
        testOpp.How_we_won__c = '';
        
        Test.startTest();
        
            insert testOpp;
        
        Test.stopTest();
        
        Opportunity resolvedOpp = [ SELECT Id, Closed_Won_Completed__c, Closed_Won_Record_Type_Completed__c FROM Opportunity WHERE Id = :testOpp.id ];
        
        System.assertEquals( false, resolvedOpp.Closed_Won_Completed__c );
    }
    
    static testMethod void basicNewBusinessOppYesCheckTest() {

        Contact testContact = new Contact( email = 'sometestemai@email.com', lastName = 'Schmidt' );
        insert testContact;

        Opportunity testOpp = genTestOppAllGates( 'the test oppptunity', testContact ,'236345234' );
        
        Test.startTest();
        
            insert testOpp;
        
        Test.stopTest();
        
        Opportunity resolvedOpp = [ SELECT Id, Closed_Won_Completed__c, Closed_Won_Record_Type_Completed__c FROM Opportunity WHERE Id = :testOpp.id ];
        
        //System.assert( resolvedOpp.Closed_Won_Completed__c );
        //System.assert( resolvedOpp.Closed_Won_Record_Type_Completed__c );
    }
    
}