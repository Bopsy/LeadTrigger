@isTest

private class AccountAfterTriggerTest {

    static testmethod void changeAccountOwner() {
        Profile p = [Select Id from Profile where name = 'Standard User'];
        
        User u = new User();
        u.ProfileId = p.Id;
        u.Username = System.now().getTime() + 'test@test-account-after-trigger.com';
        u.Alias = 'testtest';
        u.Email='test@test-account-after-trigger-12345.com';
        u.EmailEncodingKey='UTF-8';
        u.Firstname='Test';
        u.Lastname='Test';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.TimeZoneSidKey='America/Chicago';
        insert u;


        //
        // Changed run as user to be a "System Administrator" user so it would be exempted
        // from validation rules prevent ownership changes
        //
        User adminUser = [select Id from User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];

        if (adminUser == null) {
            Profile adminProfile = [Select Id from Profile where name = 'System Administrator'];
            
            adminUser = new User();
            adminUser.ProfileId = adminProfile.Id;
            adminUser.Username = System.now().getTime() + 'test@test-account-after-trigger.com';
            adminUser.Alias = 'testtest';
            adminUser.Email='test@test-account-after-trigger-12345.com';
            adminUser.EmailEncodingKey='UTF-8';
            adminUser.Firstname='Test';
            adminUser.Lastname='Test';
            adminUser.LanguageLocaleKey='en_US';
            adminUser.LocaleSidKey='en_US';
            adminUser.TimeZoneSidKey='America/Chicago';
            insert adminUser;
        }

        System.RunAs(adminUser) {
            Account a = new Account(
                Name = 'Test Account 1',
                OwnerId = u.Id,
                Employee_Size__c = '0 - 50',
                Website = 'http://www.test-account-after-trigger-12345.com'
            ); 
            insert a;

            List<Contact> c = new List<Contact>();
            c.add(new Contact(
                FirstName = 'Test1',
                LastName = 'Test1',
                AccountId = a.Id,
                OwnerId = u.Id
            )); 
            c.add(new Contact(
                FirstName = 'Test2',
                LastName = 'Test2',
                AccountId = a.Id,
                OwnerId = u.Id
            )); 
            insert c;

            Test.startTest();
            a.OwnerId = adminUser.Id;
            update a;
            
            List<Contact> results = [ SELECT Id, OwnerId FROM Contact WHERE AccountId = :a.Id AND OwnerId = :adminUser.Id ];
            System.assertEquals(2, results.size());
            Test.stopTest();
        }   
    }
}