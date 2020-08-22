@isTest
private class CommitSchedulerControllerExtTest {

    private static testMethod void testConstructor() {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement', Commit_Frequency__c = 'Monthly', Term_Range__c = '12', Total_Committed_Revenue_Input__c = 1200);
        insert agreement;
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(agreement);
        
        Test.startTest();
            CommitSchedulerControllerExt ctrlExt = new CommitSchedulerControllerExt(stdCtrl);
            CommitSchedulerControllerExt.getAgreement(agreement.Id);
            List<Commit_Schedule__c> schedules = [SELECT Agreement__c, Id, Commit_Frequency__c, Start_Date__c, End_Date__c, Commit_Amount__c, Last_Commit_Schedule__c FROM Commit_Schedule__c WHERE Agreement__c =: agreement.Id];
            delete schedules;

            for(Commit_Schedule__c schedule: schedules){
                schedule.Id = null;
            }
            String testObjects = JSON.serialize(schedules);
            
            List<Commit_Schedule__c> commits = new List<Commit_Schedule__c>{new Commit_Schedule__c(Agreement__c = agreement.Id, Commit_Amount__c = 10, Start_Date__c = Date.today())};
            
            CommitSchedulerControllerExt.saveForecasts(testObjects, JSON.serialize(commits), agreement.Id, '12', '1200', '0121W000000Iit5');
            ctrlExt.getCommitSchedules();
        Test.stopTest();
    }

}