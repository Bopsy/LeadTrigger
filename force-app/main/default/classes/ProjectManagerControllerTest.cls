@isTest
private class ProjectManagerControllerTest {

	private static testMethod void test() {
        Test.startTest();
            ProjectManagerController ctrl = new ProjectManagerController();
            ProjectManagerController.addPhase(JSON.serialize(new Phase__c(Name = 'Test Phase')));
            ProjectManagerController.addProject(JSON.serialize(new Project__c(Name = 'Test Project')));
            ProjectManagerController.queryPhases('003000000123123', 'Project');
            ProjectManagerController.queryPhases('003000000123124', 'Stakeholder');
            ProjectManagerController.queryMilestones('003000000023123');
        Test.stopTest();
	}

}