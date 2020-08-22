@IsTest
private class Peak_ContentObjectTest {

    @testSetup
    static void testSetup() {
        Contact testContact = Peak_TestUtils.createTestContact();
    }

    @isTest
    public static void testPeak_ContentObject() {

        List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];

        User testUser = Peak_TestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        }catch(Exception e){
            testUser.ContactId = NULL;
            insert testUser;
        }

        Test.startTest();

        Peak_ContentObject peakContentObject = new Peak_ContentObject();
        peakContentObject.contentID = testUser.Id;
        peakContentObject.title = Peak_TestConstants.FIRSTNAME;
        peakContentObject.description = Peak_TestConstants.TEST_DESCRIPTION;
        peakContentObject.fullDescription = Peak_TestConstants.TEST_DESCRIPTION;
        peakContentObject.attachments = new List<Attachment>();
        peakContentObject.url = Peak_TestConstants.TEST_URL;
        peakContentObject.featured = false;
        peakContentObject.bannerImage = '';
        peakContentObject.avatar = '';
        peakContentObject.commentCount = 1;
        peakContentObject.commentUrl = '';
        peakContentObject.dateTimeField = DateTime.newInstance(2011, 11, 18, 3, 3, 3);
        peakContentObject.dateField = Peak_TestConstants.TODAY;

        system.assertEquals(peakContentObject.title,Peak_TestConstants.FIRSTNAME);
        Test.stopTest();
    }

}