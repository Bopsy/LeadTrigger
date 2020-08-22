@isTest
private class SliderControllerTest {

	private static testMethod void testConstructor() {
        
        Test.startTest();
            sliderController ctrl = new sliderController();
            ctrl.choiceMap =  'Test: www.test.org';
            ctrl.getChoicesMap();
        Test.stopTest();
	}

}