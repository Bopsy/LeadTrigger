@IsTest
private class Peak_ProfileProgressControllerTest {

    @testSetup
    static void methodName() {
        Contact testContact = Peak_TestUtils.createTestContact();
    }

    // Test the dynamic query builder
    @isTest
    public static void testDynamicQueryBuilder(){
        // Set up and run as a standard user
        String[] fields = new List<String>();
        fields.add('FirstName');

        List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];

        User testUser = Peak_TestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        }catch(Exception e){
            testUser.ContactId = NULL;
            insert testUser;
        }

        // The following code runs as user 'testUser'
        String builtQuery = Peak_ProfileProgressController.dynamicQueryBuilder('User', testUser.Id, fields);
        system.assertEquals('SELECT Id, FirstName FROM User WHERE Id = \'' + testUser.Id + '\'',builtQuery);
    }
    // Test getting the user
    @isTest
    public static void testGetUser(){
        // Set up and run as a standard user
        List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];

        User testUser = Peak_TestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        }catch(Exception e){
            testUser.ContactId = NULL;
            insert testUser;
        }

        System.runAs(testUser) {
            // The following code runs as user 'testUser'
            User queryUser = Peak_ProfileProgressController.getUser();
            system.assertEquals(Peak_TestConstants.FIRSTNAME + ' ' + Peak_TestConstants.LASTNAME,queryUser.Name);
        }
    }
    @isTest
    public static void testGetUserById(){
        // Set up and run as a standard user
        List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];

        User testUser = Peak_TestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        }catch(Exception e){
            testUser.ContactId = NULL;
            insert testUser;
        }

        String[] fields = new List<String>();
        fields.add('FirstName');
        fields.add('LastName');
        fields.add('Email');


        User queryUser = Peak_ProfileProgressController.getUserById(testUser.Id, fields);
        system.assertEquals(Peak_TestConstants.FIRSTNAME, queryUser.FirstName);
        system.assertEquals(Peak_TestConstants.LASTNAME, queryUser.LastName);
        system.assertEquals(Peak_TestConstants.STANDARD_EMAIL, queryUser.Email);
    }
    // Test getting the site prefix
    @isTest
    public static void testSitePrefix(){
        String prefix = Peak_ProfileProgressController.getSitePrefix();
        System.assertNotEquals(null, prefix);
    }
}