@isTest
public with sharing class Peak_ContentObjectHelperTest {

    @isTest
    public static void testFormatFromString() {
        // Create a Peak Content Object from helper
        Peak_ContentObjectHelper contentObjectHelper = new Peak_ContentObjectHelper();
        Peak_ContentObject testObject = contentObjectHelper.formatFromString(Peak_TestConstants.TEST_GROUPNAME);

        // Assert its name property was set
        System.assertEquals(testObject.title, Peak_TestConstants.TEST_GROUPNAME);
    }


}