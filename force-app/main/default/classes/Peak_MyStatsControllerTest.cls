@isTest
public with sharing class Peak_MyStatsControllerTest {

    @isTest
    public static void testPeakStatsController() {

        // Assert simple static test
    	system.assertEquals(Peak_MyStatsController.getSampleStatApex().figure1,2);

        test.startTest();

        // Assert 1 closed opp found
        system.assert(Peak_MyStatsController.getMyClosedWonOpps() != null);
        // Assert 1 open opp found
        system.assert(Peak_MyStatsController.getMyNewOpps() != null);

        test.stopTest();

    }

}