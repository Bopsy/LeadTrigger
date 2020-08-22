@isTest(SeeAllData=true)
private class ForecastLineitemTest {

    static testMethod void initialForecastScheduleCreation() {

        

        Account testAcct = new Account( Name = 'TestAcct' );
        insert testAcct;

        Date closeDate = Date.today();
        closeDate = closeDate.addMonths( -1 );

        Opportunity testOpp = new Opportunity(
            Name = 'TestOpp',
            AccountId = testAcct.Id,
            Launch_Date__c = Date.today(),
            CloseDate = closeDate,
            Contract_Terms_Months__c = 12,
            Amount = 1200,
            StageName = 'Go / No Go',
            Use_Case1__c = 'Call Tracking',
            Authy_Use_Case__c = 'Call Tracking',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi',
            New_Business_Account_SID__c = '77777776666555444'
        );
        

        Test.startTest();
        
            insert testOpp;
        
        Test.stopTest();

        List<OpportunityLineItem> oppLineItems = [ SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id ];
        List<Forecast_Schedule__c> foreScheds = [ SELECT Id FROM Forecast_Schedule__c WHERE Opportunity__c = :testOpp.Id ];
        
        //System.assertEquals( 1, oppLineItems.size() );
        //System.assertEquals( 12, foreScheds.size() );

    }
    

    static testMethod void forecastScheduleEdit() {
        
        
        
        Account testAcct = new Account( Name = 'TestAcct' );
        insert testAcct;

        Date closeDate = Date.today();
        closeDate = closeDate.addMonths( -1 );

        Opportunity testOpp = new Opportunity(
            Name = 'TestOpp',
            AccountId = testAcct.Id,
            Launch_Date__c = Date.today(),
            CloseDate = closeDate,
            Contract_Terms_Months__c = 12,
            Amount = 1200,
            StageName = 'Go / No Go',
            Use_Case1__c = 'Call Tracking',
            Authy_Use_Case__c = 'Call Tracking',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi',
            New_Business_Account_SID__c = '77777776666555444'
        );
        
        insert testOpp;

        //List<OpportunityLineItem> oppLineItems = [ SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id ];
        //List<Forecast_Schedule__c> foreScheds = [ SELECT Id FROM Forecast_Schedule__c WHERE Opportunity__c = :testOpp.Id ];
        
        //System.assertEquals( 1, oppLineItems.size() );
        //System.assertEquals( 12, foreScheds.size() );

        Test.startTest();
        
            ForecastSchedule.forecastLineitemRecalc = false;
            Opportunity newOpp = testOpp.clone(true, true ,true ,true);
            newOpp.Amount = 2400;
            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
            oldMap.put(testOpp.Id, testOpp);
            ForecastSchedule.filterAndCreateForecasts(new List<Opportunity>{newOpp}, oldMap);
            ForecastSchedule.shiftOrCreateScheds(new List<Opportunity>{newOpp}, oldMap);
            //for ( Forecast_Schedule__c fs : foreScheds )
            //    fs.Forecast_Amount__c = 1;
                
            //update foreScheds;
        
        Test.stopTest();
        
        //Opportunity testOppResolved = [ SELECT Id, Amount FROM Opportunity WHERE Id = :testOpp.Id ];
        
        //System.assertEquals( 12, testOppResolved.Amount );

    }

    static testMethod void forecastScheduleDelete() {

        

        Account testAcct = new Account( Name = 'TestAcct' );
        insert testAcct;

        Date closeDate = Date.today();
        closeDate = closeDate.addMonths( -1 );

        Opportunity testOpp = new Opportunity(
            Name = 'TestOpp',
            AccountId = testAcct.Id,
            Launch_Date__c = Date.today(),
            CloseDate = closeDate,
            Contract_Terms_Months__c = 12,
            Amount = 1200,
            StageName = 'Go / No Go',
            Use_Case1__c = 'Call Tracking',
            Authy_Use_Case__c = 'Call Tracking',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi',
            New_Business_Account_SID__c = '77777776666555444'
        );
        
        insert testOpp;

        //List<OpportunityLineItem> oppLineItems = [ SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id ];
        //List<Forecast_Schedule__c> foreScheds = [ SELECT Id FROM Forecast_Schedule__c WHERE Opportunity__c = :testOpp.Id ];
        
        //System.assertEquals( 1, oppLineItems.size() );
        //System.assertEquals( 12, foreScheds.size() );

        Test.startTest();
        
            //ForecastSchedule.forecastLineitemRecalc = false;
        
            //List<Forecast_Schedule__c> fs4Deletion = new List<Forecast_Schedule__c>{ foreScheds[0], foreScheds[1] };
            //delete fs4Deletion;
        
        Test.stopTest();
        
        //List<Forecast_Schedule__c> foreSchedsResolved = [ SELECT Id FROM Forecast_Schedule__c WHERE Opportunity__c = :testOpp.Id ];
        //System.assertEquals( 10, foreSchedsResolved.size() );

        //Opportunity testOppResolved = [ SELECT Id, Amount FROM Opportunity WHERE Id = :testOpp.Id ];
        //System.assertEquals( 1000, testOppResolved.Amount );

    }

    static testMethod void changeOppLaunchDate() {

        

        Account testAcct = new Account( Name = 'TestAcct' );
        insert testAcct;

        Date closeDate = Date.today();
        closeDate = closeDate.addMonths( -1 );

        Opportunity testOpp = new Opportunity(
            Name = 'TestOpp',
            AccountId = testAcct.Id,
            Launch_Date__c = Date.today(),
            CloseDate = closeDate,
            Contract_Terms_Months__c = 12,
            Amount = 1200,
            StageName = 'Go / No Go',
            Use_Case1__c = 'Call Tracking',
            Authy_Use_Case__c = 'Call Tracking',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi',
            New_Business_Account_SID__c = '77777776666555444',
            FY_16_Primary_Product__c = 'Programmable Messaging'
        );
        
        insert testOpp;

        //List<OpportunityLineItem> oppLineItems = [ SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id ];
        //List<Forecast_Schedule__c> foreScheds = [ SELECT Id, Start_Date__c FROM Forecast_Schedule__c WHERE Opportunity__c = :testOpp.Id ];
        
        //System.assertEquals( 1, oppLineItems.size() );
        //System.assertEquals( 12, foreScheds.size() );

        //Map<Id, Date> fsId2StartDate = new Map<Id, Date>();
        
        //for ( Forecast_Schedule__c fs : foreScheds ) {
        //    fsId2StartDate.put( fs.Id, fs.Start_Date__c  );
        //    System.debug('TEST(changeOppLaunchDate): Forecast_Schedule__c(Id=' + fs.Id + ', Start_Date__c=' + fs.Start_Date__c + ')');
        //}

        Test.startTest();
        
            ForecastSchedule.forecastLineitemRecalc = false;
        
            Date oldLaunchDate = testOpp.Launch_Date__c;
            oldLaunchDate = oldLaunchDate.addMonths( 1 );
            testOpp.Launch_Date__c = oldLaunchDate;
        
            update testOpp;
        
        Test.stopTest();
        
        //List<Forecast_Schedule__c> foreSchedsWNewDates = [ SELECT Id, Start_Date__c FROM Forecast_Schedule__c WHERE Opportunity__c = :testOpp.Id ];
        
        //System.assert( foreSchedsWNewDates.size() > 0 );
        
        //for ( Forecast_Schedule__c fs : foreSchedsWNewDates ) {
        
        //    Date olderDate = fsId2StartDate.get( fs.Id );
        //    System.debug('TEST(changeOppLaunchDate): Check Start_Date__c(Old+1month=' + olderDate.addMonths( 1 ) + ', New=' + fs.Start_Date__c + ')');
            //System.assertEquals( olderDate.addMonths( 1 ), fs.Start_Date__c );
            
        //}

    }


    static testMethod void initialPilotForecastScheduleCreation() {

        

        Account testAcct = new Account( Name = 'TestAcct' );
        insert testAcct;

        Date closeDate = Date.today();
        closeDate = closeDate.addMonths( -1 );

        Opportunity testOpp = new Opportunity(
            Name = 'TestOpp',
            AccountId = testAcct.Id,
            Launch_Date__c = Date.today(),
            CloseDate = closeDate,
            Contract_Terms_Months__c = 12,
            Amount = 1200,
            StageName = 'Go / No Go',
            Use_Case1__c = 'Call Tracking',
            Authy_Use_Case__c = 'Call Tracking',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi',
            New_Business_Account_SID__c = '77777776666555444',
            Pilot_Start_Date__c = Date.today().addMonths(-3),
            Pilot_End_Date__c = Date.today().addMonths(-1),
            Pilot_Forecast_Category__c = 'Pipeline'
        );
        

        Test.startTest();
        
            insert testOpp;
        
        Test.stopTest();

        //List<Forecast_Schedule__c> foreScheds = [ SELECT Id FROM Forecast_Schedule__c WHERE Opportunity__c = :testOpp.Id AND Is_Pilot__c = true ];
        
        //System.assertEquals( 3, foreScheds.size(), 'Two Pilot Forecast Schedules should be created' );
    }

    static testMethod void changePilotStartEndDates() {

        

        Account testAcct = new Account( Name = 'TestAcct' );
        insert testAcct;

        Date closeDate = Date.today();
        closeDate = closeDate.addMonths( -1 );

        Opportunity testOpp = new Opportunity(
            Name = 'TestOpp',
            AccountId = testAcct.Id,
            Launch_Date__c = Date.today(),
            CloseDate = closeDate,
            Contract_Terms_Months__c = 12,
            Amount = 1200,
            StageName = 'Go / No Go',
            Use_Case1__c = 'Call Tracking',
            Authy_Use_Case__c = 'Call Tracking',
            Product__c = 'Client',
            Primary_Competitor__c = 'Agendi',
            New_Business_Account_SID__c = '77777776666555444',
            Pilot_Start_Date__c = Date.today().addMonths(-4),
            Pilot_End_Date__c = Date.today().addMonths(-2),
            Pilot_Forecast_Category__c = 'Pipeline'
        );
        
        insert testOpp;

        //List<Forecast_Schedule__c> foreScheds = [ SELECT Id, Start_Date__c FROM Forecast_Schedule__c WHERE Opportunity__c = :testOpp.Id AND Is_Pilot__c = true ];
       // System.assertEquals( 3, foreScheds.size(), '3 Pilot Forecast Schedules should be created' );

        System.debug('TEST - changePilotStartEndDates(): testOpp(BEFORE) = ' + testOpp);

        Test.startTest();
        
            ForecastSchedule.forecastLineitemRecalc = false;

            Date oldPilotStartDate = testOpp.Pilot_Start_Date__c;
            oldPilotStartDate = oldPilotStartDate.addMonths( -1 );
            testOpp.Pilot_Start_Date__c = oldPilotStartDate;

            Date oldPilotEndDate = testOpp.Pilot_End_Date__c;
            oldPilotEndDate = oldPilotEndDate.addMonths( 1 );
            testOpp.Pilot_End_Date__c = oldPilotEndDate;

            update testOpp;
        
        Test.stopTest();
        
        //testOpp = [ SELECT Id, Pilot_Start_Date__c, Pilot_End_Date__c FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1 ];
        //System.debug('TEST - changePilotStartEndDates(): testOpp(AFTER) = ' + testOpp);
        //List<Forecast_Schedule__c> foreSchedsWNewDates = [ SELECT Id, Start_Date__c, End_Date__c FROM Forecast_Schedule__c WHERE Opportunity__c = :testOpp.Id AND Is_Pilot__c = true ];
        //for (Forecast_Schedule__c f : foreSchedsWNewDates) {
        //    System.debug('TEST - changePilotStartEndDates(): forecastSched = ' + f);
        //}
        //System.assertEquals( 5, foreSchedsWNewDates.size(), '5 Pilot Forecast Schedules should be exist' );
    }
}